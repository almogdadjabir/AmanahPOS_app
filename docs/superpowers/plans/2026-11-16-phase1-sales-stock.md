# Phase 1: Sales and Stock on the Sync Core — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A sale and a stock edit work 100% offline: written to local SQLite plus the outbox in one transaction, visible on the dashboard and history the same second, pushed in the background to the live BE with no loss and no double count. The legacy `pending_*` queues and `SyncManager` are removed.

**Architecture:** Phase 0 core (`lib/core/sync/`) is reused unchanged except three hard-gate fixes (Tasks 1-3) and one engine tweak (Task 4). New feature code writes only through `LocalWriter`. Local `sales`/`sale_items`/`sale_payments` tables are authoritative for the UI. Local `stock.quantity` = server base + sum of this device's not-yet-done signed deltas. Reads are reactive via `DbChangeNotifier.watch`.

**Tech Stack:** Flutter, sqflite (+ `sqflite_common_ffi` in tests), existing Dio, `workmanager` (Android) / `BGTaskScheduler` (iOS) for the background worker, `FakeSyncServer` for tests.

**Spec:** `docs/superpowers/specs/2026-11-16-offline-first-sync-design.md`. Wire contract: `docs/BE_GAPS.md` plus the live BE docs `/Users/almogdadjabir/Documents/projects/amana/amanaPOS-be/docs/sync-contract.md` and `sync-contract-deviations.md` (read-only; never edit the BE).

## Global Constraints

- Git: agents never run `git commit`, `git push` or any git command except `git add` when the user asks. Do not commit; leave changes in the working tree. (Skill steps that say "Commit" are replaced by "stage nothing, report files changed".)
- Never edit the BE repo.
- Run tests in the FOREGROUND only (a background test once hung an agent 25 minutes). Command: `flutter test <path>`; whole sync suite: `flutter test test/core/sync test/features`.
- Money/quantity/decimal values travel as strings; compute with integer minor units or `BigInt`-safe decimal strings, never `double` accumulation, for anything persisted or sent.
- Pulled `stock` changes: re-base local stock from `stock_after` ONLY when push status is `applied`, never on `duplicate`.
- Outbox claims, cursor and `deferred_pull` are scoped by `tenant_id|user_id` after Task 1; the engine never touches another scope's rows.
- A sale is never refused locally for stock reasons (negative stock allowed). Payments must sum to net (±0.01) or the BE rejects with `validation_error`, so local validation enforces it before enqueue.
- The engine never logs out. Only an explicit session guard event may.
- All new SQL goes through `OfflineDb`'s database inside `LocalWriter.write` for writes; no nested `write`.
- Every task ends with `flutter analyze <touched files>` clean (no new infos) and its tests green.

## Review Focus

Failure modes the spec implies but no feature task would test by default:

1. Process killed between "sale row written" and "UI confirms": relaunch shows exactly one sale, one outbox row, stock decremented once (Task 6 crash-injection test).
2. Server answers `duplicate` to a replayed sale after the response was lost: local stock must NOT be re-based (Task 5 test).
3. User A logs out with unsynced sales, user B logs in on the same phone: A's sales never push under B's token; B's first sync still bootstraps (Task 1 tests).
4. Device clock wrong by days: sale `occurred_at` and dashboard "today" still agree locally; engine skew handling not used for local day boundaries (Task 8 test).
5. A product edited/deleted on another device while a local sale references it: the local sale line keeps its snapshot and the sale still syncs (Task 6 test).

---

### Task 1: Scope outbox and cursor by tenant+user (gate P1-0a)

**Files:**
- Modify: `lib/core/sync/sync_schema.dart`, `lib/core/sync/outbox/outbox_store.dart`, `lib/core/sync/outbox/outbox_entry.dart`, `lib/core/sync/sync_state_store.dart`, `lib/core/sync/sync_engine.dart`, `lib/core/sync/sync_coordinator.dart`, `lib/core/offline/offline_db.dart`
- Test: `test/core/sync/scope_test.dart`

