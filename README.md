# Pledge

**Stake money on your habits. Miss a day, fund your future.**

[pledgeapp.xyz](https://pledgeapp.xyz)

Pledge is an iOS accountability app that turns missed habits into investments. Set a daily habit, stake real money on it, and if you fail — your stake is automatically swapped into yield-generating tokens on-chain via Uniswap V3.

## How It Works

1. **Create a habit** — Gym, steps, sleep, meditation, screen time, and more
2. **Stake money** — Put $10–$50 on the line per habit
3. **Get verified** — HealthKit, location geofencing, or AI photo verification
4. **Succeed** → Keep your stake. **Fail** → Stake is invested into yield tokens

## Features

- **13+ habit types** with auto-verification via HealthKit, CoreLocation, and Screen Time
- **AI photo verification** powered by Google Gemini Vision for exercise reps
- **On-chain investment** — Failed stakes swap into USDY, bCSPX, pt-USDe, and more
- **Three risk tiers** — Safe (4-5% APY), Stable Core (8-12%), Growth (15-30%+)
- **Social leaderboards** — Compete on streaks, consistency, and total staked
- **Embedded wallet** — Privy-powered, no seed phrase required

## Architecture

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   iOS App   │────▶│  Supabase Edge   │────▶│  PledgeVault    │
│   SwiftUI   │     │  Functions (Deno) │     │  (Solidity)     │
└─────────────┘     └──────────────────┘     └─────────────────┘
       │                     │                        │
   HealthKit            Auth Bridge              Uniswap V3
   CoreLocation         Gemini Proxy             USDC → Yield
   Privy SDK            Invest Relayer           Tokens
```

## Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | SwiftUI, iOS 17+, HealthKit, CoreLocation |
| Auth & Wallet | Privy SDK (embedded wallets, social login) |
| Backend | Supabase (Postgres, Realtime, Edge Functions) |
| AI | Google Gemini 2.0 Flash (photo verification) |
| Smart Contracts | Solidity, Foundry, OpenZeppelin |
| DeFi | Uniswap V3 (USDC → yield token swaps) |
| Onramp | Coinbase Onramp |

## Smart Contract — PledgeVault

The core contract holds USDC pledges and executes investment swaps on habit failure.

- `deposit(amount)` — Lock USDC for a habit
- `investOnFailure(pledgeId)` — Relayer swaps stake into yield tokens (2% platform fee)
- `claimSuccess(pledgeId)` — Returns full USDC on habit success
- `cancelPledge(pledgeId)` — Emergency escape after 30-day timeout

Risk tier allocations determine the split between stable yields (USDY) and growth tokens (bCSPX).

## Setup

```bash
# Generate Xcode project
xcodegen generate -s project.yml

# Open in Xcode
open PledgeApp.xcodeproj

# Run contract tests
cd contracts && forge test
```

Requires `Secrets.xcconfig` with API keys (see `Secrets.xcconfig.example`) and `.env` for edge functions (see `.env.example`).

## License

MIT
