# Phase 2: Paged Bootstrap, Pull Appliers, Assets by Hash Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The sync core becomes the only way server data enters the device: a resumable paged first setup, an applier for every feed entity, and images downloaded by verified content hash; the legacy bulk bootstrap is retired.

**Architecture:** A `Bootstrapper` (beside `SyncEngine`, same scope/`sync_lock`/token rules) pages `GET sync/bootstrap/` entity by entity, feeding each item as a synthetic upsert `PullChange` through the same `ChangeApplier`s that pull uses; progress lives in scoped `sync_state` keys; the pull cursor is set (= `snapshot_cursor`) only in the final transaction. `AssetSync` runs after pull, driven by `image_hash`.

**Tech Stack:** Flutter/Dart, sqflite (+ `sqflite_common_ffi` in tests), Dio, `crypto` (sha256), existing `FakeSyncServer`.

**Spec:** `docs/superpowers/specs/2026-11-16-phase2-bootstrap-pull-assets-design.md` (parent: `2026-11-16-offline-first-sync-design.md`). BE contract (READ ONLY, never edit): `/Users/almogdadjabir/Documents/projects/amana/amanaPOS-be/docs/sync-contract.md`, `sync-contract-deviations.md`, and shapes in `apps/sync/feed.py` + `apps/sync/pull.py`. Ledger: `.superpowers/sdd/2026-11-16-phase2-bootstrap-pull-assets/progress.md`.

## Global Constraints

- NEVER run git (not even read-only) except `git add` when the user asks. No commits by agents; every "Commit" step is replaced by "report files changed". The user commits.
- Never edit the BE repo. BE needs go to `docs/BE_GAPS.md` (follow-ups section).
- Zero users: no data migration; DB bumps are additive. DB version ownership: Task 3 = v11, Task 9 = v12.
- Run tests in the FOREGROUND only (`flutter test <path>`); `flutter analyze` must not exceed 74 issues.
- Money is real: money fields stay strings on the wire; sums via `Decimal3`/integer cents, never floating accumulation. Never roll a row back to an older `version`; never overwrite a row with an unsynced outbox row except through the existing `deferred_pull` rule.
- Cursor/bootstrap state is per scope `userId|tenantId` (`SyncStateStore.forScope`). The engine never logs the user out on network/5xx/timeout. `device_id` and `sync_lock` are global.
- Inside `ChangeApplier.apply` / `onPushResult` / page transactions use only `txn`; never `OfflineDb.database`, never `LocalWriter.write` (deadlock / nested write throws).
- Bootstrap page size default 500 (BE max 1000); `sale` page size 200. `sales_since` fixed 90 days. Entity order: `business, shop, category, product, vendor, customer, user, subscription, bankak_account, stock, expiry_batch, sale, refund, inbound, notification` (manifest entities not in this list are logged and skipped).
- The background worker NEVER bootstraps (only reports `needsBootstrap`); it may sync thumbnails only.
- Missing `bootstrap_paged` capability = first setup blocked ("server not ready"), no legacy fallback.
- First setup unblocks only when the final transaction (all entities incl. 90-day sales) commits; images never block it.
- Localization: any new user-visible string goes in en + ar ARB files like existing ones.
- UI (Task 11) follows the UI revamp workflow: HTML mockup, user approves, then Flutter.

## Review Focus

1. Kill/offline/token loss after every page boundary and mid-page of a bootstrap: resume yields no duplicate/lost rows and ONE snapshot (Task 6, 8).
2. Rows written on the server between pages are delivered by `pull` from `snapshot_cursor`; final local DB equals server (Task 8).
3. Session switch (other user/tenant) mid-bootstrap: aborts quietly, progress of the other scope untouched (Task 6).
4. Local row with an unsynced outbox edit during bootstrap is deferred, never overwritten; older/equal `version` never overwrites (Task 3, 4, 6).
5. A corrupt/undecodable download or empty `image_hash` never replaces a good image and never loops (Task 9; `image_hash` is a change token, ledger ruling T1-a).

---

## File Structure