**Interfaces:**
- Consumes: `SyncSession.key` (`'$userId|$tenantId'`) from `sync_coordinator.dart`.
- Produces: outbox column `scope TEXT NOT NULL`; `OutboxStore.enqueue(..., required String scope)`; `OutboxStore.claimBatch(..., required String scope)` and `unsyncedCount({String? scope})`; `SyncStateStore` keys `cursor`, `deferred_pull`, `repair_needed` stored per scope (`SyncStateStore.forScope(String scope)` returns a scoped view; `device_id` and `sync_lock` stay global); `SyncEngine` takes `scopeProvider: String? Function()` and returns `SyncOutcome.blocked` (reason `noSession`) when null. `LocalWriter` callers obtain the scope from a new `SyncScope` singleton: `String? get current` set by the coordinator.
- DB version 7: `onUpgrade` for `oldVersion < 7` runs `ALTER TABLE outbox ADD COLUMN scope TEXT NOT NULL DEFAULT ''`; fresh `createAll` includes it; index `(scope,status,seq)`.

- [ ] **Step 1:** Write failing tests in `scope_test.dart`: (a) rows enqueued under scope `A|t1` are not returned by `claimBatch(scope:'B|t1')`; (b) cursor set under `A|t1` is null under `B|t1`; (c) engine with scopeProvider returning `B|t1` and a backlog from `A|t1` pushes nothing and leaves A's rows `pending`; (d) after switching back to `A|t1` the rows push; (e) coordinator logout keeps A's outbox rows and `SyncStateStore.clear` only clears the scoped keys of a scope whose outbox is empty.
- [ ] **Step 2:** Run `flutter test test/core/sync/scope_test.dart`; expect FAIL (symbols missing).
- [ ] **Step 3:** Implement schema column, store parameters, scoped state keys (`'cursor|$scope'`), engine `scopeProvider`, `SyncScope` singleton set/cleared by `SyncCoordinator` on session change. Update every existing test helper (`engine_harness.dart`, `test_db.dart`) to pass a fixed scope `'u1|t1'`. Existing 339 sync tests must still pass.
- [ ] **Step 4:** Run `flutter test test/core/sync`; expect all green.

### Task 2: Triggers stop awaits the in-flight run; guard ignores null session (gate P1-0b)

**Files:**
- Modify: `lib/core/sync/sync_triggers.dart`, `lib/core/sync/sync_session_guard.dart`, `lib/core/sync/sync_coordinator.dart`, `lib/core/sync/sync_engine.dart`
- Test: `test/core/sync/stop_race_test.dart`

**Interfaces:**
- Produces: `Future<void> SyncTriggers.stop()` completes only after any in-flight `engine.run` finished; `SyncEngine.cancel()` sets a flag checked between batches/pages so `stop()` returns within one network call; `SyncSessionGuard` drops events while the session is null.

- [ ] **Step 1:** Failing tests: (a) `stop()` during a slow push returns only after the run ends and no `setCursor` happens after `SyncStateStore.clear()` ran in the coordinator logout path; (b) an `unauthorized` engine status arriving after the session became null produces no `onSessionEnded` call; (c) `stop()` then `start()` for a new scope starts a fresh run.
- [ ] **Step 2:** Run it; expect FAIL.
- [ ] **Step 3:** Implement `stop()` awaiting the tracked run future, add cooperative `cancel()`, make the coordinator `await _triggers.stop()` before clearing state, and guard drops events when `current == null`.
- [ ] **Step 4:** `flutter test test/core/sync`; green.

### Task 3: Main interceptor never forces logout on network/5xx; logout gate uses outbox (gate P1-0c)

**Files:**
- Modify: `lib/core/network/app_interceptors.dart`, the logout flow that reads `blockingPendingSalesCount` (find with `grep -rn "blockingPendingSalesCount\|clearAllOnLogout" lib`), `lib/core/offline/offline_db.dart` (`clearAllLocalOfflineData`)
- Test: `test/core/network/app_interceptors_refresh_test.dart`, `test/core/offline/logout_gate_test.dart`

**Interfaces:**
- Consumes: `OutboxStore.unsyncedCount()` (all scopes).
- Produces: `AppInterceptors._refreshMainToken` logs out only on an explicit refresh rejection (401, or 400 `token_not_valid`); on network error, timeout, 5xx or 429 it fails the original request with the original error and keeps the session. `OfflineDb.clearAllLocalOfflineData({required bool force})` never deletes `outbox` or the new sales/stock-ledger rows while `unsyncedCount() > 0` unless `force` is true; the normal logout path asks the user (existing dialog) when unsynced rows exist and, on user-confirmed discard, calls the explicit `OutboxStore.discardAll()` (new, requires scope).

