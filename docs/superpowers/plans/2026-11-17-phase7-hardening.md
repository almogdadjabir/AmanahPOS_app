# Phase 7 Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline, native). Steps use checkbox syntax.

**Goal:** Bound local sync growth (prune done outbox rows), define revoke/disable behaviour (wipe only when nothing is unsynced), enforce the spec perf budgets, and close the Phase 6 minors.

**Architecture:** A small `SyncMaintenance` runs from the existing foreground `engine.afterSyncCompleted` hook (DI `_startSyncCore`). A `RevokeSessionPolicy` replaces the bare `AppInterceptors.forceLogout` passed as `onSessionEnded`. Both persist their small state in `sync_state` (no schema change).

**Tech Stack:** Flutter, sqflite (ffi in tests), get_it, flutter_test.

**Spec:** docs/superpowers/specs/2026-11-17-phase7-hardening-design.md (parent: 2026-11-16-offline-first-sync-design.md)

## Global Constraints
- DB stays v14. No v15. No migration, no new index (report a failing budget instead).
- Never run git except read-only `git diff`/`git status`. Replace every "Commit" step with nothing; I do not commit.
- Never edit the BE repo. BE needs go in docs/BE_GAPS.md.
- Foreground tests only. Targeted file runs while building; the full suite once at the end with a long timeout and `CONV_SEEDS=200`, output to the scratchpad.
- `dart format` only on the individual files changed, never a directory.
- Baseline to keep: full suite 1930 pass / 2 skip / 1 known fail (notification_permission_test "release builds never default to a LAN address"); `flutter analyze` stays at 73 (must not grow).
- Never delete an unsynced (open or rejected) outbox row. A revoke must never lose an unsynced sale.
- environment.dart is the user's; do not touch.

## Review Focus
- Outbox holds only `rejected` rows at revoke time: counts as unsynced, no wipe (test in Task 2).
- Revoke arrives with `SyncScope.current == null`: keep data, still log out, no wipe, no crash (Task 2).
- Wipe throws midway: still force logout, marker not written as "wiped" (Task 2).
- Prune on a scope with zero done rows, and with a clock set backwards (last-run in the future): must not throw nor starve forever (Task 1).
- Second revoke event after a marker exists: marker is replaced, not duplicated (Task 2).

## File Structure
- Create `lib/core/sync/maintenance/sync_maintenance.dart`: prune throttle + run.
- Create `lib/core/sync/revoke_session_policy.dart`: decide wipe vs keep, write marker, logout.
- Modify `lib/core/sync/sync_state_store.dart`: prune key, `RevokeMarker`, marker accessors.
- Modify `lib/utilities/dependencies_provider.dart` (~837 and ~909): wiring.
- Modify `lib/features/login/presentation/login_screen.dart` + l10n arb (en, ar): notice.
- Create tests under `test/core/sync/` and `test/core/perf/`.
- Modify `lib/core/sync/audit/local_checksum_queries.dart`, `checksum_audit.dart` (Task 4).
- Docs: `docs/offline.md`, memory file.

---

### Task 1: Outbox prune maintenance

**Files:**
- Create: `lib/core/sync/maintenance/sync_maintenance.dart`
- Modify: `lib/core/sync/sync_state_store.dart` (scoped key `prune_last_at`, added to `clear()`, whose `IN (?,...)` list grows by one placeholder)
- Modify: `lib/utilities/dependencies_provider.dart` (`_startSyncCore`)
- Test: `test/core/sync/sync_maintenance_test.dart`

**Interfaces:**
- Produces: `SyncStateStore.lastPruneAt() -> Future<DateTime?>`, `setLastPruneAt(DateTime)`.
- Produces: `class SyncMaintenance({required OutboxStore outbox, required SyncStateStore state, required String? Function() scopeProvider, DateTime Function()? now})` with `static const Duration interval = Duration(hours: 24)`, `static const Duration keepDone = Duration(days: 7)`, `Future<int> maybeRun()` returning rows pruned (0 when skipped).
- Consumes: `OutboxStore.pruneDone({Duration keep})`; `state.forScope(scope)`.

- [ ] **Step 1: Failing tests** (use `openTestDb()` and the enqueue/mark-done helpers as `outbox_store_test.dart` does): 
  - `prunes done rows older than 7 days, keeps younger done, open and rejected`
  - `second run within 24h prunes nothing` (assert deleted-count 0 and a done row aged 8d added after the first run survives)
  - `runs again after 24h`
  - `last run in the future (clock moved back) runs anyway` (set lastPruneAt = now + 3 days; expect it prunes)
  - `no scope -> returns 0 and writes nothing`
  - `clear() removes prune_last_at`