| File | Responsibility |
|---|---|
| `docs/superpowers/plans/2026-11-16-phase2-legacy-audit.md` (new, Task 1) | Reader-to-table audit + applier column mapping |
| `lib/core/sync/contract/sync_contract.dart` (mod) | `BootstrapManifest`, `BootstrapPage` DTOs |
| `lib/core/sync/transport/{sync_transport,http_sync_transport}.dart` (mod) | `bootstrapManifest`, `bootstrapPage` |
| `test/core/sync/support/fake_sync_server.dart` (mod) | paged bootstrap + fault knobs + `rows between pages` hook |
| `lib/core/sync/sync_state_store.dart` (mod) | bootstrap progress keys, `bootstrapped` flag, split `clear()` |
| `lib/core/sync/appliers/*_applier.dart` (new) | one per entity (Tasks 3-5) |
| `lib/core/sync/appliers/synced_entities_store.dart` (new) | generic `synced_entities` table access |
| `lib/core/sync/bootstrap/bootstrapper.dart` (new) | resumable paged bootstrap |
| `lib/core/sync/sync_engine.dart`, `sync_triggers.dart`, `sync_coordinator.dart`, `background/background_sync.dart` (mod) | wiring, resync semantics |
| `lib/core/sync/assets/asset_sync.dart` (new) | hash-driven image sync |
| `lib/core/offline/presentation/...` (mod/new) | first-setup screen, readiness from sync state |
| `lib/core/offline/offline_first_manager.dart`, `offline_asset_downloader.dart`, `data/offline_remote_data_source.dart` (removed/trimmed Task 12) | legacy retirement |

---

### Task 1: Legacy reader audit (read-only deliverable)

**Files:**
- Create: `docs/superpowers/plans/2026-11-16-phase2-legacy-audit.md`

**Interfaces:**
- Produces: per entity, (a) every reader (file:line) of the local table/JSON, (b) the exact column set + JSON keys it needs, (c) the mapping feed-row key -> column/JSON key (read BE `apps/sync/feed.py` `ser_*`), (d) the new `synced_entities` candidates (entities with no legacy reader), (e) where `OfflinePreparationListener`, `OfflineStatusBloc._onStarted`, login/logout init hook in, (f) which legacy writers/triggers Task 12 must remove. Tasks 3-5 and 11-12 consume it as their column spec.

- [ ] **Step 1: Read** `OfflineLocalCache`, `OfflineDb`, `offline_status_bloc.dart`, every bloc/widget importing `OfflineLocalCache` (product, category, business, vendors, inventory, inbound, premium inventory, `main_bottom_area`, `auth_bloc`), `OfflineCachedImage`, the dashboard `sale_refunds` query, and BE `feed.py` serializers (`ser_*` for all 15 entities).
- [ ] **Step 2: Write the audit doc** with one table row per entity (reader, columns, JSON keys, feed key mapping, version/image_hash column needs) and the decision list for tables not needed by any reader (go to `synced_entities`).
- [ ] **Step 3: Verify** every `ser_*` key of the five legacy-table entities appears in the mapping or is marked "ignored: reason". No source files changed.

---

### Task 2: Bootstrap DTOs, transport, FakeSyncServer

**Files:**
- Modify: `lib/core/sync/contract/sync_contract.dart`, `lib/core/sync/transport/sync_transport.dart`, `lib/core/sync/transport/http_sync_transport.dart`, `test/core/sync/support/fake_sync_server.dart`
- Test: `test/core/sync/bootstrap_transport_test.dart`, extend `test/core/sync/sync_contract_test.dart`, `http_sync_transport_test.dart`

**Interfaces:**
- Produces:
  - `class BootstrapManifest { final DateTime serverTime; final List<String> entities; final String snapshotCursor; fromJson/toJson }`
  - `class BootstrapPage { final String entity; final String snapshotCursor; final List<Map<String,dynamic>> items; final bool hasMore; final String? nextPageCursor; fromJson/toJson }` (wire keys `server_time, entities, snapshot_cursor, entity, items, has_more, next_page_cursor`)
  - `SyncTransport.bootstrapManifest({required String scope}) -> Future<BootstrapManifest>`
  - `SyncTransport.bootstrapPage({required String entity, String? pageCursor, int limit = 500, String? snapshotCursor, int salesSinceDays = 90, required String scope}) -> Future<BootstrapPage>`
  - `FakeSyncServer`: `seedRow(entity, Map row)` (feed-shaped), keyset paging by id, `snapshotSeq` taken at the first call, `void Function(String entity, int pageIndex)? onBootstrapPage` hook (tests write rows between pages), per-view fault knobs reused (`down`, `flakyRate`, `failNextWith`).

