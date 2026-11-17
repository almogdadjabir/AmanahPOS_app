# Phase 6: Checksum Self-Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (inline, native). Steps use checkbox (`- [ ]`) syntax. NEVER run git (user commits; only `git add` if asked). Foreground tests only (full suite ~70 s, long timeout). Format only files you changed (never `dart format <dir>`). DB stays v14.

**Goal:** Detect drift between synced local sale/refund/stock rows and the server's `sync/checksum`, repair it with a targeted re-page, and tell the owner quietly if it persists; plus a debug-only dashboard parity log.

**Architecture:** Pure local-totals queries + a `ChecksumAudit` orchestrator (verdict logic, throttle, persisted state) + `ChecksumRepair` (re-pages sale/refund/stock through existing appliers, never touches the pull cursor/bootstrap progress). Engine calls the audit after a completed, idle sync cycle. Result persisted in `sync_state`; owner banner reads it.

**Tech Stack:** Flutter, sqflite (`OfflineDb`), existing `SyncTransport`/`FakeSyncServer`, `DbChangeNotifier`, l10n arb (en+ar).

**Spec:** `docs/superpowers/specs/2026-11-17-phase6-dashboard-checksum-design.md`. Contract: BE `docs/sync-contract.md` (`GET /sync/checksum/?entity=&since=<days>` → `{entity,count,sum_total,sum_revenue?,max_seq}`; strings for sums).

## Global Constraints
- Window N = 7 days; throttle 6 h per scope; edge tolerance 5 min; one repair attempt then re-audit once; no retry loop.
- Compare only `sync_state='synced'` rows. Never delete sale/refund rows. Money in integer cents (reuse `_cents` style from `local_dashboard_queries.dart`), stock in `Decimal3`.
- Capability `checksum` (from ping/`SyncStateStore.capabilities()`) required; absent = audit does nothing.
- Owner-only banner; cashiers see nothing. `flutter analyze` must stay at 73. No BE edits (gaps go in `docs/BE_GAPS.md`).
- Baseline: 1551 pass / 2 skip / 1 known fail (notification_permission_test LAN).