- [ ] **Step 1:** Failing tests: refresh returns `DioExceptionType.connectionError` → no `forceLogout`, original error surfaces; 5xx → same; 401 → logout once; logout gate blocks (returns count) when outbox has a `pending` row in any scope; business switch does not delete rows of the outbox.
- [ ] **Step 2:** Run; FAIL.
- [ ] **Step 3:** Implement. Keep the existing public statics `forceLogout()`/`refreshInFlight` unchanged.
- [ ] **Step 4:** Run the two tests plus `flutter test test/core`; green.

### Task 4: Engine pushes without a cursor (pull waits for bootstrap)

**Files:**
- Modify: `lib/core/sync/sync_engine.dart` (around the `needsBootstrap` early return)
- Test: add to `test/core/sync/engine_test.dart`

**Interfaces:**
- Produces: with no stored cursor and `requireBootstrapWhenNoCursor` the engine still runs ping and push, skips pull, and returns `SyncOutcome.needsBootstrap`. A push-only cycle must still apply push results.

- [ ] **Step 1:** Failing test: empty cursor, 3 pending mutations, server up → all three `done`, outcome `needsBootstrap`, no `pull` request made (assert on the fake server request log).
- [ ] **Step 2:** Run; FAIL. **Step 3:** Implement. **Step 4:** `flutter test test/core/sync`; green (convergence test unaffected: it seeds a cursor).

### Task 5: Stock ledger table and `StockApplier`

**Files:**
- Create: `lib/core/sync/appliers/stock_applier.dart`, `lib/features/inventory/data/local/stock_local_store.dart`
- Modify: `lib/core/offline/offline_db.dart` (stock table gets `base_quantity REAL`-free design: keep `quantity` as the displayed value, add `base_quantity TEXT NOT NULL DEFAULT '0'`), `lib/utilities/dependencies_provider.dart` (register applier)
- Test: `test/core/sync/stock_applier_test.dart`

**Interfaces:**
- Produces: `StockApplier implements ChangeApplier` with `entity = 'stock'`, `skipWhenLocalPending = false`, tables `{stock}`.
  - `apply(txn, change)`: set `base_quantity` from `data.quantity`; set `quantity = base + Σ(delta of this device's outbox rows for (product,shop) with status pending|inflight|blocked)`.
  - `onPushResult(txn, sent, result)`: only when `result.status == applied`: take `stock_after` for the affected `(product,shop)` as the new `base_quantity` and recompute `quantity` the same way (the just-sent row is now `done` so excluded). `duplicate`/`rejected`: for `rejected` of a stock mutation, recompute `quantity` (the rejected delta no longer counts); for `duplicate` do nothing to base.
  - `StockLocalStore.pendingDeltaSum(DatabaseExecutor, productId, shopId) -> Decimal string` helper used by both and by the sale service. Delta decimals are summed as scaled integers (3 fractional digits) to avoid float drift.
- Product `stock_level` column and `json` on `products` are kept in sync by the same transaction (existing UI reads them).

- [ ] **Step 1:** Failing tests: pull `stock=10` with local pending `-3` → quantity 7; `applied` with `stock_after=12` and another pending `-1` → quantity 11; `duplicate` with stale `stock_after=2` leaves base and quantity unchanged; `rejected` stock.remove drops its delta; pull while no pending → quantity = pulled; decimal `0.1`×3 deltas sum exactly.
- [ ] **Step 2:** Run; FAIL. **Step 3:** Implement. **Step 4:** Run; green.

### Task 6: Sales tables, `SaleService.createSale`, `SaleApplier`

**Files:**
- Create: `lib/features/pos/data/local/sale_local_store.dart`, `lib/features/pos/domain/sale_service.dart`, `lib/core/sync/appliers/sale_applier.dart`, `lib/core/sync/sync_scope.dart` (if not created in Task 1)
- Modify: `lib/core/offline/offline_db.dart` (tables below, DB version 8), `lib/features/pos/data/repository_impl/pos_repo_impl.dart`, `lib/utilities/dependencies_provider.dart`
- Test: `test/features/pos/sale_service_test.dart`, `test/core/sync/sale_applier_test.dart`, `test/features/pos/sale_crash_test.dart`