- [ ] **Step 1: Write failing tests**: `BootstrapPage.fromJson` rejects missing `items`; `HttpSyncTransport.bootstrapPage` sends `entity,page_cursor,limit,snapshot_cursor,sales_since` query params, maps 401 typed codes like `pull`, honours scope (`scopeChanged`); `FakeSyncServer` returns all seeded rows exactly once across pages (limit 2, 5 rows => 3 pages, `hasMore` false on last, `nextPageCursor` null), same `snapshotCursor` echoed on every page, and a row seeded via `onBootstrapPage` after page 1 is NOT in the pages but IS returned by `pull(cursor: snapshotCursor)`.
- [ ] **Step 2: Run** `flutter test test/core/sync/bootstrap_transport_test.dart` -> FAIL (symbols missing).
- [ ] **Step 3: Implement** the DTOs (same `_str/_list/_obj` helpers as `PullResponse`), the two transport methods in `HttpSyncTransport` (path `api/v1/sync/bootstrap/`, same Dio, same error mapper and gzip as `pull`), and the Fake (keyset by id ordering; feed entries for seeded rows get `seq` > snapshot only when written after the snapshot).
- [ ] **Step 4: Run** the same test + `flutter test test/core/sync` -> PASS.
- [ ] **Step 5:** do not commit; report files changed.

---

### Task 3: SyncStateStore bootstrap state, DB v11, catalog appliers (business, shop, category, product)

**Files:**
- Modify: `lib/core/sync/sync_state_store.dart`, `lib/core/offline/offline_db.dart` (v11), `lib/core/sync/sync_appliers.dart`, `lib/core/sync/sync_schema.dart` if needed
- Create: `lib/core/sync/appliers/{business,shop,category,product}_applier.dart`, `lib/core/sync/appliers/applier_support.dart`
- Test: `test/core/sync/sync_state_store_test.dart` (extend), `test/core/sync/catalog_appliers_test.dart`, `test/core/offline/offline_db_v11_test.dart`

**Interfaces:**
- Produces (`SyncStateStore`, scoped): `Future<BootstrapProgress?> bootstrapProgress(DatabaseExecutor e)`, `Future<void> setBootstrapProgress(DatabaseExecutor txn, BootstrapProgress? p)`, `Future<bool> isBootstrapped()`, `Future<void> setBootstrapped(DatabaseExecutor txn, bool v)`; `class BootstrapProgress { String snapshotCursor; List<String> entities; List<String> done; String? pageCursor; DateTime startedAt; toJson/fromJson }` (one JSON value under key `bootstrap_progress|<scope>`; `bootstrapped|<scope>` is a separate key never touched by `clear()`); `clear()` unchanged for `bootstrapped`, and also clears `bootstrap_progress`. `applier_support.dart`: `bool decimalOk(Object?)`, `Future<void> upsertVersioned(Transaction, table, id, version, row)` returning without writing when stored `version >= incoming` (equal or older never overwrites), `logSkip(entity, id, reason)`.
- `*Applier implements ChangeApplier` with `entity` = `business|shop|category|product`, `tables` per audit, `localVersion` reading the `version` column, `skipWhenLocalPending` default true. Row writes follow the Task 1 mapping (typed columns + legacy-compatible `json`); `delete` removes the row; `upsert` with `is_active:false` keeps the row inactive; malformed rows are skipped and logged, never throw. DB v11 (additive, idempotent in `onUpgrade` and `onCreate`): add `version INTEGER` to businesses, shops, categories, products, customers; `image_hash TEXT` to categories, products.
- Consumes: Task 1 audit.

