---
phase: 06-investment-backend
plan: 01
subsystem: invest-relayer
tags: [edge-function, supabase, ethers, on-chain, relayer]
requires: [PledgeVaultRH deployed on RH Chain Testnet]
provides: [invest-relayer edge function, on-chain investment relay capability]
affects: [supabase/functions/invest-relayer/]
tech-stack: [Deno, ethers.js v6, Supabase Edge Functions]
key-files:
  - supabase/functions/invest-relayer/index.ts
key-decisions:
  - Used ethers.js v6 with npm:ethers@6 Deno specifier (not v5)
  - USDC decimals queried from on-chain contract with fallback to 18
  - 1000 USDC testnet safety cap on single transactions
  - No JWT verification (matches existing edge function pattern; contract's onlyRelayer modifier provides access control)
  - Structured error classification (400 input / 500 config / 502 chain errors)
duration: ~2 minutes
completed: 2026-03-08T09:38:44Z
---

# 06-01 Summary: Invest-Relayer Edge Function

## Performance

- Start: 2026-03-08T09:36:49Z
- End: 2026-03-08T09:38:44Z
- Duration: ~2 minutes
- All tasks completed successfully

## Accomplishments

1. **Created invest-relayer Supabase edge function** that acts as the on-chain relayer, calling `PledgeVaultRH.investForUser` via ethers.js v6 when the app reports a missed habit.

2. **Deployed to Supabase** with `--no-verify-jwt` flag. Function is ACTIVE (version 1) at `https://ciwengqnkfkkanayoqgz.supabase.co/functions/v1/invest-relayer`.

3. **Verified all endpoints** via curl:
   - Invalid wallet address returns 400 with descriptive error
   - Negative amount returns 400 with descriptive error
   - Amount exceeding 1000 USDC cap returns 400 with descriptive error
   - Valid inputs without RELAYER_PRIVATE_KEY returns 500 (expected -- secret needs to be set via `supabase secrets set`)
   - OPTIONS preflight returns 204

## Task Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | `ea7e85e` | Create invest-relayer edge function with ethers.js v6 |
| Task 2 | (no file changes) | Deployed via `supabase functions deploy` + tested via curl |

## Files Created/Modified

- **Created:** `supabase/functions/invest-relayer/index.ts` -- Edge function implementing the on-chain relayer

## Decisions Made

1. **ethers.js v6 syntax**: Used `ethers.parseUnits()` (top-level), `ethers.JsonRpcProvider`, `new ethers.Wallet()`, `new ethers.Contract()` -- all v6 patterns, not v5.

2. **USDC decimals from contract**: Queries `decimals()` from the USDC contract at `0xbf4479C07Dc6fdc6dAa764A0ccA06969e894275F` with try/catch fallback to 18, matching the plan requirement to not hardcode decimals.

3. **Error classification**: Three categories of errors with appropriate HTTP status codes:
   - 400: Input validation failures (bad address, negative/excessive amount)
   - 500: Server configuration errors (missing RELAYER_PRIVATE_KEY)
   - 502: Chain/RPC errors (transaction reverts, network failures)

4. **Security**: Private key loaded only from `Deno.env.get("RELAYER_PRIVATE_KEY")`, never logged, never included in error responses. Contract's `onlyRelayer` modifier provides access control at the smart contract level.

## Deviations from Plan

- **Task 2: No separate commit** -- Task 2 was purely operational (deploy + test via CLI), with no source file changes. The function was deployed successfully and tested, but there were no files to commit. The plan listed `supabase/functions/invest-relayer/index.ts` as the file for Task 2, but that file was already committed in Task 1.

- **RELAYER_PRIVATE_KEY not set** -- As anticipated by the plan, the deployer's private key is not available in the current environment. The user needs to run: `supabase secrets set RELAYER_PRIVATE_KEY=<their-deployer-private-key>` to enable end-to-end transaction execution.

## Issues Encountered

- **Deno CLI not available**: Could not run `deno check` for syntax verification. Verified correctness by code inspection instead (ethers v6 API usage, Deno imports, TypeScript types).

- **RELAYER_PRIVATE_KEY not configured**: Expected per plan. User action required: `supabase secrets set RELAYER_PRIVATE_KEY=<key>`.

## Next Phase Readiness

The invest-relayer edge function is deployed and ready. To complete the end-to-end flow:

1. **Set the relayer secret**: `supabase secrets set RELAYER_PRIVATE_KEY=<deployer-private-key>`
2. **iOS integration** (06-02): The app needs to call this function when a habit is missed, passing the user's wallet address and the stake amount
3. **User USDC approval**: Before `investForUser` can succeed, the user must have approved the PledgeVaultRH contract to spend their USDC (ERC-20 approval)

### Endpoint Reference

```
POST https://ciwengqnkfkkanayoqgz.supabase.co/functions/v1/invest-relayer
Content-Type: application/json

{
  "user_wallet": "0x...",
  "usdc_amount": 5.00
}

Response (success):
{
  "success": true,
  "tx_hash": "0x...",
  "explorer_url": "https://explorer.testnet.chain.robinhood.com/tx/0x..."
}
```
