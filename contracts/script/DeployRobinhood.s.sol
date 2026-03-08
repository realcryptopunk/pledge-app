// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PledgeVault} from "../src/PledgeVault.sol";
import {MockERC20} from "../test/mocks/MockERC20.sol";
import {MockSwapRouter} from "../test/mocks/MockSwapRouter.sol";

contract DeployRobinhood is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer    = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        // Deploy mock tokens
        MockERC20 mockUSDC  = new MockERC20("USD Coin",     "USDC",  6);
        MockERC20 mockUSDY  = new MockERC20("Ondo USDY",    "USDY",  18);
        MockERC20 mockBCSPX = new MockERC20("Backed bCSPX", "bCSPX", 18);

        // Mint supply to deployer
        mockUSDC.mint(deployer,  1_000_000e6);
        mockUSDY.mint(deployer,  1_000_000e18);
        mockBCSPX.mint(deployer, 1_000_000e18);

        // Deploy MockSwapRouter — simulates Uniswap V3 swaps at 1:1 by default.
        // Seed it with USDY and bCSPX so it can mint output tokens on swap.
        MockSwapRouter mockRouter = new MockSwapRouter();

        // Deploy PledgeVault pointing to the mock router
        PledgeVault vault = new PledgeVault(
            address(mockUSDC),
            address(mockUSDY),
            address(mockBCSPX),
            address(mockRouter),
            deployer, // treasury
            deployer  // relayer (replace after deploy)
        );

        vm.stopBroadcast();

        console.log("=== Robinhood Testnet Deployment ===");
        console.log("MockUSDC      :", address(mockUSDC));
        console.log("MockUSDY      :", address(mockUSDY));
        console.log("MockBCSPX     :", address(mockBCSPX));
        console.log("MockSwapRouter:", address(mockRouter));
        console.log("PledgeVault   :", address(vault));
        console.log("Owner/Treasury/Relayer:", deployer);
        console.log("");
        console.log("Next steps:");
        console.log("  1. Call vault.setRelayer(<backend-address>) once relayer is deployed");
    }
}
