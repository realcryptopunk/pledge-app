// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PledgeVault} from "../src/PledgeVault.sol";
import {MockERC20} from "../test/mocks/MockERC20.sol";

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24  fee;
        int24   tickLower;
        int24   tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24  fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);

    function mint(MintParams calldata params)
        external payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
}

contract DeployArbitrum is Script {
    // Uniswap V3 on Arbitrum Sepolia
    address constant SWAP_ROUTER_02   = 0x101F443B4d1b059569D643917553c771E1b9663E;
    address constant NFT_POSITION_MGR = 0x6b2937Bde17889EDCf8fbD8dE31C3C2a70Bc4d65;

    uint24 constant POOL_FEE   = 3000;   // 0.3%
    // Full-range ticks for fee=3000 (tickSpacing=60): floor(887272/60)*60
    int24  constant TICK_LOWER = -887220;
    int24  constant TICK_UPPER =  887220;

    // Seed amounts — enough for a useful hackathon demo
    uint256 constant SEED_USDC  = 100_000e6;   // 100k USDC
    uint256 constant SEED_18DEC = 100_000e18;  // 100k USDY / bCSPX

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer    = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // Deploy mock tokens (USDY and bCSPX have no Arbitrum Sepolia deployments)
        MockERC20 mockUSDC  = new MockERC20("USD Coin",     "USDC",  6);
        MockERC20 mockUSDY  = new MockERC20("Ondo USDY",    "USDY",  18);
        MockERC20 mockBCSPX = new MockERC20("Backed bCSPX", "bCSPX", 18);

        // Mint supply to deployer (vault operations + pool seeding)
        mockUSDC.mint(deployer,  1_000_000e6);
        mockUSDY.mint(deployer,  1_000_000e18);
        mockBCSPX.mint(deployer, 1_000_000e18);

        // Deploy PledgeVault
        // deployer acts as both treasury and relayer initially; replace relayer with
        // the actual backend address after deployment via vault.setRelayer()
        PledgeVault vault = new PledgeVault(
            address(mockUSDC),
            address(mockUSDY),
            address(mockBCSPX),
            SWAP_ROUTER_02,
            deployer, // treasury
            deployer  // relayer (replace after deploy)
        );

        // Seed Uniswap V3 pools so the vault's swaps have liquidity to execute against
        INonfungiblePositionManager nfpm = INonfungiblePositionManager(NFT_POSITION_MGR);
        _seedPool(nfpm, deployer, address(mockUSDC), address(mockUSDY),  SEED_USDC, SEED_18DEC);
        _seedPool(nfpm, deployer, address(mockUSDC), address(mockBCSPX), SEED_USDC, SEED_18DEC);

        vm.stopBroadcast();

        console.log("=== Arbitrum Sepolia Deployment ===");
        console.log("MockUSDC   :", address(mockUSDC));
        console.log("MockUSDY   :", address(mockUSDY));
        console.log("MockBCSPX  :", address(mockBCSPX));
        console.log("PledgeVault:", address(vault));
        console.log("Owner/Treasury/Relayer:", deployer);
        console.log("");
        console.log("Next steps:");
        console.log("  1. Call vault.setRelayer(<backend-address>) once relayer is deployed");
    }

    /// @dev Creates (if needed) and seeds a Uniswap V3 pool at 1:1 USD price.
    ///      tokenA is always USDC (6 dec); tokenB is always an 18-dec token.
    ///      Tokens are sorted (token0 < token1) as required by the position manager.
    function _seedPool(
        INonfungiblePositionManager nfpm,
        address deployer,
        address tokenA,   // USDC (6 dec)
        address tokenB,   // USDY or bCSPX (18 dec)
        uint256 amountA,
        uint256 amountB
    ) internal {
        // Sort tokens; remember which side USDC ended up on
        bool usdcIsToken0 = tokenA < tokenB;
        (address token0, address token1) = usdcIsToken0
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        (uint256 amount0Desired, uint256 amount1Desired) = usdcIsToken0
            ? (amountA, amountB)
            : (amountB, amountA);

        // sqrtPriceX96 encodes sqrt(token1/token0) * 2^96 (Q64.96).
        // At 1:1 USD value between USDC (6 dec) and an 18-dec token:
        //   USDC is token0 → price = 1e18/1e6 = 1e12 → sqrtPrice = sqrt(1e12) * 2^96 = 1e6 * 2^96
        //   USDC is token1 → price = 1e6/1e18 = 1e-12 → sqrtPrice = 2^96 / 1e6
        // 2^96 = 79228162514264337593543950336
        // floor(2^96 / 1e6) = 79228162514264337593543  (precomputed; remainder 950336 dropped)
        uint160 sqrtPriceX96 = usdcIsToken0
            ? uint160(1_000_000) * uint160(79228162514264337593543950336)  // 7.92e34, fits uint160
            : uint160(79228162514264337593543);                             // 7.92e22

        // Create pool and set initial price (no-op if already exists at this price)
        nfpm.createAndInitializePoolIfNecessary(token0, token1, POOL_FEE, sqrtPriceX96);

        // Approve and mint a full-range LP position
        IERC20(token0).approve(address(nfpm), amount0Desired);
        IERC20(token1).approve(address(nfpm), amount1Desired);

        nfpm.mint(INonfungiblePositionManager.MintParams({
            token0:         token0,
            token1:         token1,
            fee:            POOL_FEE,
            tickLower:      TICK_LOWER,
            tickUpper:      TICK_UPPER,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min:     0,
            amount1Min:     0,
            recipient:      deployer,
            deadline:       block.timestamp + 600
        }));
    }
}
