# Phase 3: Wallet Onramp - Context

**Gathered:** 2026-03-06
**Status:** Ready for research

<vision>
## How This Should Work

Users never think about crypto. They sign in with email, Apple, or Google — and behind the scenes, Privy creates an embedded wallet silently. The entire wallet layer is invisible.

When it's time to deposit money, it feels like Venmo or Cash App — link a payment method, type an amount, tap deposit. Coinbase Onramp handles the fiat-to-crypto conversion, but the user just sees "add money." No seed phrases, no gas fees, no blockchain jargon.

After their first deposit, users pick a risk profile once — conservative, moderate, or aggressive — and it applies to all their failed stakes. They can change it later in settings, but the default experience is pick-once-and-forget.

This phase is about making the money layer real and demo-ready. Privy replaces the current phone/OTP auth flow entirely, becoming the single auth + wallet system. One integration handles both sign-in and wallet creation.

</vision>

<essential>
## What Must Be Nailed

- **Privy integration actually working** — Auth (email/Apple/Google) and embedded wallet creation functioning end-to-end for the demo
- **Coinbase Onramp integration** — Real fiat deposit flow working, not mocked
- **Backend and auth fully set up** — Replace current phone/OTP with Privy as the single auth system
- **Risk profile selection** — One-time choice during setup (conservative/moderate/aggressive), changeable in settings

</essential>

<boundaries>
## What's Out of Scope

- Actual DeFi investing/yield — risk profiles exist in the UI but don't route to real T-bills, Pendle PTs, or tokenized ventures yet. That's a future phase.
- Complex onboarding education — no crypto explainers or wallet tutorials. It's invisible, so there's nothing to explain.

</boundaries>

<specifics>
## Specific Ideas

- Keep it minimal — match the existing app aesthetic. Simple screens, just get the flow working for the demo.
- Deposit should feel like any fintech app, not a crypto experience
- Risk profile is a simple one-time selection screen, not a quiz or assessment

</specifics>

<notes>
## Additional Context

User's primary goal is demo-readiness — this phase is about making the money layer functional, not polished. Privy serves double duty as both auth and wallet, simplifying the stack significantly. The current phone/OTP auth flow will be fully replaced.

</notes>

---

*Phase: 03-wallet-onramp*
*Context gathered: 2026-03-06*
