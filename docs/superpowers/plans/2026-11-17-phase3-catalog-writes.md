# Phase 3: Catalog Writes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Category, product and vendor create/update/delete plus product/category image upload work fully offline through `LocalWriter` + the outbox, and every push outcome is handled.

**Architecture:** Three services (`CategoryService`, `ProductService`, `VendorService`) mirror `StockService`: validate, write the local row, enqueue, in one `LocalWriter.write`. Outbox gets a multi-entity dependency list. The three appliers implement `onPushResult`. An `ImageUploader` runs after push for `pending_uploads`. Catalog screens read local tables only.

**Tech Stack:** Flutter, sqflite (+ffi in tests), flutter_bloc, get_it, dio, uuid, crypto (sha256), existing `FakeSyncServer`.

**Spec:** `docs/superpowers/specs/2026-11-17-phase3-catalog-writes-design.md` (incl. "Builder-check resolutions"). Parent: `docs/superpowers/specs/2026-11-16-offline-first-sync-design.md`. Read the Phase 2 ledger `.superpowers/sdd/2026-11-16-phase2-bootstrap-pull-assets/progress.md` for rulings.

## Global Constraints

- NO git commands by agents (user commits). Where the usual template says "Commit", write the task report listing changed files instead.
- Never edit the BE repo (`/Users/almogdadjabir/Documents/projects/amana/amanaPOS-be`); BE needs go to `docs/BE_GAPS.md`.
- Zero users: no data migration; DB version bump to **v14**; dev devices reinstall.
- Tests run in the FOREGROUND only. Baseline: 1156 pass / 2 skip, `flutter analyze` 73 issues (must not grow).
- Money is a String; never double. IDs are UUID v4 generated on device.
- `LocalWriter.write` never nests; bodies use `scope.txn` only, never `OfflineDb.database`.
- Catalog writes are owner/manager only (BE `forbidden` otherwise): service refuses cashiers with `CatalogValidationException`.
- Role/business type come from the injected actor (same as `StockActor`), never a live fetch.
- Conflict policy A: `conflict_unique` never rewrites ids automatically; "Merge into existing" is user-triggered only.
- `image_hash` = sha256 of the UPLOADED bytes; a downloaded file is never compared to it (ruling T1-a).
- Image uploads are foreground only (the OS worker never uploads).
- No REST catalog writer (`saveProductsToCache`, `saveCategoriesToCache`, `saveVendors`, REST add/edit/delete of the three entities) may survive.
- Follow Nile Ledger for any new UI; HTML mockup approval is NOT needed for small state markers/dialogs, but a new full screen needs the user's approval first.

## Review Focus

1. A sale/stock/inbound row naming a product whose create returned `retry` is never sent before that create is `done` (it would be saved with `product = NULL`). Pinned in Task 2.
2. A rejected create (e.g. `conflict_unique`, `limit_exceeded`) must fail later same-entity rows (edit, delete) and dependents, not leave them stuck `pending`. Pinned in Task 5.
3. A lost image-upload response then retry leaves exactly one server image and the stored `image_hash` equals the local sha256. Pinned in Task 6.
4. A list refresh/pull/bootstrap never erases or reverts an unsynced local create/edit/delete. Pinned in Tasks 3 and 7.
5. Merge-into-existing leaves no row in any table pointing at the dropped local id. Pinned in Task 8 (schema-grep test).
6. Deleting a never-sent create leaves no outbox row, image file, or pending upload behind. Pinned in Task 3/4/6.

---

### Task 1: Audit + `authedFor` dedupe (F6)

**Files:**
- Create: `docs/superpowers/plans/2026-11-17-phase3-audit.md` (report only)
- Modify: `lib/core/sync/sync_engine.dart` (the `_authed` / `authedFor` pair)
- Test: `test/core/sync/sync_engine_authed_test.dart` (create or extend the existing authed tests)