- [ ] **Step 1: Write failing tests**: state store round-trips `BootstrapProgress` per scope, scope B sees none, `clear()` removes progress but keeps `bootstrapped`; each applier: upsert inserts, same id newer `version` updates, older/equal `version` is a no-op (`product` price unchanged), `delete` removes, inactive row kept with `is_active` false in JSON, malformed row (missing `id`) skipped without throwing, product `image_hash` column stored; v11 migration test opens a v10 DB and finds the new columns.
- [ ] **Step 2: Run** the three test files -> FAIL.
- [ ] **Step 3: Implement** state store additions, `applier_support.dart`, the four appliers, v11 migration, and register them in `buildSyncAppliers()`.
- [ ] **Step 4: Run** `flutter test test/core/sync test/core/offline` -> PASS (no regression).
- [ ] **Step 5:** report files changed.

---

### Task 4: Remaining appliers (customer, vendor, expiry_batch, user, subscription, notification, bankak_account) + `synced_entities`

**Files:**
- Create: `lib/core/sync/appliers/{customer,vendor,expiry_batch,user,subscription,notification,bankak_account}_applier.dart`, `lib/core/sync/appliers/synced_entities_store.dart`
- Modify: `lib/core/offline/offline_db.dart` (still v11: add table in this task's work on the same version), `sync_appliers.dart`
- Test: `test/core/sync/other_appliers_test.dart`

**Interfaces:**
- Produces: table `synced_entities(entity TEXT, id TEXT, version INTEGER, json TEXT NOT NULL, updated_at TEXT, PRIMARY KEY(entity,id))` and `class SyncedEntitiesStore { upsert(txn, entity, id, version, json); delete(txn, entity, id); localVersion(txn, entity, id) }`. `customer` and `vendor` write their existing legacy tables (`customers`, `vendors`) per the Task 1 mapping; `expiry_batch`, `user`, `subscription`, `notification`, `bankak_account` use `synced_entities` unless the audit found a legacy reader (then that table). Cashier-visible rule: nothing special, the server already scopes.
- Consumes: Task 3 `applier_support.dart`.

- [ ] **Step 1: Write failing tests** (one per applier): upsert, newer wins, older no-op (versioned ones), delete, malformed skipped; customer `loyalty_points` stored as sent (server-owned).
- [ ] **Step 2: Run** `flutter test test/core/sync/other_appliers_test.dart` -> FAIL.
- [ ] **Step 3: Implement** store + appliers; register.
- [ ] **Step 4: Run** `flutter test test/core/sync test/core/offline` -> PASS.
- [ ] **Step 5:** report files changed.

---

### Task 5: Refund applier + `sale_refunds`; existing appliers accept bootstrap-shaped items

**Files:**
- Create: `lib/core/sync/appliers/refund_applier.dart`
- Modify: `lib/core/offline/offline_db.dart` (v11: `sale_refunds`), `sync_appliers.dart`
- Test: `test/core/sync/refund_applier_test.dart`, `test/core/sync/bootstrap_shape_contract_test.dart`

**Interfaces:**
- Produces: `sale_refunds(id TEXT PRIMARY KEY, sale_id TEXT, shop_id TEXT, total TEXT, occurred_at TEXT, method TEXT, json TEXT)` matching the dashboard contract (`local_dashboard_queries.dart` comment: `id, sale_id, shop_id, total TEXT, occurred_at TEXT UTC ISO`); `RefundApplier` (`entity` `refund`, `tables` `{'sale_refunds'}`): upsert maps feed `ser_refund` (read BE `feed.py`), `occurred_at` = refund `created_at`; delete removes. Must also touch `sales` status handling: do NOT change sale status here (the pulled sale row carries it).
- `bootstrap_shape_contract_test.dart`: one real-shaped item per entity (copied verbatim from BE `ser_*` field sets, with the nested sale items/payments and stock/expiry without `version`) wrapped as `PullChange(seq: 0, id: item['id'], version: item['version'], data: item, originDeviceId: null, shopId: null)` applied through EVERY registered applier incl. existing stock/sale/inbound; assert rows exist and no exception. Fix any existing applier that reads wrapper-only fields (e.g. `change.shopId`) by falling back to the row's `shop`/`shop_id`.

- [ ] **Step 1: Write failing tests** as above plus: dashboard `_refunds` query returns non-zero after a refund applier upsert (use `LocalDashboardQueries` against the test DB).
- [ ] **Step 2: Run** -> FAIL. **Step 3: Implement.** **Step 4: Run** `flutter test test/core/sync test/features/dashboard test/core/offline` -> PASS.
- [ ] **Step 5:** report files changed.

---

### Task 6: Bootstrapper

**Files:**
- Create: `lib/core/sync/bootstrap/bootstrapper.dart`
- Test: `test/core/sync/bootstrapper_test.dart`, `test/core/sync/bootstrapper_resume_test.dart`

**Interfaces:**
- Produces:
  - `enum BootstrapOutcome { completed, interrupted, blocked, alreadyRunning, notNeeded }`
  - `class BootstrapStatus { BootstrapOutcome? outcome; String? currentEntity; int entityIndex; int entityCount; int rowsApplied; bool offline; SyncBlockReason? block }` exposed as `Stream<BootstrapStatus> get status`.
  - `class Bootstrapper { Bootstrapper({required OfflineDb db, required SyncTransport transport, required SyncStateStore state, required ChangeApplierRegistry appliers, required DbChangeNotifier notifier, required String? Function() scopeProvider, required Future<void> Function() assertScope, required Future<Set<String>> Function() capabilities, int pageSize = 500, DateTime Function()? now}); Future<BootstrapOutcome> run(); void cancel(); }`
- Behavior (spec section 2): capability gate (`bootstrap_paged`) -> acquire `sync_lock` (`alreadyRunning` if held) -> resume stored `BootstrapProgress` else fetch manifest and store snapshot + ordered entities (client order from Global Constraints) -> per entity page loop; each page = one SQLite transaction: apply each item as synthetic `PullChange(seq: 0, entity, op: 'upsert', id, version, data)` honoring `skipWhenLocalPending` (deferred via `deferred_pull` JSON, same encoding as the engine) and `localVersion`, then update progress (`pageCursor`, `done`) inside the same transaction; final transaction: `setCursor(snapshot)`, `setBootstrapped(true)`, clear progress. Notify applier tables after each commit. Typed transport errors map exactly like the engine (token refresh path via an injected `Future<T> Function<T>(Future<T> Function()) authed` wrapper reused from the engine — expose it from the engine rather than duplicating). `assertScope` throws inside the page txn so a session switch rolls the page back and returns `interrupted` quietly. Offline/timeout returns `interrupted` with `offline: true`, never logs out.
- Consumes: Task 2 transport, Task 3 state store, Tasks 3-5 appliers.

- [ ] **Step 1: Write failing tests** (all with `FakeSyncServer` + in-memory DB): (a) happy path with 3 entities across pages ends `completed`, cursor == snapshot, `bootstrapped` true, progress cleared, all rows present; (b) `onBootstrapPage` writes a row after page 1; after `completed`, one engine pull from the cursor delivers it and DB == server; (c) kill (throw from the transport) after every page boundary k in 1..N then rerun: final DB identical, exactly ONE `bootstrapManifest` call and the same snapshot throughout, no duplicate rows; (d) an exception thrown inside the page transaction leaves progress at the previous page (atomic); (e) scope switch mid-run (scopeProvider changes before page 2): outcome `interrupted`, other scope's progress/state untouched, no rows written for the new page; (f) row whose id has a pending outbox row is deferred (local value unchanged, present in deferred JSON), final txn leaves deferrals intact; (g) older `version` row does not overwrite a newer local row; (h) manifest lists an unknown entity and a cashier manifest lacking `vendor`/`inbound`: unknown skipped, absent not requested; (i) missing `bootstrap_paged` capability -> `blocked`, nothing requested; (j) 401 `token_expired` once -> refresh then continue; `account_disabled` -> `blocked`.
- [ ] **Step 2: Run** `flutter test test/core/sync/bootstrapper_test.dart test/core/sync/bootstrapper_resume_test.dart` -> FAIL.
- [ ] **Step 3: Implement** `Bootstrapper`; factor the shared deferred-JSON encode/decode out of `sync_engine.dart` into a small `lib/core/sync/deferred_pull.dart` used by both (no behavior change; engine tests stay green).
- [ ] **Step 4: Run** the two test files and `flutter test test/core/sync` -> PASS.
- [ ] **Step 5:** report files changed.

---

### Task 7: Engine/trigger/coordinator integration and resync semantics

**Files:**
- Modify: `lib/core/sync/sync_engine.dart`, `sync_triggers.dart`, `sync_coordinator.dart`, `background/background_sync.dart`, `lib/utilities/dependencies_provider.dart`
- Test: `test/core/sync/bootstrap_integration_test.dart`, extend `sync_engine_test.dart`, `background_sync_test.dart`, `sync_triggers_test.dart`

**Interfaces:**
- Produces: `SyncEngine` exposes `Future<T> authed<T>(Future<T> Function() call)` (the existing `_authed`, public) and, on `SyncOutcome.needsBootstrap`, `SyncTriggers` calls `Bootstrapper.run()` (foreground only), then re-runs the engine once. `_resetForBootstrap` now: clears cursor + old bootstrap progress + old deferred pulls, keeps `bootstrapped`, keeps local rows and outbox. A second `fullResyncRequired` within 10 minutes of a completed bootstrap -> engine `backoff` (normal backoff schedule, loud report), no immediate restart. `BackgroundSyncRunner` on `needsBootstrap` reports success without bootstrapping. `SyncCoordinator` stops the bootstrapper on logout/scope change (`cancel()`), `DependenciesProvider` registers `Bootstrapper` and `AssetSync` hook point.
- Consumes: Tasks 6.

- [ ] **Step 1: Write failing tests**: no cursor + online -> engine returns `needsBootstrap`, triggers run the bootstrapper, then the engine pulls and ends `completed`; `full_resync_required` on pull keeps `bootstrapped` true and local rows, outbox untouched, re-bootstraps with a NEW snapshot; second resync within 10 min backs off without restarting; background runner never calls the bootstrapper (spy) and returns success; logout mid-bootstrap cancels; kill switch `SYNC_ENGINE=false` builds no bootstrapper.
- [ ] **Step 2: Run** -> FAIL. **Step 3: Implement.** **Step 4: Run** `flutter test test/core/sync` -> PASS.
- [ ] **Step 5:** report files changed.

---

### Task 8: Lifecycle and convergence tests for bootstrap

**Files:**
- Modify: `test/core/sync/convergence_test.dart`, `test/core/sync/support/engine_harness.dart`
- Create: `test/core/sync/bootstrap_lifecycle_test.dart`

**Interfaces:** consumes Tasks 2-7; produces no new production API.

- [ ] **Step 1: Write the tests**: (a) lifecycle journey: first login -> bootstrap interrupted at 90% (offline) -> relaunch resumes -> done -> offline day of sales -> reconnect; (b) two devices: device B bootstraps while device A keeps selling; after pull both converge and stock equals the arithmetic sum; (c) cashier scope bootstrap sees only its shop/stock and never requests vendor/inbound; (d) convergence generator gains an action "device cold-starts (wipe cursor, bootstrap) mid-run" and `full_resync_required`; run `CONV_SEEDS=60` default and `--dart-define=CONV_SEEDS=200` once; (e) perf: 20k products bootstrap in 40 pages of 500 stays under a generous budget (assert one txn per page, test DB).
- [ ] **Step 2: Run** `flutter test test/core/sync/bootstrap_lifecycle_test.dart test/core/sync/convergence_test.dart` -> expect FAIL where behavior is missing; fix production code in the owning task's files (note it in the ledger), not by weakening tests.
- [ ] **Step 3: Run** the same plus `flutter test test/core/sync` and `flutter test test/core/sync/convergence_test.dart --dart-define=CONV_SEEDS=200` -> PASS.
- [ ] **Step 4:** report files changed.

---

### Task 9: AssetSync by hash (DB v12)

**Files:**
- Create: `lib/core/sync/assets/asset_sync.dart`
- Modify: `lib/core/offline/offline_db.dart` (v12: reshape `offline_assets`), appliers `category/product` (register assets), `lib/core/offline/data/offline_local_cache.dart` (asset helpers), `pubspec.yaml` (`crypto`) if absent
- Test: `test/core/sync/asset_sync_test.dart`, `test/core/offline/offline_db_v12_test.dart`

**Interfaces:**
- Produces: table `offline_assets(type TEXT, id TEXT, variant TEXT, url TEXT, expected_hash TEXT, local_path TEXT, local_hash TEXT, bytes INTEGER, state TEXT, attempts INTEGER DEFAULT 0, next_attempt_at TEXT, PRIMARY KEY(type,id,variant))` (`variant` `thumb|full`). `class AssetSync { AssetSync({required OfflineDb db, required Dio dio, required Directory Function() assetsDir, required DbChangeNotifier notifier, required String? Function() scopeProvider, DateTime Function()? now, int concurrency = 2}); Future<AssetSyncResult> run({int maxFiles = 40, int maxBytes = 20 * 1024 * 1024, bool thumbnailsOnly = false}); }` `AssetSyncResult { int downloaded; int failed; int remaining; }`. Appliers call `registerAsset(txn, type, id, variant, url, expectedHash)` (in `applier_support.dart`) when a row's `image`/`thumbnail_url`/`image_hash` is present, which marks the asset stale when `expected_hash` changed.
- Behavior: select rows with `local_hash != expected_hash` or no file and `next_attempt_at <= now`, thumbs first; download to temp; `expected_hash` (= feed `image_hash`) is a CHANGE TOKEN only (BE serves re-processed WebP; its hash is of the uploaded bytes), so verify instead: HTTP 200, non-empty, decodes as an image, size equals Content-Length when present; failure -> delete temp, `attempts++` with exponential backoff, keep the OLD file; success -> atomic rename, set `local_path/local_hash`, notify; empty `expected_hash` -> download once keyed by url, mark `state='nohash'`, never retried unless the url changes; orphan files (row deleted/hash changed) removed in a later pass only after the new file is verified; sends the sync auth header ONLY for the BE host (other hosts anonymous); no work when scope is null.

- [ ] **Step 1: Write failing tests** with a fake Dio adapter: hash match downloads and renames; mismatch keeps old file and backs off; empty hash downloads once and stops; hash change redownloads, unchanged hash does not; thumbs before full; maxFiles/maxBytes respected; second concurrent `run` is a no-op; temp file never left as the final path.
- [ ] **Step 2: Run** -> FAIL. **Step 3: Implement.** **Step 4: Run** `flutter test test/core/sync/asset_sync_test.dart test/core/offline` -> PASS.
- [ ] **Step 5:** report files changed.

---

### Task 10: Asset triggers and image readers

**Files:**
- Modify: `lib/core/sync/sync_triggers.dart` or engine post-pull hook, `background/background_sync.dart` (thumbnails only), `lib/core/offline/presentation/widgets/offline_cached_image.dart`, `lib/utilities/dependencies_provider.dart`
- Test: `test/core/sync/asset_triggers_test.dart`, widget test for `OfflineCachedImage`

**Interfaces:**
- Produces: after a pull run that completed (and once after bootstrap completes) the app calls `AssetSync.run()`; the background worker calls `run(thumbnailsOnly: true)` inside its existing 25 s budget; `OfflineCachedImage` resolves local path from the new `offline_assets` rows (by url) falling back to network exactly as today. A failed/offline asset run never changes the sync outcome.
- Consumes: Task 9.

- [ ] **Step 1: Write failing tests**: run called after completed pull and not after backoff/blocked; background passes `thumbnailsOnly: true`; widget shows the local file when `local_path` exists and the network image otherwise; asset failure does not fail `syncNow`.
- [ ] **Step 2: Run** -> FAIL. **Step 3: Implement.** **Step 4: Run** `flutter test test/core test/features` -> PASS.
- [ ] **Step 5:** report files changed.

---

### Task 11: First-setup screen and readiness from sync state (needs the user's approval of the mockup)

**Files:**
- Create: `docs/superpowers/mockups/phase2-first-setup.html` (mockup, Nile Ledger), `lib/core/offline/presentation/first_setup_screen.dart` (after approval)
- Modify: `lib/core/offline/presentation/bloc/offline_status_bloc.dart` (+ event/state), the offline-preparation listener slot found in Task 1, ARB files en/ar
- Test: `test/core/offline/first_setup_screen_test.dart`, bloc tests

**Interfaces:**
- Produces: `OfflineStatusState.setupStatus` derived from `SyncStateStore.isBootstrapped()` + `Bootstrapper.status`: `required | running(entity, index, count, rowsApplied) | blockedOffline | blockedServer | done`; `hasCache`/`canUseAppOffline` are `true` iff `bootstrapped`. Screen: step list, per-entity counts, offline message ("Internet is required only for first setup"), retry button, resumes on relaunch, shows non-blocking "Images downloading" after done; a refresh (`bootstrapped` true, cursor reset) shows only a small progress indicator and never blocks.
- Consumes: Tasks 6-7, Task 1 hook points.

- [ ] **Step 1:** write the HTML mockup (states: running, offline, server not ready, done+images) and STOP: ask the user to approve before any Flutter UI. No source changes before approval.
- [ ] **Step 2 (after approval): Write failing tests**: bloc emits `required` -> `running` -> `done` from fakes; offline + no `bootstrapped` -> `blockedOffline`; refresh state never produces a blocking status; widget renders each state and the retry callback fires; strings exist in en + ar.
- [ ] **Step 3: Run** -> FAIL. **Step 4: Implement** screen/bloc changes (no remaining legacy refresh call in the bloc). **Step 5: Run** `flutter test test/core/offline test/features` -> PASS.
- [ ] **Step 6:** report files changed.

---

### Task 12: Retire legacy and document

**Files:**
- Modify/remove (per Task 1 list): `lib/core/offline/offline_first_manager.dart`, `offline_asset_downloader.dart`, `data/offline_remote_data_source.dart` (`getBootstrap`, `getAssetManifest`), `data/offline_local_cache.dart` (`saveBootstrap`, `saveAssetManifest*`, asset manifest helpers, `hasBootstrapCache`), `lib/core/offline/offline_db.dart` (`hasBootstrapCache`), `dependencies_provider.dart`, `docs/offline.md`, `docs/BE_GAPS.md`, `docs/superpowers/specs/...` status lines
- Test: update/replace affected tests; `test/core/offline/legacy_removed_test.dart` (grep-style assertion that the removed symbols are gone is NOT needed; compile + green suite is the proof)

**Interfaces:** produces nothing new. Rules: remove only what the Task 1 audit lists and only after Tasks 3-11 are green; `clearAllOnLogout` keeps its semantics (never deletes unsynced sales or the outbox); blocs keep public signatures.

- [ ] **Step 1: Remove** the listed legacy symbols and wiring; **Step 2: Update docs** (`docs/offline.md`: new Bootstrap/Pull/Assets section, how to add an entity now includes registering an asset; BE_GAPS follow-ups: any BE question found, e.g. empty `image_hash` legacy rows, stock rows for untracked products, bootstrap stale-snapshot signal not validated server-side).
- [ ] **Step 3: Run** `flutter analyze` (<= 74), `flutter test` (all, foreground; expect >= 807 pass + new tests), `flutter test test/core/sync/convergence_test.dart --dart-define=CONV_SEEDS=200`.
- [ ] **Step 4:** report files changed and the final counts.

---

## Self-review (against the spec)

- Spec goals: paged resumable bootstrap (T2, T6, T7, T8); appliers for all entities (T3-T5); assets by hash (T9, T10); legacy retired (T12); FakeSyncServer + convergence (T2, T8). First-setup UX blocking/refresh split (T7, T11). Calls 1-8 of the spec: background never bootstraps (T7); no stale-row deletion (T6 does not delete); one code path via synthetic upserts (T6); capability gate (T6, T7); unblock on full commit (T6, T11); fixed entity order (Global Constraints); role change not handled (none, documented in T12); audit first (T1).
- Types checked: `BootstrapProgress`, `BootstrapOutcome`, `BootstrapStatus`, `AssetSyncResult`, `registerAsset` are defined once and referenced consistently.
- DB versions: T3 and T4/T5 share v11 (written in one bump during T3's migration and extended in T4/T5 by editing the same `onCreate/onUpgrade` step before release; no user data exists), T9 = v12.
- Review Focus tests live in T6 (1, 3, 4), T8 (2), T3 (4), T9 (5).
