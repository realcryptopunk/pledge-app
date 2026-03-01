# PRD: Pledge — Discipline With Teeth

**Version:** 1.0
**Author:** Nav + Scout
**Date:** February 25, 2026
**Status:** Draft

---

## 1. Executive Summary

Pledge is an iOS app that combines habit tracking with financial accountability. Users stake real money on their daily habits. When they fail, the staked money is automatically converted into fixed-yield Pendle Principal Tokens (PTs) — stablecoin-based, zero-coupon bond-like instruments that mature at a guaranteed value. The time-lock is built into the asset itself. Users are either disciplined or building wealth — they win either way.

**One-liner:** *"Miss your habit, fund your future."*

**Category:** Health & Fitness
**Platform:** iOS 26+ (iPhone first, Apple Watch V1.1)
**Monetization:** Platform fee on penalties + Premium subscription + PT yield spread
**Target Launch:** Q3 2026

---

## 2. Problem Statement

### Why Existing Habit Apps Fail
- **No real consequences** — checking a box has zero stakes. 92% of habit app users churn within 30 days.
- **Self-reported** — users lie. There's no verification that the habit was actually completed.
- **No financial skin in the game** — behavioral science proves loss aversion is 2x more powerful than reward motivation (Kahneman & Tversky, Prospect Theory).

### The Insight
People don't need another reminder. They need **consequences**. But consequences that don't actually punish — they redirect.

---

## 3. Target Audience

### Primary: The Aspiring Disciplined (18-35)
- Follows self-improvement content (Goggins, Huberman, Atomic Habits)
- Has tried and failed with habit apps
- Has disposable income ($50-200/mo discretionary)
- Motivated by challenges (75 Hard, Dry January, No Fap)
- Active on TikTok, X/Twitter, Instagram reels

### Secondary: Fitness Enthusiasts (22-40)
- Already disciplined but wants accountability
- Gym culture, running, cold plunge community
- Willing to pay for tools that maintain streaks

### Tertiary: Financial Wellness Seekers (25-40)
- Wants to save/invest but lacks discipline
- "Trick me into investing" mindset
- Sees the dual-benefit value proposition