**Interfaces:**
- Produces: `Future<T> SyncEngine.authedFor<T>(String scope, Future<T> Function() call)` unchanged signature; `_authed` becomes a thin delegate so one refresh/scope-check implementation remains. Produces the audit doc used by Tasks 3-8.

- [ ] **Step 1:** Write the audit doc: (a) every caller of `saveProductsToCache`, `saveCategoriesToCache`, `saveVendors`, `deleteProductFromCache`, `removeVendorFromCache` and every REST call of the three entities (`grep`), with the screen/bloc that owns it; (b) every table with a column holding a product, category or vendor id (parse `offline_db.dart`, `SaleLocalStore.createTables`, `StockLocalStore`, inbound tables, `synced_assets`, outbox payload keys); (c) all add/edit/delete entry points (buttons, routes) for the three entities, and whether the add-product form carries an initial stock quantity.
- [ ] **Step 2:** Write `authedFor shares one refresh budget with _authed` test: a call that 401s `token_expired` once refreshes once and succeeds via both entry points; a second 401 does not refresh again. Run it; expected FAIL only if behavior differs, otherwise it pins current behavior (green) before the refactor.
- [ ] **Step 3:** Refactor so both entry points run the same private implementation; keep the scope check (`scopeProvider()==scope && readSessionKey()==scope`) after a refresh.
- [ ] **Step 4:** `flutter test test/core/sync` passes; analyzer count not above 73.

### Task 2: Outbox multi-dependency (DB v14)

**Files:**
- Modify: `lib/core/sync/sync_schema.dart` (add `depends_on_json TEXT` migration `addOutboxDependsOnList(db)`; backfill from `depends_on_entity_id`), `lib/core/offline/offline_db.dart` (`_dbVersion = 14`, v14 step + onCreate), `lib/core/sync/outbox/outbox_entry.dart`, `lib/core/sync/outbox/outbox_store.dart`, `lib/core/sync/local_writer.dart`, `lib/features/pos/domain/sale_service.dart`, `lib/features/inventory/domain/stock_service.dart`
- Test: `test/core/sync/outbox_dependencies_test.dart`, `test/core/offline/offline_db_v14_test.dart`

**Interfaces:**
- Produces: `OutboxEntry.dependsOn: List<String>` (replaces `dependsOnEntityId`; keep a read-only getter `dependsOnEntityId` => first or null only if existing tests need it, else delete). `WriteScope.enqueue({..., List<String> dependsOn = const []})`. `OutboxStore.openCreateIds(DatabaseExecutor txn, Iterable<String> ids, {required String scope}) -> Future<Set<String>>` (entity ids with an open `create`).
- Semantics: a row is `blocked` at enqueue while ANY id in `dependsOn` has an open create in the scope; `unblockDependents(entityId)` re-checks the remaining list and only flips to `pending` when none remain open; `failDependents` cascades as today and also fails later same-entity rows of the failed entity (see Task 5).

- [ ] **Step 1:** Write failing tests: `blocks while any dependency create is open`, `unblocks only when the last dependency is done` (3 deps, done one by one), `rejected dependency fails the dependent with dependency_failed`, `unknown or already-done dependency does not block`, `v14 migration backfills the single column into the list and is idempotent`.
- [ ] **Step 2:** Run them; expected FAIL (no `dependsOn`).
- [ ] **Step 3:** Implement the schema step, `OutboxEntry` JSON column mapping, `enqueue` via `openCreateIds`, `unblockDependents`/`failDependents` using `depends_on_json` (query with `LIKE` on the quoted id or a filter in Dart per scope; builder chooses, correctness first).
- [ ] **Step 4:** In `SaleService.create`, `StockService._op` and `createInbound`, compute `dependsOn` = product ids (non-custom lines) (+ vendor id for inbound) and pass it. Test `sale with line of product whose create is open is blocked, then pending after the create is done` and `custom lines add no dependency`.
- [ ] **Step 5:** Add the `retry`-ordering test to `test/core/sync/engine_*` style: product.create answered `retry` in batch 1, a sale referencing it is NOT in batch 2 until the create is `done` (Review Focus 1).
- [ ] **Step 6:** Full `flutter test test/core` green; analyzer <= 73.

