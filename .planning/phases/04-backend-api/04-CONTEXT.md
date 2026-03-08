# Phase 4: Backend API - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<vision>
## How This Should Work

Everything lives in Supabase — the app is fully cloud-backed with real-time subscriptions. When a user signs in with Privy on any device, all their habits, streaks, stakes, and portfolio data are there. No local-only data.

The most important thing is getting real money flowing. The Coinbase Onramp sessionToken generation needs a server-side endpoint so users can actually fund their wallets. This is the #1 blocker — everything else supports the core loop of "stake real money on habits."

Supabase handles the database (Postgres), edge functions (Coinbase sessionToken, Gemini API proxy), and real-time subscriptions (streaks updating live, portfolio balances refreshing automatically).

The Gemini API key currently hardcoded in the iOS app moves server-side into an edge function for security.

</vision>

<essential>
## What Must Be Nailed

- **Real money flowing** — Coinbase Onramp sessionToken endpoint so deposits actually work
- **Full data persistence** — Habits, logs, streaks, stakes, portfolio all synced to Supabase
- **Real-time subscriptions** — Data updates live across the app without manual refresh
- **Gemini API proxy** — Move the hardcoded API key server-side for security

</essential>

<boundaries>
## What's Out of Scope

- No hard exclusions — build whatever makes sense for a complete backend
- Social features, analytics, push notifications are all fair game if they fit naturally

</boundaries>

<specifics>
## Specific Ideas

- User already has a Supabase project created with URL and anon key ready
- Privy is the auth system (phone OTP + embedded wallet) — Supabase should work alongside it, not replace it
- Coinbase Onramp requires server-side JWT signing via their Create Onramp Session API
- Current data models: Habit, HabitLog, TodayHabit, ActivityItem, RiskProfile
- Wallet address comes from Privy embedded wallet, stored in AppState

</specifics>

<notes>
## Additional Context

- ISSUE-001 from Phase 3: Coinbase Onramp requires server-side sessionToken (blocking real funding)
- PhotoVerificationService.swift has hardcoded Gemini API key: needs to move server-side
- SupabaseConfig.swift exists with placeholder credentials — ready to wire up
- Supabase Swift SDK v2.0 already in project.yml
- AuthService.swift (Apple Sign-In via Supabase) exists but is unused — superseded by Privy

</notes>

---

*Phase: 04-backend-api*
*Context gathered: 2026-03-07*
