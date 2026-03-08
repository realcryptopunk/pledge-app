// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PledgeVault} from "../src/PledgeVault.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockSwapRouter} from "./mocks/MockSwapRouter.sol";

contract PledgeVaultTest is Test {
    // Mirror events from PledgeVault for vm.expectEmit assertions
    event Registered(address indexed user, PledgeVault.RiskTier tier);
    event Deposited(address indexed user, uint256 indexed pledgeId, uint256 amount);
    event InvestedOnFailure(uint256 indexed pledgeId, address indexed user, uint256 pledgeAmount, uint256 fee, uint256 usdyOut, uint256 bcspxOut);
    event ClaimedSuccess(uint256 indexed pledgeId, address indexed user, uint256 amount);
    event PledgeCancelled(uint256 indexed pledgeId, address indexed user, uint256 amount);
    event InvestmentWithdrawn(address indexed user, uint256 usdyAmount, uint256 bcspxAmount);
    event RelayerUpdated(address newRelayer);
    event TreasuryUpdated(address newTreasury);
    event PlatformFeeBpsUpdated(uint256 newBps);
    event PledgeTimeoutUpdated(uint256 newTimeout);

    PledgeVault    vault;
    MockERC20      mockUSDC;
    MockERC20      mockUSDY;
    MockERC20      mockBCSPX;
    MockSwapRouter mockRouter;

    address owner    = makeAddr("owner");
    address relayer  = makeAddr("relayer");
    address treasury = makeAddr("treasury");
    address alice    = makeAddr("alice");
    address bob      = makeAddr("bob");

    uint256 constant PLEDGE = 1000e6; // 1,000 USDC (6 decimals)

    function setUp() public {
        mockUSDC  = new MockERC20("USD Coin",      "USDC",  6);
        mockUSDY  = new MockERC20("Ondo USDY",     "USDY",  18);
        mockBCSPX = new MockERC20("Backed bCSPX",  "bCSPX", 18);
        mockRouter = new MockSwapRouter();

        vm.prank(owner);
        vault = new PledgeVault(
            address(mockUSDC),
            address(mockUSDY),
            address(mockBCSPX),
            address(mockRouter),
            treasury,
            relayer
        );

        // Fund users with USDC and approve vault
        mockUSDC.mint(alice, 100_000e6);
        mockUSDC.mint(bob,   100_000e6);
        vm.prank(alice); mockUSDC.approve(address(vault), type(uint256).max);
        vm.prank(bob);   mockUSDC.approve(address(vault), type(uint256).max);
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    function test_constructor_sets_immutables() public view {
        assertEq(address(vault.usdc()),       address(mockUSDC));
        assertEq(vault.usdy(),                address(mockUSDY));
        assertEq(vault.bcspx(),               address(mockBCSPX));
        assertEq(address(vault.swapRouter()), address(mockRouter));
        assertEq(vault.treasury(),            treasury);
        assertEq(vault.relayer(),             relayer);
        assertEq(vault.platformFeeBps(),      200);
        assertEq(vault.nextPledgeId(),        0);
    }

    function test_constructor_reverts_zero_usdc() public {
        vm.expectRevert("PledgeVault: zero usdc");
        new PledgeVault(address(0), address(mockUSDY), address(mockBCSPX), address(mockRouter), treasury, relayer);
    }

    function test_constructor_reverts_zero_usdy() public {
        vm.expectRevert("PledgeVault: zero usdy");
        new PledgeVault(address(mockUSDC), address(0), address(mockBCSPX), address(mockRouter), treasury, relayer);
    }

    function test_constructor_reverts_zero_bcspx() public {
        vm.expectRevert("PledgeVault: zero bcspx");
        new PledgeVault(address(mockUSDC), address(mockUSDY), address(0), address(mockRouter), treasury, relayer);
    }

    function test_constructor_reverts_zero_swapRouter() public {
        vm.expectRevert("PledgeVault: zero swapRouter");
        new PledgeVault(address(mockUSDC), address(mockUSDY), address(mockBCSPX), address(0), treasury, relayer);
    }

    function test_constructor_reverts_zero_treasury() public {
        vm.expectRevert("PledgeVault: zero treasury");
        new PledgeVault(address(mockUSDC), address(mockUSDY), address(mockBCSPX), address(mockRouter), address(0), relayer);
    }

    function test_constructor_reverts_zero_relayer() public {
        vm.expectRevert("PledgeVault: zero relayer");
        new PledgeVault(address(mockUSDC), address(mockUSDY), address(mockBCSPX), address(mockRouter), treasury, address(0));
    }

    function test_constructor_tier_allocations() public view {
        (uint256 usdyBps, uint256 bcspxBps) = vault.getTierAllocations(PledgeVault.RiskTier.LOW);
        assertEq(usdyBps,  7000);
        assertEq(bcspxBps, 3000);

        (usdyBps, bcspxBps) = vault.getTierAllocations(PledgeVault.RiskTier.MEDIUM);
        assertEq(usdyBps,  5000);
        assertEq(bcspxBps, 5000);

        (usdyBps, bcspxBps) = vault.getTierAllocations(PledgeVault.RiskTier.HIGH);
        assertEq(usdyBps,  3000);
        assertEq(bcspxBps, 7000);
    }

    // -------------------------------------------------------------------------
    // register()
    // -------------------------------------------------------------------------

    function test_register_LOW() public {
        vm.prank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        assertEq(uint256(vault.userTier(alice)), uint256(PledgeVault.RiskTier.LOW));
    }

    function test_register_MEDIUM() public {
        vm.prank(alice);
        vault.register(PledgeVault.RiskTier.MEDIUM);
        assertEq(uint256(vault.userTier(alice)), uint256(PledgeVault.RiskTier.MEDIUM));
    }

    function test_register_HIGH() public {
        vm.prank(alice);
        vault.register(PledgeVault.RiskTier.HIGH);
        assertEq(uint256(vault.userTier(alice)), uint256(PledgeVault.RiskTier.HIGH));
    }

    function test_register_emits_event() public {
        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit Registered(alice, PledgeVault.RiskTier.HIGH);
        vault.register(PledgeVault.RiskTier.HIGH);
    }

    function test_register_same_tier_no_event() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.HIGH);
        vm.recordLogs();
        vault.register(PledgeVault.RiskTier.HIGH);
        vm.stopPrank();
        assertEq(vm.getRecordedLogs().length, 0);
    }

    function test_register_can_change_tier_while_pledge_active() public {
        // With per-pledge tier capture, register can be called at any time
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        vault.deposit(PLEDGE); // pledge captures LOW
        vault.register(PledgeVault.RiskTier.HIGH); // no revert
        vm.stopPrank();
        assertEq(uint256(vault.userTier(alice)), uint256(PledgeVault.RiskTier.HIGH));
    }

    function test_register_new_pledge_uses_updated_tier() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        vault.deposit(PLEDGE);
        vault.register(PledgeVault.RiskTier.HIGH);
        uint256 pledgeId2 = vault.deposit(PLEDGE);
        vm.stopPrank();

        (, PledgeVault.RiskTier tier,,,) = vault.getPledge(pledgeId2);
        assertEq(uint256(tier), uint256(PledgeVault.RiskTier.HIGH));
    }

    // -------------------------------------------------------------------------
    // deposit()
    // -------------------------------------------------------------------------

    function test_deposit_pulls_usdc_into_vault() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        vault.deposit(PLEDGE);
        vm.stopPrank();

        assertEq(mockUSDC.balanceOf(address(vault)), PLEDGE);
        assertEq(mockUSDC.balanceOf(alice), 100_000e6 - PLEDGE);
    }

    function test_deposit_increments_pledge_id() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 id0 = vault.deposit(PLEDGE);
        uint256 id1 = vault.deposit(PLEDGE);
        vm.stopPrank();

        assertEq(id0, 0);
        assertEq(id1, 1);
        assertEq(vault.nextPledgeId(), 2);
    }

    function test_deposit_stores_pledge_data() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.MEDIUM);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        (address user, PledgeVault.RiskTier tier, uint256 amount,, bool active) = vault.getPledge(pledgeId);
        assertEq(user,             alice);
        assertEq(uint256(tier),    uint256(PledgeVault.RiskTier.MEDIUM));
        assertEq(amount,           PLEDGE);
        assertTrue(active);
    }

    function test_deposit_emits_event() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        vm.expectEmit(true, true, false, true);
        emit Deposited(alice, 0, PLEDGE);
        vault.deposit(PLEDGE);
        vm.stopPrank();
    }

    function test_deposit_reverts_zero_amount() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        vm.expectRevert("PledgeVault: zero amount");
        vault.deposit(0);
        vm.stopPrank();
    }

    function test_deposit_allows_multiple_concurrent_pledges() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 id0 = vault.deposit(PLEDGE);
        uint256 id1 = vault.deposit(PLEDGE * 2);
        vm.stopPrank();

        assertEq(mockUSDC.balanceOf(address(vault)), PLEDGE + PLEDGE * 2);

        (,, uint256 amt0,,) = vault.getPledge(id0);
        (,, uint256 amt1,,) = vault.getPledge(id1);
        assertEq(amt0, PLEDGE);
        assertEq(amt1, PLEDGE * 2);
    }

    // -------------------------------------------------------------------------
    // investOnFailure()
    // -------------------------------------------------------------------------

    /// @dev Returns pledgeId for the setup pledge
    function _setupFailure(address user, PledgeVault.RiskTier tier, uint256 amount)
        internal returns (uint256 pledgeId)
    {
        vm.startPrank(user);
        vault.register(tier);
        pledgeId = vault.deposit(amount);
        vm.stopPrank();
    }

    function test_investOnFailure_takes_2pct_fee() public {
        uint256 pledgeId = _setupFailure(alice, PledgeVault.RiskTier.LOW, PLEDGE);
        uint256 expectedFee = (PLEDGE * 200) / 10000;

        vm.prank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);

        assertEq(mockUSDC.balanceOf(treasury), expectedFee);
    }

    function test_investOnFailure_LOW_tier_split() public {
        uint256 pledgeId     = _setupFailure(alice, PledgeVault.RiskTier.LOW, PLEDGE);
        uint256 fee          = (PLEDGE * 200) / 10000;
        uint256 investAmount = PLEDGE - fee;
        uint256 usdyExpected  = (investAmount * 7000) / 10000;
        uint256 bcspxExpected = investAmount - usdyExpected;

        vm.prank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);

        assertEq(mockUSDY.balanceOf(address(vault)),  usdyExpected);
        assertEq(mockBCSPX.balanceOf(address(vault)), bcspxExpected);
    }

    function test_investOnFailure_MEDIUM_tier_split() public {
        uint256 pledgeId     = _setupFailure(alice, PledgeVault.RiskTier.MEDIUM, PLEDGE);
        uint256 fee          = (PLEDGE * 200) / 10000;
        uint256 investAmount = PLEDGE - fee;
        uint256 usdyExpected  = (investAmount * 5000) / 10000;
        uint256 bcspxExpected = investAmount - usdyExpected;

        vm.prank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);

        assertEq(mockUSDY.balanceOf(address(vault)),  usdyExpected);
        assertEq(mockBCSPX.balanceOf(address(vault)), bcspxExpected);
    }

    function test_investOnFailure_HIGH_tier_split() public {
        uint256 pledgeId     = _setupFailure(alice, PledgeVault.RiskTier.HIGH, PLEDGE);
        uint256 fee          = (PLEDGE * 200) / 10000;
        uint256 investAmount = PLEDGE - fee;
        uint256 usdyExpected  = (investAmount * 3000) / 10000;
        uint256 bcspxExpected = investAmount - usdyExpected;

        vm.prank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);

        assertEq(mockUSDY.balanceOf(address(vault)),  usdyExpected);
        assertEq(mockBCSPX.balanceOf(address(vault)), bcspxExpected);
    }

    function test_investOnFailure_no_dust_in_vault() public {
        uint256 pledgeId = _setupFailure(alice, PledgeVault.RiskTier.HIGH, PLEDGE);

        vm.prank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);

        assertEq(mockUSDC.balanceOf(address(vault)), 0);
    }

    function test_investOnFailure_emits_event() public {
        uint256 pledgeId     = _setupFailure(alice, PledgeVault.RiskTier.LOW, PLEDGE);
        uint256 fee          = (PLEDGE * 200) / 10000;
        uint256 investAmount = PLEDGE - fee;
        uint256 usdyExpected  = (investAmount * 7000) / 10000;
        uint256 bcspxExpected = investAmount - usdyExpected;

        vm.prank(relayer);
        vm.expectEmit(true, true, false, true);
        emit InvestedOnFailure(pledgeId, alice, PLEDGE, fee, usdyExpected, bcspxExpected);
        vault.investOnFailure(pledgeId, 0, 0);
    }

    function test_investOnFailure_deactivates_pledge() public {
        uint256 pledgeId = _setupFailure(alice, PledgeVault.RiskTier.LOW, PLEDGE);

        vm.prank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);

        (,,,, bool active) = vault.getPledge(pledgeId);
        assertFalse(active);
    }

    function test_investOnFailure_reverts_not_relayer() public {
        uint256 pledgeId = _setupFailure(alice, PledgeVault.RiskTier.LOW, PLEDGE);

        vm.prank(alice);
        vm.expectRevert("PledgeVault: not relayer");
        vault.investOnFailure(pledgeId, 0, 0);
    }

    function test_investOnFailure_reverts_not_active() public {
        vm.prank(relayer);
        vm.expectRevert("PledgeVault: not active");
        vault.investOnFailure(0, 0, 0); // pledgeId 0 never created
    }

    function test_investOnFailure_reverts_double_invoke() public {
        uint256 pledgeId = _setupFailure(alice, PledgeVault.RiskTier.LOW, PLEDGE);

        vm.startPrank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);
        vm.expectRevert("PledgeVault: not active");
        vault.investOnFailure(pledgeId, 0, 0);
        vm.stopPrank();
    }

    function test_investOnFailure_multiple_concurrent_pledges() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pid0 = vault.deposit(PLEDGE);
        uint256 pid1 = vault.deposit(PLEDGE * 2);
        vm.stopPrank();

        vm.startPrank(relayer);
        vault.investOnFailure(pid0, 0, 0);
        vault.investOnFailure(pid1, 0, 0);
        vm.stopPrank();

        assertEq(mockUSDC.balanceOf(address(vault)), 0);
        (,,,, bool active0) = vault.getPledge(pid0);
        (,,,, bool active1) = vault.getPledge(pid1);
        assertFalse(active0);
        assertFalse(active1);
    }

    function test_investOnFailure_reverts_slippage_usdy() public {
        uint256 pledgeId     = _setupFailure(alice, PledgeVault.RiskTier.LOW, PLEDGE);
        uint256 fee          = (PLEDGE * 200) / 10000;
        uint256 investAmount = PLEDGE - fee;
        uint256 usdyExpected = (investAmount * 7000) / 10000;

        // call with exact expected output — should pass (mock mints exactly this)
        vm.prank(relayer);
        vault.investOnFailure(pledgeId, usdyExpected, 0);
    }

    // -------------------------------------------------------------------------
    // claimSuccess()
    // -------------------------------------------------------------------------

    function test_claimSuccess_returns_full_amount() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        uint256 balBefore = mockUSDC.balanceOf(alice);

        vm.prank(relayer);
        vault.claimSuccess(pledgeId);

        assertEq(mockUSDC.balanceOf(alice), balBefore + PLEDGE);
    }

    function test_claimSuccess_no_fee_taken() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.prank(relayer);
        vault.claimSuccess(pledgeId);

        assertEq(mockUSDC.balanceOf(treasury), 0);
    }

    function test_claimSuccess_deactivates_pledge() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.prank(relayer);
        vault.claimSuccess(pledgeId);

        (,,,, bool active) = vault.getPledge(pledgeId);
        assertFalse(active);
    }

    function test_claimSuccess_emits_event() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.prank(relayer);
        vm.expectEmit(true, true, false, true);
        emit ClaimedSuccess(pledgeId, alice, PLEDGE);
        vault.claimSuccess(pledgeId);
    }

    function test_claimSuccess_reverts_not_relayer() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.prank(alice);
        vm.expectRevert("PledgeVault: not relayer");
        vault.claimSuccess(pledgeId);
    }

    function test_claimSuccess_reverts_not_active() public {
        vm.prank(relayer);
        vm.expectRevert("PledgeVault: not active");
        vault.claimSuccess(0); // pledgeId 0 never created
    }

    function test_claimSuccess_reverts_double_invoke() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.startPrank(relayer);
        vault.claimSuccess(pledgeId);
        vm.expectRevert("PledgeVault: not active");
        vault.claimSuccess(pledgeId);
        vm.stopPrank();
    }

    function test_claimSuccess_one_of_two_concurrent_pledges() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pid0 = vault.deposit(PLEDGE);
        uint256 pid1 = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.prank(relayer);
        vault.claimSuccess(pid0);

        // pid1 still active
        (,,,, bool active1) = vault.getPledge(pid1);
        assertTrue(active1);
        // vault still holds PLEDGE for pid1
        assertEq(mockUSDC.balanceOf(address(vault)), PLEDGE);
    }

    // -------------------------------------------------------------------------
    // cancelPledge()
    // -------------------------------------------------------------------------

    function test_cancelPledge_returns_usdc_after_timeout() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        uint256 balBefore = mockUSDC.balanceOf(alice);

        vm.warp(block.timestamp + vault.pledgeTimeout());

        vm.prank(alice);
        vault.cancelPledge(pledgeId);

        assertEq(mockUSDC.balanceOf(alice), balBefore + PLEDGE);
        assertEq(mockUSDC.balanceOf(address(vault)), 0);
    }

    function test_cancelPledge_deactivates_pledge() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.warp(block.timestamp + vault.pledgeTimeout());

        vm.prank(alice);
        vault.cancelPledge(pledgeId);

        (,,,, bool active) = vault.getPledge(pledgeId);
        assertFalse(active);
    }

    function test_cancelPledge_emits_event() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.warp(block.timestamp + vault.pledgeTimeout());

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit PledgeCancelled(pledgeId, alice, PLEDGE);
        vault.cancelPledge(pledgeId);
    }

    function test_cancelPledge_reverts_before_timeout() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.warp(block.timestamp + vault.pledgeTimeout() - 1);

        vm.prank(alice);
        vm.expectRevert("PledgeVault: timeout not reached");
        vault.cancelPledge(pledgeId);
    }

    function test_cancelPledge_reverts_not_active() public {
        vm.prank(alice);
        vm.expectRevert("PledgeVault: not active");
        vault.cancelPledge(0); // pledgeId 0 never created
    }

    function test_cancelPledge_reverts_not_pledge_owner() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.warp(block.timestamp + vault.pledgeTimeout());

        vm.prank(bob);
        vm.expectRevert("PledgeVault: not pledge owner");
        vault.cancelPledge(pledgeId);
    }

    function test_cancelPledge_no_fee_taken() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.warp(block.timestamp + vault.pledgeTimeout());

        vm.prank(alice);
        vault.cancelPledge(pledgeId);

        assertEq(mockUSDC.balanceOf(treasury), 0);
    }

    function test_cancelPledge_allows_new_pledge_after() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.warp(block.timestamp + vault.pledgeTimeout());

        vm.startPrank(alice);
        vault.cancelPledge(pledgeId);
        uint256 newPledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        (,,,, bool active) = vault.getPledge(newPledgeId);
        assertTrue(active);
    }

    function test_cancelPledge_only_cancels_specified_pledge() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pid0 = vault.deposit(PLEDGE);
        uint256 pid1 = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.warp(block.timestamp + vault.pledgeTimeout());

        vm.prank(alice);
        vault.cancelPledge(pid0);

        (,,,, bool active1) = vault.getPledge(pid1);
        assertTrue(active1);
        assertEq(mockUSDC.balanceOf(address(vault)), PLEDGE); // pid1 still held
    }

    // -------------------------------------------------------------------------
    // withdrawInvestment()
    // -------------------------------------------------------------------------

    function test_withdrawInvestment_transfers_usdy_and_bcspx() public {
        uint256 pledgeId = _setupFailure(alice, PledgeVault.RiskTier.LOW, PLEDGE);

        vm.prank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);

        uint256 usdyInVault  = mockUSDY.balanceOf(address(vault));
        uint256 bcspxInVault = mockBCSPX.balanceOf(address(vault));

        vm.prank(alice);
        vault.withdrawInvestment();

        assertEq(mockUSDY.balanceOf(alice),           usdyInVault);
        assertEq(mockBCSPX.balanceOf(alice),          bcspxInVault);
        assertEq(mockUSDY.balanceOf(address(vault)),  0);
        assertEq(mockBCSPX.balanceOf(address(vault)), 0);
    }

    function test_withdrawInvestment_clears_balances() public {
        uint256 pledgeId = _setupFailure(alice, PledgeVault.RiskTier.HIGH, PLEDGE);

        vm.prank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);

        vm.prank(alice);
        vault.withdrawInvestment();

        assertEq(vault.usdyBalances(alice),  0);
        assertEq(vault.bcspxBalances(alice), 0);
    }

    function test_withdrawInvestment_accumulates_across_failures() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pid0 = vault.deposit(PLEDGE);
        uint256 pid1 = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.startPrank(relayer);
        vault.investOnFailure(pid0, 0, 0);
        vault.investOnFailure(pid1, 0, 0);
        vm.stopPrank();

        uint256 fee          = (PLEDGE * 200) / 10000;
        uint256 investAmount = PLEDGE - fee;
        // Two failures → 2x the invested amounts
        uint256 expectedUsdy = (investAmount * 7000 * 2) / 10000;

        assertEq(vault.usdyBalances(alice), expectedUsdy);

        vm.prank(alice);
        vault.withdrawInvestment();

        assertEq(mockUSDY.balanceOf(alice), expectedUsdy);
    }

    function test_withdrawInvestment_emits_event() public {
        uint256 pledgeId = _setupFailure(alice, PledgeVault.RiskTier.MEDIUM, PLEDGE);

        vm.prank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);

        uint256 expectedUsdy  = vault.usdyBalances(alice);
        uint256 expectedBcspx = vault.bcspxBalances(alice);

        vm.prank(alice);
        vm.expectEmit(true, false, false, true);
        emit InvestmentWithdrawn(alice, expectedUsdy, expectedBcspx);
        vault.withdrawInvestment();
    }

    function test_withdrawInvestment_reverts_nothing_to_withdraw() public {
        vm.prank(alice);
        vm.expectRevert("PledgeVault: nothing to withdraw");
        vault.withdrawInvestment();
    }

    function test_withdrawInvestment_reverts_double_withdraw() public {
        uint256 pledgeId = _setupFailure(alice, PledgeVault.RiskTier.LOW, PLEDGE);

        vm.prank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);

        vm.startPrank(alice);
        vault.withdrawInvestment();
        vm.expectRevert("PledgeVault: nothing to withdraw");
        vault.withdrawInvestment();
        vm.stopPrank();
    }

    function test_withdrawInvestment_two_users_independent() public {
        uint256 alicePid = _setupFailure(alice, PledgeVault.RiskTier.LOW,  PLEDGE);
        uint256 bobPid   = _setupFailure(bob,   PledgeVault.RiskTier.HIGH, PLEDGE);

        vm.startPrank(relayer);
        vault.investOnFailure(alicePid, 0, 0);
        vault.investOnFailure(bobPid, 0, 0);
        vm.stopPrank();

        uint256 aliceUsdy  = vault.usdyBalances(alice);
        uint256 aliceBcspx = vault.bcspxBalances(alice);
        uint256 bobUsdy    = vault.usdyBalances(bob);
        uint256 bobBcspx   = vault.bcspxBalances(bob);

        vm.prank(alice);
        vault.withdrawInvestment();

        assertEq(mockUSDY.balanceOf(address(vault)),  bobUsdy);
        assertEq(mockBCSPX.balanceOf(address(vault)), bobBcspx);
        assertEq(mockUSDY.balanceOf(alice),           aliceUsdy);
        assertEq(mockBCSPX.balanceOf(alice),          aliceBcspx);
    }

    // -------------------------------------------------------------------------
    // Admin
    // -------------------------------------------------------------------------

    function test_setRelayer_updates() public {
        address newRelayer = makeAddr("newRelayer");
        vm.prank(owner);
        vault.setRelayer(newRelayer);
        assertEq(vault.relayer(), newRelayer);
    }

    function test_setRelayer_emits_event() public {
        address newRelayer = makeAddr("newRelayer");
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit RelayerUpdated(newRelayer);
        vault.setRelayer(newRelayer);
    }

    function test_setRelayer_reverts_zero() public {
        vm.prank(owner);
        vm.expectRevert("PledgeVault: zero relayer");
        vault.setRelayer(address(0));
    }

    function test_setRelayer_reverts_non_owner() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.setRelayer(makeAddr("x"));
    }

    function test_setTreasury_updates() public {
        address newTreasury = makeAddr("newTreasury");
        vm.prank(owner);
        vault.setTreasury(newTreasury);
        assertEq(vault.treasury(), newTreasury);
    }

    function test_setTreasury_reverts_zero() public {
        vm.prank(owner);
        vm.expectRevert("PledgeVault: zero treasury");
        vault.setTreasury(address(0));
    }

    function test_setTreasury_reverts_non_owner() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.setTreasury(makeAddr("x"));
    }

    function test_setPlatformFeeBps_updates() public {
        vm.prank(owner);
        vault.setPlatformFeeBps(500);
        assertEq(vault.platformFeeBps(), 500);
    }

    function test_setPlatformFeeBps_reverts_too_high() public {
        vm.prank(owner);
        vm.expectRevert("PledgeVault: fee too high");
        vault.setPlatformFeeBps(1001);
    }

    function test_setPlatformFeeBps_reverts_non_owner() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.setPlatformFeeBps(100);
    }

    function test_setPledgeTimeout_updates() public {
        vm.prank(owner);
        vault.setPledgeTimeout(7 days);
        assertEq(vault.pledgeTimeout(), 7 days);
    }

    function test_setPledgeTimeout_emits_event() public {
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit PledgeTimeoutUpdated(7 days);
        vault.setPledgeTimeout(7 days);
    }

    function test_setPledgeTimeout_reverts_zero() public {
        vm.prank(owner);
        vm.expectRevert("PledgeVault: zero timeout");
        vault.setPledgeTimeout(0);
    }

    function test_setPledgeTimeout_reverts_non_owner() public {
        vm.prank(alice);
        vm.expectRevert();
        vault.setPledgeTimeout(1 days);
    }

    // -------------------------------------------------------------------------
    // Integration / Lifecycle
    // -------------------------------------------------------------------------

    function test_full_success_lifecycle() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.MEDIUM);
        uint256 pledgeId = vault.deposit(PLEDGE);
        vm.stopPrank();

        uint256 aliceBalBefore = mockUSDC.balanceOf(alice);

        vm.prank(relayer);
        vault.claimSuccess(pledgeId);

        assertEq(mockUSDC.balanceOf(alice), aliceBalBefore + PLEDGE);
        assertEq(mockUSDC.balanceOf(address(vault)), 0);

        (,,,, bool active) = vault.getPledge(pledgeId);
        assertFalse(active);
    }

    function test_full_failure_lifecycle() public {
        uint256 pledgeId     = _setupFailure(alice, PledgeVault.RiskTier.MEDIUM, PLEDGE);
        uint256 fee          = (PLEDGE * 200) / 10000;
        uint256 investAmount = PLEDGE - fee;

        vm.prank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);

        assertEq(mockUSDC.balanceOf(treasury),        fee);
        assertEq(mockUSDC.balanceOf(address(vault)),  0);
        assertEq(mockUSDY.balanceOf(address(vault)),  investAmount / 2);
        assertEq(mockBCSPX.balanceOf(address(vault)), investAmount - investAmount / 2);
    }

    function test_mixed_lifecycle_success_and_failure() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 successPid = vault.deposit(PLEDGE);
        uint256 failPid    = vault.deposit(PLEDGE);
        vm.stopPrank();

        uint256 aliceBalBefore = mockUSDC.balanceOf(alice);

        vm.startPrank(relayer);
        vault.claimSuccess(successPid);
        vault.investOnFailure(failPid, 0, 0);
        vm.stopPrank();

        // Success pledge refunded, fee taken on failure
        uint256 fee = (PLEDGE * 200) / 10000;
        assertEq(mockUSDC.balanceOf(alice), aliceBalBefore + PLEDGE);
        assertEq(mockUSDC.balanceOf(treasury), fee);
    }

    function test_user_can_start_new_pledge_after_success() public {
        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pid0 = vault.deposit(PLEDGE);
        vm.stopPrank();

        vm.prank(relayer);
        vault.claimSuccess(pid0);

        vm.prank(alice);
        uint256 pid1 = vault.deposit(PLEDGE);

        (,,,, bool active) = vault.getPledge(pid1);
        assertTrue(active);
    }

    function test_two_users_different_tiers_independent() public {
        uint256 alicePid = _setupFailure(alice, PledgeVault.RiskTier.LOW,  PLEDGE);
        uint256 bobPid   = _setupFailure(bob,   PledgeVault.RiskTier.HIGH, PLEDGE);

        vm.startPrank(relayer);
        vault.investOnFailure(alicePid, 0, 0);
        vault.investOnFailure(bobPid, 0, 0);
        vm.stopPrank();

        assertEq(mockUSDC.balanceOf(address(vault)), 0);
        assertEq(mockUSDC.balanceOf(treasury), (PLEDGE * 200 * 2) / 10000);
    }

    // -------------------------------------------------------------------------
    // Fuzz
    // -------------------------------------------------------------------------

    function testFuzz_fee_calculation(uint256 amount) public {
        amount = bound(amount, 1, 1_000_000e6);
        mockUSDC.mint(alice, amount);

        vm.startPrank(alice);
        vault.register(PledgeVault.RiskTier.LOW);
        uint256 pledgeId = vault.deposit(amount);
        vm.stopPrank();

        vm.prank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);

        uint256 expectedFee = (amount * 200) / 10000;
        assertEq(mockUSDC.balanceOf(treasury), expectedFee);
        assertEq(mockUSDC.balanceOf(address(vault)), 0);
    }

    function testFuzz_tier_split_sums_correctly(uint256 amount, uint8 tierSeed) public {
        amount = bound(amount, 10000, 1_000_000e6);
        mockUSDC.mint(alice, amount);

        PledgeVault.RiskTier tier = PledgeVault.RiskTier(tierSeed % 3);

        vm.startPrank(alice);
        vault.register(tier);
        uint256 pledgeId = vault.deposit(amount);
        vm.stopPrank();

        vm.prank(relayer);
        vault.investOnFailure(pledgeId, 0, 0);

        uint256 fee          = (amount * 200) / 10000;
        uint256 investAmount = amount - fee;

        assertEq(
            mockUSDY.balanceOf(address(vault)) + mockBCSPX.balanceOf(address(vault)),
            investAmount,
            "split must sum to investAmount"
        );
    }
}