**Interfaces:**
- Tables (all `IF NOT EXISTS`): `sales(id TEXT PK, shop_id, customer_id, cashier_id, status, subtotal, discount, tax_amount, net_amount, tax_rate, tax_inclusive, tax_name, receipt_number, local_receipt_number, occurred_at, received_at, version INTEGER, sync_state TEXT, warnings_json)`, `sale_items(id TEXT PK, sale_id, product_id NULL, product_name, is_custom INT, quantity, unit_price, unit_cost NULL, line_total, snapshot_json)`, `sale_payments(sale_id, method, amount)`; indexes `sales(shop_id, occurred_at)`, `sales(status)`, `sale_items(sale_id)`. `sync_state` ∈ `pending|synced|rejected`.
- `SaleService.createSale(SaleDraft draft) -> Future<Sale>`: inside ONE `LocalWriter.write(tables:{sales,sale_items,sale_payments,stock,products,outbox})`: validate payments sum to net (±0.01, else throw `SaleValidationException`), insert rows with a new UUID v4 sale id and item ids, decrement `stock.quantity` and `products.stock_level` for non-custom lines (negative allowed), enqueue ONE outbox entry `entity:'sale', op:'create', entity_id: saleId` with the `sale.create` payload (field names per `CreateSaleRequestDto` plus `items[].id`, `occurred_at`, `cashier`, `device_id`, `tax_rate`, `tax_inclusive`, `tax_name`, `payments:[{method,amount}]`, `local_receipt_number`, per-line `unit_cost`). No separate stock mutation (the BE decrements stock for `sale.create` and returns `stock_after`).
- `local_receipt_number`: `'L-' + first 4 of deviceId + '-' + zero-padded per-device counter` kept in `sync_state` (increment inside the same transaction).
- `SaleApplier` (`entity:'sale'`, `skipWhenLocalPending` true, `localVersion` returns `sales.version`): `apply` upserts the sale, items and payments from `data`; `onPushResult`: `applied`/`duplicate` → set `sync_state='synced'`, `receipt_number`, `warnings_json`; `rejected` → `sync_state='rejected'` and keep the row (never delete a sale; the pending-sync screen shows it). Stock re-base is handled by `StockApplier` through the push result's `stock_after`.
- `PosRepoImpl.submitSale` stops calling the network; it maps the cart to `SaleDraft`, calls `SaleService.createSale`, returns the local result immediately (`PosSubmitResult` gains a local variant; keep the existing UI contract).

- [ ] **Step 1:** Failing tests: createSale writes sale+items+payments+one outbox row, stock decremented once, change notifier fires `sales` once after commit; payments mismatch throws and writes nothing; custom line has no stock effect and null product; `sale_crash_test.dart` uses `CrashSimulation` to kill after the sale rows but before commit → on reopen no sale and no outbox row; kill after commit → exactly one of each; `duplicate` replay result sets `synced` without touching stock; applier ignores a pulled older version; a pulled sale from another device appears in `sales` and does not touch stock locally (StockApplier owns it); a sale line whose product row is later deleted still renders from `snapshot_json`.
- [ ] **Step 2:** Run; FAIL. **Step 3:** Implement. **Step 4:** Run; green; `flutter analyze` on touched files.

### Task 7: Stock edits and inbound through the outbox

**Files:**
- Create: `lib/features/inventory/domain/stock_service.dart`
- Modify: `lib/features/inventory/data/repository_impl/inventory_repo_impl.dart`, `lib/utilities/dependencies_provider.dart`
- Test: `test/features/inventory/stock_service_test.dart`

**Interfaces:**
- Produces: `StockService.add/remove/adjust({productId, shopId, delta, reason})` and `receiveInbound(CreateInboundRequestDto)`, each one `LocalWriter.write` that updates `stock.quantity` (and `products.stock_level`) and enqueues `stock.add|remove|adjust` (payload `{product_id, shop_id, delta, reason, occurred_at}`; `remove` sends the magnitude) or `inbound.create` (payload = existing DTO json plus a client id). `stock.count` and `transfer` stay out of Phase 1 (manager-only, Phase 4+). Cashiers may only act on their own shop (enforced locally by role + shop, mirroring BE decision 4).

- [ ] **Step 1:** Failing tests per op: quantity changes immediately, outbox row has exact payload, `add` with delta ≤ 0 rejected locally, restaurant business type refuses stock ops locally with a clear error, notifier fires.
- [ ] **Step 2-4:** Run FAIL, implement, run green.

### Task 8: Reactive dashboard and sales history from local tables