### Anti-Personas (NOT our user)
- People in financial distress (ethics — we don't want vulnerable people staking rent money)
- Users under 18
- Gambling addicts (this is NOT gambling — money is always returned)

---

## 4. Core Value Proposition

| If you succeed | If you fail |
|---|---|
| Keep your money | Money gets invested for you |
| Build discipline | Build wealth |
| Grow your streak | Grow your portfolio |
| Bragging rights | Financial safety net |

**Key insight:** Reframe failure as investing, not punishment. The user can never truly lose.

---

## 5. Feature Specification

### 5.1 Onboarding Flow

```
Screen 1: "What if missing a habit made you richer?"
Screen 2: Choose your habits (pick 1-3)
Screen 3: Set your stakes ($5 / $10 / $25 per habit per day)
Screen 4: Set your vault lock period (30 / 90 / 365 days)
Screen 5: Add payment method (Coinbase Onramp — Apple Pay / Card / Coinbase account)
Screen 6: Deposit initial balance ($50 minimum → USDC on Arbitrum)
Screen 7: Set verification methods for each habit
Screen 8: You're live — first habit starts tomorrow
```

### 5.2 Habits & Verification

#### Tier 1 — Auto-Verified (MVP)
| Habit | Verification Method | iOS API |
|---|---|---|
| Wake up by [time] | First app interaction of the day | `UIApplication.didBecomeActiveNotification` + timestamp |
| Walk [X] steps | Step count by end of day | `HealthKit: HKQuantityType.stepCount` |
| Workout [X]x/week | Logged workout session | `HealthKit: HKWorkoutType` |
| Limit screen time to [X]hrs | Daily screen time check | `DeviceActivity` framework |
| No phone after [time] | Screen locked / no usage after cutoff | `DeviceActivity` + `ManagedSettings` |
| Sleep [X] hours | Sleep duration | `HealthKit: HKCategoryType.sleepAnalysis` |
| Meditate [X] min | Mindful minutes logged | `HealthKit: HKCategoryType.mindfulSession` + accelerometer stillness |

#### Tier 2 — Photo Verified (V1.1)
| Habit | Verification Method | iOS API |
|---|---|---|
| Cold shower / plunge | Timed photo in bathroom + timestamp | `AVCaptureSession` + `Vision` |
| Read [X] pages | Photo of book page + OCR page number | `VNRecognizeTextRequest` |
| Healthy meal | Photo of food + ML classification | `VNClassifyImageRequest` + `CoreML` |
| Clean room / make bed | Photo comparison to baseline | `Vision` + custom `MLModel` |
| Journal entry | Word count + sentiment analysis | `NLTagger` + character count |

#### Tier 3 — Location Verified (V1.2)
| Habit | Verification Method | iOS API |
|---|---|---|
| Go to gym | Geofence entry at gym location | `CLCircularRegion` + `CLLocationManager` |
| Outdoor time [X] min | GPS confirms outdoor location | `CoreLocation` continuous |
| No fast food | Geofence avoidance of fast food | Reverse geofencing |
| Attend [class/church/etc] | Geofence entry at set location | `CLCircularRegion` |

### 5.3 Staking System

#### Deposit
- Minimum deposit: $50
- Payment via Coinbase Onramp (Apple Pay, debit card, bank transfer, or Coinbase account)
- Funds on-ramped directly to USDC on Arbitrum One
- Deposited USDC held in PledgeVault.sol smart contract
- Funds displayed in USD at all times (1 USDC ≈ $1)

#### Stake Configuration
- Per-habit daily stake: $5 / $10 / $25 / Custom
- Weekly cap option (e.g., max $50/week across all habits)
- Grace period: 1 "free pass" per week (configurable)

#### Penalty Trigger
```
11:59 PM local time → Verification engine runs
│
├─ Habit VERIFIED → ✅ No penalty. Streak +1.
│
├─ Habit NOT VERIFIED → ⏰ 30-min grace period push notification
│   │
│   ├─ Verified within grace → ✅ No penalty. Streak +1.
│   │
│   └─ Still not verified → 💸 Penalty triggered
│       ├─ Stake amount deducted from USDC Vault Balance
│       ├─ 80% → Pendle PT purchase (USDC → PT-aUSDC via Pendle Router V4)
│       ├─ 20% → Platform fee (Pledge revenue, held in USDC)
│       └─ Push notification: "Missed wake-up. $10 invested in PT. Matures Jun 26."
│
└─ Habit SKIPPED (free pass used) → ⏸️ No penalty. No streak.
```

#### Anti-Cheat
- Photo verification includes EXIF timestamp + location metadata
- Device time manipulation detection (compare to server time via NTP)
- HealthKit data cross-referenced with device unlock patterns
- Suspicious patterns flagged (e.g., 10K steps at 11:58 PM)
- ML model for photo fraud detection (stock photos, screenshots)

### 5.4 Investment Pool (Pendle Principal Tokens)

#### What the User Sees
```
┌─────────────────────────────────────┐
│  💰 Your Investment Pool            │
│                                     │
│  Total Invested:    $247.00         │
│  Projected Value:   $259.35         │
│  Fixed Yield:       +4.99% APY     │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  PT-aUSDC Position           │   │
│  │  Purchased: $247.00          │   │
│  │  Face Value: $259.35         │   │
│  │  Maturity: Jun 26, 2026      │   │
│  │  ████████████░░░░  89 days   │   │
│  └──────────────────────────────┘   │
│                                     │
│  [Maturity History]                 │
└─────────────────────────────────────┘
```

#### What's Actually Happening
- Penalty USDC → Pendle Router V4 → Purchase PT (Principal Token) at discount
- PT is a zero-coupon bond: buy at $0.95, redeems for $1.00 at maturity
- Example: $10 penalty buys ~$10.50 face value of PT-aUSDC (5% implied yield)
- Platform selects best stablecoin PT market on Pendle (aUSDC, GLP, sDAI, etc.)
- All positions held in PledgeVault.sol on Arbitrum One
- No seed phrases, no wallet, no crypto jargon exposed to user
- User sees "fixed yield savings" — never sees "crypto" or "DeFi"

#### How Pendle PTs Work
```
Today                          Maturity Date
  │                                │
  │  Buy PT at discount            │  PT redeems for full value
  │  $0.95 per $1 face value      │  $1.00 per token
  │                                │
  │  ──────────────────────────►   │
  │     Time = yield accrual       │
  │     (no price volatility)      │
```
- **Fixed yield** — return is locked in at purchase. No market risk on stablecoins.
- **Time-lock is built in** — PTs can't be redeemed early at full value. This IS the lock period.
- **Stablecoin-only** — no BTC/ETH volatility. Underlying is always USD-pegged.

#### Maturity / Unlock
- PT maturity dates range from 30 days to 12 months (platform selects appropriate market)
- Matured PTs are auto-redeemed to USDC via Chainlink Keepers
- Redeemed USDC can be:
  - Withdrawn to bank (off-ramp via Coinbase Offramp)
  - Re-staked into vault balance
  - Rolled into new PT position (compounding)
- **No early withdrawal penalty fee** — but selling PT before maturity on Pendle AMM means receiving slightly less than face value (market-determined, typically 0.5-2% less)

### 5.5 Dashboard / Home Screen

```
┌──────────────────────────────────────┐
│  Vault                    ⚙️  👤    │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  TODAY'S STAKES                │  │
│  │                                │  │
│  │  $45 on the line               │  │
│  │  3 habits remaining            │  │
│  │                                │  │
│  │  ⏰ Wake up 6am    ✅ Done     │  │
│  │  🏋️ Gym session    ⏳ Pending  │  │
│  │  📵 Screen < 3hrs  ⏳ Pending  │  │
│  │  😴 Sleep by 11pm  🔒 Tonight │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌─────────┐  ┌─────────────────┐   │
│  │ 🔥 23   │  │ 💰 $259         │   │
│  │ day     │  │ savings pool    │   │
│  │ streak  │  │ 4.9% fixed      │   │
│  └─────────┘  └─────────────────┘   │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  THIS WEEK                     │  │
│  │  M ✅ T ✅ W ✅ T ✅ F ⏳ S · S · │  │
│  │  $35 saved / $10 in PT         │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  PENALTY FEED                  │  │
│  │  Yesterday: Missed gym → $10  │  │
│  │  Feb 20: Missed wake up → $10 │  │
│  │  Feb 18: Screen time → $25    │  │
│  └────────────────────────────────┘  │
│                                      │
│         [🏠] [📊] [➕] [👥] [⚙️]    │
└──────────────────────────────────────┘
```

### 5.6 Social Features (V1.1)

#### Accountability Partners
- Invite friends to see your streaks
- Friends get notified when you fail ("Nav missed his 6am wake up 😂")
- Optional: friends can add to your stake ("I'll add $5 if you miss gym")

#### Leaderboards
- Global: longest streak, most invested, highest portfolio growth
- Friends: head-to-head discipline score
- Weekly challenges: "Early Bird Week" — everyone stakes wake-up time

#### Shareable Cards
- Auto-generated streak cards for Instagram/TikTok
- "23 days disciplined. $45 invested. 4.9% fixed yield."
- Portfolio milestone celebrations ("Your vault hit $1,000! 🎉")

### 5.7 Notifications Strategy

| Trigger | Time | Message |
|---|---|---|
| Morning habit start | Habit start time | "Rise and shine. $10 on the line. ⏰" |
| Habit approaching deadline | 2 hours before cutoff | "$10 says you can't finish your workout 💪" |
| Habit missed (grace period) | Cutoff time | "30 minutes to save your $10. Verify now." |
| Penalty triggered | Cutoff + 30 min | "Missed it. $10 invested at 4.9% yield. Matures Jun 26 📈" |
| Streak milestone | On achievement | "🔥 30 day streak! You've saved $300 in stakes." |
| PT maturity approaching | Weekly | "Your $247 position matures in 12 days → $259 at maturity" |
| PT matured | On maturity date | "Your PT matured! $259 USDC ready to withdraw or re-invest 🔓" |
| Friend activity | Real-time | "Jake just missed his gym stake. +$10 to his vault 😂" |

### 5.8 Widgets & Lock Screen

#### Home Screen Widgets
| Size | Content |
|---|---|
| Small | Today's streak count 🔥 + $ at stake |
| Medium | Today's habits checklist + $ at stake + streak |
| Large | Full dashboard: habits + streak + portfolio value + weekly grid |

#### Lock Screen Widgets
| Type | Content |
|---|---|
| Circular | Streak count 🔥 |
| Rectangular | "3 habits left • $45 at stake" |
| Inline | "🔥 23 days • $261 invested" |

#### Live Activity
- Active during habit windows
- Shows countdown to cutoff + amount at stake
- "Gym closes in 2h 14m • $10 at stake"

#### Apple Watch
- Complication: streak count + next habit
- Quick glance: today's habits status
- Haptic reminder at habit time

---

## 6. Monetization

### 6.1 Revenue Streams

#### Stream 1: Platform Fee on Penalties (Primary)
- 20% of every penalty amount
- User stakes $10, fails → $2 fee, $8 invested
- **Projection at scale:**
  - 50K active users × 2 failures/week × $10 avg stake × 20% fee
  - = **$200K/week = $10.4M/year**

#### Stream 2: Premium Subscription
| | Free | Premium ($9.99/mo) | Premium ($59.99/yr) |
|---|---|---|---|
| Habits | 2 | Unlimited | Unlimited |
| Verification | Auto only | Auto + Photo + Location | Auto + Photo + Location |
| PT maturity selection | Auto (platform picks) | Choose maturity date | Choose maturity date |
| Free passes | 1/week | 3/week | 3/week |
| Accountability partners | 1 | Unlimited | Unlimited |
| Analytics | Basic | Advanced (trends, predictions) | Advanced |
| Shareable cards | Basic | Custom themes | Custom themes |

**Projection:** 10% conversion × 50K users × $8/mo avg = **$40K/mo**

#### Stream 3: PT Yield Spread (Passive)
- Platform buys PTs at market discount (e.g., 5% implied yield)
- Pass through majority of fixed yield to user, keep spread (e.g., user gets 4%, platform keeps 1%)
- Yield is deterministic — locked in at purchase time, no variable DeFi rates
- **Projection:** $5M aggregate PT positions × ~1% spread = **$50K/year** (grows with AUM)

#### Stream 4: Early Withdrawal (Market-Based)
- Matured PT withdrawal: free (PT redeems at face value)
- Early withdrawal (before PT maturity): user sells PT on Pendle AMM at market price
  - Typical discount: 0.5-2% below face value depending on time to maturity
  - Platform takes no fee — the "penalty" is the natural market discount
  - Transparent: user sees exact amount they'll receive before confirming

### 6.2 Unit Economics

| Metric | Value |
|---|---|
| CAC (target) | $8-15 (social virality + content marketing) |
| LTV (12-month) | $180 (penalties + subscription) |
| LTV:CAC ratio | 12-22x |
| Monthly churn (target) | <8% (financial commitment = retention) |
| Payback period | <30 days |

---

## 7. Technical Architecture

### 7.1 System Overview

```
┌──────────────────────┐     ┌──────────────────────┐
│     iOS App           │     │    Apple Watch App    │
│  Swift / SwiftUI      │     │    WatchKit          │
│  HealthKit            │     │    HealthKit          │
│  DeviceActivity       │     └──────────┬───────────┘
│  CoreLocation         │                │
│  CoreML / Vision      │                │
│  WidgetKit            │                │
│  ActivityKit          │                │
│  StoreKit 2           │                │
└──────────┬────────────┘                │
           │                             │
           ▼                             ▼
┌──────────────────────────────────────────────────┐
│              Backend API (Node.js / Hono)         │
│                                                   │
│  ├── Auth Service (Firebase Auth / phone + email) │
│  ├── Habit Engine (verification + penalty logic)  │
│  ├── Onramp Service (Coinbase Onramp SDK)         │
│  ├── Investment Service (Pendle PT orchestration) │
│  ├── Notification Service (APNs + FCM)            │
│  ├── Social Service (friends + leaderboards)      │
│  └── Analytics (Mixpanel / Amplitude)             │
└──────────┬───────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────┐
│           Crypto Layer (Arbitrum One)              │
│                                                   │
│  ├── PledgeVault.sol (USDC deposits + PT mgmt)    │
│  ├── Pendle Router V4 (USDC → PT swaps)           │
│  └── Chainlink Keepers (auto-redeem matured PTs)  │
│                                                   │
│  On-ramp: Coinbase Onramp (fiat → USDC Arbitrum)  │
│  Off-ramp: Coinbase Offramp (USDC → fiat)         │
│  Yield: Pendle PT discount (fixed, no DeFi pool)  │
└──────────────────────────────────────────────────┘
```

### 7.2 Tech Stack

| Layer | Technology |
|---|---|
| iOS App | Swift 6+, SwiftUI, iOS 26+ (Liquid Glass) |
| Watch App | SwiftUI, WatchOS 10+ |
| Backend | Node.js + Hono (or Bun) on Railway/Fly.io |
| Database | Supabase (Postgres) + Redis for caching |
| Auth | Firebase Auth (phone + Apple Sign In) |
| Payments | Coinbase Onramp SDK + Apple IAP (subscriptions) |
| Crypto | Arbitrum One + Pendle V2 + Pendle Hosted SDK, Solidity, ethers.js |
| On/Off-ramp | Coinbase Onramp / Offramp |
| Automation | Chainlink Keepers (auto-redeem matured PTs) |
| Push | Firebase Cloud Messaging + APNs |
| Analytics | Mixpanel |
| CI/CD | GitHub Actions + Fastlane |
| Monitoring | Sentry (iOS) + Datadog (backend) |

### 7.3 Smart Contracts

#### PledgeVault.sol (Single Contract)
```
Core Functions:
- deposit(amount)         → receive USDC into user's vault balance
- investInPT(amount, market) → swap USDC → PT via Pendle Router V4
- redeemPT(ptAddress)     → redeem matured PT back to USDC
- withdraw(amount)        → transfer USDC to user's wallet
- getUserPosition(user)   → returns USDC balance + PT positions

View Functions:
- getActivePositions(user) → list of PT positions with maturity dates
- getProjectedValue(user)  → total value at maturity (all PTs at face value)
- getRedeemableValue(user) → value of matured PTs ready to claim

Admin Functions:
- updatePendleRouter(addr) → update Pendle Router address
- collectFees(amount)      → withdraw platform fees
- pause() / unpause()      → emergency controls

Integration Addresses (Arbitrum One):
- Pendle Router V4: 0x888888888889758F76e7103c6CbF23ABbF58F946
- USDC:            0xaf88d065e77c8cC2239327C5EDb3A432268e5831
- PT Markets:      Selected dynamically based on best yield + liquidity
```

#### Chainlink Keepers Integration
```
- checkUpkeep()    → scan for matured PT positions across all users
- performUpkeep()  → auto-redeem matured PTs back to USDC in vault
- Runs on schedule (daily check for newly matured positions)
```

---

## 8. Data Model

### Users
```
id, phone, email, name, created_at, is_premium,
premium_expires_at, coinbase_user_id, vault_address,
vault_balance_usdc, total_staked, total_penalties,
total_invested_in_pts, current_streak, longest_streak
```

### Habits
```
id, user_id, type, name, verification_method,
stake_amount, schedule (daily/weekly), target_value,
grace_passes_remaining, is_active, created_at
```

### Habit Logs
```
id, habit_id, user_id, date, status (verified/failed/skipped),
verified_at, verification_data (JSON), penalty_amount,
invested_amount, fee_amount
```

### Vault Transactions
```
id, user_id, type (deposit/pt_purchase/pt_redeem/withdrawal/fee),
amount_usdc, tx_hash, pt_address (nullable),
created_at
```

### PT Positions
```
id, user_id, pt_token_address, pt_market_name,
pt_amount, purchase_price_usdc, face_value_usdc,
implied_yield_pct, purchase_date, maturity_date,
status (active/matured/redeemed/sold_early),
redeem_tx_hash (nullable)
```

---

## 9. Legal & Compliance

### 9.1 Regulatory Strategy

| Concern | Approach |
|---|---|
| **Money Transmitter** | Coinbase is the merchant of record and licensed money transmitter. We never hold user fiat directly. |
| **Securities** | PTs function like fixed-yield savings bonds — predictable return, no speculation. Framed as "fixed-yield savings," not "crypto investing." Stronger position than volatile crypto portfolios. |
| **Apple App Store** | App is a "habit tracker with fixed-yield savings." No volatile crypto. No BTC/ETH. "Savings" framing with guaranteed maturity value. Coinbase Onramp is Apple-approved payment method. |
| **Gambling** | NOT gambling — users always get money back (PT matures to full value, not forfeited). No element of chance. Outcome is entirely user-controlled. |
| **KYC/AML** | Coinbase handles all KYC/AML as merchant of record. Users authenticate via Coinbase account or identity verification during onramp. |
| **Age restriction** | 18+ only. Age verification during onboarding + Coinbase KYC. |

### 9.2 Terms of Service Key Points
- User USDC held in audited smart contract on Arbitrum (PledgeVault.sol)
- Platform is not a financial advisor
- PT positions carry smart contract risk; underlying stablecoin could depeg
- Early withdrawal means selling PT at market price (may be slightly below face value)
- Maximum daily/weekly stake limits to prevent problem behavior
- Self-exclusion option available

### 9.3 Responsible Design
- Maximum stake cap: $50/day, $200/week
- Mandatory cooldown if user loses >$100 in a week (prompt to reduce stakes)
- Self-exclusion: user can pause staking at any time
- Financial wellness check: if user's penalty rate >60%, suggest reducing stakes
- Clear display of investment risks

---

## 10. Go-to-Market Strategy

### 10.1 Launch Strategy

**Phase 1: Closed Beta (Week 1-4)**
- 500 users from self-improvement communities
- Reddit: r/selfimprovement, r/discipline, r/75hard
- X/Twitter: DM self-improvement influencers
- Focus: validate core loop (stake → verify → penalize → invest)

**Phase 2: Public Beta (Week 5-8)**
- Open waitlist with referral mechanism
- "Invite 3 friends, skip the line"
- Target: 5,000 users
- Focus: retention metrics, penalty rates, deposit sizes

**Phase 3: Public Launch (Week 9-12)**
- Product Hunt launch
- Influencer partnerships (see below)
- PR: "The app that fines you for being lazy — and invests the money"
- Target: 25,000 users

### 10.2 Marketing Channels

#### Content / Viral (Primary — $0 CAC)
- TikTok/Reels: "I lost $200 to my habit app... here's my portfolio now" format
- Shareable streak cards designed for Instagram stories
- "Vault Reveal" trend — users show their invested balance after 30/90 days
- YouTube shorts: discipline challenge content

#### Influencer Partnerships
| Tier | Examples | Cost | Expected |
|---|---|---|---|
| Micro (10-50K) | Discipline/fitness TikTokers | $500-2K | 1-3K installs |
| Mid (50-500K) | Self-improvement YouTubers | $2-10K | 5-15K installs |
| Macro (500K+) | Iman Gadzhi, Alex Hormozi adjacent | $10-50K | 20-50K installs |

#### Paid Acquisition (Phase 3+)
- Meta/Instagram: target fitness, self-improvement, financial wellness interests
- TikTok ads: UGC-style "I can't believe this app" content
- Apple Search Ads: "habit tracker," "discipline app," "75 hard app"

### 10.3 Virality Mechanics
- **Failure notifications to friends** — social pressure + entertainment
- **Shareable cards** — designed for Instagram stories
- **Referral program** — both users get 1 free week of Premium
- **Group challenges** — "75 Hard together" with shared stakes
- **Vault reveals** — end of lock period celebration content

---

## 11. Success Metrics

### North Star Metric
**Weekly Active Stakers (WAS)** — users who have ≥1 active stake and verified ≥1 habit in the past 7 days

### KPIs

| Metric | Target (Month 1) | Target (Month 6) | Target (Month 12) |
|---|---|---|---|
| Total Users | 5K | 50K | 200K |
| Weekly Active Stakers | 2K | 25K | 100K |
| Avg Stake/User/Week | $30 | $40 | $50 |
| Penalty Rate | 25-35% | 20-30% | 20-25% |
| Avg Deposit Size | $75 | $100 | $150 |
| Premium Conversion | 5% | 10% | 12% |
| D7 Retention | 60% | 65% | 70% |
| D30 Retention | 35% | 45% | 50% |
| Monthly Revenue | $15K | $250K | $1M+ |
| Aggregate Vault Balance | $100K | $3M | $15M |

---

## 12. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Apple rejects app | Low-Medium | Critical | No volatile crypto. "Fixed-yield savings" framing. No BTC/ETH. Coinbase is Apple-approved. Appeal process ready. |
| Users game the system | High | Medium | Multi-signal verification, anti-cheat ML, server-side time validation |
| Pendle smart contract exploit | Low | Critical | Pendle is audited, $5B+ TVL. Monitor for incidents. Emergency pause on PledgeVault. Diversify across PT markets. |
| Stablecoin depeg (USDC) | Low | High | USDC is Circle-backed, most regulated stablecoin. Monitor in real-time. Auto-pause deposits if depeg >1%. |
| Pendle market liquidity | Low-Medium | Medium | Only use PT markets with >$10M liquidity. Monitor depth before large trades. Batch small penalty amounts. |
| Regulatory action | Low | Critical | Coinbase handles KYC/AML. Legal counsel. No investment advice. "Savings" framing. |
| Low penalty rates (users too disciplined) | Medium | Medium | Good problem. Pivot revenue to subscriptions. Add harder habits. |
| High penalty rates (users quit) | Medium | High | Smart stake recommendations. Cooldown system. Celebrate investment growth. |

---

## 13. Milestones & Timeline

### MVP (Weeks 1-3) — Real Money From Day One
- [ ] Core app shell: onboarding, home dashboard, settings
- [ ] 3 auto-verified habits: wake up, steps, workout
- [ ] Coinbase Onramp integration (fiat → USDC on Arbitrum)
- [ ] PledgeVault.sol deployed on Arbitrum One
- [ ] Pendle PT integration: penalty USDC → PT-aUSDC via Router V4
- [ ] Penalty engine (cron job, midnight local time)
- [ ] PT position tracking UI (maturity date, fixed yield, projected value)
- [ ] Push notifications
- [ ] Home screen widget

### V1.0 (Weeks 4-6) — Polish & Premium
- [ ] Chainlink Keepers: auto-redeem matured PTs
- [ ] Coinbase Offramp: USDC → fiat withdrawal
- [ ] PT maturity history + unlock flow
- [ ] Screen Time API integration (DeviceActivity)
- [ ] Premium subscription (StoreKit 2 + Apple IAP)
- [ ] TestFlight beta
- [ ] Push notification polish

### V1.1 (Weeks 7-10) — Social & Verification
- [ ] Photo verification habits (cold shower, meals, reading)
- [ ] Social features: accountability partners, friend penalties feed
- [ ] Shareable streak cards
- [ ] Apple Watch app
- [ ] Lock screen widgets + Live Activities
- [ ] App Store launch

### V1.2+ (Weeks 11-16) — Growth
- [ ] Location-verified habits (gym, outdoor time)
- [ ] Group challenges
- [ ] Leaderboards
- [ ] Multi-market PT selection (premium: choose maturity)
- [ ] Android development begins

---

## 14. Competitive Landscape

| App | Revenue/mo | What They Do | Our Advantage |
|---|---|---|---|
| Finch ($2M) | Virtual pet + habits | No financial stakes, no verification |
| Opal ($1M) | Screen time blocking | Single-purpose, no investment angle |
| 75 Hard ($100K) | Challenge tracking | No financial consequence, self-reported |
| Beeminder (~$50K est) | Pledge money on goals | Money is LOST on failure (charity). We INVEST it. |
| stickK (~$30K est) | Commitment contracts | Old design, money goes to anti-charity. No crypto. |
| Forest ($100K) | Focus timer, grow trees | No financial stakes |

**Our differentiation:** Everyone else either has no stakes (most apps) or forfeits money on failure (Beeminder/stickK). We're the only one that **invests** penalty money, making failure a positive outcome. This is a fundamentally different psychological framing.

---

## 15. Decisions Made

1. **Minimum iOS version:** iOS 26 — latest APIs, Liquid Glass, newest WidgetKit
2. **Real money MVP:** Coinbase Onramp + Pendle PTs integrated from launch. No simulated portfolio phase.
3. **Pendle PTs over generic crypto portfolio:** Stablecoin-only, fixed-yield, zero-coupon instruments. Time-lock built into the asset. No BTC/ETH volatility.
4. **Stablecoin-only strategy:** No volatile crypto exposure. Predictable returns. Stronger regulatory and App Store position.
5. **Coinbase Onramp over Stripe/Bridge/MoonPay:** Direct Arbitrum + USDC support. Coinbase handles KYC/AML as merchant of record. Apple-approved.
6. **App name:** Pledge — Discipline With Teeth
7. **Apple Watch:** V1.1 (not MVP)
8. **Android:** After iOS PMF
9. **Challenges:** Generic discipline challenges — not tied to any specific program. Any habit trackable by phone is fair game.

---

*"You're either building discipline or building wealth. Pledge makes sure you're always building something."*