- [ ] **Step 2: Run** `flutter test test/core/sync/sync_maintenance_test.dart`; expect FAIL (missing symbols).
- [ ] **Step 3: Implement** the store accessors (mirror `lastAuditAt`/`setLastAuditAt`) and `SyncMaintenance.maybeRun`: skip when `last != null && now >= last && now - last < interval`; otherwise `pruneDone(keep: keepDone)` then `setLastPruneAt(now)`. Never throws (catch, `developer.log`, return 0).
- [ ] **Step 4: Wire** in `_startSyncCore`: build `SyncMaintenance` from `getIt<OutboxStore>()`, `getIt<SyncStateStore>()`, `() => SyncScope.current`; the hook becomes `await audit.maybeRun(); await maintenance.maybeRun();` (each independently guarded so one failure does not skip the other).
- [ ] **Step 5: Run** the new test plus `sync_state_store_test.dart` and `sync_di_test.dart`; expect PASS.

### Task 2: Revoke / disable policy

**Files:**
- Create: `lib/core/sync/revoke_session_policy.dart`
- Modify: `lib/core/sync/sync_state_store.dart` (global key `revoke_marker`, NOT removed by `clear()` and not by `OfflineDb.clearAllLocalOfflineData`)
- Modify: `lib/utilities/dependencies_provider.dart` (`onSessionEnded` at ~837; completed-sync hook clears the marker)
- Modify: `lib/features/login/presentation/login_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` (+ regenerate l10n the way the repo does)
- Modify: `lib/core/sync/sync_coordinator.dart` (replace the "known limitation" comment at ~205 with a pointer to the policy)
- Test: `test/core/sync/revoke_session_policy_test.dart`

**Interfaces:**
- Produces: `class RevokeMarker { final SyncSessionEvent reason; final int pendingCount; final DateTime at; toJson/tryFromJson }`; `SyncStateStore.revokeMarker() -> Future<RevokeMarker?>`, `setRevokeMarker(RevokeMarker?)` (unscoped store, global key, null deletes).
- Produces: `class RevokeSessionPolicy({required OutboxStore outbox, required SyncStateStore state, required Future<void> Function() wipe, required Future<void> Function() logout, required String? Function() scopeProvider, DateTime Function()? now})` with `Future<void> handle(SyncSessionEvent e)`.
- Rules for `handle`: `needsLogin` -> `logout()` only. `accountDisabled`/`deviceRevoked`: `n = scope == null ? -1 : await outbox.unsyncedCount(scope: scope)`; if `n == 0` -> `wipe()` (catch + log on error) then `logout()`; else (n > 0, or n == -1 treated as keep) -> `setRevokeMarker(RevokeMarker(reason, max(n,0), now))` then `logout()`. `logout()` always runs, even if wipe or marker write throws.
- Consumes: `OutboxStore.unsyncedCount({String? scope})` (rejected included); `SyncSessionEvent`.

- [ ] **Step 1: Failing tests** (fakes for wipe/logout recording call order):
  - `deviceRevoked with empty outbox wipes then logs out`
  - `accountDisabled with an open row keeps data, writes marker(count=1), logs out, never wipes`
  - `only a rejected row counts as unsynced: no wipe` (Review Focus)
  - `null scope keeps data, no marker count crash, logs out` (Review Focus)
  - `wipe throws -> logout still called, no marker` (Review Focus)
  - `second event replaces the marker` (Review Focus)
  - `needsLogin never wipes and never writes a marker`
  - `marker survives OfflineDb.clearAllLocalOfflineData and SyncStateStore.clear()`
  - store test: `RevokeMarker` json roundtrip, garbage value reads as null.
