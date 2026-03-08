# Task: Hackathon Demo Polish — Branch hackathon/demo-ready

DEADLINE: TOMORROW. Move fast, no perfectionism.

## 1. README.md (for hackathon submission)

Create a compelling README.md at repo root:

```markdown
# Pledge — Discipline With Teeth 🛡️

> The habit app where missing a goal auto-invests into tokenized stocks on Robinhood Chain.

## 🎯 What Is Pledge?

Pledge is an iOS app that lets users stake real money on their habits. Miss a habit? Your stake doesn't disappear — it auto-invests into tokenized stocks (Tesla, Amazon, Palantir, AMD) on Robinhood Chain.

**You either build discipline or build a portfolio. Win-win.**

## 🏗️ Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│   iOS App        │     │   Backend         │     │  Robinhood Chain    │
│   (SwiftUI)      │────▶│   (Relayer)       │────▶│  (Testnet)          │
│                  │     │                   │     │                     │
│ • Habit tracking │     │ • Missed habit    │     │ • PledgeVaultRH.sol │
│ • HealthKit      │     │   detection       │     │ • USDC deposits     │
│ • GPS verify     │     │ • investForUser() │     │ • Stock allocations │
│ • Vision AI      │     │   calls           │     │ • Portfolio tracking│
│ • Gemini photo   │     │                   │     │                     │
│ • Portfolio UI   │     │                   │     │ • TSLA, AMZN, PLTR  │
└─────────────────┘     └──────────────────┘     │ • AMD, NFLX tokens  │
                                                   └─────────────────────┘
```

## 📱 iOS App Features

- **13 verifiable habits** — gym, pushups, pull-ups, jumping jacks, steps, sleep, cold shower, meditation, reading, journal, workout, screen time, wake up
- **4 verification methods:**
  - 🏥 HealthKit (steps, sleep, workouts)
  - 📍 GPS geo-fencing (gym check-ins)
  - 📹 Vision AI (real-time pushup/pull-up counting with pose detection)
  - 📸 Gemini 2.0 Flash (BeReal-style photo verification)
- **3 risk profiles:** Blue Chip Stocks, Growth Mix, High Conviction
- **Beautiful UI:** Custom design system with aqua/clean themes, skeuomorphic glass cards, fluid gradients
- **57+ Swift files**, pure SwiftUI, iOS 26+, zero external dependencies (except Vortex)

## 📜 Smart Contract

**PledgeVaultRH.sol** — Deployed on Robinhood Chain Testnet (Chain ID: 46630)

| Function | Description |
|---|---|
| `investForUser(user, amount)` | Pulls USDC, takes 20% fee, allocates 80% across stocks |
| `emergencyWithdraw()` | User exits all positions, gets USDC back |
| `getUserPortfolio(user)` | Returns token addresses + balances |
| `setAllocations(allocs)` | Owner configures stock split (must total 100%) |

**Default Allocation:** 30% TSLA · 25% AMZN · 25% PLTR · 20% AMD

- 21 Foundry tests, all passing
- OpenZeppelin: Ownable, ReentrancyGuard, SafeERC20
- Solidity 0.8.20, optimizer enabled

### Token Addresses (Robinhood Chain Testnet)
| Token | Address |
|---|---|
| USDC | `0xbf4479C07Dc6fdc6dAa764A0ccA06969e894275F` |
| TSLA | `0xC9f9c86933092BbbfFF3CCb4b105A4A94bf3Bd4E` |
| AMZN | `0x5884aD2f920c162CFBbACc88C9C51AA75eC09E02` |
| PLTR | `0x1FBE1a0e43594b3455993B5dE5Fd0A7A266298d0` |
| AMD  | `0x71178BAc73cBeb415514eB542a8995b82669778d` |
| NFLX | `0x3b8262A63d25f0477c4DDE23F83cfe22Cb768C93` |

## 💰 Business Model

- **20% platform fee** on all missed habit stakes
- **$9.99/mo premium** (advanced analytics, custom habits)
- **Market validation:** Beeminder does $50-80K/mo with terrible UX

## 🛠️ Tech Stack

- **iOS:** Swift/SwiftUI, Vision framework, HealthKit, CoreLocation, AVFoundation
- **AI:** Gemini 2.0 Flash (photo verification)
- **Smart Contracts:** Solidity 0.8.20, Foundry, OpenZeppelin
- **Chain:** Robinhood Chain Testnet (Arbitrum Orbit L3, Chain ID 46630)
- **Backend:** Supabase (edge functions, auth bridge, database)

## 🏆 Hackathon

Built for **Arbitrum Open House NYC** — targeting Robinhood Chain Founder-in-Residence ($100K)

## 📦 Build & Run

### iOS App
```bash
open PledgeApp.xcodeproj
# Set signing team, build to device/simulator
```

### Smart Contract
```bash
cd contracts
forge build
forge test -v
# Deploy:
forge script script/Deploy.s.sol --rpc-url https://rpc.testnet.chain.robinhood.com --broadcast --private-key $KEY
```

## 👥 Team

Built by Nav (@realcryptopunk)
```

## 2. Add NatSpec comments to PledgeVaultRH.sol

Read contracts/src/PledgeVaultRH.sol and add NatSpec comments:
- `/// @title`, `/// @author`, `/// @notice` at the contract level
- `/// @notice` and `/// @param` for each public/external function
- `/// @dev` for implementation notes

This is important for the "smart contract quality" judging criteria.

## 3. Copy pitch deck and video script into this branch

```bash
git show hackathon/robinhood-chain:PITCH-DECK.md > PITCH-DECK.md
git show hackathon/robinhood-chain:VIDEO-SCRIPT.md > VIDEO-SCRIPT.md
git show hackathon/robinhood-chain:HACKATHON-ROBINHOOD.md > HACKATHON-ROBINHOOD.md
```

## 4. Build check
```bash
cd /Users/openclaw/.openclaw/workspace/pledge-app
xcodebuild -project PledgeApp.xcodeproj -scheme PledgeApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
cd contracts && forge build && forge test --summary
```

## 5. Commit and push
```bash
git add -A
git commit -m "hackathon: demo-ready — README, NatSpec, pitch deck, video script"
git push origin hackathon/demo-ready
```
