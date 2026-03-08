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
    event EmergencyWithdraw(address indexed user, uint256 totalReturned);
    event AllocationsUpdated(uint256 count);
    event RelayerUpdated(address newRelayer);
    event TreasuryUpdated(address newTreasury);

    PledgeVaultRH public vault;
    MockERC20 public usdc;
    address public treasury = makeAddr("treasury");
    address public relayer = makeAddr("relayer");
    address public user = makeAddr("user");
    address public user2 = makeAddr("user2");
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

        // Fund user2
        usdc.mint(user2, 10000e18);
        vm.prank(user2);
        usdc.approve(address(vault), type(uint256).max);
    }

    // =====================
    // Constructor
    // =====================

    function test_constructor_sets_state() public view {
        assertEq(address(vault.usdc()), address(usdc));
        assertEq(vault.treasury(), treasury);
        assertEq(vault.relayer(), relayer);
        assertEq(vault.owner(), owner);
        assertEq(vault.platformFeeBps(), 200);
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

    // =====================
    // investForUser
    // =====================

    function test_investForUser_splits_correctly() public {
        uint256 amount = 1000e18;

        vm.prank(relayer);
        vault.investForUser(user, amount);

        // 2% fee = 20 USDC to treasury
        assertEq(usdc.balanceOf(treasury), 20e18, "treasury fee");

        // 98% = 980 USDC distributed:
        // TSLA: 980 * 30% = 294
        assertEq(vault.userStockBalances(user, tsla), 294e18, "TSLA balance");
        // AMZN: 980 * 25% = 245
        assertEq(vault.userStockBalances(user, amzn), 245e18, "AMZN balance");
        // PLTR: 980 * 25% = 245
        assertEq(vault.userStockBalances(user, pltr), 245e18, "PLTR balance");
        // AMD: 980 * 20% = 196
        assertEq(vault.userStockBalances(user, amd), 196e18, "AMD balance");

        // Vault holds the 980 USDC (tracked as stock positions)
        assertEq(usdc.balanceOf(address(vault)), 980e18, "vault balance");
    }

    function test_investForUser_emits_event() public {
        vm.expectEmit(true, false, false, true);
        emit Invested(user, 500e18, 10e18);

        vm.prank(relayer);
        vault.investForUser(user, 500e18);
    }

    function test_investForUser_accumulates() public {
        vm.startPrank(relayer);
        vault.investForUser(user, 1000e18);
        vault.investForUser(user, 1000e18);
        vm.stopPrank();

        assertEq(vault.userStockBalances(user, tsla), 588e18);
        assertEq(vault.userStockBalances(user, amzn), 490e18);
        assertEq(vault.userStockBalances(user, pltr), 490e18);
        assertEq(vault.userStockBalances(user, amd), 392e18);
    }

    function test_investForUser_multiple_users_independent() public {
        vm.startPrank(relayer);
        vault.investForUser(user, 1000e18);
        vault.investForUser(user2, 500e18);
        vm.stopPrank();

        // User1: 980 * 30% = 294
        assertEq(vault.userStockBalances(user, tsla), 294e18);
        // User2: 490 * 30% = 147
        assertEq(vault.userStockBalances(user2, tsla), 147e18);

        // Balances are independent
        assertEq(vault.userStockBalances(user, amzn), 245e18);
        assertEq(vault.userStockBalances(user2, amzn), 122500000000000000000); // 122.5
    }

    function test_investForUser_small_amount() public {
        // Test with 1 USDC (1e18)
        vm.prank(relayer);
        vault.investForUser(user, 1e18);

        // Fee: 1e18 * 200 / 10000 = 0.02e18
        assertEq(usdc.balanceOf(treasury), 0.02e18);

        // Invest: 0.98e18
        uint256 total = vault.userStockBalances(user, tsla) +
            vault.userStockBalances(user, amzn) +
            vault.userStockBalances(user, pltr) +
            vault.userStockBalances(user, amd);
        assertEq(total, 0.98e18, "total invested");
    }

    function test_investForUser_very_small_amount_dust() public {
        // 100 wei - fee is 2 wei, invest is 98 wei
        vm.prank(relayer);
        vault.investForUser(user, 100);

        assertEq(usdc.balanceOf(treasury), 2); // 2 wei fee

        // Some dust may be lost due to integer division
        uint256 total = vault.userStockBalances(user, tsla) +
            vault.userStockBalances(user, amzn) +
            vault.userStockBalances(user, pltr) +
            vault.userStockBalances(user, amd);
        // 98 * 3000/10000 = 29, 98 * 2500/10000 = 24, 98 * 2500/10000 = 24, 98 * 2000/10000 = 19
        // Total: 29 + 24 + 24 + 19 = 96 (2 wei dust lost)
        assertEq(total, 96, "dust from integer division");
    }

    function test_investForUser_reverts_nonRelayer() public {
        vm.expectRevert("PledgeVault: not relayer");
        vault.investForUser(user, 100e18);
    }

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

    function test_investForUser_reverts_noAllocations() public {
        // Deploy fresh vault without allocations
        PledgeVaultRH freshVault = new PledgeVaultRH(address(usdc), treasury, relayer);

        usdc.mint(user, 100e18);
        vm.prank(user);
        usdc.approve(address(freshVault), type(uint256).max);

        vm.prank(relayer);
        vm.expectRevert("PledgeVault: no allocations");
        freshVault.investForUser(user, 100e18);
    }

    function test_investForUser_reverts_insufficientBalance() public {
        address broke = makeAddr("broke");
        // No USDC minted, but approve
        vm.prank(broke);
        usdc.approve(address(vault), type(uint256).max);

        vm.prank(relayer);
        vm.expectRevert(); // ERC20 transfer will fail
        vault.investForUser(broke, 100e18);
    }

    function test_investForUser_reverts_noApproval() public {
        address noApproval = makeAddr("noApproval");
        usdc.mint(noApproval, 100e18);
        // No approval given

        vm.prank(relayer);
        vm.expectRevert(); // SafeERC20 will revert
        vault.investForUser(noApproval, 100e18);
    }

    // =====================
    // emergencyWithdraw
    // =====================

    function test_emergencyWithdraw() public {
        vm.prank(relayer);
        vault.investForUser(user, 1000e18);

        uint256 userBalBefore = usdc.balanceOf(user);

        vm.expectEmit(true, false, false, true);
        emit EmergencyWithdraw(user, 980e18);

        vm.prank(user);
        vault.emergencyWithdraw();

        // User gets back 980 USDC (after 2% fee was taken on invest)
        assertEq(usdc.balanceOf(user) - userBalBefore, 980e18, "returned amount");

        // All positions cleared
        assertEq(vault.userStockBalances(user, tsla), 0);
        assertEq(vault.userStockBalances(user, amzn), 0);
        assertEq(vault.userStockBalances(user, pltr), 0);
        assertEq(vault.userStockBalances(user, amd), 0);
    }

    function test_emergencyWithdraw_after_multiple_invests() public {
        vm.startPrank(relayer);
        vault.investForUser(user, 500e18);
        vault.investForUser(user, 500e18);
        vm.stopPrank();

        uint256 userBalBefore = usdc.balanceOf(user);

        vm.prank(user);
        vault.emergencyWithdraw();

        // 2 x 500 = 1000. Fee: 2 x 10 = 20. Return: 980
        assertEq(usdc.balanceOf(user) - userBalBefore, 980e18);
    }

    function test_emergencyWithdraw_one_user_doesnt_affect_another() public {
        vm.startPrank(relayer);
        vault.investForUser(user, 1000e18);
        vault.investForUser(user2, 500e18);
        vm.stopPrank();

        vm.prank(user);
        vault.emergencyWithdraw();

        // user2 positions untouched
        assertEq(vault.userStockBalances(user2, tsla), 147e18);
        assertEq(vault.userStockBalances(user2, amzn), 122500000000000000000);
    }

    function test_emergencyWithdraw_cannot_withdraw_twice() public {
        vm.prank(relayer);
        vault.investForUser(user, 1000e18);

        vm.startPrank(user);
        vault.emergencyWithdraw();

        vm.expectRevert("PledgeVault: no positions");
        vault.emergencyWithdraw();
        vm.stopPrank();
    }

    function test_emergencyWithdraw_reverts_noPositions() public {
        vm.prank(user);
        vm.expectRevert("PledgeVault: no positions");
        vault.emergencyWithdraw();
    }

    // =====================
    // getUserPortfolio
    // =====================

    function test_getUserPortfolio() public {
        vm.prank(relayer);
        vault.investForUser(user, 1000e18);

        (address[] memory tokens, uint256[] memory balances) = vault.getUserPortfolio(user);

        assertEq(tokens.length, 4);
        assertEq(balances.length, 4);

        uint256 total = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            total += balances[i];
        }
        assertEq(total, 980e18, "total portfolio");
    }

    function test_getUserPortfolio_empty() public view {
        (address[] memory tokens, uint256[] memory balances) = vault.getUserPortfolio(user);
        assertEq(tokens.length, 0);
        assertEq(balances.length, 0);
    }

    function test_getUserPortfolio_after_withdraw() public {
        vm.prank(relayer);
        vault.investForUser(user, 1000e18);

        vm.prank(user);
        vault.emergencyWithdraw();

        (address[] memory tokens, uint256[] memory balances) = vault.getUserPortfolio(user);
        assertEq(tokens.length, 0);
        assertEq(balances.length, 0);
    }

    // =====================
    // setAllocations
    // =====================

    function test_setAllocations_updates() public {
        // Change to 50/50 TSLA/AMZN
        PledgeVaultRH.StockAllocation[] memory allocs = new PledgeVaultRH.StockAllocation[](2);
        allocs[0] = PledgeVaultRH.StockAllocation(tsla, 5000);
        allocs[1] = PledgeVaultRH.StockAllocation(amzn, 5000);

        vm.expectEmit(false, false, false, true);
        emit AllocationsUpdated(2);

        vault.setAllocations(allocs);

        assertEq(vault.getAllocationsCount(), 2);

        // New invest should use new allocations
        vm.prank(relayer);
        vault.investForUser(user, 1000e18);

        assertEq(vault.userStockBalances(user, tsla), 490e18); // 980 * 50%
        assertEq(vault.userStockBalances(user, amzn), 490e18); // 980 * 50%
    }

    function test_setAllocations_single_asset() public {
        PledgeVaultRH.StockAllocation[] memory allocs = new PledgeVaultRH.StockAllocation[](1);
        allocs[0] = PledgeVaultRH.StockAllocation(tsla, 10000);
        vault.setAllocations(allocs);

        assertEq(vault.getAllocationsCount(), 1);

        vm.prank(relayer);
        vault.investForUser(user, 1000e18);

        assertEq(vault.userStockBalances(user, tsla), 980e18);
    }

    function test_setAllocations_reverts_badBps() public {
        PledgeVaultRH.StockAllocation[] memory allocs = new PledgeVaultRH.StockAllocation[](1);
        allocs[0] = PledgeVaultRH.StockAllocation(tsla, 5000);

        vm.expectRevert("PledgeVault: bps must total 10000");
        vault.setAllocations(allocs);
    }

    function test_setAllocations_reverts_overBps() public {
        PledgeVaultRH.StockAllocation[] memory allocs = new PledgeVaultRH.StockAllocation[](2);
        allocs[0] = PledgeVaultRH.StockAllocation(tsla, 6000);
        allocs[1] = PledgeVaultRH.StockAllocation(amzn, 6000);

        vm.expectRevert("PledgeVault: bps must total 10000");
        vault.setAllocations(allocs);
    }

    function test_setAllocations_reverts_zeroToken() public {
        PledgeVaultRH.StockAllocation[] memory allocs = new PledgeVaultRH.StockAllocation[](1);
        allocs[0] = PledgeVaultRH.StockAllocation(address(0), 10000);

        vm.expectRevert("PledgeVault: zero token");
        vault.setAllocations(allocs);
    }

    function test_setAllocations_reverts_zeroBps() public {
        PledgeVaultRH.StockAllocation[] memory allocs = new PledgeVaultRH.StockAllocation[](2);
        allocs[0] = PledgeVaultRH.StockAllocation(tsla, 10000);
        allocs[1] = PledgeVaultRH.StockAllocation(amzn, 0);

        vm.expectRevert("PledgeVault: zero bps");
        vault.setAllocations(allocs);
    }

    function test_setAllocations_reverts_nonOwner() public {
        PledgeVaultRH.StockAllocation[] memory allocs = new PledgeVaultRH.StockAllocation[](1);
        allocs[0] = PledgeVaultRH.StockAllocation(tsla, 10000);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vault.setAllocations(allocs);
    }

    // =====================
    // setRelayer
    // =====================

    function test_setRelayer() public {
        address newRelayer = makeAddr("newRelayer");

        vm.expectEmit(false, false, false, true);
        emit RelayerUpdated(newRelayer);

        vault.setRelayer(newRelayer);
        assertEq(vault.relayer(), newRelayer);
    }

    function test_setRelayer_new_relayer_can_invest() public {
        address newRelayer = makeAddr("newRelayer");
        vault.setRelayer(newRelayer);

        vm.prank(newRelayer);
        vault.investForUser(user, 100e18);

        assertGt(vault.userStockBalances(user, tsla), 0);
    }

    function test_setRelayer_old_relayer_reverts() public {
        address newRelayer = makeAddr("newRelayer");
        vault.setRelayer(newRelayer);

        vm.prank(relayer); // old relayer
        vm.expectRevert("PledgeVault: not relayer");
        vault.investForUser(user, 100e18);
    }

    function test_setRelayer_reverts_zero() public {
        vm.expectRevert("PledgeVault: zero relayer");
        vault.setRelayer(address(0));
    }

    function test_setRelayer_reverts_nonOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vault.setRelayer(makeAddr("new"));
    }

    // =====================
    // setTreasury
    // =====================

    function test_setTreasury() public {
        address newTreasury = makeAddr("newTreasury");

        vm.expectEmit(false, false, false, true);
        emit TreasuryUpdated(newTreasury);

        vault.setTreasury(newTreasury);
        assertEq(vault.treasury(), newTreasury);
    }

    function test_setTreasury_fees_go_to_new() public {
        address newTreasury = makeAddr("newTreasury");
        vault.setTreasury(newTreasury);

        vm.prank(relayer);
        vault.investForUser(user, 1000e18);

        assertEq(usdc.balanceOf(newTreasury), 20e18);
        assertEq(usdc.balanceOf(treasury), 0); // old treasury gets nothing
    }

    function test_setTreasury_reverts_zero() public {
        vm.expectRevert("PledgeVault: zero treasury");
        vault.setTreasury(address(0));
    }

    function test_setTreasury_reverts_nonOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        vault.setTreasury(makeAddr("new"));
    }

    // =====================
    // Fuzz tests
    // =====================

    function testFuzz_investForUser_fee_calculation(uint256 amount) public {
        // Bound to reasonable range (1 wei to 1M USDC)
        amount = bound(amount, 1, 1_000_000e18);

        usdc.mint(user, amount);
        vm.prank(user);
        usdc.approve(address(vault), amount);

        uint256 treasuryBefore = usdc.balanceOf(treasury);

        vm.prank(relayer);
        vault.investForUser(user, amount);

        uint256 expectedFee = (amount * 200) / 10000;
        assertEq(usdc.balanceOf(treasury) - treasuryBefore, expectedFee, "fee mismatch");
    }

    function testFuzz_invest_and_withdraw_conserves_value(uint256 amount) public {
        amount = bound(amount, 100, 1_000_000e18); // min 100 to avoid total dust loss

        usdc.mint(user, amount);
        vm.prank(user);
        usdc.approve(address(vault), amount);

        uint256 userBalBefore = usdc.balanceOf(user);

        vm.prank(relayer);
        vault.investForUser(user, amount);

        vm.prank(user);
        vault.emergencyWithdraw();

        uint256 userBalAfter = usdc.balanceOf(user);
        uint256 expectedFee = (amount * 200) / 10000;
        uint256 investAmount = amount - expectedFee;

        // Withdrawn amount may be slightly less than investAmount due to integer division dust
        uint256 returned = userBalAfter - (userBalBefore - amount);
        assertLe(returned, investAmount, "returned more than invested");
        // Max 4 wei dust (one per allocation token)
        assertGe(returned, investAmount - 4, "too much dust lost");
    }

    // =====================
    // Integration / E2E
    // =====================

    function test_full_lifecycle() public {
        // 1. Owner sets allocations (already done in setUp)
        assertEq(vault.getAllocationsCount(), 4);

        // 2. Relayer invests for user
        vm.prank(relayer);
        vault.investForUser(user, 1000e18);

        // 3. Check portfolio
        (address[] memory tokens, uint256[] memory balances) = vault.getUserPortfolio(user);
        assertEq(tokens.length, 4);

        uint256 total = 0;
        for (uint256 i = 0; i < balances.length; i++) {
            total += balances[i];
        }
        assertEq(total, 980e18);

        // 4. Owner changes allocations
        PledgeVaultRH.StockAllocation[] memory newAllocs = new PledgeVaultRH.StockAllocation[](2);
        newAllocs[0] = PledgeVaultRH.StockAllocation(tsla, 7000);
        newAllocs[1] = PledgeVaultRH.StockAllocation(amzn, 3000);
        vault.setAllocations(newAllocs);

        // 5. Another invest uses new allocations
        vm.prank(relayer);
        vault.investForUser(user, 1000e18);

        // User now has old + new positions
        // Old TSLA: 294, new TSLA: 980 * 70% = 686
        assertEq(vault.userStockBalances(user, tsla), 294e18 + 686e18);

        // 6. User withdraws everything
        uint256 userBalBefore = usdc.balanceOf(user);
        vm.prank(user);
        vault.emergencyWithdraw();

        uint256 returned = usdc.balanceOf(user) - userBalBefore;
        // 980 (first) + 980 (second) = 1960
        assertEq(returned, 1960e18);

        // 7. Portfolio is empty
        (tokens, balances) = vault.getUserPortfolio(user);
        assertEq(tokens.length, 0);
    }

    function test_owner_updates_relayer_and_treasury_mid_flow() public {
        // Invest with original relayer
        vm.prank(relayer);
        vault.investForUser(user, 500e18);

        // Owner swaps relayer and treasury
        address newRelayer = makeAddr("newRelayer");
        address newTreasury = makeAddr("newTreasury");
        vault.setRelayer(newRelayer);
        vault.setTreasury(newTreasury);

        // New relayer invests, fees go to new treasury
        vm.prank(newRelayer);
        vault.investForUser(user, 500e18);

        assertEq(usdc.balanceOf(treasury), 10e18);     // old treasury: first fee only
        assertEq(usdc.balanceOf(newTreasury), 10e18);   // new treasury: second fee only
    }
}
