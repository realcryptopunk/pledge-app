---
phase: 04-backend-api
plan: 03
subsystem: auth-bridge
tags: [supabase, privy, edge-function, jwt, auth, ios-client]

requires:
  - phase: 04-01
    provides: Supabase CLI linked, database schema with user_profiles table, SupabaseConfig.swift
  - phase: 03-02
    provides: PrivyManager singleton, EnvConfig, Combine sink pattern

provides:
  - Auth bridge edge function deployed (verifies Privy tokens, upserts user_profiles, mints Supabase JWTs)
  - PrivyManager obtains Supabase session after Privy login
  - AppState has authenticated SupabaseClient for RLS-protected operations
  - Token refresh mechanism for expired Supabase JWTs
  - Guest mode preserved (skips Supabase auth)

affects: [04-04, 04-05, 04-06]

tech-stack:
  added: [jose (Deno JWT library), Supabase Edge Functions]
  patterns: [Privy JWKS verification, custom Supabase JWT minting, accessToken provider pattern]

key-files:
  created: [supabase/functions/auth-bridge/index.ts]
  modified: [Core/Services/PrivyManager.swift, Core/SupabaseConfig.swift, Core/AppState.swift]

key-decisions:
  - "Use JWT_SECRET env var name instead of SUPABASE_JWT_SECRET (Supabase CLI reserves SUPABASE_ prefix for custom secrets)"
  - "Deploy with --no-verify-jwt since the function does its own Privy token verification"
  - "Non-blocking auth bridge call — Privy login succeeds even if Supabase bridge fails"
  - "Token captured by value in Combine sink closure (simple, recreates client on refresh)"

patterns-established:
  - "Edge function pattern: CORS headers, POST-only, structured error responses"
  - "Privy JWKS token verification via jose library"
  - "PrivyManager.authenticateWithSupabase() called in both verifyOTP and checkAuthState"
  - "AppState.supabaseClient created via SupabaseConfig.authenticatedClient(accessToken:)"

issues-created: []

duration: ~25min
completed: 2026-03-07
---

# Phase 4 Plan 3: Auth Bridge + User Profiles Summary

**Privy-to-Supabase auth bridge edge function deployed, iOS auth flow wired to obtain Supabase JWT and create authenticated client after Privy login**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-03-07T11:00:00Z
- **Completed:** 2026-03-07T11:25:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Created and deployed `auth-bridge` edge function to Supabase (project ref: ciwengqnkfkkanayoqgz)
- Edge function verifies Privy JWT via JWKS endpoint, upserts user_profiles with service_role client, mints custom Supabase JWT with user_profiles.id as `sub` claim
- Set JWT_SECRET and PRIVY_APP_ID secrets on Supabase project
- PrivyManager gains `supabaseAccessToken` and `supabaseUserId` published properties
- `authenticateWithSupabase()` called after OTP verification and on app relaunch (checkAuthState)
- `refreshSupabaseTokenIfNeeded()` method for pre-emptive token refresh (5-minute window)
- SupabaseConfig gains `authenticatedClient(accessToken:)` factory method using SDK v2 accessToken provider
- AppState subscribes to `privyManager.$supabaseAccessToken` via Combine to create authenticated SupabaseClient
- Guest mode (`signInAsGuest()`) skips Supabase auth — no bridge call, no client created
- Sign-out clears all Supabase state (token, userId, client)

## Task Commits

1. **Task 1: Create auth bridge edge function** - `c0cad6c` (feat)
2. **Task 2: Update iOS auth flow to obtain Supabase session** - `d74900b` (feat)

## Files Created/Modified

- `supabase/functions/auth-bridge/index.ts` — Edge function: Privy token verification, user_profiles upsert, Supabase JWT minting
- `Core/Services/PrivyManager.swift` — Added supabaseAccessToken, supabaseUserId, authenticateWithSupabase(), refreshSupabaseTokenIfNeeded()
- `Core/SupabaseConfig.swift` — Added authenticatedClient(accessToken:) factory method
- `Core/AppState.swift` — Added supabaseClient, supabaseUserId, Combine subscriptions for Supabase state

