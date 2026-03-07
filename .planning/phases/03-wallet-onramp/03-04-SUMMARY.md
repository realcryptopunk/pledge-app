---
phase: 03-wallet-onramp
plan: 04
subsystem: funding
tags: [coinbase-onramp, wkwebview, deposit, setup-flow]

requires:
  - phase: 03-02
    provides: Privy auth with walletAddress in AppState
provides:
  - CoinbaseOnrampView WKWebView wrapper (ready for sessionToken migration)
  - SetupDepositView wired with Coinbase-branded button
  - Simulated deposit flow for all users (no backend yet)
affects: [setup-flow, portfolio]

tech-stack:
  added: [WKWebView, UIViewRepresentable, WKNavigationDelegate]
  patterns: [Coordinator pattern for UIKit bridging]

key-files:
  created: [Features/Funding/CoinbaseOnrampView.swift]
  modified: [Features/Setup/SetupDepositView.swift]

key-decisions:
  - "Simulated deposit for all users — Coinbase requires server-side sessionToken"
  - "Privy iOS SDK lacks funding API — must use direct Coinbase integration when backend exists"
  - "Kept CoinbaseOnrampView as reference for when backend generates sessionTokens"

patterns-established:
  - "UIViewRepresentable + Coordinator for WKWebView integration"

issues-created:
  - "Coinbase Onramp requires server-side sessionToken (ISSUES.md)"

duration: ~30min
completed: 2026-03-07
---

# Phase 3 Plan 4: Coinbase Onramp + Deposit Flow Summary

**CoinbaseOnrampView with WKWebView, Coinbase-branded deposit button, simulated flow pending backend**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-03-07T05:30:00Z
- **Completed:** 2026-03-07T06:00:00Z
- **Tasks:** 3 (2 auto + 1 checkpoint)
- **Files modified:** 2

## Accomplishments
- CoinbaseOnrampView wraps WKWebView via UIViewRepresentable with Coordinator
- Coinbase Onramp URL builder with addresses JSON, USDC/Base defaults
- SetupDepositView shows "Fund with Coinbase" blue gradient button (replaces Apple Pay)
- Deposit is simulated for all users until backend generates sessionTokens
- Guest mode and authenticated mode both advance setup flow identically

## Task Commits

1. **Task 1: Build CoinbaseOnrampView with WKWebView** - `866f589` (feat)
2. **Task 2: Wire Coinbase Onramp into SetupDepositView** - `eb41c03` (feat)
3. **Checkpoint: Human verification** - discovered sessionToken requirement
4. **Fix: Simulated deposit flow** - `29afc81` (fix)

## Files Created/Modified
- `Features/Funding/CoinbaseOnrampView.swift` - WKWebView wrapper for Coinbase Onramp
- `Features/Setup/SetupDepositView.swift` - Coinbase-branded button, simulated deposit

## Decisions Made
- Privy iOS SDK has no funding API (`useFundWallet()` is React/Expo only)
- Coinbase Onramp enforces sessionToken requirement (since July 2025)
- SessionToken requires a backend to call Coinbase's Create Onramp Session API
- Simulated deposit for all users until backend is built
- Kept CoinbaseOnrampView for future use when sessionToken generation exists

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Coinbase Onramp sessionToken required**
- **Found during:** Checkpoint verification (user tested)
- **Issue:** Coinbase returns "requires a sessionToken" — URL-param approach no longer works
- **Research:** Privy iOS SDK confirmed to have zero funding methods (checked Swift interface, feature matrix)
- **Fix:** Made deposit simulated for all users, logged issue for backend work
- **Files modified:** Features/Setup/SetupDepositView.swift
- **Verification:** Setup flow advances correctly for all users

---

**Total deviations:** 1 auto-fixed (1 blocking), 0 deferred
**Impact on plan:** Core UI complete, funding requires backend (future phase)

## Issues Encountered
- Coinbase Onramp requires server-side sessionToken generation via their API
- Privy Dashboard shows Account Funding feature but it's not available in iOS SDK

## Next Phase Readiness
- Deposit UI is built and ready for real funding when backend exists
- CoinbaseOnrampView ready to accept sessionToken parameter
- Phase 3 is functionally complete (auth, wallet, risk profile, deposit UI)

---
*Phase: 03-wallet-onramp*
*Completed: 2026-03-07*