**Files:**
- Create: `lib/features/dashboard/data/local/local_dashboard_queries.dart`
- Modify: `lib/features/dashboard/data/repositories/dashboard_repository_impl.dart`, `lib/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart`, `lib/features/sales_history/data/repository_impl/sales_history_repo_impl.dart`
- Test: `test/features/dashboard/local_dashboard_queries_test.dart`

**Interfaces:**
- Produces: `Stream<DashboardSummary> watchToday({required String shopId})` via `DbChangeNotifier.watch` on `{sales, sale_items, sale_payments}`; "today" = business timezone calendar day (`business.timezone`, default `Africa/Khartoum`) computed from `occurred_at`; revenue statuses `completed|partial_refund|refunded`, revenue per sale = `net_amount`, refunds subtracted on refund date (refund rows arrive in Phase 4, so the query already joins `sale_refunds` when the table exists); payment breakdown from `sale_payments`; top sellers by Σ quantity from product lines. The bloc subscribes to the stream, emits the first value from SQLite with no loading state, and no longer shows a spinner for cached data. History lists read `sales` ordered by `occurred_at DESC` with keyset paging.

- [ ] **Step 1:** Failing tests: insert a sale via `SaleService` → the stream emits the new total within 100 ms of commit (fake_async or real with a 16 ms debounce allowance); midnight boundary in `Africa/Khartoum` with a device clock set to UTC; a `rejected` sale still counts locally (it happened) but is flagged; wrong device clock (3 days ahead) still lists the sale under that day consistently.
- [ ] **Step 2-4:** FAIL, implement, green. Compare against `GET sales/dashboard-summary/` fixtures in the test using recorded JSON for one day.

### Task 9: Pending Sync screen on the outbox

**Files:**
- Modify: `lib/features/sync/presentation/bloc/pending_sync_bloc.dart` (+ event/state), `lib/features/sync/presentation/pending_sync_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`, `lib/core/offline/presentation/bloc/offline_status_bloc.dart`, `lib/features/business/presentation/widgets/home/home_header.dart`
- Test: `test/features/sync/pending_sync_bloc_test.dart`

**Interfaces:**
- Consumes: `OutboxStore.unsyncedCount`, `rejected()`, `retryRejected(id)`, `discard(id)`.
- Produces: state lists pending/rejected/blocked rows with entity, human label, last error, and for `blocked` rows the id of the rejected row they wait behind; actions retry and discard (discard of a sale asks confirmation and marks the sale `sync_state='rejected'`, never deletes it); header badge shows `unsyncedCount` and the engine phase (`SyncStatus`), with "Server unreachable" wording based on `ServerReachability`, not device Wi-Fi. Strings added in both ARB files.

- [ ] **Step 1:** Failing bloc tests with an in-memory outbox containing pending, rejected and blocked rows. **Step 2-4:** FAIL, implement, green; run `flutter gen-l10n` and `flutter analyze`.

### Task 10: Background worker that survives the OS

**Files:**
- Create: `lib/core/sync/background/background_sync.dart`, `lib/core/sync/background/background_entry.dart`
- Modify: `pubspec.yaml` (`workmanager`, exact version pinned), `android/app/src/main/AndroidManifest.xml` if the plugin needs it, `ios/Runner/Info.plist` (`BGTaskSchedulerPermittedIdentifiers`, `UIBackgroundModes` fetch+processing), `ios/Runner/AppDelegate.swift`, `lib/main.dart`
- Test: `test/core/sync/background_sync_test.dart`

**Interfaces:**
- Produces: `BackgroundSync.register()` schedules a periodic (15 min, network-connected, not battery-low-constrained) task `amana.sync` plus a one-off expedited task enqueued by `SyncTriggers` after-write when the app is backgrounded. `backgroundEntry()` (a top-level `@pragma('vm:entry-point')`) builds a minimal DI (OfflineDb, OutboxStore, SyncStateStore, HttpSyncTransport, SyncEngine; no UI, no Bloc), reads the session from secure storage, runs `engine.run(SyncReason.background)` with a 25 s budget and returns success unless the outcome is `backoff`/`blocked`. The DB lease (`sync_lock`) already guarantees the foreground engine and the worker never push concurrently; the worker must call `OfflineDb` in a way that tolerates the foreground isolate holding the same file (WAL mode on).
- A pure-Dart `BackgroundSyncRunner.runOnce(...)` holds the logic so it is unit tested; the platform glue stays thin.