## Decisions Made

- **JWT_SECRET env var name:** Supabase CLI reserves the `SUPABASE_` prefix for auto-provisioned secrets. Used `JWT_SECRET` instead of `SUPABASE_JWT_SECRET` for the custom signing secret.
- **--no-verify-jwt deployment:** Since the edge function does its own Privy JWKS token verification, we deployed without Supabase's default JWT verification gate. This allows the iOS app to call the function without needing a valid Supabase auth session first (chicken-and-egg problem).
- **Non-blocking bridge call:** If the auth bridge fails (network error, server error), Privy login still succeeds. The user can use the app locally; Supabase operations will just fail gracefully until token is obtained.
- **Client recreation on token change:** Each time `supabaseAccessToken` changes, a new SupabaseClient is created. This is simple and correct since the token is captured by value in the accessToken closure.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] SUPABASE_JWT_SECRET cannot be set as custom secret**
- **Found during:** Task 1 deployment
- **Issue:** `supabase secrets set SUPABASE_JWT_SECRET=...` was rejected because Supabase CLI reserves the `SUPABASE_` prefix for auto-provisioned secrets
- **Fix:** Used `JWT_SECRET` as the env var name; updated edge function code to read from `JWT_SECRET` instead
- **Files modified:** supabase/functions/auth-bridge/index.ts

**2. [Rule 3 - Blocking] Docker not running for edge function deployment**
- **Found during:** Task 1 deployment
- **Issue:** Supabase CLI requires Docker Desktop for bundling edge functions
- **Fix:** Started Docker Desktop and waited for it to be ready before retrying deployment
- **Impact:** Minor delay, no code changes needed

**3. [Rule 3 - Blocking] Anon key format incompatible with default JWT verification**
- **Found during:** Task 1 verification
- **Issue:** The project uses `sb_publishable_` format anon key which is rejected by Supabase's default JWT verification on edge functions
- **Fix:** Deployed with `--no-verify-jwt` flag; the function does its own Privy token verification anyway
- **Files modified:** None (deployment flag only)

---

**Total deviations:** 3 auto-fixed (all blocking), 0 deferred
**Impact on plan:** All fixes necessary for deployment. No scope creep.

## Issues Encountered

### PRIVY_APP_SECRET not available
- **Description:** The .env file does not contain `PRIVY_APP_SECRET`. The edge function currently uses JWKS-based token verification (which does not require the app secret) rather than Privy REST API verification. If JWKS verification proves insufficient in production, the app secret will need to be set via `supabase secrets set PRIVY_APP_SECRET=...`.
- **Impact:** None for current implementation (JWKS verification is the recommended approach)
- **Resolution:** Set the secret manually if REST API fallback is needed: `supabase secrets set PRIVY_APP_SECRET=<value> --project-ref ciwengqnkfkkanayoqgz`

### Pre-existing build failure in swift-clocks dependency
- **Description:** The xcodebuild full build fails due to "Unable to find module dependency: ConcurrencyExtras" in swift-clocks (transitive dep from Supabase Swift SDK). This is a pre-existing issue documented in 04-01-SUMMARY.md.
- **Impact:** Full xcodebuild does not succeed, but all project-level Swift files have no compilation errors. The error is in a transitive dependency, not in our code.
- **Resolution:** May require updating package versions or cleaning SPM cache in a future task.

## Next Phase Readiness

- Auth bridge deployed and responding (tested: returns 401 for invalid tokens as expected)
- PrivyManager provides Supabase token/userId for downstream plans
- AppState.supabaseClient ready for RLS-protected database operations in 04-04 (Data Persistence)
- user_profiles table will be populated on first real Privy login
- 04-04 can use `appState.supabaseClient?.from("habits")` pattern for CRUD operations
- 04-05 (Gemini Proxy + Real-time) can use the authenticated client for realtime subscriptions

---
*Phase: 04-backend-api*
*Completed: 2026-03-07*
