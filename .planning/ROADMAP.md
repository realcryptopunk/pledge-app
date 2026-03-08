# Roadmap

## Milestone 1: Core Functionality

### Phase 1: functional-habits — Complete

Make habits functional with real data, persistence, and verification.

| Plan | Name | Status |
|------|------|--------|
| 01-01 | HealthKit Setup | Complete |
| 01-02 | Add Habit Flow | Complete |
| 01-03 | Verification Engine | Complete |

### Phase 2: location-verification — Complete

Add geofence-based habit verification using CoreLocation. Supports gym attendance, outdoor time tracking, fast food avoidance, and generic location attendance.

| Plan | Name | Status |
|------|------|--------|
| 02-01 | CoreLocation Service + Project Config | Complete |
| 02-02 | Model Extensions + Verification Wiring | Complete |
| 02-03 | Location Picker UI + AddHabitView | Complete |

### Phase 3: wallet-onramp — Complete

Integrate Privy for embedded wallet creation and Coinbase Onramp for fiat funding. Add 3-tier risk profile system (conservative T-bills, moderate Pendle PTs, aggressive tokenized ventures via Robinhood).

| Plan | Name | Status |
|------|------|--------|
| 03-01 | Privy SDK + Wallet Service | Complete |
| 03-02 | Auth Migration + Wallet Creation | Complete |
| 03-03 | Risk Profile System | Complete |
| 03-04 | Coinbase Onramp + Deposit Flow | Complete |

### Phase 4: backend-api — Complete

Supabase backend with full data persistence, real-time subscriptions, Coinbase Onramp sessionToken edge function, and Gemini API proxy. Resolves ISSUE-001 (server-side sessionToken blocking real funding).

| Plan | Name | Status |
|------|------|--------|
| 04-01 | Supabase Foundation + Database Schema | Complete |
| 04-02 | Coinbase Onramp Session Token | Complete |
| 04-03 | Auth Bridge + User Profiles | Complete |
| 04-04 | Data Persistence (Habits + Logs) | Complete |
| 04-05 | Gemini Proxy + Real-time | Complete |
| 04-06 | Username + Social Leaderboards | Complete |

## Milestone 2: Investment Infrastructure

### Phase 5: investment-contracts — Complete

PledgeVaultRH smart contract on Robinhood Chain Testnet. Non-custodial vault that pulls pre-approved USDC from user wallets and distributes across stock allocations (TSLA/AMZN/PLTR/AMD). Relayer-operated with emergency withdraw for users. Deployed at `0x70d73b04d0c2ee4f73eb44cbf5377a2c3fbc52ba`.

| Plan | Name | Status |
|------|------|--------|
| 05-01 | Foundry Setup + PledgeVaultRH Contract | Complete |
| 05-02 | Contract Tests + Deployment | Complete |

### Phase 6: investment-backend

Supabase edge function relayer for automated on-chain investment when habits are missed. Calls PledgeVaultRH.investForUser via ethers.js. iOS app integration for end-to-end demo flow.

| Plan | Name | Status |
|------|------|--------|
| 06-01 | Invest Relayer Edge Function | Pending |
| 06-02 | iOS App Integration | Pending |

### Phase 7: portfolio-integration

iOS app integration with real on-chain data. USDC approval flow during onboarding, real portfolio values from contract state, maturity tracking, withdrawal UI.

| Plan | Name | Status |
|------|------|--------|
| — | Not yet planned | — |
