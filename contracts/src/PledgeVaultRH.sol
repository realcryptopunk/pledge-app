// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PledgeVaultRH is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- State ---
    IERC20 public immutable usdc;
    address public relayer;
    address public treasury;
    uint256 public platformFeeBps = 200; // 2%

    struct StockAllocation {
        address token;
        uint256 bps;
    }

    StockAllocation[] public defaultAllocations;

    // user => stockToken => USDC-denominated balance
    mapping(address => mapping(address => uint256)) public userStockBalances;

    // track which tokens a user holds for iteration
    mapping(address => address[]) internal _userTokens;
    mapping(address => mapping(address => bool)) internal _hasToken;

    // --- Events ---
    event Invested(address indexed user, uint256 usdcAmount, uint256 fee);
    event EmergencyWithdraw(address indexed user, uint256 totalReturned);
    event AllocationsUpdated(uint256 count);
    event RelayerUpdated(address newRelayer);
    event TreasuryUpdated(address newTreasury);

    // --- Modifiers ---
    modifier onlyRelayer() {
        require(msg.sender == relayer, "PledgeVault: not relayer");
        _;
    }

    // --- Constructor ---
    constructor(address _usdc, address _treasury, address _relayer) Ownable(msg.sender) {
        require(_usdc != address(0), "PledgeVault: zero usdc");
        require(_treasury != address(0), "PledgeVault: zero treasury");
        require(_relayer != address(0), "PledgeVault: zero relayer");
        usdc = IERC20(_usdc);
        treasury = _treasury;
        relayer = _relayer;
    }

    // --- Core ---

    function investForUser(address user, uint256 usdcAmount) external onlyRelayer nonReentrant {
        require(user != address(0), "PledgeVault: zero user");
        require(usdcAmount > 0, "PledgeVault: zero amount");
        require(defaultAllocations.length > 0, "PledgeVault: no allocations");

        // Pull USDC from user (requires prior approval)
        usdc.safeTransferFrom(user, address(this), usdcAmount);

        // Platform fee
        uint256 fee = (usdcAmount * platformFeeBps) / 10000;
        if (fee > 0) {
            usdc.safeTransfer(treasury, fee);
        }

        // Distribute remaining across stock allocations (tracked as USDC value)
        uint256 investAmount = usdcAmount - fee;
        for (uint256 i = 0; i < defaultAllocations.length; i++) {
            StockAllocation memory alloc = defaultAllocations[i];
            uint256 tokenAmount = (investAmount * alloc.bps) / 10000;
            if (tokenAmount > 0) {
                userStockBalances[user][alloc.token] += tokenAmount;
                if (!_hasToken[user][alloc.token]) {
                    _userTokens[user].push(alloc.token);
                    _hasToken[user][alloc.token] = true;
                }
            }
        }

        emit Invested(user, usdcAmount, fee);
    }

    function emergencyWithdraw() external nonReentrant {
        address[] memory tokens = _userTokens[msg.sender];
        require(tokens.length > 0, "PledgeVault: no positions");

        uint256 totalReturn = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 bal = userStockBalances[msg.sender][tokens[i]];
            if (bal > 0) {
                totalReturn += bal;
                userStockBalances[msg.sender][tokens[i]] = 0;
            }
            _hasToken[msg.sender][tokens[i]] = false;
        }
        delete _userTokens[msg.sender];

        require(totalReturn > 0, "PledgeVault: nothing to withdraw");
        usdc.safeTransfer(msg.sender, totalReturn);

        emit EmergencyWithdraw(msg.sender, totalReturn);
    }

    // --- Views ---

    function getUserPortfolio(address user)
        external
        view
        returns (address[] memory tokens, uint256[] memory balances)
    {
        tokens = _userTokens[user];
        balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balances[i] = userStockBalances[user][tokens[i]];
        }
    }

    function getAllocationsCount() external view returns (uint256) {
        return defaultAllocations.length;
    }

    // --- Admin ---

    function setAllocations(StockAllocation[] calldata allocs) external onlyOwner {
        delete defaultAllocations;
        uint256 totalBps = 0;
        for (uint256 i = 0; i < allocs.length; i++) {
            require(allocs[i].token != address(0), "PledgeVault: zero token");
            require(allocs[i].bps > 0, "PledgeVault: zero bps");
            totalBps += allocs[i].bps;
            defaultAllocations.push(allocs[i]);
        }
        require(totalBps == 10000, "PledgeVault: bps must total 10000");
        emit AllocationsUpdated(allocs.length);
    }

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
}