### Task 3: Category and vendor services

**Files:**
- Create: `lib/features/category/domain/category_service.dart`, `lib/features/inventory/domain/vendor_service.dart`, `lib/core/sync/catalog_support.dart` (shared `CatalogValidationException`, `CatalogActor`, `canWriteCatalog`, `pendingMarker` queries)
- Modify: `lib/utilities/dependencies_provider.dart` (register both lazily, same `actor` source as `StockService`)
- Test: `test/features/category/category_service_test.dart`, `test/features/inventory/vendor_service_test.dart`

**Interfaces:**
- Produces: `class CatalogValidationException implements Exception { final String message; }`; `class CatalogActor { final AppBusinessType businessType; final AppUserRole role; }`; `bool CatalogActor.canWrite` (owner/manager).
- `CategoryService.create({required String name, String? parent, String? description}) -> Future<String>` (returns new id); `update(String id, EditCategoryRequestDto dto)`; `delete(String id)` (refused while active products or active children exist locally; never-sent create is dropped with its outbox rows in one txn, otherwise local row set inactive + enqueue `delete` with `baseVersion`). Payload = `AddCategoryRequestDto.toJson()` plus `id`.
- `VendorService.create(CreateVendorRequestDto) -> Future<String>`, `update(String id, UpdateVendorRequestDto)`, `delete(String id)` with the same rules. Payload = DTO `toJson()` plus `id`.
- `CatalogSupport.pendingEntityIds(DatabaseExecutor, String entity) -> Future<Set<String>>` (ids with open outbox rows, used by UI markers).
- `tables` constants: category `{'categories','products',outbox}`, vendor `{'vendors',outbox}`.

- [ ] **Step 1:** Failing tests per service: `cashier is refused and nothing is written`, `create writes the row (version null) and one create outbox row with the client id`, `update enqueues only changed fields with baseVersion`, `update of an unsent create is a second outbox row`, `delete of a never-sent create removes row and outbox rows`, `delete of a synced row marks inactive and enqueues delete`, `category delete refused with active products/children`, `duplicate name against local rows refused (vendors: none)`, `category product_count/category_name refreshed on rename`.
- [ ] **Step 2:** Run; expected FAIL.
- [ ] **Step 3:** Implement the services reusing applier derivations (extract the shared helpers `refreshCategoryProductCount`, `refreshProductsCategoryName` already in `applier_support.dart`). Category `create` with a parent whose create is open sets `dependsOn: [parent]`.
- [ ] **Step 4:** Test (Review Focus 4): bootstrap/pull applying a newer server row for an id with an open outbox row is deferred (existing `skipWhenLocalPending`), and the local edit remains.
- [ ] **Step 5:** Tests green, analyzer <= 73.

### Task 4: Product service (+ image staging)

**Files:**
- Create: `lib/features/products/domain/product_service.dart`, `lib/core/sync/images/pending_upload_store.dart`
- Modify: `lib/core/sync/sync_schema.dart` (v14: `pending_uploads` table), `lib/core/offline/offline_db.dart` (create in v14 + onCreate + wipe paths), `lib/utilities/dependencies_provider.dart`
- Test: `test/features/products/product_service_test.dart`, `test/core/sync/pending_upload_store_test.dart`

