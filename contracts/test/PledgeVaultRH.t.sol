// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PledgeVaultRH.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract PledgeVaultRHTest is Test {
    event Invested(address indexed user, uint256 usdcAmount, uint256 fee);

    PledgeVaultRH public vault;
    MockERC20 public usdc;
    address public treasury = makeAddr("treasury");
    address public relayer = makeAddr("relayer");
    address public user = makeAddr("user");
    address public owner;

    // Stock token addresses (mock)
    address public tsla = makeAddr("TSLA");
    address public amzn = makeAddr("AMZN");
    address public pltr = makeAddr("PLTR");
    address public amd = makeAddr("AMD");

    function setUp() public {
        owner = address(this);
        usdc = new MockERC20("USD Coin", "USDC");
        vault = new PledgeVaultRH(address(usdc), treasury, relayer);

        // Set default allocations: 30% TSLA, 25% AMZN, 25% PLTR, 20% AMD
        PledgeVaultRH.StockAllocation[] memory allocs = new PledgeVaultRH.StockAllocation[](4);
        allocs[0] = PledgeVaultRH.StockAllocation(tsla, 3000);
        allocs[1] = PledgeVaultRH.StockAllocation(amzn, 2500);
        allocs[2] = PledgeVaultRH.StockAllocation(pltr, 2500);
        allocs[3] = PledgeVaultRH.StockAllocation(amd, 2000);
        vault.setAllocations(allocs);

        // Fund user with USDC
        usdc.mint(user, 10000e18);
        vm.prank(user);
        usdc.approve(address(vault), type(uint256).max);
    }

    // --- investForUser ---

    function test_investForUser_splits_correctly() public {
        uint256 amount = 1000e18;

        vm.prank(relayer);
        vault.investForUser(user, amount);

        // 2% fee = 20 USDC to treasury
        assertEq(usdc.balanceOf(treasury), 20e18, "treasury fee");

        // 98% = 980 USDC distributed:
        // TSLA: 800 * 30% = 240
        assertEq(vault.userStockBalances(user, tsla), 294e18, "TSLA balance");
        // AMZN: 800 * 25% = 200
        assertEq(vault.userStockBalances(user, amzn), 245e18, "AMZN balance");
        // PLTR: 800 * 25% = 200
        assertEq(vault.userStockBalances(user, pltr), 245e18, "PLTR balance");
        // AMD: 800 * 20% = 160
        assertEq(vault.userStockBalances(user, amd), 196e18, "AMD balance");

        // Vault holds the 980 USDC (tracked as stock positions)
        assertEq(usdc.balanceOf(address(vault)), 980e18, "vault balance");
    }

    function test_investForUser_emits_event() public {
        uint256 amount = 500e18;

        vm.expectEmit(true, false, false, true);
        emit Invested(user, 500e18, 10e18);

        vm.prank(relayer);
        vault.investForUser(user, amount);
    }

    function test_investForUser_accumulates() public {
        vm.startPrank(relayer);
        vault.investForUser(user, 1000e18);
        vault.investForUser(user, 1000e18);
        vm.stopPrank();

        // Should double
        assertEq(vault.userStockBalances(user, tsla), 588e18);
    }

    // --- Access control ---

    function test_investForUser_reverts_nonRelayer() public {
        vm.expectRevert("PledgeVault: not relayer");
        vault.investForUser(user, 100e18);
    }

    function test_setAllocations_reverts_nonOwner() public {
        PledgeVaultRH.StockAllocation[] memory allocs = new PledgeVaultRH.StockAllocation[](1);
        allocs[0] = PledgeVaultRH.StockAllocation(tsla, 10000);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vault.setAllocations(allocs);
    }

    function test_setRelayer_reverts_nonOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vault.setRelayer(makeAddr("new"));
    }

    function test_setTreasury_reverts_nonOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vault.setTreasury(makeAddr("new"));
    }

    // --- Edge cases ---

    function test_investForUser_reverts_zeroAmount() public {
        vm.prank(relayer);
        vm.expectRevert("PledgeVault: zero amount");
        vault.investForUser(user, 0);
    }

    function test_investForUser_reverts_zeroAddress() public {
        vm.prank(relayer);
        vm.expectRevert("PledgeVault: zero user");
        vault.investForUser(address(0), 100e18);
    }

    function test_constructor_reverts_zeroUsdc() public {
        vm.expectRevert("PledgeVault: zero usdc");
        new PledgeVaultRH(address(0), treasury, relayer);
    }

    function test_constructor_reverts_zeroTreasury() public {
        vm.expectRevert("PledgeVault: zero treasury");
        new PledgeVaultRH(address(usdc), address(0), relayer);
    }

    function test_constructor_reverts_zeroRelayer() public {
        vm.expectRevert("PledgeVault: zero relayer");
        new PledgeVaultRH(address(usdc), treasury, address(0));
    }

    function test_setAllocations_reverts_badBps() public {
        PledgeVaultRH.StockAllocation[] memory allocs = new PledgeVaultRH.StockAllocation[](1);
        allocs[0] = PledgeVaultRH.StockAllocation(tsla, 5000);

        vm.expectRevert("PledgeVault: bps must total 10000");
        vault.setAllocations(allocs);
    }

    function test_setAllocations_reverts_zeroToken() public {
        PledgeVaultRH.StockAllocation[] memory allocs = new PledgeVaultRH.StockAllocation[](1);
        allocs[0] = PledgeVaultRH.StockAllocation(address(0), 10000);

        vm.expectRevert("PledgeVault: zero token");
        vault.setAllocations(allocs);
    }

    // --- emergencyWithdraw ---

    function test_emergencyWithdraw() public {
        vm.prank(relayer);
        vault.investForUser(user, 1000e18);

        uint256 userBalBefore = usdc.balanceOf(user);

        vm.prank(user);
        vault.emergencyWithdraw();

        // User gets back 980 USDC (after 2% fee was taken)
        assertEq(usdc.balanceOf(user) - userBalBefore, 980e18, "returned amount");

        // All positions cleared
        assertEq(vault.userStockBalances(user, tsla), 0);
        assertEq(vault.userStockBalances(user, amzn), 0);
        assertEq(vault.userStockBalances(user, pltr), 0);
        assertEq(vault.userStockBalances(user, amd), 0);
    }

    function test_emergencyWithdraw_reverts_noPositions() public {
        vm.prank(user);
        vm.expectRevert("PledgeVault: no positions");
        vault.emergencyWithdraw();
    }

    // --- getUserPortfolio ---

    function test_getUserPortfolio() public {
        vm.prank(relayer);
        vault.investForUser(user, 1000e18);

        (address[] memory tokens, uint256[] memory balances) = vault.getUserPortfolio(user);

        assertEq(tokens.length, 4);
        assertEq(balances.length, 4);

        // Verify totals add to 800
        uint256 total = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            total += balances[i];
        }
        assertEq(total, 980e18, "total portfolio");
    }

    // --- Admin ---

    function test_setRelayer() public {
        address newRelayer = makeAddr("newRelayer");
        vault.setRelayer(newRelayer);
        assertEq(vault.relayer(), newRelayer);
    }

    function test_setTreasury() public {
        address newTreasury = makeAddr("newTreasury");
        vault.setTreasury(newTreasury);
        assertEq(vault.treasury(), newTreasury);
    }

    function test_setRelayer_reverts_zero() public {
        vm.expectRevert("PledgeVault: zero relayer");
        vault.setRelayer(address(0));
    }

    function test_setTreasury_reverts_zero() public {
        vm.expectRevert("PledgeVault: zero treasury");
        vault.setTreasury(address(0));
    }
}
