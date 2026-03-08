// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PledgeVault} from "../src/PledgeVault.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract PledgeVaultIntegrationTest is Test {
    PledgeVault vault;
    MockERC20   usdc;
    MockERC20   usdy;
    MockERC20   bcspx;

    address deployer = 0x1bB38d9F94804A36EEE5FB8e18D012B5Aa687563; // Owner/Relayer/Treasury
    address alice    = makeAddr("alice");

    uint256 constant PLEDGE = 100e6; // 100 USDC

    function setUp() public {
        // Attach to deployed Arbitrum Sepolia addresses
        vault = PledgeVault(0xb7DdF629007C2A489C254eea3726750235B82178);
        usdc  = MockERC20(0x9cA75917e9c158569a602cb2504823282fb4Fc45);
        usdy  = MockERC20(0xa6b874b3d8A7998aB470701Ba05558Ad51539d9E);
        bcspx = MockERC20(0xCCf2A2cf6d3a444D6aCd2B239CABAcab48C669e9);

        // Impersonate deployer to fund Alice for testing
        vm.startPrank(deployer);
        usdc.transfer(alice, 1000e6);
        vm.stopPrank();

        // Alice approves the vault
        vm.prank(alice);
        usdc.approve(address(vault), type(uint256).max);
    }

    function test_live_deposit_and_fail_swap() public {
        // 1. Alice deposits
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.MEDIUM);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        // 2. Relayer fails the habit and triggers live Uniswap V3 swap
        vm.prank(deployer);
        vault.investOnFailure(pledgeId, 0, 0);

        // 3. Verify real testnet swaps occurred
        uint256 usdyBal  = vault.usdyBalances(alice);
        uint256 bcspxBal = vault.bcspxBalances(alice);
        
        console.log("Alice USDY balance:", usdyBal);
        console.log("Alice bCSPX balance:", bcspxBal);

        assertTrue(usdyBal > 0, "USDY swap failed");
        assertTrue(bcspxBal > 0, "bCSPX swap failed");
    }
}