# Project State

## Current Position

Phase: 5 of 7 (investment-contracts)
Plan: Not started
Status: Phase planned, ready for execution
Last activity: 2026-03-07 - Phase 5 planned (2 plans, 4 tasks)

Progress: ██████████ 100% Milestone 1 | ░░░░░░░░░░ 0% Milestone 2

## Accumulated Decisions

| Phase | Decision | Rationale |
|-------|----------|-----------|
| 03-01 | Used Privy SDK 2.0 (from: 2.0.0) | Actual available SDK version |
| 03-02 | ProcessInfo env vars for credentials | .env bundle loading doesn't work in Simulator |
| 03-02 | Combine sinks for state propagation | Cross-service state sync between PrivyManager and AppState |
| 03-03 | Three-tier risk profile (conservative/moderate/aggressive) | Matches PRD allocation strategy |
| 03-04 | Simulated deposit flow | Coinbase Onramp requires server-side sessionToken |
| 03-04 | Privy iOS SDK lacks funding API | useFundWallet() only in React/Expo SDKs |
| 04-03 | JWT_SECRET env var (not SUPABASE_JWT_SECRET) | Supabase CLI reserves SUPABASE_ prefix |
| 04-03 | --no-verify-jwt for edge functions | sb_publishable_ anon key format incompatible with default verification |
| 04-03 | Non-blocking auth bridge | Privy login succeeds even if Supabase bridge fails |
| 04-04 | Local-first persistence pattern | UI updates immediately, Supabase sync async |
| 04-06 | Username required before app access | Enforced in PledgeApp routing |
| 04-06 | Leaderboard via edge function | service_role key needed for cross-user queries |
| 05-00 | Smart contract approval pattern (not Privy server signing) | Privy MPC wallets can't be signed from server without authorization keys; contract approval is standard DeFi pattern |
| 05-00 | Foundry over Hardhat | Superior DeFi testing (fork tests, fuzzing), Solidity-native |
| 05-00 | Pendle Router V4 on Arbitrum | Latest router at 0x888...946, native USDC at 0xaf88...5831 |

## Deferred Issues

- ISSUE-001: Coinbase Onramp requires server-side sessionToken — RESOLVED by 04-02 (edge function deployed, needs CDP credentials)
- ISSUE-002: Coinbase Onramp chain was set to "base" — RESOLVED, updated to "arbitrum" in CoinbaseOnrampView + edge function

## Blockers/Concerns Carried Forward

- Pre-existing build issue: swift-clocks (Supabase transitive dep) fails with missing module dependency — not caused by our changes
- Supabase anon key in .env uses sb_publishable_ format — may need standard JWT format from dashboard for some operations
- Pendle may not have contracts on Arbitrum Sepolia — fork testing against mainnet recommended over testnet deployment
- Smart contract requires audit before mainnet deployment

## Session Continuity

Last session: 2026-03-07
Stopped at: Phase 5 planned, ready for execution
Resume file: None