**Interfaces:**
- Consumes: Task 2 `dependsOn`, Task 3 `CatalogActor`/exception.
- Produces: `ProductService.create(AddProductRequestDto dto, {String? initialQuantity, String? shopId}) -> Future<String>`; `update(String id, UpdateProductRequestDto dto)`; `delete(String id)`. `dto.imageUpload` is staged, not sent. Payload = `dto.toJson()` + `id` + `image_pending: true` when an image was staged. `dependsOn` = the product's category when its create is open. Initial quantity (if the form has it) = a dependent `stock.add` (StockService, same transaction is NOT possible: two `LocalWriter.write` cannot nest, so ProductService performs both enqueues in its own write using `StockLocalStore` helpers; builder confirms with audit Task 1).
- `PendingUploadStore`: table `pending_uploads(entity TEXT, entity_id TEXT, local_path TEXT, sha256 TEXT, bytes INTEGER, state TEXT, attempts INTEGER, next_attempt_at TEXT, last_error TEXT, PRIMARY KEY(entity, entity_id))`; `stage(Transaction, {entity, entityId, File source}) -> Future<PendingUpload>` (copies bytes to `<appSupport>/pending_images/<entityId>`, computes sha256, generates 160 px thumbnail path), `replace` deletes the old file, `cancel(Transaction, entity, entityId)` deletes row + files, `due(DatabaseExecutor) -> Future<List<PendingUpload>>`.

- [ ] **Step 1:** Failing tests: `create with image stages a file, writes sha256 of the bytes and image_pending true`, `second pick replaces the row and deletes the old file`, `delete cancels the upload and removes files`, `cashier refused`, `price must be a decimal string`, `duplicate sku/barcode (including inactive local rows) refused`, `product.create depends on an open category create`, `update changing only price enqueues {price} with baseVersion`, `stock_level untouched by create/update`.
- [ ] **Step 2:** Run; FAIL.
- [ ] **Step 3:** Implement the store and service. Local row for a staged image points `thumbnail_url`/`image_url` at nothing; the image widget resolves the pending file by entity id (Task 6).
- [ ] **Step 4:** Tests green; analyzer <= 73.

### Task 5: Appliers' `onPushResult` + FakeSyncServer catalog

**Files:**
- Modify: `lib/core/sync/appliers/category_applier.dart`, `product_applier.dart`, `vendor_applier.dart`, `applier_support.dart`, `lib/core/sync/outbox/outbox_store.dart` (`failDependents` also fails later same-entity rows), `lib/core/sync/sync_schema.dart` + `offline_db.dart` (v14: `server_json TEXT` on categories/products/vendors, last server state for discard-restore), `test/core/sync/support/fake_sync_server.dart`
- Test: `test/core/sync/catalog_push_results_test.dart`, extend `test/core/sync/convergence_test.dart`