- [ ] **Step 2: Run** the file; expect FAIL.
- [ ] **Step 3: Implement** marker (+store accessors) and policy per the rules above.
- [ ] **Step 4: Wire** DI: `onSessionEnded: RevokeSessionPolicy(outbox: getIt<OutboxStore>(), state: getIt<SyncStateStore>(), wipe: getIt<OfflineDb>().clearAllLocalOfflineData, logout: AppInterceptors.forceLogout, scopeProvider: () => SyncScope.current).handle`. In the completed-sync hook (Task 1's) add `state.setRevokeMarker(null)` (a completed sync proves the device is not revoked); guarded like the others.
- [ ] **Step 5: Login notice.** `login_screen.dart` reads `revokeMarker()` once on init and shows a danger-style notice when non-null, using the same notice widget style already used in that screen (reuse the existing component; find it in the file). Keys: `loginRevokedPendingTitle`, `loginRevokedPendingBody(int count)` in en + ar (Arabic must be real Arabic, plural-safe wording). Widget test: marker present -> notice text with the count; absent -> no notice.
- [ ] **Step 6: Run** the new tests, `sync_coordinator_test.dart`, `sync_session_guard_test.dart`, `sync_di_test.dart`, the login widget test; expect PASS.

### Task 3: Perf budgets as tests

**Files:**
- Create: `test/core/perf/perf_budgets_test.dart`
- Modify (only if a budget needs it, otherwise report): the owning query code

**Interfaces:** consumes the existing POS product list/search store used by the POS screen, `SaleService.createSale` (as in `test/features/pos/sale_crash_test.dart`), and the dashboard queries (as in `local_dashboard_queries_test.dart`). Find the real entry points there; do not invent new ones.

- [ ] **Step 1: Write the tests**, each asserting the median of 9 timed runs after one warm-up, printing the median:
  - `product list first page on 20k products < 16 ms`
  - `product search on 20k products < 16 ms` (a prefix term and a mid-string term)
  - `sale save < 50 ms` on a FILE db with `synchronous=FULL` (same fixture as `sale_crash_test.dart`; the existing test only asserts 100 ms)
  - `dashboard re-query on 50k sales < 30 ms` (seed like the existing 20k test; keep the existing 100 ms/20k test)
  - `cold start to first POS query < 1 s`: open a file DB already holding 20k products + 5k sales through `OfflineDb.database`, then run the first POS list query; measure open + query.
- [ ] **Step 2: Run** `flutter test test/core/perf/perf_budgets_test.dart`; record the measured medians.
- [ ] **Step 3: For each miss**, first try a query-level fix with no schema change (select fewer columns, LIMIT, avoid per-row work). If it needs an index or a v15 change, mark the test `skip:` with a one-line reason, and add it to the final report and docs/offline.md "Known limitations". Do not bump the DB version.
- [ ] **Step 4: Re-run** the file; expect PASS (or documented skips only).

### Task 4: Phase 6 deferred minors

**Files:**
- Modify: `lib/core/sync/audit/local_checksum_queries.dart` (`sales`, ~line 50), `lib/core/sync/audit/checksum_audit.dart` (~line 179 and the hook entry), `test/core/sync/audit/*`

- [ ] **Step 1: Failing tests** in the existing audit tests:
  - `sales() filters by cutoff in SQL`: same results as now; add a row with a null/unparseable ts and a row on each side of the cutoff and the edge tolerance; behaviour must be unchanged (edge flag still set, unparseable skipped).
  - `missing maxSeq on either side does not prove "unchanged"`: when before or after `maxSeq` is absent, the moved-during-audit guard treats the audit as inconclusive (today it defaults to 0 and can match falsely).
  - `maybeRun checks the throttle before doing any work`: with a fresh `lastAuditAt`, no transport/local query is made.
- [ ] **Step 2: Run** them; expect FAIL where behaviour changes.
- [ ] **Step 3: Implement:** SQL `WHERE sync_state='synced' AND COALESCE(received_at, occurred_at) >= ?` using `cutoff - edgeTolerance` as the SQL lower bound (rows inside the tolerance still need the Dart edge/cutoff check, so keep the Dart check for rows between `cutoff - tolerance` and `cutoff + tolerance`); make `maxSeq` nullable in the comparison; move the throttle check to the top of `maybeRun`.
- [ ] **Step 4: Run** `flutter test test/core/sync/audit/`; expect PASS.

### Task 5: Reliability pass, docs, full verification

**Files:** `lib/core/sync/sync_engine.dart` (read), `docs/offline.md`, memory file.

- [ ] **Step 1: Read-through** of `sync_engine.dart` (run loop, `_rowDelay`, lease/claim expiry at the `claimLease`/`lockTtl` constants, `_releaseClaimed`, the resync-loop window at ~289) and `outbox_store.dart` claim/lease SQL, looking only for: a claimed row whose lease can never expire, a backoff that can exceed the 5 min cap through `Retry-After` unboundedly (a server-sent absurd value), a retry delay that never resets after success. For each real bug: failing test first, minimal fix. If none, say so in the report. No speculative refactors.
- [ ] **Step 2: Docs:** in `docs/offline.md` remove the revoke "known limitation", describe the policy and the prune, add checklist item 19 (revoke with pending rows keeps data + login notice; revoke with empty outbox wipes) and item 20 (done outbox rows older than 7 days disappear after a sync).
- [ ] **Step 3: Verify:** `flutter analyze` (must be 73), then the full suite once: `CONV_SEEDS=200 flutter test > <scratchpad>/full.txt 2>&1` with a 600000 ms timeout; expect 1930+new pass / 2 skip / 1 known fail.
- [ ] **Step 4: One `/code-review`**, fix only real findings.
- [ ] **Step 5: Update memory** `offline-first-sync.md` (Phase 7 done: files, rules, numbers measured, what stayed open) and the MEMORY.md index line.
