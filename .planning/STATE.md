# Project State

## Current Position

Phase: 3 of 3 (wallet-onramp)
Plan: 4 of 4 in current phase
Status: Phase 3 complete
Last activity: 2026-03-07 - Completed phase 03 execution

Progress: ██████████ 100% (all 3 phases complete)

## Accumulated Decisions

| Phase | Decision | Rationale |
|-------|----------|-----------|
| 03-01 | Used Privy SDK 2.0 (from: 2.0.0) | Actual available SDK version |
| 03-02 | ProcessInfo env vars for credentials | .env bundle loading doesn't work in Simulator |
| 03-02 | Combine sinks for state propagation | Cross-service state sync between PrivyManager and AppState |
| 03-03 | Three-tier risk profile (conservative/moderate/aggressive) | Matches PRD allocation strategy |
| 03-04 | Simulated deposit flow | Coinbase Onramp requires server-side sessionToken |
| 03-04 | Privy iOS SDK lacks funding API | useFundWallet() only in React/Expo SDKs |

## Deferred Issues

- ISSUE-001: Coinbase Onramp requires server-side sessionToken for real funding (see .planning/phases/03-wallet-onramp/ISSUES.md)

## Blockers/Concerns Carried Forward

- Pre-existing build issue: swift-clocks (Supabase transitive dep) fails with missing module dependency — not caused by our changes

## Session Continuity

Last session: 2026-03-07
Stopped at: Phase 03 complete
Resume file: None
