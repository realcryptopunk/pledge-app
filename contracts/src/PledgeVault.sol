// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ISwapRouter} from "./interfaces/ISwapRouter.sol";

/// @title PledgeVault
/// @notice Holds user USDC pledges while habits are active. Each deposit creates
///         a unique pledge (identified by pledgeId) so users can run multiple habits
///         concurrently. On failure, a trusted relayer triggers real Uniswap V3 swaps
///         into USDY + bCSPX based on the pledge's captured risk tier. On success,
///         USDC is returned in full.
/// @dev USDY/bCSPX accumulate per-user in usdyBalances/bcspxBalances.
///      Users retrieve them via withdrawInvestment() at any time after investOnFailure().
contract PledgeVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Enums ---

    enum RiskTier { LOW, MEDIUM, HIGH }

    // --- Structs ---

    struct Pledge {
        address  user;
        RiskTier tier;        // captured at deposit time
        uint256  amount;
        uint256  depositedAt;
        bool     active;
    }

    // --- State ---

    IERC20      public immutable usdc;
    ISwapRouter public immutable swapRouter;
    address     public immutable usdy;
    address     public immutable bcspx;

    address  public relayer;
    address  public treasury;
    uint256  public platformFeeBps = 200; // 2%
    uint256  public pledgeTimeout  = 30 days;

    uint24  public constant POOL_FEE    = 3000;  // 0.3%
    uint256 public constant MAX_FEE_BPS = 1000;  // 10% cap

    // [usdyBps, bcspxBps] indexed by RiskTier
    // LOW    = [7000, 3000]
    // MEDIUM = [5000, 5000]
    // HIGH   = [3000, 7000]
    uint256[2][3] private _tierAllocations;

    uint256 public nextPledgeId;
    mapping(uint256 => Pledge)   public pledges;
    mapping(address => RiskTier) public userTier;

    // Per-user accumulated investment balances (populated by investOnFailure)
    mapping(address => uint256) public usdyBalances;
    mapping(address => uint256) public bcspxBalances;

    // --- Events ---

    event Registered(address indexed user, RiskTier tier);
    event Deposited(address indexed user, uint256 indexed pledgeId, uint256 amount);
    event InvestedOnFailure(
        uint256 indexed pledgeId,
        address indexed user,
        uint256 pledgeAmount,
        uint256 fee,
        uint256 usdyOut,
        uint256 bcspxOut
    );
    event ClaimedSuccess(uint256 indexed pledgeId, address indexed user, uint256 amount);
    event PledgeCancelled(uint256 indexed pledgeId, address indexed user, uint256 amount);
    event InvestmentWithdrawn(address indexed user, uint256 usdyAmount, uint256 bcspxAmount);
    event RelayerUpdated(address newRelayer);
    event TreasuryUpdated(address newTreasury);
    event PlatformFeeBpsUpdated(uint256 newBps);
    event PledgeTimeoutUpdated(uint256 newTimeout);

    // --- Modifiers ---

    modifier onlyRelayer() {
        require(msg.sender == relayer, "PledgeVault: not relayer");
        _;
    }

    // --- Constructor ---

    constructor(
        address _usdc,
        address _usdy,
        address _bcspx,
        address _swapRouter,
        address _treasury,
        address _relayer
    ) Ownable(msg.sender) {
        require(_usdc       != address(0), "PledgeVault: zero usdc");
        require(_usdy       != address(0), "PledgeVault: zero usdy");
        require(_bcspx      != address(0), "PledgeVault: zero bcspx");
        require(_swapRouter != address(0), "PledgeVault: zero swapRouter");
        require(_treasury   != address(0), "PledgeVault: zero treasury");
        require(_relayer    != address(0), "PledgeVault: zero relayer");

        usdc       = IERC20(_usdc);
        usdy       = _usdy;
        bcspx      = _bcspx;
        swapRouter = ISwapRouter(_swapRouter);
        treasury   = _treasury;
        relayer    = _relayer;

        _tierAllocations[uint256(RiskTier.LOW)]    = [uint256(7000), uint256(3000)];
        _tierAllocations[uint256(RiskTier.MEDIUM)] = [uint256(5000), uint256(5000)];
        _tierAllocations[uint256(RiskTier.HIGH)]   = [uint256(3000), uint256(7000)];
    }

    // --- Core ---

    /// @notice Set or update the caller's risk tier. The tier in effect at deposit
    ///         time is captured per-pledge, so changing it does not affect existing pledges.
    /// @param tier The risk tier: LOW (70% USDY / 30% bCSPX), MEDIUM (50/50), HIGH (30/70)
    function register(RiskTier tier) external {
        if (userTier[msg.sender] == tier) return;
        userTier[msg.sender] = tier;
        emit Registered(msg.sender, tier);
    }

    /// @notice Deposit USDC to start a new habit accountability window. A unique
    ///         pledgeId is returned; pass it to the relayer so it can resolve the habit.
    ///         Multiple concurrent pledges per user are supported.
    /// @param amount Amount of USDC to pledge (must be pre-approved)
    /// @return pledgeId Unique identifier for this pledge
    function deposit(uint256 amount) external nonReentrant returns (uint256 pledgeId) {
        require(amount > 0, "PledgeVault: zero amount");

        usdc.safeTransferFrom(msg.sender, address(this), amount);

        pledgeId = nextPledgeId++;
        pledges[pledgeId] = Pledge({
            user:        msg.sender,
            tier:        userTier[msg.sender],
            amount:      amount,
            depositedAt: block.timestamp,
            active:      true
        });

        emit Deposited(msg.sender, pledgeId, amount);
    }

    /// @notice Called by the relayer when a habit is missed. Takes a platform fee,
    ///         then swaps remaining USDC into USDY + bCSPX per the pledge's risk tier.
    /// @param pledgeId     The pledge to resolve as failed
    /// @param usdyMinOut   Minimum USDY tokens to receive (slippage guard). Pass 0 during testing.
    /// @param bcspxMinOut  Minimum bCSPX tokens to receive (slippage guard). Pass 0 during testing.
    function investOnFailure(uint256 pledgeId, uint256 usdyMinOut, uint256 bcspxMinOut)
        external nonReentrant onlyRelayer
    {
        Pledge storage p = pledges[pledgeId];
        require(p.active, "PledgeVault: not active");

        address  user   = p.user;
        uint256  pledge = p.amount;
        RiskTier tier   = p.tier;

        // CEI: clear state before any external calls
        p.active = false;
        p.amount = 0;

        uint256 fee = (pledge * platformFeeBps) / 10000;
        if (fee > 0) {
            usdc.safeTransfer(treasury, fee);
        }

        uint256 investAmount = pledge - fee;

        uint256[2] memory alloc = _tierAllocations[uint256(tier)];
        uint256 usdyAmount  = (investAmount * alloc[0]) / 10000;
        // Remainder to bcspx avoids rounding dust
        uint256 bcspxAmount = investAmount - usdyAmount;

        // Approve router for the full invest amount, then consume across two swaps
        usdc.forceApprove(address(swapRouter), investAmount);

        uint256 usdyOut  = _swap(address(usdc), usdy,  usdyAmount,  usdyMinOut);
        uint256 bcspxOut = _swap(address(usdc), bcspx, bcspxAmount, bcspxMinOut);

        // Reset approval (defense-in-depth)
        usdc.forceApprove(address(swapRouter), 0);

        // Record per-user balances so withdrawInvestment() can attribute correctly
        usdyBalances[user]  += usdyOut;
        bcspxBalances[user] += bcspxOut;

        emit InvestedOnFailure(pledgeId, user, pledge, fee, usdyOut, bcspxOut);
    }

    /// @notice Called by the relayer when a habit is successfully completed.
    ///         Returns the full pledge amount to the user with no fee.
    /// @param pledgeId The pledge to resolve as successful
    function claimSuccess(uint256 pledgeId) external nonReentrant onlyRelayer {
        Pledge storage p = pledges[pledgeId];
        require(p.active, "PledgeVault: not active");

        address user   = p.user;
        uint256 amount = p.amount;

        // CEI: clear state before transfer
        p.active = false;
        p.amount = 0;

        usdc.safeTransfer(user, amount);

        emit ClaimedSuccess(pledgeId, user, amount);
    }

    /// @notice Emergency escape hatch: user can reclaim their USDC if the relayer
    ///         has not resolved the pledge within `pledgeTimeout` seconds of deposit.
    ///         No fee is taken — this is purely a liveness safety net.
    /// @param pledgeId The pledge to cancel
    function cancelPledge(uint256 pledgeId) external nonReentrant {
        Pledge storage p = pledges[pledgeId];
        require(p.active, "PledgeVault: not active");
        require(p.user == msg.sender, "PledgeVault: not pledge owner");
        require(
            block.timestamp >= p.depositedAt + pledgeTimeout,
            "PledgeVault: timeout not reached"
        );

        uint256 amount = p.amount;

        // CEI: clear state before transfer
        p.active = false;
        p.amount = 0;

        usdc.safeTransfer(msg.sender, amount);

        emit PledgeCancelled(pledgeId, msg.sender, amount);
    }

    /// @notice Withdraw accumulated USDY and bCSPX from previous failed habits.
    ///         Transfers the caller's full invested balance of both tokens back to them.
    function withdrawInvestment() external nonReentrant {
        uint256 usdyAmt  = usdyBalances[msg.sender];
        uint256 bcspxAmt = bcspxBalances[msg.sender];
        require(usdyAmt > 0 || bcspxAmt > 0, "PledgeVault: nothing to withdraw");

        // CEI: clear balances before transfers
        usdyBalances[msg.sender]  = 0;
        bcspxBalances[msg.sender] = 0;

        if (usdyAmt  > 0) IERC20(usdy).safeTransfer(msg.sender, usdyAmt);
        if (bcspxAmt > 0) IERC20(bcspx).safeTransfer(msg.sender, bcspxAmt);

        emit InvestmentWithdrawn(msg.sender, usdyAmt, bcspxAmt);
    }

    // --- Views ---

    function getPledge(uint256 pledgeId)
        external
        view
        returns (
            address  user,
            RiskTier tier,
            uint256  amount,
            uint256  depositedAt,
            bool     active
        )
    {
        Pledge storage p = pledges[pledgeId];
        return (p.user, p.tier, p.amount, p.depositedAt, p.active);
    }

    function getTierAllocations(RiskTier tier)
        external
        view
        returns (uint256 usdyBps, uint256 bcspxBps)
    {
        uint256[2] memory alloc = _tierAllocations[uint256(tier)];
        return (alloc[0], alloc[1]);
    }

    // --- Admin ---

    function setRelayer(address _relayer) external onlyOwner {
        require(_relayer != address(0), "PledgeVault: zero relayer");
        relayer = _relayer;
        emit RelayerUpdated(_relayer);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "PledgeVault: zero treasury");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setPlatformFeeBps(uint256 _bps) external onlyOwner {
        require(_bps <= MAX_FEE_BPS, "PledgeVault: fee too high");
        platformFeeBps = _bps;
        emit PlatformFeeBpsUpdated(_bps);
    }

    function setPledgeTimeout(uint256 _timeout) external onlyOwner {
        require(_timeout > 0, "PledgeVault: zero timeout");
        pledgeTimeout = _timeout;
        emit PledgeTimeoutUpdated(_timeout);
    }

    // --- Internal ---

    function _swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 minOut)
        internal
        returns (uint256 amountOut)
    {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn:           tokenIn,
            tokenOut:          tokenOut,
            fee:               POOL_FEE,
            recipient:         address(this),
            amountIn:          amountIn,
            amountOutMinimum:  minOut,
            sqrtPriceLimitX96: 0
        });
        return swapRouter.exactInputSingle(params);
    }
}
