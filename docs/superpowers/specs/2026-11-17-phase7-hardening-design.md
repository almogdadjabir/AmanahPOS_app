# Phase 7 hardening - short design

Parent spec: 2026-11-16-offline-first-sync-design.md (Phase 7 row, perf budgets, BE_GAPS section 12).

## Intent
Close the real remaining gaps so the sync layer is safe to run unattended: bounded local growth, a defined revoke/disable policy, enforced perf budgets. Backoff (engine 2s..5min + jitter + Retry-After; assets 1min..24h) and revoke *detection* already exist and are out of scope except for review.

## Goals
1. **Prune `done` outbox rows.** `OutboxStore.pruneDone` exists but has no caller. Run it from the foreground `afterSyncCompleted` hook, throttled to once per 24 h (sync_state key, scoped, cleared with the scope). Keep window 7 days (existing default). Never touches open/rejected rows.
2. **Revoke / disable policy (user choice b).** On `deviceRevoked` / `accountDisabled`: if the scope has zero unsynced outbox rows (rejected counts as unsynced) -> `clearAllLocalOfflineData()` then forced logout. Otherwise keep all data, forced logout, and persist a "revoked with pending" marker (count + reason) that the login screen shows as a notice ("N unsynced items stay on this device, contact the owner"). `needsLogin` is unchanged (never wipes).
3. **Perf budgets enforced in tests** (spec): product list/search <16 ms on 20k products, sale save <50 ms, dashboard re-query <30 ms on 50k sales, cold start to POS <1 s with local data (measured as DB open + first POS product query). Median of several runs to avoid flake.
4. **Reliability pass.** Read-through of engine loop / lease expiry / backoff caps / crash points, fix only demonstrated bugs with a test.
5. **Phase 6 deferred minors** (small): `sales()` date filter in SQL, `maxSeq` default, audit hook before throttle check.

## Non-goals / anti-goals
- No DB version bump (stays v14). If a budget fails and needs an index, report it, do not migrate.
- No backend edits; BE needs go to docs/BE_GAPS.md.
- No export-to-file of unsynced rows (option c rejected). No deletion of local sales older than the 90-day window (checksum audit and history depend on them). No tombstone pruning (tombstones are deleted on pull already).
- A revoke must never lose an unsynced sale.

## Approaches
Only one sensible way for each item; considered and dropped: pruning on every sync (needless writes), pruning in the background isolate (adds a second writer), wiping regardless of pending rows (loses money).

## My calls (not yet confirmed by you)
- 24 h prune throttle, 7 day keep.
- Marker stored in sync/shared prefs rather than the DB (survives the wipe path, no schema change).
- Items 5 included because they are tiny; drop if you disagree.
- Budgets asserted at spec values on the dev machine; margin handled by median-of-N.

## Docs
Update docs/offline.md (remove the revoke "known limitation", add checklist item 19: revoke with/without pending), BE_GAPS only if a gap appears, memory file at the end.