- [ ] **Step 1:** Failing tests for `BackgroundSyncRunner`: no session → returns without network; session + backlog + fake server up → drains and reports success; lease held by a live foreground run → returns `alreadyRunning` without error; budget exceeded → stops between batches and reports partial.
- [ ] **Step 2-4:** FAIL, implement, green. Then manual checklist in `docs/offline.md` "Background sync on device" (force-stop, battery saver, airplane mode) — the executor writes the checklist, the user runs it on devices.

### Task 11: Remove the legacy queues and flip the flag on

**Files:**
- Delete: `lib/core/sync/sync_manager.dart`, `lib/features/pos/data/model/offline/offline_sales_queue.dart`, `lib/features/pos/data/model/offline/offline_sale_dto.dart`, `lib/features/inventory/data/offline/offline_inbound_queue.dart`, `lib/features/inventory/data/offline/offline_inbound_dto.dart`; remove `pending_sales`, `pending_sale_items`, `pending_inbound_transactions` creation and deletes in `lib/core/offline/offline_db.dart` (DB version 9 drops them in `onUpgrade`)
- Modify: `lib/core/sync/sync_flags.dart` (`defaultValue: true`; keep the define as a kill switch), all call sites found by `grep -rn "SyncManager\|OfflineSalesQueue\|OfflineInboundQueue\|syncPendingSales" lib test`, `lib/utilities/dependencies_provider.dart`
- Test: existing suites updated; `flutter test` whole repo.

- [ ] **Step 1:** Remove the classes and fix every call site so the whole repo compiles with the sync core as the only write path. **Step 2:** `flutter analyze` (no new infos over the 75 pre-existing) and `flutter test`; expect 0 failures. **Step 3:** Update `docs/offline.md` and the memory note's status.

### Task 12: Full user lifecycle and convergence tests

**Files:**
- Modify: `test/core/sync/support/fake_sync_server.dart` (stock deltas by BigInt decimal already exist; add `sale.create` accept-always with `payments` sum check, `items[].id`, `stock_after`, receipt numbers, and the clock-suspect rule), `test/core/sync/convergence_test.dart`
- Create: `test/features/lifecycle/cashier_day_test.dart`, `test/features/lifecycle/two_devices_test.dart`

**Interfaces:**
- Consumes: `SaleService`, `StockService`, engine harness.
- Produces: scenario tests using real services over in-memory SQLite and the fake server.

- [ ] **Step 1:** Write `cashier_day_test.dart`: setup (bootstrapped catalog, cursor seeded) → server DOWN 2 h (fake_async) → 40 sales and 3 stock adds with kills (`CrashSimulation`) at random points → server UP → everything drains in order; server totals equal local totals; no sale lost or doubled; stock equals base − sold + added exactly; dashboard stream value equals server checksum; rejected payment-mismatch is impossible from the UI path.
- [ ] **Step 2:** Write `two_devices_test.dart`: two devices sell the same product offline, one also adds stock, server flaky + lost responses + `dropResponseAfterApply` → both converge to the same stock and the same set of sales (extend the seeded convergence test with sale.create and stock ops, default 60 seeds, `CONV_SEEDS` still honoured).
- [ ] **Step 3:** Run `flutter test test/core/sync test/features`; expect all green. Run `CONV_SEEDS=200 flutter test test/core/sync/convergence_test.dart` once and record the result in the ledger.

---

## Self-Review

- Spec coverage: gates P1-0a/b/c → Tasks 1-3; engine without cursor (needed because legacy bootstrap is replaced in P2) → Task 4; stock deltas and re-base rule → Task 5; sales local-first and same-second dashboard → Tasks 6, 8; background worker → Task 10; legacy removal and zero-user DB drop → Task 11; lifecycle tests → Task 12. Catalog, bootstrap, customers, refunds/cancel, team stay in Phases 2-5 (refund tables are referenced defensively in Task 8 only).
- Type consistency: `scope` is the string `'$userId|$tenantId'` throughout; `SaleService`/`StockService` are the only writers of sales/stock rows; `StockApplier` is the only code that touches `base_quantity`.
- Known open item for the user: until Phase 2 ships the paged bootstrap, the catalog still comes from the legacy `offline/bootstrap/` download, and pulled changes wait (Task 4); sales, stock edits and the dashboard already work fully offline.