**Interfaces:**
- Produces: `onPushResult` behavior per spec table. Helper `Future<void> adoptServerRow(Transaction txn, String table, String id, PushResult r)` in `applier_support.dart` (writes `version`, replaces fields from `r.serverState` when present, stores `server_json`). Local rejection state is carried by the outbox row (`error_code`, `error_message`); conflict id is carried in the outbox row message payload via a new `error_entity_id` column or JSON in `error_message` (builder's call; Task 8 reads it).
- FakeSyncServer produces: catalog `create|update|delete` with `base_version`, unique SKU/barcode/name collisions -> `rejected conflict_unique` with `conflict_entity_id`, `entity_deleted` on update of a deleted row, `limit_exceeded` knob, `forbidden` for cashier actors, in-batch ordering, `dependency_failed` for dependents of a rejected create, `product = NULL` + `product_missing` for a sale line of an unknown product, `PUT image` idempotent by `X-Content-SHA256` (returns `image`, `thumbnail_url`, `version`, sets `image_hash`).

- [ ] **Step 1:** Failing tests: `applied adopts version and clears pending`, `duplicate behaves like applied`, `applied+merged replaces fields from server_state`, `conflict_unique leaves the local row and marks the outbox row rejected with conflict_entity_id`, `entity_deleted on update keeps local row inactive and rejected`, `forbidden / limit_exceeded / validation_error keep row with message`, `rejected create fails later edit and delete of the same entity with dependency_failed` (Review Focus 2), `rejected category create fails the product that depends on it`, `delete converges on entity_deleted` (engine already does).
- [ ] **Step 2:** Run; FAIL.
- [ ] **Step 3:** Implement; extend FakeSyncServer; add catalog actions (create, edit, delete, conflicting create) to the convergence test for 3 devices.
- [ ] **Step 4:** `flutter test test/core/sync` green; `CONV_SEEDS=200` once at the end of the task; analyzer <= 73.

### Task 6: ImageUploader + image widget

**Files:**
- Create: `lib/core/sync/images/image_uploader.dart`, `lib/core/sync/images/image_uploader_wiring.dart`
- Modify: `lib/core/sync/sync_engine.dart` or `sync_triggers.dart` (run after a push that is `completed`, foreground only, never in `background_sync.dart`), `lib/core/offline/presentation/widgets/offline_cached_image.dart`, `lib/core/sync/transport/*` (multipart PUT with `X-Content-SHA256`, `Idempotency-Key`, auth via the Task 1 authed helper)
- Test: `test/core/sync/image_uploader_test.dart`, `test/core/offline/offline_cached_image_pending_test.dart`

**Interfaces:**
- Produces: `ImageUploader.run() -> Future<ImageUploadReport>`; picks `PendingUploadStore.due` whose entity has no open outbox row; `PUT api/v1/products/<id>/image/` or `api/v1/products/categories/<id>/image/`, field `image`. On success: update row `image`/`thumbnail_url`/`version`/`image_hash = sha256`, `registerAsset`, delete upload row and staged file, notify `products`/`categories`/`synced_assets`. Error table: network/timeout/5xx -> backoff (reuse AssetSync constants), never give up; 400 `hash_mismatch` -> recompute from file, unreadable file => `failed`; 401 `token_expired` -> refresh once; 403/404/413 -> `failed` with message (retry from pending-sync screen); entity row gone -> cancel.
- `OfflineCachedImage` shows the pending staged file/thumbnail for an entity id with a `pending_uploads` row, before any `synced_assets` file.

- [ ] **Step 1:** Failing tests: `uploads after the create is done and not before`, `lost response then retry results in one server image and image_hash equals local sha256` (Review Focus 3, against FakeSyncServer), `network failure backs off and keeps the file`, `403 parks as failed`, `edit pending blocks upload until the update is done`, `entity deleted while waiting cancels upload and file`, widget shows the pending file.
- [ ] **Step 2:** Run; FAIL. **Step 3:** Implement. **Step 4:** Tests green, analyzer <= 73.

### Task 7: Repos and blocs go local-only; cashier entry points

**Files:**
- Modify: `lib/features/products/data/repository_impl/product_repo_impl.dart`, `lib/features/category/data/repository_impl/category_repo_impl.dart`, `lib/features/inventory/data/repository_impl/inventory_repo_impl.dart` (vendor methods), `lib/features/products/presentation/bloc/product_bloc.dart`, `lib/features/category/presentation/bloc/category_bloc.dart`, `lib/features/inventory/presentation/bloc/vendors_bloc.dart`, `lib/core/offline/data/offline_local_cache.dart` (delete REST writers; keep readers), the three form/list screens, `lib/features/products/presentation/product_detail_screen.dart`, plus any caller found in the Task 1 audit
- Test: `test/features/products/product_bloc_local_test.dart`, `test/features/category/category_bloc_local_test.dart`, `test/features/inventory/vendors_bloc_local_test.dart`

**Interfaces:**
- Consumes: Tasks 3-4 services, `DbChangeNotifier.watch`.
- Produces: repos call the services; blocs read SQLite pages (`getProducts({categoryId, search})` keyset/page from SQLite) and re-read on `products`/`categories`/`vendors`/`outbox`/`synced_assets` notifications; no REST list/get for these three; list rows expose `isPendingSync` / `syncFailed` derived from `CatalogSupport.pendingEntityIds` and rejected outbox rows. Inactive products hidden in pickers. Empty state while first setup runs uses the existing gate. Cashiers: add/edit/delete buttons hidden or disabled (list from audit).

- [ ] **Step 1:** Failing tests: `list shows an unsynced created product without any REST call`, `a pull/bootstrap does not erase or revert a pending edit` (Review Focus 4), `add product with image returns immediately offline and the row appears`, `delete hides the row at once`, `cashier sees no add/edit/delete`, `no REST catalog writer remains` (a test greps `lib/` for removed method names).
- [ ] **Step 2:** Run; FAIL. **Step 3:** Implement and delete the legacy writers. **Step 4:** Full `flutter test` green; analyzer <= 73.

### Task 8: Pending-sync screen: conflict actions, discard, merge

**Files:**
- Create: `lib/features/sync/domain/catalog_conflict_service.dart`
- Modify: `lib/features/sync/presentation/pending_sync_outbox_view.dart`, `bloc/pending_sync_bloc.dart`, `bloc/pending_sync_event.dart`, `bloc/pending_sync_state.dart`, `lib/core/sync/outbox/outbox_store.dart` (discard of catalog rows), l10n `en` + `ar` strings
- Test: `test/features/sync/catalog_conflict_service_test.dart`, `test/features/sync/pending_sync_catalog_test.dart`

**Interfaces:**
- Produces: `CatalogConflictService.mergeInto(String localId, String serverId, {required String entity}) -> Future<MergeReport>` (one `LocalWriter.write`; rewrites the id in every table found by the Task 1 audit, open outbox payloads/`depends_on_json`, `pending_uploads`; drops the rejected create; returns affected-row counts for the confirmation dialog). `Future<void> discardRejected(String mutationId)`: rejected create -> delete local row + staged files; rejected update/delete -> restore from `server_json` (row flagged stale until the next pull when absent). Merge offered only when the rejected row carries `conflict_entity_id`.
- Screen: shows the entity label, server message, `Edit and retry` (reopens the form with the local row, re-enqueues), `Merge into existing` (confirmation with counts), `Discard`.

- [ ] **Step 1:** Failing tests: `merge rewrites product id in stock, sale_items, inbound lines, outbox payloads, depends_on, pending_uploads and leaves no row with the old id` (Review Focus 5: a test that enumerates every table with a column in the audit list and fails if one is not covered), `merge is atomic (a failure mid-way changes nothing)`, `merge hidden without conflict_entity_id`, `discard rejected create removes row/outbox/files` (Review Focus 6), `discard rejected update restores server_json`, `dependents of a discarded create stay failed`.
- [ ] **Step 2:** Run; FAIL. **Step 3:** Implement. **Step 4:** Tests green; the dialog is a standard Nile Ledger confirm (no new full screen).

### Task 9: Lifecycle, docs, BE_GAPS

**Files:**
- Create: `test/features/lifecycle/catalog_lifecycle_test.dart`
- Modify: `docs/offline.md`, `docs/BE_GAPS.md`, `docs/superpowers/specs/2026-11-17-phase3-catalog-writes-design.md` (status)

- [ ] **Step 1:** Lifecycle test (FakeSyncServer): offline day = create category + product with image + vendor, sell the new product, edit price, delete a vendor; reconnect -> everything `done`, server has one image, sale line has the product, counts/stock correct; second device pulls all of it; conflicting SKU on two devices ends `rejected conflict_unique` with Merge available, merge then converges.
- [ ] **Step 2:** Update `docs/offline.md` (Phase 3 section, files, how-to) and add BE_GAPS follow-ups: `image_pending` accepted/echoed on create; `PUT image` honours `Idempotency-Key` and returns `version`; `conflict_entity_id` for category/vendor name collisions; cashier catalog rule difference; category delete rule (protected vs cascade).
- [ ] **Step 3:** Run the full suite once, `flutter analyze` (<= 73), `CONV_SEEDS=200` once. Report totals. Final whole-branch review and one `/code-review` run happen after this task (user rule).
