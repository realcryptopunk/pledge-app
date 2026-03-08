---
phase: 04-backend-api
plan: 01
subsystem: database
tags: [supabase, postgres, rls, migration, ios-client]

requires:
  - phase: 03-02
    provides: EnvConfig with ProcessInfo pattern for credentials, Privy auth system
provides:
  - Supabase CLI initialized and linked to remote project (ciwengqnkfkkanayoqgz)
  - Full database schema with 6 tables, indexes, RLS policies, leaderboard view
  - SupabaseConfig.swift wired to EnvConfig (no hardcoded placeholders)
affects: [04-02, 04-03, 04-04, 04-05, 04-06]

tech-stack:
  added: [Supabase CLI v2.20.12, Supabase Postgres]
  patterns: [SQL migration files in supabase/migrations/, RLS per-user policies using auth.uid()]

key-files:
  created: [supabase/config.toml, supabase/migrations/00001_initial_schema.sql]
  modified: [Core/SupabaseConfig.swift]

key-decisions:
  - "Keep SUPABASE_SERVICE_ROLE_KEY and SUPABASE_JWT_SECRET out of iOS app EnvConfig - server-side only"
  - "Use auth.uid() = id pattern for user_profiles RLS (assumes Supabase auth.uid maps to user profile id)"
  - "Leaderboard as regular VIEW not materialized view (simpler, sufficient for current scale)"

patterns-established:
  - "SQL migrations in supabase/migrations/ with sequential numbering"
  - "RLS policies: owner-only for mutations, authenticated read for social/public data"
  - "updated_at trigger function shared across tables"

issues-created: []

duration: ~20min
completed: 2026-03-07
---

# Phase 4 Plan 1: Supabase Foundation + Database Schema Summary

**Supabase CLI linked to remote project, 6-table Postgres schema with RLS policies, and SupabaseConfig wired to EnvConfig credentials**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-03-07T10:40:00Z
- **Completed:** 2026-03-07T11:00:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Supabase CLI initialized and linked to remote project (ref: ciwengqnkfkkanayoqgz)
- Complete database schema: user_profiles, habits, habit_logs, deposits, transactions, friendships
- RLS enabled on all 6 tables with per-user policies, leaderboard view, updated_at triggers, 8 indexes
- SupabaseConfig.swift now reads real credentials from EnvConfig (ProcessInfo env vars)

## Task Commits

Each task was committed atomically:

1. **Task 1: Initialize Supabase CLI and link project** - `74aa179` (feat)
2. **Task 2: Create database schema migration with RLS** - `831daee` (feat)
3. **Task 3: Configure SupabaseConfig.swift with real credentials** - `21eed0f` (feat)

## Files Created/Modified
- `supabase/config.toml` - Supabase local config, linked to project ciwengqnkfkkanayoqgz
- `supabase/.gitignore` - Ignores local Supabase temp files
- `supabase/migrations/00001_initial_schema.sql` - Full schema: 6 tables, indexes, RLS, view, triggers
- `Core/SupabaseConfig.swift` - Wired to EnvConfig.supabaseURL and EnvConfig.supabaseAnonKey

## Decisions Made
- Kept service role key and JWT secret out of iOS EnvConfig (server-side only, already in .env.example)
- Used regular VIEW for leaderboard instead of materialized view (simpler for current scale)
- RLS user_profiles has two SELECT policies: own-profile full access + authenticated public profiles for social

## Deviations from Plan

None - plan executed as written with one expected auth gate.

## Issues Encountered

### AUTH GATE: Database password required for `supabase db push`

- **Description:** `supabase db push` requires the Postgres database password to connect to the remote database. The password was not available in environment variables or the .env file.
- **Impact:** Migration file is created and committed but NOT yet applied to the remote database.
- **Resolution required:** User needs to either:
  1. Run `supabase db push -p <database_password>` with their Supabase database password
  2. Or apply the SQL manually via the Supabase Dashboard SQL Editor (Project Settings > SQL Editor > paste contents of `supabase/migrations/00001_initial_schema.sql`)
- **Note:** The database password can be found/reset at: https://supabase.com/dashboard/project/ciwengqnkfkkanayoqgz/settings/database

### Pre-existing build failure in swift-clocks dependency

- **Description:** `xcodebuild` fails with "Unable to find module dependency: ConcurrencyExtras" in swift-clocks (transitive dep from Supabase Swift SDK). This is a pre-existing issue unrelated to our changes.
- **Impact:** Full build does not succeed, but all project-level Swift files compile without errors. No SupabaseConfig-related compilation issues.
- **Resolution:** May require updating package versions or cleaning SPM cache in a future task.

## Next Phase Readiness
- Database schema is ready; migration needs to be applied (see auth gate above)
- SupabaseConfig.swift compiles and is ready for use by 04-02 (Coinbase session token edge function)
- 04-03 (Auth Bridge) can proceed with user_profiles table structure
- 04-04 (Data Persistence) can proceed with habits/habit_logs table structure

---
*Phase: 04-backend-api*
*Completed: 2026-03-07*