## Review Focus
1. Pending/rejected local sales (not on server) must never cause a mismatch (test: unsynced + rejected rows present → `match`).
2. Window edge: a synced row within 5 min of the cutoff → `inconclusive`, not mismatch/repair.
3. Server moved during the audit (second checksum call differs in `max_seq`) → `inconclusive`.
4. Repair with a local pending edit on the same row must skip that row (appliers' `skipWhenLocalPending`), and a persistent surplus local row yields `drift`, never a delete.
5. Scope switch / logout mid-audit must write nothing (assert scope before each write).

## File Structure
- Create `lib/core/sync/audit/local_checksum_queries.dart` — local totals.
- Create `lib/core/sync/audit/checksum_audit.dart` — verdicts, throttle, persisted state, orchestrates repair.
- Create `lib/core/sync/audit/checksum_repair.dart` — targeted re-page.
- Modify `lib/core/sync/transport/sync_transport.dart` + `http_sync_transport.dart` — `checksum()`.
- Modify `lib/core/sync/contract/sync_contract.dart` — `ChecksumResponse`.
- Modify `lib/core/sync/sync_state_store.dart` — audit state keys.
- Modify `lib/core/sync/sync_engine.dart` — `afterSyncCompleted` hook.
- Modify `lib/utilities/dependencies_provider.dart` — wiring.
- Modify `test/core/sync/support/fake_sync_server.dart` — checksum endpoint + drift injection.
- Create `lib/features/sync/presentation/widgets/data_drift_banner.dart`; modify Pending Sync screen + the Home screen widget that hosts the dashboard summary; `lib/l10n/app_en.arb`, `app_ar.arb` (+ regenerate l10n the same way prior phases did).
- Create `lib/features/dashboard/data/local/dashboard_parity.dart` (debug parity).
- Tests under `test/core/sync/audit/` and `test/features/sync/`.

---

### Task 1: Transport `checksum()` + contract + fake server

**Files:** `sync_contract.dart`, `sync_transport.dart`, `http_sync_transport.dart`, `fake_sync_server.dart`; tests `test/core/sync/audit/checksum_transport_test.dart`.

**Interfaces — Produces:**
- `class ChecksumResponse { final String entity; final int count; final String? sumTotal; final String? sumRevenue; final int maxSeq; static ChecksumResponse fromJson(Map<String,dynamic>); }` (sums are decimal strings; `max_seq` may arrive int or string → parse to int, default 0).
- `SyncTransport.checksum({required String entity, int sinceDays = 7, required String scope}) → Future<ChecksumResponse>`.
- `FakeSyncServer`: `checksum` computes from its own server rows (sale: count, Σ net_amount all statuses, Σ net_amount on completed/partial_refund/refunded; refund: Σ total; stock: Σ quantity; window = created_at ≥ now−sinceDays) and `int checksumCalls`; `void injectDrift(...)` is NOT needed: tests drift the **local** DB or drop rows from the fake's feed instead.

- [ ] **Step 1:** Write failing tests: `ChecksumResponse.fromJson` parses `{"entity":"sale","count":3,"sum_total":"150.00","sum_revenue":"100.00","max_seq":"42"}`; null `sum_total` for non-money entities; `HttpSyncTransport.checksum` hits `GET sync/checksum/` with `entity` and `since` query params and the same scope check/auth as `pull` (mirror the existing `http_sync_transport_test.dart` pattern); fake returns server totals after seeded sales.
- [ ] **Step 2:** Run `flutter test test/core/sync/audit/checksum_transport_test.dart` → FAIL (symbols missing).
- [ ] **Step 3:** Implement per Interfaces; copy the scope-refusal and error mapping of `HttpSyncTransport.pull` exactly.
- [ ] **Step 4:** Run the test → PASS; `flutter test test/core/sync/http_sync_transport_test.dart test/core/sync/fake_sync_server_test.dart` still pass.

### Task 2: Local checksum queries

**Files:** `lib/core/sync/audit/local_checksum_queries.dart`; test `test/core/sync/audit/local_checksum_queries_test.dart`.

**Interfaces — Produces:**
```dart
class LocalChecksum { final int count; final String sumTotal; final String? sumRevenue;
  final bool nearEdge; /* a synced row within edgeTolerance of cutoff */ }
class LocalChecksumQueries {
  LocalChecksumQueries(OfflineDb db);
  Future<LocalChecksum> sales({required DateTime cutoff, Duration edgeTolerance = const Duration(minutes: 5)});
  Future<LocalChecksum> refunds({required DateTime cutoff, Duration edgeTolerance = const Duration(minutes: 5)});
  Future<LocalChecksum> stock();
}
```
Sums formatted as 2-decimal strings (sale/refund, from integer cents) and `Decimal3.format` (stock), so they compare as numbers, not text.

- [ ] **Step 1:** Failing tests: (a) sales: 3 synced in window (one `cancelled`), 1 `pending` sync_state, 1 `rejected`, 1 synced before cutoff → count 3, `sumTotal` = Σ net_amount of the 3, `sumRevenue` excludes `cancelled`; (b) window uses `received_at`, falling back to `occurred_at` when null; (c) `nearEdge` true when a synced row is 2 min after cutoff, false at 1 h; (d) refunds: row counts when its own `occurred_at` OR its sale's timestamp is in window, `sync_state` `synced` only (`sale_refunds` has `sync_state`; check column in `offline_db.dart`/`RefundService`); (e) stock sums `base_quantity` of all rows (e.g. `0.333` + `0.667` = `1.000`, exact, no float drift); (f) 0.1+0.2 style cents case exact.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement with `rawQuery`, rounding each row to integer cents then summing (same technique as `_cents` in `local_dashboard_queries.dart`, import or mirror it); timestamps compared as UTC ISO text like the dashboard queries do.
- [ ] **Step 4:** Run → PASS.

### Task 3: Audit state persistence

**Files:** `sync_state_store.dart`; test added to `test/core/sync/sync_state_store_test.dart`.

**Interfaces — Produces on `SyncStateStore`:**
`Future<DateTime?> lastAuditAt()`, `Future<void> setLastAuditAt(DateTime)`, `Future<AuditState?> auditState()`, `Future<void> setAuditState(AuditState?)` (scope-keyed via `_k`, cleared by `clear()`), where
`class AuditState { final String status; /* 'ok' | 'drift' */ final DateTime at; final Map<String,dynamic> detail; toJson/tryFromJson }`.

- [ ] **Step 1:** Failing tests: round-trip; scope isolation (scope A drift invisible to scope B); `clear()` removes both keys; corrupt JSON → null (never throws).
- [ ] **Step 2–4:** Run FAIL → implement (mirror `deviceRegistration` get/put style, keys `audit_last_at`, `audit_state`) → PASS. Notify `SyncTables.syncState` on write so the banner stream updates.

### Task 4: ChecksumRepair

**Files:** `lib/core/sync/audit/checksum_repair.dart`; test `test/core/sync/audit/checksum_repair_test.dart`.

**Interfaces:**
- Consumes: `SyncTransport.bootstrapManifest/bootstrapPage`, `ChangeApplierRegistry.of(entity)`, `PullChange`, `hasLocalPendingOutbox`, `DbChangeNotifier`, `AuthedCall`.
- Produces: `ChecksumRepair({required OfflineDb db, required SyncTransport transport, required ChangeApplierRegistry appliers, required DbChangeNotifier notifier, required AuthedCall Function(String scope) authedFor, required Future<void> Function() assertScope, int pageSize = 200})` and
  `Future<int> repair({required String scope, List<String> entities = const ['sale','refund','stock'], int salesSinceDays = 7})` → rows applied.

- [ ] **Step 1:** Failing tests with `FakeSyncServer`: (a) a sale present on the server but missing locally is inserted; (b) a row with local version ≥ server is left alone; (c) a row with a pending outbox edit is skipped (`skipWhenLocalPending`); (d) pull cursor, `bootstrapProgress` and `bootstrapped` flag are byte-identical before/after; (e) scope changes mid-run (`assertScope` throws) → page rolled back, nothing partial; (f) multi-page (pageSize 2, 5 rows) pages through `next_page_cursor`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement: one fresh `bootstrapManifest` for `snapshot_cursor`; per entity loop `bootstrapPage(entity, pageCursor, limit, snapshotCursor, salesSinceDays, scope)`; per page ONE transaction doing, per item, the same version guard + deferral-skip + `applier.apply` as `Bootstrapper._commitPage` (lines ~455-550) but with no progress/deferred-pull writes (skipped pending rows are simply left to normal pull); `assertScope()` inside the txn; notify touched tables after commit; cap pages per entity at 20000 like Bootstrapper.
- [ ] **Step 4:** Run → PASS.

### Task 5: ChecksumAudit

**Files:** `lib/core/sync/audit/checksum_audit.dart`; test `test/core/sync/audit/checksum_audit_test.dart`.

**Interfaces:**
- Consumes: Task 1 `checksum()`, Task 2 queries, Task 3 state, Task 4 `repair`, `SyncOutcome`-free; `Future<bool> Function() idle` (outbox empty for scope & engine not running), `Future<Set<String>> Function() capabilities`, `String? Function() scopeProvider`, `DateTime Function() now`.
- Produces:
```dart
enum AuditVerdict { match, inconclusive, mismatch }
enum AuditRun { skipped, ok, repaired, drift, inconclusive }
class ChecksumAudit {
  ChecksumAudit({...});
  static const Duration minInterval = Duration(hours: 6);
  static const int windowDays = 7;
  Future<AuditRun> maybeRun({bool force = false});   // throttle + preconditions, never throws
  Future<AuditVerdict> verdict();                    // one pass over sale, refund, stock
}
```
`verdict()`: for each entity fetch server checksum, compute local with `cutoff = now−7d` (one `now` captured before both), compare `count` and sums numerically (sale: `sum_total` and `sum_revenue`; refund `sum_total`; stock `sum_total`); `nearEdge` ⇒ inconclusive; re-fetch the server checksum after the local read and if `max_seq` changed ⇒ inconclusive.
`maybeRun`: skipped if no `checksum` capability, no scope, not idle, or (not force and within `minInterval` of `lastAuditAt`); `match` ⇒ state `ok`; `mismatch` ⇒ `repair` then `verdict()` once more: `match` ⇒ `repaired` (state `ok`), `mismatch` ⇒ state `drift` with `detail` `{entity: {localCount, serverCount, localSum, serverSum}}`, `inconclusive` ⇒ no state change and `lastAuditAt` NOT set (retry next cycle). Transport/auth errors ⇒ `skipped`, lastAuditAt unchanged.

- [ ] **Step 1:** Failing tests (fake server + real in-memory DB): match → `ok`, state ok, throttled second call `skipped`; `force` bypasses throttle; unsynced+rejected local rows → still `match` (Review Focus 1); edge row → `inconclusive`, no repair call, lastAuditAt unset (2); server write between the two checksum calls → `inconclusive` (3); server has an extra sale → `mismatch` → repair inserts → `repaired`; persistent mismatch (local surplus synced sale) → `drift` with detail, local row NOT deleted (4); not idle → `skipped`; missing capability → `skipped`; scope null/changed → nothing written (5); transport error → `skipped`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement per Interfaces; call `repair` at most once per `maybeRun`; wrap whole body in try/catch reporting like `SyncEngine._report`.
- [ ] **Step 4:** Run → PASS.

### Task 6: Engine hook + DI

**Files:** `sync_engine.dart`, `dependencies_provider.dart`; tests `test/core/sync/audit/engine_audit_hook_test.dart`.

**Interfaces:** `SyncEngine` gains optional ctor param `Future<void> Function()? afterSyncCompleted`, invoked (fire-and-forget, errors reported) at the end of `syncNow` ONLY when the final outcome is `completed`, `moreToPull` is false, and after `_running = false`. DI registers `LocalChecksumQueries`, `ChecksumRepair`, `ChecksumAudit` (idle = `!engine running` and `OutboxStore` has no open rows for `SyncScope.current`), and passes `afterSyncCompleted: () => audit.maybeRun()`. Background worker isolate must NOT run the audit (foreground only), so the hook is wired in the foreground DI path only.

- [ ] **Step 1:** Failing tests: hook fires once after a completed no-more-to-pull sync; not on `backoff`/`blocked`/`needsBootstrap`/`cancelled`; not when `moreToPull`; a throwing hook doesn't change the outcome; hook runs after the engine is idle (calling `syncNow` from inside the hook does not return `alreadyRunning`).
- [ ] **Step 2–4:** FAIL → implement → PASS. Run `flutter test test/core/sync/sync_engine_test.dart test/core/sync/sync_di_test.dart` for regressions.

### Task 7: Owner banner (UI + strings)

**Files:** `data_drift_banner.dart`, Pending Sync screen, the Home widget hosting the dashboard summary, `app_en.arb`, `app_ar.arb`, regenerated l10n; test `test/features/sync/data_drift_banner_test.dart`.

**Interfaces:** `DataDriftBanner` (stateless view over an `AuditState?` + `isOwner`): renders nothing unless `isOwner && status=='drift'`. Keys: `shDataDriftTitle`, `shDataDriftBody`. EN title "Some numbers may be off"; body "This phone's totals do not match the server. Tap Sync now; if it stays, contact support." AR equivalents (follow the tone of existing `sh*` Arabic keys). Owner check = the same check the Team screen uses. A small bloc/stream reads `SyncStateStore.auditState()` on `DbChangeNotifier` `syncState` events (pattern: Pending Sync bloc).

- [ ] **Step 1:** Failing widget tests: owner + drift → banner visible; owner + ok/null → nothing; cashier + drift → nothing; Arabic locale renders the Arabic title.
- [ ] **Step 2–4:** FAIL → implement banner, mount it at the top of the Pending Sync screen and above the dashboard summary on Home → PASS. Run `flutter gen-l10n` the same way earlier phases did.

### Task 8: Debug parity check

**Files:** `lib/features/dashboard/data/local/dashboard_parity.dart`; test `test/features/dashboard/dashboard_parity_test.dart`.

**Interfaces:** `class DashboardParity { Future<List<String>> diff({required DashboardSummary local, required DashboardSummary remote}); }` comparing gross, count, cash, bankak, refunds total (cents), returning human lines; `ChecksumAudit` optional ctor param `Future<void> Function()? debugParity` called after `maybeRun` only under `kDebugMode`, logging each diff line via `developer.log(name: 'DashboardParity')`. Never throws, never shown in release.

- [ ] **Step 1:** Failing tests: identical summaries → empty list; gross differs by 1 cent → one line naming `gross`; unsynced-today local summary yields a line tagged "unsynced rows present" instead of an error.
- [ ] **Step 2–4:** FAIL → implement (wire in DI with `localQueries.summaryFor` vs `DashboardRemoteDataSource`) → PASS.

### Task 9: Convergence + docs + full verification

**Files:** `test/core/sync/audit/audit_convergence_test.dart`; `docs/BE_GAPS.md`, `docs/offline.md`.

- [ ] **Step 1:** Test (seeded, reuse `convergence_test.dart` harness, `CONV_SEEDS` env, default 20, run 200 once): random sales/refunds/stock + random local drift (delete a synced sale row / bump a server sale / drop a refund) → after `maybeRun(force:true)` state is `ok` for repairable drift (missing rows) and `drift` for unrepairable (local surplus), never a deleted money row, never an exception.
- [ ] **Step 2:** Add to `docs/BE_GAPS.md` (consolidated list, "Nice to have"): checksum window boundary uses server `created_at` vs local `received_at`; ask BE to include `max_seq` as int and document `since` as days; sum_total basis `net_amount` vs dashboard `total_amount` cross-ref item 3. Add on-device item 18 to `docs/offline.md`: force a drift (airplane mode, delete a sale server-side) and confirm repair/banner.
- [ ] **Step 3:** Run, foreground, long timeout: `CONV_SEEDS=200 flutter test test/core/sync/audit/audit_convergence_test.dart`, then the full `flutter test` (expect baseline + new, only the 1 known fail), `flutter analyze` (≤ 73). `dart format` only files created/changed in this plan.
- [ ] **Step 4:** Run ONE `/code-review`, fix only real findings, update memory `offline-first-sync.md` (Phase 6 done, state keys, banner, caveats: repair never rolls back equal/higher local versions; surplus local synced rows only reported).
