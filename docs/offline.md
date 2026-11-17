# Offline-First System

## Overview

The app is designed to work fully offline after the first online session.
SQLite (`sqflite`) stores the catalog (business, shops, categories, products,
customers, vendors, stock), sales, refunds and images locally. Since Phase 2
the sync core (`lib/core/sync/`) is the ONLY way server data enters the
device: a resumable paged first setup (bootstrap), a pull applier for every
feed entity, and images downloaded by change token. Local writes (sales,
stock edits, inbound) go through the outbox and sync when the device is back
online. Catalog screens (products, categories, vendors) read SQLite only
and write through the outbox since Phase 3; other REST-refreshing blocs
still write some legacy tables (Phases 4-5 retire them).

## Files

```
lib/core/offline/
├── offline_db.dart                    ← SQLite DB singleton (OfflineDb.instance), schema v14
├── offline_constants.dart             ← table name constants
├── data/
│   └── offline_local_cache.dart       ← legacy-shaped reads (+ a few non-catalog REST writers)
└── presentation/
    ├── first_setup_screen.dart        ← blocking first-setup screen (Nile Ledger)
    ├── bloc/
    │   ├── first_setup_status.dart    ← FirstSetupStatus.derive (readiness rule)
    │   ├── offline_status_bloc.dart
    │   ├── offline_status_event.dart
    │   └── offline_status_state.dart
    └── widgets/
        ├── offline_cached_image.dart  ← synced_assets file, else network
        └── offline_hero.dart

lib/core/network/
└── network_monitor.dart               ← wraps connectivity_plus, emits bool stream

lib/core/sync/                         ← sync core (see "Sync core" below)
├── bootstrap/bootstrapper.dart        ← resumable paged first setup
├── bootstrap/bootstrap_controller.dart← what the first-setup UI reads
├── assets/asset_sync.dart             ← image download by change token
├── assets/asset_sync_wiring.dart      ← shared AssetSync construction (app + worker)
└── appliers/*_applier.dart            ← one ChangeApplier per feed entity
```

Removed in Phase 2 (Task 12): `OfflineFirstManager`, `OfflineAssetDownloader`,
`OfflineRemoteDataSource` (`GET offline/bootstrap/`, `GET
offline/assets/manifest/`), their DTOs (`OfflineBootstrapDto`,
`OfflineAssetManifestDto`, `OfflineAssetRecord`), `saveBootstrap`,
`saveAssetManifest*`, the asset-manifest helpers, `hasBootstrapCache`,
`OfflineDb.clearBootstrapCache/setMetadata/getMetadata`, the legacy
preparing-offline screen (`preparing_offline_screen.dart`,
`preparation_steps.dart`, `footer_status.dart`) and the never-set state
fields (`assetStatus`, `lastBootstrapSyncAt`, `lastAssetSyncAt`). DB v13
drops the `offline_assets` and `sync_metadata` tables.

## NetworkMonitor

```dart
// Check current status:
final bool isOnline = await networkMonitor.isOnline;

// Subscribe to changes:
networkMonitor.onStatusChanged  // Stream<bool>
networkMonitor.start()          // starts the connectivity_plus subscription
```

Detects: `mobile`, `wifi`, `ethernet`, `vpn`.

## OfflineLocalCache

Reads the cache tables in the legacy DTO shapes (the appliers write those
shapes). Wraps `OfflineDb`. Phase 3 removed every REST catalog writer
(`saveProductsToCache`, `saveCategoriesToCache`, `saveVendors`,
`removeVendorFromCache`, `deleteProductFromCache`); a test greps `lib/` so
none comes back (`test/features/catalog/no_rest_catalog_writer_test.dart`).

Key methods:
```dart
Future<void> clearAllOnLogout()      // catalog wipe + every scope's setup keys
Future<List<BusinessData>> getBusinesses()
Future<List<ShopData>> getShops()
Future<List<CategoryData>> getCategories()             // inactive hidden
Future<List<ProductData>> getProducts({String? categoryId, String? search,
    bool? isActive})                                  // null all, true active
Future<CatalogSyncMarks> getCatalogSyncMarks(String entity)  // row markers
Future<List<StockData>> getStock({String? shopId})
Future<List<VendorData>> getVendors()                  // active only
Future<String?> getSyncedAssetPathByUrl(String? url)   // image widget
```

## OfflineStatusBloc

Singleton in GetIt. Provided at root via `BlocProvider(create: (_) => getIt<OfflineStatusBloc>())`.
Constructor: `networkMonitor`, `outboxUnsyncedCount`, `firstSetup`
(`BootstrapController` provider; null = kill switch).

### State (`OfflineStatusState`)

```dart
OfflineConnectionStatus connectionStatus  // unknown | online | offline
OfflineBootstrapStatus  bootstrapStatus   // legacy mirror of setupStatus
OfflineSalesSyncStatus  salesSyncStatus   // idle | syncing | success | failure
bool    hasCache            // = tenant bootstrapped (legacy name)
bool    canUseAppOffline    // = tenant bootstrapped (legacy name)
int     pendingSalesCount
DateTime? lastSalesSyncAt
String? errorMessage
FirstSetupStatus setupStatus  // checking | required | running(entity, index,
                              // count, rowsApplied) | blockedOffline |
                              // blockedServer | done  (the readiness gate)
bool    setupRefreshing       // bootstrapped scope re-downloading (non-blocking)

// Derived:
bool get isOnline
bool get isOffline
bool get isBusy
bool get hasFailure
```

### Events

| Event | Who dispatches it |
|---|---|
| `OnOfflineStatusStarted` | `AuthBloc._onLoadBusinessEvent` (after business loads) |
| `OnOfflineStatusRefreshRequested` | First-setup retry -> `BootstrapController.retry()` |
| `OnOfflineStatusSyncSalesRequested` | Manual refresh of the unsynced outbox count |
| `OnOfflineConnectionChanged(isOnline)` | Internally from `NetworkMonitor` stream |
| `OnOfflinePendingSalesCountChanged(count)` | After a connection change (outbox count) |
| `OnOfflineStatusResetRequested` | Logout |

### `_onStarted` Logic

```
BootstrapController (null = kill switch -> done, never blocks)
├── isTenantBootstrapped(live tenant) → done (hasCache = canUseAppOffline = true)
├── bootstrapper running              → running(entity, N of M, rows)
├── offline                           → blockedOffline
├── serverNotReady / gate refused     → blockedServer
└── otherwise                         → required (triggers start the run)
```
Progress events (`Bootstrapper.status`) re-derive it; a run outcome re-reads
the `bootstrapped` flag.

### `_onConnectionChanged` Logic

Updates `connectionStatus`, re-derives `setupStatus` (the sync triggers
retry the bootstrap on connectivity regained) and, when online,
`unawaited(_backgroundSyncSales())` refreshes the unsynced outbox count.
There is no network-reconnect bootstrap of its own any more (the legacy
`OfflineFirstManager` watcher is gone; `SyncTriggers` owns reconnects).

**Does NOT re-trigger `AuthBloc`.** If business failed to load while offline, that is handled by a listener in `OfflinePreparationListener` (Fix 1).

## Pending sales count and logout gate

`OfflineStatusBloc` takes `outboxUnsyncedCount` (`OutboxStore.unsyncedCount()`,
every scope, rejected included). `pendingSalesCount` and the logout gate
(`blockingPendingOfflineSalesCount`) are exactly that count. The legacy
`SyncManager` / `OfflineSalesQueue` / `OfflineInboundQueue` and their tables
(`pending_sales`, `pending_sale_items`, `pending_inbound_transactions`) were
removed in Phase 1 (DB v10 drops the tables; zero production users, nothing
migrated).

## First setup, pull and assets (Phase 2)

Spec: `docs/superpowers/specs/2026-11-16-phase2-bootstrap-pull-assets-design.md`;
plan and legacy audit: `docs/superpowers/plans/2026-11-16-phase2-*.md`. BE
contract (read only): `amanaPOS-be/docs/sync-contract.md` (`GET
sync/bootstrap/`).

### Flow (first launch online)

```
SplashBloc → authenticated
  → AuthBloc.add(OnLoadProfileEvent) → profile → OnLoadBusinessEvent
    → business loaded (REST: `businesses` stays the REST inserter)
    → SyncCoordinator: session ready (scope userId|tenantId) → SyncTriggers.start()
      → engine: ping → push → no cursor → needsBootstrap
        → Bootstrapper.run() (foreground only, same run, same sync_lock)
          → final txn: cursor = snapshot_cursor + `bootstrapped` + progress cleared
        → engine runs once more: pull from snapshot_cursor
        → AssetSync.run() (fire-and-forget, never blocks)
    → offlineStatusBloc.add(OnOfflineStatusStarted)
      → BootstrapController.isTenantBootstrapped() + Bootstrapper.status
      → state.setupStatus (FirstSetupStatus.derive)
OfflinePreparationListener: setupStatus.blocksApp + business present
  → FirstSetupScreen (blocking, step list, "Step N of M", rows, retry,
    "Internet is required only for first setup", sign out)
  → closes on `done` (final bootstrap txn committed; images never block)
```

### Bootstrapper (`lib/core/sync/bootstrap/bootstrapper.dart`)

* Gate: server capability `bootstrap_paged` (plus `push`, `pull`). Missing =
  `blocked` with `serverNotReady` ("server not ready" on the screen), never a
  legacy fallback. App resume retries that block; other blocks (token,
  account) only by a manual retry or a new session.
* Outcomes: `completed`, `interrupted` (offline / timeout / 5xx / cancel /
  session switch; `offline: true` when unreachable; never logs out),
  `blocked`, `alreadyRunning` (another runner holds `sync_lock`),
  `notNeeded`. `BootstrapStatus` (stream) carries `scope`, `currentEntity`,
  `entityIndex`/`entityCount`, `rowsApplied`, `offline`, `block`.
* Manifest once per bootstrap: snapshot cursor + entity list are stored in
  the scoped `bootstrap_progress` key; a resume reuses them (never a new
  snapshot mid-bootstrap). Client entity order is fixed: `business, shop,
  category, product, vendor, customer, user, subscription, bankak_account,
  stock, expiry_batch, sale, refund, inbound, notification`; entities the
  manifest does not list (cashier) are skipped, unknown names logged and
  skipped. Page size 500 (sale 200), `sales_since` fixed 90 days.
* Each page = ONE SQLite transaction: every item becomes a synthetic upsert
  `PullChange(seq: 0, op: 'upsert', id, version, data: item)` through the
  SAME `ChangeApplier` pull uses, honoring `skipWhenLocalPending` (deferred
  into `deferred_pull`, kept by the final txn) and `localVersion` (never
  rolls back); then the page cursor / done set advance in the same txn.
  Kill/offline/token loss at any point resumes at the stored page cursor
  with no duplicate or lost rows. A session switch aborts quietly
  (`assertScope` inside the page txn rolls the page back).
* `snapshot_cursor` rule: the pull cursor is set (= stored snapshot) ONLY by
  the final transaction, together with `bootstrapped = true` and the
  progress removal. Rows written on the server during the bootstrap arrive
  by the following pull. The BE does not validate the snapshot in
  `bootstrap_page`; a stale snapshot is detected by the first pull
  (`full_resync_required`), which restarts the bootstrap (a second one right
  after a completed bootstrap backs off instead of looping).
* No stale-row deletion in Phase 2: rows not seen in a bootstrap stay until
  a later `delete` change or `full_resync_required` (documented limitation;
  role changes for the same user do not re-bootstrap).

### `bootstrapped` flag and readiness

* Scoped `sync_state` keys: `cursor`, `bootstrap_progress`, `bootstrapped`,
  `bootstrap_completed_at`, `deferred_pull` (per `userId|tenantId`).
  `device_id` and `sync_lock` are global.
* Engine "bootstrap needed" = no cursor OR not `bootstrapped` for the scope.
* `full_resync_required` clears the cursor and old progress but KEEPS
  `bootstrapped`: the app stays usable from local data and the re-download
  is a non-blocking refresh (`setupRefreshing`, small indicator only).
* UI gate is per TENANT (ruling T11-a): `done` when ANY scope of the signed-in
  tenant is bootstrapped on this device (catalog tables are shared by the
  tenant's users), so a shift change without internet never stops sales.
  The new user's own bootstrap still runs, non-blocking, when online; the
  engine never pulls for that user before it finishes (no cursor).
* Data exposure note: until a new user's own bootstrap finishes, they see
  the tenant's catalog as previously pulled by another user of the SAME
  tenant on this device; it may include rows their own feed would hide
  (other shops' stock, vendors, customers for a cashier). Screens filter by
  shop; Phase 2 does not delete out-of-scope rows. Never another tenant's
  rows (wipe on business switch, shop/tenant filters).
* Wipe pairing (ruling T1-d): `clearAllOnLogout` (logout / business switch)
  and `OfflineDb.clearAllLocalOfflineData` delete the catalog tables AND, in
  the same transaction, every scope's cursor, `bootstrapped`, bootstrap
  progress and completion time (`SyncStateStore.resetSetupOfAllScopes`), so
  a re-login sets up again instead of pulling on top of an empty catalog.
  They NEVER delete the outbox, `deferred_pull`, `sales` (+ items/payments)
  or `sale_refunds` (ruling T5-a: sales are never wiped and the cursor
  resumes per scope; wiping refunds alone would overstate net sales). Logout
  stops the triggers (and cancels a bootstrap) BEFORE the wipe
  (`DependenciesProvider.pauseSyncForWipe`).
* Kill switch (`SYNC_ENGINE=false`): no controller, readiness never blocks,
  and there is NO data path for the catalog any more (the legacy bulk
  bootstrap is gone): a flag-off build only shows what REST-refreshing
  screens cache. Accepted; the flag is an emergency switch, not a mode.

### Pull appliers

`buildSyncAppliers()` (`lib/core/sync/sync_appliers.dart`) registers one
applier per feed entity: `business` (merge-only into an existing
`businesses` row + `synced_entities`), `shop` (`business_id` = scope
tenant), `category`, `product` (derives `category_name`, `stock_level`,
category `product_count`), `customer`, `vendor`, `stock` (derives
`product_name`, `product_sku`, `shop_name`, `is_low_stock`), `expiry_batch`,
`sale`, `refund` (`sale_refunds`), `inbound` (derives `vendor_name`,
`shop_name`, `created_by_name`), `user`, `subscription`, `notification`,
`bankak_account` (`synced_entities`). Bootstrap and pull share them.

* `is_low_stock` follows the BE (`StockLevel.is_low_stock`, what REST rows
  carry): `quantity <= min_stock_level`, so an out-of-stock row is also low
  (screens check `is_out_of_stock` first where they tell them apart).
* Derived names (stock/inbound `product_name`, `shop_name`, `vendor_name`,
  ...) are computed when the row is written: they stay stale after a rename
  until that row is rewritten (known limitation).

### Assets (images) by change token

* Table `synced_assets(type, id, variant thumb|full, url, expected_hash,
  local_path, local_hash, bytes, state, attempts, next_attempt_at)`, files in
  `<appSupport>/synced_assets` (`as_*`). The legacy `offline_assets` table
  and downloader are gone (v13); logout also deletes a leftover legacy
  `offline_assets` folder.
* Appliers register images with `registerAsset(txn, type, id, variant, url,
  expectedHash)` / `registerRowAssets` (`applier_support.dart`) from the feed
  row's `thumbnail_url` / `image` / `image_hash`. `expected_hash` is the
  feed `image_hash` used as a CHANGE TOKEN only (ruling T1-a: the BE hash is
  of the UPLOADED bytes but serves re-processed WebP, so a download can never
  match it). A changed token marks the asset stale; the old file stays until
  the new one is verified.
* `AssetSync.run({maxFiles: 40, maxBytes: 20 MB, thumbnailsOnly})`: thumbs
  first, concurrency 2, download to a temp file, verify (HTTP 200, non-empty,
  image magic bytes + trailer, size == Content-Length when present), atomic
  rename, then `local_path/local_hash`. Failures keep the old file and back
  off exponentially (1 min .. 24 h); network/5xx never give up; an empty
  token (legacy BE rows) downloads once keyed by url (`nohash`) and gives up
  when a content failure (4xx, not an image, size mismatch) brings its
  attempts to 5 (attempts also count earlier transient failures). 401/403 from the BE host skip the run without
  counting. Auth headers only for the BE host. Orphans swept after a grace.
* Triggers: after a run that ends `completed`, once after a bootstrap
  `completed`, and on app resume, only while the server answers;
  fire-and-forget, never changes a sync outcome.
* `OfflineCachedImage` shows the `synced_assets` file for the url (query
  `?v=` ignored, exact match first, then the newest row; any row whose file
  exists, so a pending re-download still shows the previous image), else
  `Image.network` exactly as before. It re-resolves on `synced_assets`
  notifications. No legacy lookup remains.

### Background worker rules

The OS worker NEVER bootstraps: `needsBootstrap` is reported as success
after the push half (the bootstrap is a foreground job, 25 s budget). After
a `completed` sync it may run `AssetSync.run(thumbnailsOnly: true)` inside
the same budget. It uses the same appliers (`buildSyncAppliers()`).

### Dev devices

Devices that ran an earlier v11/v12 development build must REINSTALL (the
v11 step was extended in place before release, e.g. `sale_refunds`; zero
production users, nothing is migrated).

## Catalog writes (Phase 3)

Spec: `docs/superpowers/specs/2026-11-17-phase3-catalog-writes-design.md`
(audit: `docs/superpowers/plans/2026-11-17-phase3-audit.md`). Owners and
managers create, edit and delete categories, products and vendors with no
connection; cashiers see no entry point and the services refuse them
(`CatalogValidationException`).

### Flow

1. A form calls the bloc -> use case -> repo -> `CategoryService` /
   `ProductService` / `VendorService`. One `LocalWriter.write`: the row
   (client UUID v4, money as strings) + its outbox row (`create`, `update`
   with `base_version`, `delete`). A product create with an opening
   quantity also enqueues a dependent `stock.add`; "General" is created in
   the same write when no category was picked.
2. A picked image is copied and hashed outside the transaction, staged in
   `pending_uploads` inside it, shown at once from the local file, and sent
   by the foreground `ImageUploader` once the row's own outbox rows are
   done (create first, then `PUT .../image/`). An image-only edit enqueues
   nothing: `SyncTriggers` starts the upload from the `pending_uploads`
   notification.
3. Anything naming an unsent create (a product's category, a sale line,
   stock / inbound lines) waits `blocked` (`depends_on_json`) until that
   create is `done`; a rejected create fails them (`dependency_failed`).
4. Lists (`ProductBloc`, `CategoryBloc`, `VendorsBloc`) read SQLite only and
   re-read on `DbChangeNotifier` (`ProductBloc`: an outbox / upload-only
   notify re-reads only the sync markers, review M10; a products,
   categories, stock or synced_assets notify re-reads the list);
   the markers count only the signed-in scope's rows (review M6); a pull never overwrites a row with an
   open local change (`skipWhenLocalPending`). Pull to refresh re-reads and
   calls `SyncTriggers.syncNow()` (fire and forget, `requestCatalogSync`).
5. Push results: see "Catalog push results" below. A rejected row stays
   local and shows "Sync failed" on its list row and on the pending-sync
   screen.
6. The open POS cart (fix-wave I2): `PosBloc` re-checks its product lines
   on every `products` notify and at checkout
   (`SaleService.unavailableProductIds`: no local row, or `is_active`
   false). Gone lines are dropped with a localized notice
   (`posItemsUnavailable`); `SaleService.createSale` refuses them too
   (`SaleProductUnavailableException`, nothing written), so a sale never
   reaches the BE naming a product a merge, a discard or a dropped create
   removed.
7. Logout (review M1): `clearAllOnLogout` wipes the catalog tables but
   first stashes every catalog row with an open outbox row (plus a
   product's stock rows) per scope in `sync_state`
   (`catalog_stash|<scope>`, `CatalogStash`). The same scope's next
   bootstrap restores them in its final commit where it wrote no row (a
   server row always wins); another account never sees them.

### Pending-sync screen: conflicts, discard, merge (Task 8)

`CatalogConflictService` (`lib/features/sync/domain/catalog_conflict_service.dart`),
used by `PendingSyncBloc` for rows whose entity is product / category /
vendor. Conflict policy A: nothing is rewritten automatically.

- **Edit and retry** (a rejected create / update that the server refused
  itself, not a `dependency_failed` cascade): opens the entity's normal
  form (`openCatalogEditor`, no new screen). When the form saved an edit,
  `editAndRetry` folds the queued `update` rows into the rejected row
  (later fields win, dependencies merged), removes them and queues the row
  again (`OutboxStore.retryRejectedIn`, which also revives the rows it
  failed). Closing the form without saving changes nothing. A product SKU
  cannot be edited (immutable): a SKU conflict is resolved by merge or
  discard.
- **Merge into existing**: offered only when the rejected create carries
  `conflict_entity_id` (`error_entity_id`; today products only, BE_GAPS).
  The screen shows a standard confirm with the count of records that will
  point at the existing item (`previewMerge`: the real merge in a rolled
  back transaction). `mergeInto` is ONE `LocalWriter.write`: the local
  entity's outbox rows are dropped, every other outbox row's payload (any
  JSON path), `depends_on_json` and legacy `depends_on_entity_id` are
  rewritten (`OutboxStore.rekeyForMerge`), the rows the rejected create had
  failed or blocked go back to the queue, and every audited table is
  rewritten: `products.category_id`, `categories.parent_id`, `stock`
  (rows folded into the existing product's row, recomputed: the copy's
  opening stock and other queued stock changes ADD to the existing
  product's stock), `sale_items.product_id`, `synced_assets` (dropped),
  `outbox.failed_by_entity_id`, and the JSON columns listed in
  `CatalogConflictService.jsonColumns`. The copy's own queued edits are
  dropped, and so is its staged image (row and file; fix-wave ruling): it
  never replaces the existing product's server image, and an image already
  staged for the existing row stays queued. The confirm dialog says all
  three, plus a warning when the existing row is inactive (deleted on the
  server; `MergeReport.targetInactive`, review M2). After a merge the bloc
  starts a sync, so an existing row that was not pulled yet (the copy
  stands in under its id with no version) gets its server state at once
  (review M4). The local row is deleted, or takes the server id with no
  version when the server row is not pulled yet. Deliberately NOT
  rewritten: `sale_refunds.json` (raw feed, server ids only) and
  `sales.warnings_json` (display history). The schema-grep test fails when
  a new column that can hold a catalog id is added without being covered.
- **Discard** (`discardRejected`): ruling R7 applies here too (fix-wave
  I3). A catalog create that anything waits on (outbox rows listing it in
  `depends_on`, in any open status, including rows already failed
  `dependency_failed` by its rejection; for a category also its active
  local products and child categories) is NOT discarded:
  `DiscardOutcome.hasDependents`, and the screen does not offer Discard
  for it (`PendingSyncRow.dependents` / `canDiscard`, with a localized
  hint: merge it, or edit and retry). The opening `stock.add` written with
  a product create (the row right after it, `seq + 1`) is part of the
  create, not a dependent. A create claimed by a sync run and never
  answered (`claimed_at` set, not `rejected`) may already be on the
  server: `DiscardOutcome.mayBeOnServer` (review M8; "Send now" settles
  it). Otherwise a create removes every open row of the entity and its
  opening stock, deletes the local row, its stock rows, image
  registrations and staged image (files after the commit). With no
  signed-in scope nothing is discarded (review M6). An update / delete restores the row from `server_json` with any
  later queued edit re-applied on top; a field only the discarded change
  set is cleared. With no stored server state the row is kept and marked
  `local_stale: true` until the next pulled version replaces it. A row
  being sent (`inflight` / leased) is never discarded.
- **Retry of a row naming a gone item** (T5 I4): a rejected row whose
  `depends_on` names an id with no create row and no local product /
  category / vendor row (`CatalogSupport.goneDependencies`) is flagged on
  the screen; its Retry asks first (sent, the BE keeps it without that
  link: a sale keeps its money, not its product / stock), and "Retry all"
  skips it.
- **Edit and retry on a rejected UPDATE** (review M5, T8/9 concern 4): the
  user's edit may already have been claimed or sent on its own (a rejected
  update does not hold later edits). It still counts as saved; its fields
  are removed from the rejected row before it is queued again, so an old
  rejected value (a price) is never resent over the new one; a rejected
  row left with no field is deleted.
- A row whose local copy is marked `local_stale` says so ("replaced at the
  next sync", T8/9 concern 5).
- **Failed image uploads** (403 / 404 / 413 / unreadable file) are listed
  with Retry (`ImageUploader.retryFailed`); the notification starts the
  upload run.

### Files

```
lib/features/category/domain/category_service.dart
lib/features/products/domain/product_service.dart
lib/features/inventory/domain/vendor_service.dart
lib/core/sync/catalog_support.dart        ← CatalogActor, CatalogValidationException, helpers
lib/core/sync/catalog_sync_marks.dart     ← "waiting to sync" / "sync failed" markers
lib/core/sync/catalog_refresh.dart        ← pull to refresh -> syncNow
lib/core/sync/catalog_stash.dart          ← logout stash / bootstrap restore of unsynced catalog rows (M1)
lib/core/sync/images/                     ← PendingUploadStore, ImageUploader, resolver
lib/features/sync/domain/catalog_conflict_service.dart
lib/features/sync/presentation/widgets/catalog_editor.dart
```

### How to

- **Add a column that holds a product / category / vendor id**: add it to
  `CatalogConflictService.idColumns` (real column) or `jsonColumns` (JSON)
  and handle it in `_merge`; the schema-grep test in
  `catalog_conflict_service_test.dart` fails until you do.
- **Resolve a stuck catalog row by hand**: Pending sync screen -> the row ->
  Edit and retry / Merge into existing / Discard.
- **Run the Phase 3 tests**: `flutter test test/features/sync
  test/features/lifecycle/catalog_lifecycle_test.dart test/core/sync`.

## Offline-First Data Pattern in Blocs

Catalog blocs (`ProductBloc`, `CategoryBloc`, `VendorsBloc`, Phase 3 Task 7)
never call REST:

- Reads: SQLite through `OfflineLocalCache` (lists active rows only; the
  whole catalog, no paging), plus `CatalogSyncMarks` for the row markers.
- Re-read: each bloc listens to `DbChangeNotifier.changes` and re-reads
  (16 ms debounce, an overtaken read is dropped) when a local write or a
  pull touches its `watchedTables` (products/categories/stock/outbox/
  pending_uploads/synced_assets; vendors/outbox).
- Writes: use case -> repo -> `ProductService` / `CategoryService` /
  `VendorService` (row + outbox in one `LocalWriter.write`), then a re-read,
  then `submitStatus: success`. A refusal (`CatalogValidationException`,
  e.g. cashier, duplicate barcode) is `submitError` and nothing is written.
- Add product: the auto "General" category (`newCategoryName`) and the
  opening stock (dependent `stock.add`) are in the SAME write as the
  product create. A delete hides the row at once (`is_active: false`).
- Category images are staged like product images (`CategoryService`
  takes the `PendingUploadStore`; the form reuses `FormPhotoTile`,
  `CategoryThumb` shows the staged file first).
- Markers: `CatalogSyncPill` ("Not synced" = open outbox row or waiting
  upload; "Sync failed" = rejected outbox row or failed upload).
- Cashiers (`AppPermissions.canEditCatalog` false) see no add/edit/delete
  entry point (products list + swipe, product detail, categories list +
  swipe, category detail, vendors sheet); the services refuse them too.
- First setup: the existing `FirstSetupScreen` gate covers these screens.
- A pull never erases or reverts a pending local edit (appliers'
  `skipWhenLocalPending` defers it), pinned end to end by
  `catalog_pull_keeps_local_edit_test`.

---

## Sync core (offline-first, Phase 0)

Outbox-based sync core under `lib/core/sync/`. It is **on by default** and is
the ONLY write path for sales, stock edits and inbound receipts
(`SaleService`, `StockService`, through `LocalWriter`). The kill switch
`--dart-define=SYNC_ENGINE=false` only stops the engine, its triggers and the
background worker: local saves still land in the outbox (and sync later). Spec: `docs/superpowers/specs/2026-11-16-offline-first-sync-design.md`.
Backend contract (read-only): `amanaPOS-be/docs/sync-contract.md` and
`sync-contract-deviations.md`.

### Files

```
lib/core/sync/
├── sync_flags.dart              ← kSyncEngineEnabled (SYNC_ENGINE), required capabilities
├── sync_schema.dart             ← outbox + sync_state tables (DB v6)
├── db_change_notifier.dart      ← "tables changed" broadcast + debounced watch()
├── local_writer.dart            ← THE write path: rows + outbox in one transaction
├── outbox/outbox_store.dart     ← enqueue / claim / results / counts
├── outbox/outbox_entry.dart
├── change_applier.dart          ← per-entity server -> local writer + registry
├── sync_state_store.dart        ← cursor, device id, capabilities, lock, skew
├── reachability.dart            ← "does my server answer?" (sync/ping)
├── sync_engine.dart             ← ping -> push -> pull, single flight, backoff
├── sync_triggers.dart           ← WHEN to run (resume, connectivity, writes, periodic, manual)
├── sync_token_refresher.dart    ← refresh for sync; never logs out
├── sync_session_guard.dart      ← engine status -> needsLogin / accountDisabled / deviceRevoked
├── sync_device_registrar.dart   ← best-effort POST sync/devices/
├── sync_coordinator.dart        ← app glue: AuthBloc session + lifecycle -> triggers
├── sync_appliers.dart           ← buildSyncAppliers(): the one applier list (app + worker)
├── deferred_pull.dart           ← pulled changes waiting for unsynced local rows
├── appliers/                    ← one ChangeApplier per feed entity (+ applier_support.dart)
├── bootstrap/                   ← Bootstrapper (paged first setup) + BootstrapController (UI)
├── assets/                      ← AssetSync (images by change token) + wiring
├── background/                  ← OS worker (never bootstraps)
├── contract/sync_contract.dart  ← wire DTOs (incl. BootstrapManifest / BootstrapPage)
└── transport/                   ← SyncTransport, HttpSyncTransport (own Dio), auth headers
```

### Architecture

```
 UI / Bloc / Repository
        │  LocalWriter.write(tables, body)        (one SQLite transaction)
        ▼
 ┌──────────────────────────────┐   notify(tables + outbox)   ┌────────────────┐
 │ local tables  +  outbox rows │ ─────────────────────────▶  │ DbChangeNotifier│──▶ watch() queries (UI)
 └──────────────────────────────┘                             └───────┬────────┘
                                                                      │ outbox changed (5 s window)
 NetworkMonitor (false→true) ─┐                                       ▼
 App resume / periodic 5 min ─┼────────────────────────────▶  SyncTriggers ── gate: token + ping caps {push,pull}
 Manual syncNow ──────────────┘                                       │ (coalesced, backoff-aware)
                                                                      ▼
                                                                 SyncEngine
              ping (ServerReachability) → push batches (≤100) → pull pages (500) → cursor
                       │ 401 token_expired → SyncTokenRefresher (refreshed | rejected | transient)
                       │ results / changes → ChangeApplierRegistry → local tables (inside txn)
                       ▼
                 status stream ──▶ SyncSessionGuard ──▶ SyncCoordinator ──▶ existing forced logout
                                                                            (data and outbox KEPT)
```

### Write path

Every local change that must reach the server goes through `LocalWriter`:

```dart
await getIt<LocalWriter>().write(
  tables: {'products'},
  body: (scope) async {
    await scope.txn.update('products', {...}, where: 'id = ?', whereArgs: [id]);
    await scope.enqueue(
      entity: 'product',
      op: 'update',
      entityId: id,
      payload: {'name': name, 'price': '12.50'}, // money as STRINGS
      baseVersion: localVersion,                  // versioned entities
    );
  },
);
```

Row writes and the outbox row commit or roll back together; listeners are
notified only after commit. Never call `LocalWriter.write` inside another
`write` (it throws), and never touch `OfflineDb.database` inside `body`: use
`scope.txn` (sqflite would deadlock).

### Outbox and engine

* Outbox statuses: `pending`, `inflight` (claimed under a lease), `blocked`
  (waiting for a dependency's create), `rejected` (needs user action), `done`.
* The engine is single flight (in-process flag + `sync_lock` DB lease), pushes
  in batches of 100, matches results by `mutation_id`, writes each batch's
  results in one transaction, applies each pull page plus its cursor in one
  transaction, and never orders by wall clock. A scope with no cursor (or
  not `bootstrapped`) gets `needsBootstrap`; the foreground triggers then
  run the Bootstrapper (see "First setup, pull and assets").
* Session rules: `token_expired` → one refresh per run. Only an explicit
  refresh rejection (401 / 400 `token_not_valid` from the refresh endpoint)
  blocks with `needsLogin`. Offline / timeout / 5xx never end the session.
  `account_disabled` / `device_revoked` block. The engine itself never logs
  out; `SyncCoordinator` uses the app's existing forced-logout path
  (`AppInterceptors.forceLogout`), which keeps offline data and the outbox.
  Known limitation (review M1): there is NO quarantine/export flow for
  `account_disabled` / `device_revoked` with unsynced rows. The forced
  sign-out keeps every outbox / sales row (never
  `OfflineDb.clearAllLocalOfflineData`); the rows sync when a session of the
  same scope comes back, or stay visible on the pending-sync screen
  (another account's rows can be discarded there after confirmation).
* User discard / retry (pending-sync screen, `OutboxStore.discard /
  discardAll / retryRejected`), each ONE transaction (review I1/I2/M4):
  * Discard only removes rows that are `pending` / `blocked` / `rejected`
    with no lease. A row claimed by a sync run (`inflight`, possibly on the
    wire) is refused (`DiscardOutcome.sending`), a `done` row too
    (`alreadySynced`); the screen shows a message and reloads the list.
  * A discarded `sale.create` keeps its local sale, marked `rejected`
    (code `discarded`, or the server's code when it was rejected); its
    dependents are failed (`dependency_failed`); the local stock of every
    (product, shop) the removed/failed rows affected (sale lines, stock
    add/remove/adjust, inbound lines) is recomputed (base + remaining open
    rows), so a discarded sale gives its quantity back immediately.
  * Retry puts a `rejected` row back to `pending` (attempts 0), puts its
    local sale back from `rejected` to `pending` and recomputes stock (the
    row's effect counts again, exactly once).
  * `PendingSyncBloc` then notifies `outbox`, `sales*`, `stock`, `products`
    (`DbChangeNotifier`); `SyncBadgeCubit` also re-counts on every `outbox`
    notification, so the badge follows local writes without an engine run.
  * Not covered: a `pending` row whose earlier send got no answer (network
    cut after the server committed) can still be discarded; the server keeps
    that sale and the next pull brings it back as synced.
* Logout: triggers stop; `SyncStateStore.clear()` (cursor, capabilities,
  last sync) runs **only if the outbox has no unsynced row**. Outbox rows are
  never deleted on logout.

### Scope (user and tenant)

Outbox rows carry a `scope` (`userId|tenantId`, `SyncSession.key`); the pull cursor, `deferred_pull` and `repair_needed` are stored per scope (`SyncStateStore.forScope`). `device_id` and `sync_lock` stay global. The engine only claims, pushes and pulls for the current scope (`SyncScope.current`, set by `SyncCoordinator`) and returns `blocked(noSession)` with no session. Push/pull requests are bound to their scope: the sync auth interceptor refuses to send when the live auth session no longer matches (`SyncTransportKind.scopeChanged`), and the engine aborts quietly (claims released, no backoff). Rows from before DB v7 have scope `''` and are never pushed.

### Dependencies (DB v14)

An outbox row may wait on several entities: `depends_on_json` is a JSON array of entity ids (NULL = none; replaces the unused single `depends_on_entity_id`, backfilled by `SyncSchema.addOutboxDependsOnList`). `OutboxStore.enqueue(dependsOn:)` records only the ids that have an open (not `done`, so `rejected` counts) `create` in the same scope (`OutboxStore.openCreateIds`) and stores the row `blocked` when any is recorded. When a create is `done`, `unblockDependents` re-checks each dependent's whole list and flips it to `pending` only when none is open. Only a rejected/discarded **create** fails its dependents (`OutboxStore.failsDependents`; `dependency_failed`, cascading only through failed creates): a rejected or discarded product/vendor `update`/`delete` never fails the sales, stock ops or inbounds naming it. Writers: `sale.create` -> every non-custom line product; `stock.add|remove|adjust` -> its product; `inbound.create` -> vendor + every line product. This is what keeps a sale from being pushed after a product create that answered `retry` (the BE would store the line with `product = NULL`).

A failed create also fails the LATER rows of the same entity (an edit or delete queued behind it) with `dependency_failed` (Task 5, Review Focus 2); the rows failed because of id X carry `error_message = OutboxStore.dependencyFailedMessage(X)` (`Dependency X failed`). `retryRejected` of a create revives them (recursively through revived creates): `blocked` while a dependency create is open, else `pending`; a row naming another dependency that has no create row any more stays rejected (best effort). `retryRejected` of any row now goes back `blocked` (not `pending`) while one of its dependency creates is still open. Per-entity order (`claimBatch`): a not-`done` earlier row of the same entity id holds later rows, EXCEPT a `rejected` `update`/`delete` of a catalog entity (`OutboxStore.catalogEntities`: category, product, vendor; ruling I2): later edits of that row are still sent with their own `base_version` and the BE merges them field-wise. A rejected create, and any rejected sale/stock/inbound row, still holds. A rejected `sale.refund` does NOT hold later refunds of the same sale (Phase 4: refunds are independent and append-only; found by the two-device refund test). A `rejected` row is not "local pending" for pull deferral (`hasLocalPendingOutbox` counts `pending`/`inflight`/`blocked` only), so a newer server row is applied over the user's rejected edit locally; the rejected row keeps its payload on the pending-sync screen (Task 8 offers edit/retry/discard).

Retry of a row naming a gone dependency (ruling I4, fix-wave): discard of a create with dependents is refused (I3), so this is rare; when it happens the pending-sync screen flags the row and asks before sending it (the BE keeps it without that link: `product = NULL`, `product_missing`; no money is lost, the product link is). "Retry all" skips such rows.

Revival (review M9): every row failed `dependency_failed` because of create X carries `failed_by_entity_id = X` (DB v14 outbox column), set both by the local cascade and by the engine for a real BE `dependency_failed` (one of the row's dependencies has an open local create; that id is also added to its `depends_on_json`). `retryRejected` / merge revive by that column; the `error_message` text match is kept only for rows failed before the column existed. A merge moves the column to the surviving id.

BE finding 1 (BE_GAPS, client stopgap, fix-wave I1): the BE fails EVERY mutation later in the same push that depends on the entity of ANY rejected mutation (`services._apply_one` `failed_ids`), not only a rejected create. The engine therefore treats a server `dependency_failed` as `retry`, not `rejected`, when none of the row's dependencies (its `depends_on` plus the server's `depends_on`) has an open local create (`SyncEngine._isStrayDependencyFailure`): the row is due again at once (backoff after 3 such retries) and the same run sends it alone. A sale in the same push as a rejected product edit is therefore recorded, exactly once, and its local stock never goes back up. Pinned by `catalog_push_results_test` "BE finding 1" and exercised by the convergence test (any device may now delete any product; counter `be_finding1_sale_retried`).

### Catalog push results (Phase 3, Task 5)

`CategoryApplier`, `ProductApplier`, `VendorApplier.onPushResult` share `catalogPushResult` (applier_support.dart):
- `applied`/`duplicate` -> `adoptServerRow(txn, table, id, r, sent:)`: never lowers the stored `version`; `merged` + `server_state` (BE snapshot keys `category_id`/`parent_id` mapped by `feedShapeOf`, image keys dropped) replaces the local fields unless another unconfirmed row of the entity still shows a newer local edit; otherwise the version is adopted only for a `create` or `version == base_version + 1` (an edit sent without a base leaves it to the pulled echo). A `delete` adopts nothing (the pulled tombstone removes the row).
- `rejected`: the engine stores `error_code`, `error_message` (first `errors{}` message when the message is empty, `SyncEngine.rejectionMessage`) and `error_entity_id` (= `conflict_entity_id`, DB v14 outbox column, read by "Merge into existing"). `entity_deleted` on an update marks the local row `is_active: false`; `conflict_unique` never rewrites ids.
- `server_json` (DB v14, on `categories`/`products`/`vendors`) = the last server state (feed-shaped `data` + `version`), written by pull/bootstrap and by `adoptServerRow`; NULL for a never-synced create. Used to restore a row on discard.
- `outbox.claimed_at` (DB v14) is set the first time a sync run claims a row and never cleared. `CatalogSupport.dropNeverSentCreate` drops a create only when it is `rejected` or was never claimed: a `pending` create may already be on the server (lost response, crash after send).

Limitation: per-entity ordering and `depends_on` are resolved within one scope. Another user's unsynced create is not seen as a dependency (Task 3's logout gate makes this rare).

### Catalog image uploads (Phase 3, Task 6)

Staged images (`pending_uploads` + `<appSupport>/pending_images`, Task 4) are sent by `ImageUploader` (`lib/core/sync/images/image_uploader.dart`), FOREGROUND ONLY:
- Started by `SyncTriggers` next to `AssetSync` (after a run that ends `completed`, after a bootstrap `completed`, on app resume) and also on connectivity regained, only while the server answers; fire-and-forget, never changes a sync outcome, never logs out. When it uploaded something, AssetSync runs once more. The OS worker (`background_sync.dart` / `background_entry.dart`) never builds one (a test greps for it).
- Eligible: `due(scope)` rows whose entity row exists and has NO open outbox row of its own (`pending`/`inflight`/`blocked`); a `rejected` create parks it (waits). Entity row gone, or a never-synced row (`version` NULL) without any create row -> upload row + file cancelled.
- Request (`HttpSyncTransport.putImage`, the `ImageUploadTransport`): multipart `PUT api/v1/products/<id>/image/` or `api/v1/products/categories/<id>/image/`, field `image`, content type by magic bytes, `X-Content-SHA256` and `Idempotency-Key` = the staged sha256, through `engine.authedFor(scope)`; 15 s connect/receive, 60 s send. 4xx keep the BE code (`hash_mismatch`, `forbidden`).
- Success (one txn): row `image_url`/`thumbnail_url` (products) + json `image`/`thumbnail_url`, `image_hash` = local sha256, `version` only when newer than the stored one (a pull that already applied it or a newer row wins), `server_json` image keys + version, `registerRowAssets`, upload row deleted (guarded on its `local_path`: a newer pick is left alone); staged file deleted after the commit; notifies only what changed: `products`/`categories` + `synced_assets` when the row was written, `pending_uploads` when the upload row was removed (T6 M6). The upload debounce re-checks foreground when it fires and is cancelled on pause (review M7). The BE answers a same-bytes replay `unchanged`: a lost response + retry leaves one server image.
- Errors: network/timeout/maintenance/5xx/429/408 -> `attempts+1`, `next_attempt_at` = `AssetSync.backoffFor` (1 min doubling to 24 h, or a longer Retry-After), file kept, never gives up, the run stops on network/timeout. 400 `hash_mismatch` -> sha recomputed from the file, stored when different, retried once (a second mismatch backs off). Other 400, 403, 404, 413, unreadable file -> `failed` + `last_error`; `ImageUploader.retryFailed(entity, id)` / `PendingUploadStore.retryFailed` put it back. 401 `token_expired` -> one refresh via `authedFor`; any remaining 401, `account_disabled`, `device_revoked`, refresh rejected, scope changed -> run stops, row untouched.
- `PendingUploadStore.sweepOrphans` runs from the uploader at most once per hour per instance.
- `OfflineCachedImage(entityType:, entityId:)`: an entity with a `pending_uploads` row in the current scope shows the staged file first (decoded with `cacheWidth` from the layout width), before any `synced_assets` file or the network. One shared `PendingImageResolver` (one query per `pending_uploads` notify, only while subscribed; after a user switch the next `acquire` drops the previous scope's map and reloads, T6 M3). Until its first load finishes the widget shows its placeholder (no flash of the url / error tile, T6 M4). Used by `ProductThumb`, the POS product tile and the product form's photo tile. Without the pair the widget behaves as before.
- Known window: an edit enqueued while an upload is in flight carries the pre-upload `base_version`; the server applies it as `merged` (Task 5 rules), nothing is lost.

### Stock edits and inbound (Phase 1)

`InventoryRepoImpl.addStock / removeStock / adjustStock /
createInboundTransaction` always call `StockService`
(`lib/features/inventory/domain/stock_service.dart`), never REST; the
inventory and inbound blocs only read back the local quantity. Each call is one `LocalWriter.write`: the outbox row
plus `StockLocalStore.recompute` (quantity = base + pending, base untouched,
`products.stock_level` re-summed; a missing local stock row is created with
base 0).

* `stock.add|remove|adjust` payload `{product_id, shop_id, delta, reason,
  occurred_at}`; `add` needs delta > 0, `remove` sends the magnitude,
  `adjust` is signed. The stock screen sends the quantity exactly as typed
  (never `formatQty`-rounded). Remove mode sends `stock.remove` of exactly
  the entered quantity (`OnRemoveStock`), never "shown quantity - q" (the
  shown list can be stale, e.g. after POS sales). Count mode is an absolute
  target sent as `adjust` with delta = target - local quantity, computed
  inside the write transaction. Absolute counts from several devices
  therefore ADD UP (signed adjusts) until `stock.count` (manager-only) is
  adopted in a later phase. Entity id: a fresh UUID per
  mutation (never the product id: a rejected stock row would block the
  product's later rows, and the BE would fail later same-batch mutations
  of that product with `dependency_failed`).
* `inbound.create` payload = `CreateInboundRequestDto.toJson()` (BE
  `InboundReceiveSerializer`) plus `client_inbound_id` (= entity id = the
  server InboundTransaction id). Pending inbound lines count in
  `pendingDeltaUnits`; a local `inbound_transactions` history row is written
  in the same transaction. `InboundApplier`: `applied` re-bases from
  `stock_after`, `duplicate` never does, `rejected` recomputes and removes
  the local history row; pulled inbound only updates history (never stock).
* Local refusals (`StockValidationException`, mirroring the BE): restaurants
  (all ops), cashiers on a shop other than their default shop, cashiers for
  inbound, zero deltas, more than 3 decimals.
* Expiry: `stock.add` has no expiry field, so an add with an expiry date
  uses the REST add (it creates the ProductBatch) when online, then raises
  the local base by exactly the quantity (the next pull brings the absolute
  value). Offline it is refused with "Expiry tracking needs a connection"
  and nothing is written (docs/BE_GAPS.md follow-up).
* Inbound history: after a local submit the inbound bloc reloads history
  from the local table (no REST refresh), and
  `OfflineLocalCache.saveInboundTransactions` keeps rows whose id has an
  open `inbound.create` outbox row, so an unsynced receipt never vanishes
  (which could invite a double submit).
* Not in Phase 1: `stock.count`, `stock.transfer`. Transfer stays REST; on
  success `StockService.applyOnlineTransfer` moves exactly the quantity of
  local base between the two shops (no outbox row; the next pull brings the
  absolute values). The legacy `OfflineLocalCache` stock writers
  (`updateStockQuantity`, `deductStockQuantity`, `transferStockLocally`,
  per-shop `products.stock_level`) are gone: `StockLocalStore` is the only
  writer of `stock` / `products.stock_level` (sum over shops).

### Dashboard and sales history (Phase 1)

The Home dashboard and the sales list read the local `sales` /
`sale_items` / `sale_payments` tables only (no REST call), whatever the flag.
The remote dashboard data source is kept for the future debug checksum
comparison (`getDashboardSummary`, no pending merge any more).

* `LocalDashboardQueries.watchToday` (`features/dashboard/data/local/`) is a
  `DbChangeNotifier.watch` over `sales, sale_items, sale_payments, products,
  sale_refunds`: the first value comes straight from SQLite and every commit
  (a local sale, a pulled sale from another device, a push result)
  re-emits within the 16 ms debounce. It also re-runs at each business hour
  boundary (sparkline, midnight rollover). `DashboardSummaryBloc` subscribes
  and emits data directly: no loading/refreshing state for local data.
* Semantics copy the live `GET sales/dashboard-summary/` view field by field
  (revenue statuses `completed|partial_refund|refunded`, gross on
  `total_amount` = local `subtotal`, breakdown by `payment_method`, top
  sellers by Σ quantity then product id, custom = lines, comparison with the
  previous day, shift only for cashiers). The revenue basis is ONE switch,
  `saleRevenueCentsSql` (the contract doc says `net_amount`: BE_GAPS
  follow-up). Sums are integer cents/milli-units in SQL (each row rounded on
  its own, never a floating accumulation); doubles only at the entity edge.
* A rejected sale still counts locally (it happened); the dashboard shows
  "Offline" while any counted sale is not synced, and the list shows it as
  "Sync failed" with the server reason.
* Refunds: subtracted on the refund date (`occurred_at`) from
  `sale_refunds`, which the `RefundApplier` fills from bootstrap and pull
  (refunds made through REST on any device, this one included, arrive via
  the feed). **Phase 4 must land before real use: refunds are not created
  locally yet** (a REST return changes the server totals at once; the local
  dashboard nets it only after the next pull).
* Returns are offered only for SYNCED sales (`canBeReturned` needs
  `isOfflinePending == false`); a pending/rejected sale shows the existing
  localized banner "Waiting to sync. You can return this sale after it
  syncs." and no return action.
* Visibility: `sales` has no tenant column, so every local sale read
  (dashboard, top sellers, sparkline, history page/count/search) is limited
  to shops of the ACTIVE business: `shop_id IN (SELECT id FROM shops WHERE
  business_id = <AuthBloc defaultBusiness> OR business_id IS NULL)`, see
  `SaleLocalStore.visibleShopSql`. While the business is unknown (profile
  not loaded) nothing is visible; the live dashboard re-runs on every
  AuthBloc business change, so this is never a permanent empty state.
  Logout / business-switch wipes never delete local sales: the pull cursor
  is per scope (user|tenant) and resumes, so a wiped synced sale would never
  come back. Another business's sales simply stay invisible until you
  switch back.
* `shops` is watched by the dashboard stream. The legacy cache writes it
  outside `LocalWriter`, so every shops writer outside the appliers
  (`saveBusinessesToCache`, `clearAllOnLogout`, `clearAllLocalOfflineData`)
  calls `OfflineDb.notifyTablesChanged({'shops'})` after its commit (the
  `ShopApplier` is notified by the engine/bootstrapper after each commit). DI sets `OfflineDb.onTablesChanged` to
  `DbChangeNotifier.notify`. So a
  re-login whose bootstrap fills `shops` after the first dashboard value
  re-emits the real totals. The history list re-reads on its next load or
  refresh.
* The sales list follows the selected POS shop.
* Status filters (Completed, Returned, ...) match synced sales only, like
  the legacy list; pending and rejected sales appear under "All" and the
  "Not synced" filter.
* Sparkline: sales stamped after the current hour (another device's clock
  ahead) are folded into the last bucket so the bars add up to gross (the
  endpoint drops them from its sparkline).
* Pulled sales flagged `occurred_at_suspect` use the server `created_at`
  as the local `occurred_at` (the BE reports them on that date).
* Home cold start shows nothing in the summary area until the first local
  value (milliseconds), never a "no sales" flash and never a spinner.
* Still needs the network: sale detail refresh /
  `getSaleById`, returns (`ReturnItemsScreen`), sales reports
  (`GET sales/reports/`), and stock transfer.
* Timezone: `BusinessDay` (`core/time/business_day.dart`) has a fixed-offset
  table (Africa/Khartoum = UTC+2, no DST since 2017; unknown zones use it).
  The zone/currency are the last ones the server reported in the cached
  dashboard summary, else Africa/Khartoum/SDG. A business day becomes a UTC
  text range on `occurred_at`. "Today" is the device clock in that zone: a
  wrong clock shifts "today", but the sale stamped by the same clock lands
  in the same day, so dashboard and list agree. The list's date filters use
  the same business days (its presets still take y/m/d from the device's
  local date: different only if the device zone differs from the business).
* History: `LocalSalesHistory` orders by `(occurred_at, id) DESC` with keyset
  paging behind the page-number interface; search matches the receipt
  number or the local receipt number. Sale detail/returns still call REST.
* Performance (test, 20k sales): dashboard ~4 ms for a shop, ~12 ms for all
  shops; first history page ~11 ms. Existing indexes suffice (DB stays v9).

### Triggers

`SyncTriggers`: start kick, app resume, connectivity false→true, outbox change
(first notification opens a 5 s window; runs only if rows are `pending`),
periodic 5 min while foreground, manual `syncNow` (also pull to refresh on
the product, category and vendor screens, Phase 3). A `pending_uploads`
change (an image-only edit stages an image but enqueues no outbox row; the
pending-sync screen's upload retry) starts an image-upload run after a 2 s
window (`uploadDebounce`, review M1), under the same server-reachable gate
as every image run. Triggers during a run
collapse into one follow-up. `alreadyRunning` from another runner → exactly
one retry after the lock TTL (2 min). `backoff` → wait for the engine's
`nextRetryAt` (manual always runs; connectivity may cut a network backoff
short, never a maintenance window). Nothing runs before `start()` or after
`stop()`.

### Background sync on device

Files: `lib/core/sync/background/background_sync.dart` (`BackgroundSyncRunner`,
all logic, unit-tested in `test/core/sync/background_sync_test.dart`) and
`background_entry.dart` (`callbackDispatcher`, `BackgroundSync.initialize/
register/requestSoon`, plugin `workmanager` 0.10.10).

* Unless the kill switch is set (`SYNC_ENGINE=false`): `main.dart` calls `BackgroundSync.initialize()`,
  which schedules the periodic task `amana.sync` (15 min, network connected,
  NOT battery constrained, exponential retry from 1 min). `SyncTriggers` asks
  for the one-off `amana.sync.now` when the app is paused with `pending`
  outbox rows, or a write lands while paused; once per background period.
  Expedited only on Android 12+ (API 31, read through the
  `amana_pos/device_info` channel `getSdkInt`; falls back to normal work when
  out of quota). On Android 11 and lower (or unknown SDK) it is a normal
  one-off with the same constraints: workmanager_android 0.10.9's worker does
  not implement `getForegroundInfoAsync()`, which WorkManager needs for
  expedited work below API 31 (review I3).
* A run: session key from storage (`user_id` claim of the stored access token
  `|` stored `X-Tenant-ID`; none → nothing is built or sent) → capability gate
  (`push`+`pull`) → the SAME engine and appliers as the app
  (`buildSyncAppliers()`) on the same database file → `syncNow(background)`
  with a 25 s budget (`engine.cancel()` stops between batches/pages; a call
  still hanging 3 s later is abandoned and recovered by the claim lease).
  `backoff`/`blocked`/partial → the OS retries; `alreadyRunning` (the app
  holds `sync_lock`) → success, nothing done.
* The database is opened with `busy_timeout` 5 s, WAL and
  `synchronous = FULL` (review I5: with WAL, `NORMAL` can lose the last
  commits, i.e. a confirmed and printed sale, on power loss / OS crash).
  Cost: one WAL fsync per commit, a few ms per write (sale save on a file DB
  ~3 ms on a Mac, `test/features/pos/sale_crash_test.dart`; measure on a
  low-end Android); a sale is still one commit. The worker never closes it
  (sqflite shares the native connection across isolates).
* The app re-notifies the applier tables on resume, so screens pick up what a
  background run changed.
* iOS: `Info.plist` has the BGTask ids (`amana.sync`, `amana.sync.processing`)
  and `UIBackgroundModes` fetch+processing; `AppDelegate` registers the launch
  handlers and the plugin registrant for the headless engine.
* Minimum iOS is now 15.0 (Runner deployment target, same as the Podfile).

Manual checklist (run on real devices, default build (engine on), signed in,
server reachable unless stated). For each: make 3 sales offline-first (or
with the server stopped), confirm the badge shows 3 unsynced, then:

1. **Background, not killed.** Home button; wait 15-20 min with network on.
   Server shows the 3 sales; reopening the app shows 0 unsynced and the
   dashboard matches the server.
2. **Swipe away (process killed by user).** Kill from recents; wait up to
   30 min. Android: sales arrive. iOS: BGAppRefresh runs at the system's discretion
   (may take hours; after a user swipe-away iOS may not run it at all).
3. **Force-stop (Android Settings → Force stop).** WorkManager is cancelled by
   the OS by design; nothing syncs until the app is opened. Open it: sales
   sync within seconds, no duplicates on the server.
4. **Battery saver / Doze.** Enable battery saver, screen off 1 h. Expect
   delay, not loss: the sales arrive at the next maintenance window or app
   open. Then disable it and confirm.
5. **Airplane mode.** Sell 3 in airplane mode, background the app, wait 20 min
   (nothing should run: network constraint), turn airplane mode off. Sales
   arrive within ~15 min without opening the app (Android).
6. **Server down 2 h.** Stop the backend, sell, background the app for 2 h,
   start the backend. Sales arrive by the next periodic run; each sale exists
   exactly once on the server; stock decremented once.
7. **Low storage.** Fill the device to < 200 MB free, sell, background. The
   sale must still be saved locally (or refused with an error, never lost
   half-written); sync resumes when space is freed.
8. **Process death mid-push.** With many unsynced sales (≥ 150) start a sync
   and kill the app (`adb shell am kill com.amanapos` or swipe away)
   during the push. Reopen after > 3 min: all sales on the server exactly
   once (replays answered `duplicate`), local stock not re-based twice, no row
   stuck `inflight`.
9. **App open while the worker runs.** Trigger the worker (`adb shell cmd
   jobscheduler run -f com.amanapos <job id>` or wait), open the app
   immediately: no crash, no "database is locked" error, the badge settles to
   0, no duplicate sales.
10. **Logout with unsynced sales, other user logs in.** The worker must not
    push user A's sales under B (A's rows stay pending until A signs in).

### How to add an entity

1. Implement `ChangeApplier` (see `lib/core/sync/change_applier.dart`):
   * `entity` (wire name), `tables` (local tables it writes, notified after commit);
   * `apply(txn, change)` for pulled `upsert` / `delete`; idempotent;
   * `onPushResult(txn, sent, result)` for this device's `applied` /
     `duplicate` / `rejected` results.
2. Rules (each one was found by the convergence test or review):
   * `skipWhenLocalPending` defaults to `true`: a pulled change waits while the
     same row has unsynced outbox rows. Return `false` only for values derived
     from server base + local deltas (stock).
   * Versioned entities (category, product, customer, vendor, shop, user,
     business) override `localVersion(txn, change)` so a deferred change that
     is not newer than the local row is dropped instead of rolling it back.
   * Re-base stock from `stock_after` **only** when `result.status` is
     `applied`. A `duplicate` replays the ORIGINAL `stock_after` and would
     make stock stale.
   * Inside `apply`, `onPushResult` and the page-commit hook use only `txn`.
     Never read or write through `OfflineDb.database` there (deadlock), and
     never call `LocalWriter.write` from inside them (nested writes throw).
   * The same `apply` serves bootstrap items: a bootstrap item is the feed
     row's `data` only (synthetic change `seq: 0`, no `origin_device_id`, no
     `shop_id` wrapper). Read everything you need from `change.data` (take
     the shop from the row's own `shop`/`shop_id`), and add the entity to
     `test/core/sync/bootstrap_shape_contract_test.dart` with one real-shaped
     row copied from the BE serializer (`apps/sync/feed.py`).
   * Rows with images: call `registerRowAssets(txn, type, id, data)` (or
     `registerAsset(txn, type, id, 'thumb'|'full', url, imageHash)`) in
     `apply`, and `unregisterAssets(txn, type, id)` on delete; add
     `kSyncedAssetsTable` to `tables` so image widgets refresh.
   * Malformed rows: `logSkip` and return, never throw (one bad row must not
     poison a page). Money stays a string; sum with `Decimal3`/cents.
3. Register it in `buildSyncAppliers()` (`lib/core/sync/sync_appliers.dart`),
   the one list shared by the app and the background worker.
4. Add it to `Bootstrapper.entityOrder` at its dependency position
   (parents first) if the BE bootstrap manifest serves it.
5. If its rows are tenant catalog data, add its table to the wipe paths
   (`clearAllOnLogout`, `OfflineDb.clearAllLocalOfflineData`); never add
   sales-like money history there (ruling T5-a).
6. Write through `LocalWriter` + `scope.enqueue(...)` in the repository
   (Phases 3-5 for catalog writes).
7. Add the entity to the convergence test's random actions and to the
   `FakeSyncServer` bootstrap pages.

### Flags and URLs

* The engine is ON by default; `--dart-define=SYNC_ENGINE=false` is the kill
  switch. `main.dart` always calls `DependenciesProvider.startSyncIfEnabled()`:
  with the engine on, triggers start when `AuthBloc` has a signed-in user with
  a business and stop on logout; with the kill switch it only keeps
  `SyncScope.current` following the session (so sales/stock edits still save
  to the outbox) and builds no engine, triggers or background worker.
  If the sync core fails to start (any DI / async error in
  `startSyncIfEnabled`), it falls back to the same scope-following as the
  kill switch (review I4), so checkout keeps writing to the outbox; nothing
  syncs until the next launch.
* Kill switch consequences (review M8, intended): with `SYNC_ENGINE=false`
  NOTHING syncs (no push, no pull, no first setup, no background worker),
  and the logout gate counts every unsynced outbox row, so a user with any
  local sale / stock edit cannot sign out until an engine-on build ships.
  Use it only as an emergency switch.
  Every run is also gated on a stored access token and on `sync/ping`
  advertising `push` and `pull`. The device is registered (`POST
  api/v1/sync/devices/`) when the server advertises `devices`.
* Backend base URL (`--dart-define=API_BASE=...`, trailing slash):
  local LAN `http://192.168.1.168:8000/`, Android emulator `http://10.0.2.2:8000/`.
  Example: `flutter run --dart-define=API_BASE=http://10.0.2.2:8000/`.

### Tests

```
flutter test test/core/sync                       # whole sync core suite
flutter test test/core/offline                    # DB versions, first setup, wipes, images, vendors
flutter test test/core/sync/sync_triggers_test.dart
flutter test test/core/sync/convergence_test.dart # 60 seeds by default (~20 s)
flutter test test/core/sync/convergence_test.dart --dart-define=CONV_SEEDS=200   # before a release
flutter test test/core/sync/convergence_test.dart --dart-define=CONV_SEED=17     # replay one seed
flutter analyze
```

Convergence knobs: `CONV_SEEDS` (count), `CONV_FIRST`, `CONV_SEED`,
`CONV_DEVICES` (default 3), `CONV_FAULTS` / `CONV_CRASHES` (default true),
`CONV_MIN_ACTIONS` / `CONV_MAX_ACTIONS`, `CONV_VERBOSE`. Tests use an
in-memory FFI database (`test/core/sync/support/test_db.dart`) and the
`FakeSyncServer` (`test/core/sync/support/fake_sync_server.dart`).

Phase 2 tests (bootstrap, pull appliers, assets, first setup):

| Test | Guards |
|---|---|
| `test/core/sync/bootstrapper_test.dart`, `bootstrapper_resume_test.dart` | page txn, resume after kill/offline/token loss at every page boundary, single snapshot, session switch, deferral, version guard |
| `test/core/sync/bootstrap_integration_test.dart`, `bootstrap_lifecycle_test.dart` | engine/triggers/coordinator wiring, resync semantics, wipe pairing |
| `test/core/sync/bootstrap_shape_contract_test.dart` | one real-shaped bootstrap item per entity through its applier |
| `test/core/sync/bootstrap_transport_test.dart`, `bootstrap_controller_test.dart` | transport errors, UI controller |
| `test/core/sync/catalog_appliers_test.dart`, `other_appliers_test.dart`, `refund_applier_test.dart`, `stock_applier_test.dart` | appliers (incl. `is_low_stock` BE rule) |
| `test/core/sync/asset_sync_test.dart`, `asset_triggers_test.dart` | image download/verify/backoff/orphans, triggers, worker thumbnails only |
| `test/core/sync/image_uploader_test.dart`, `offline_cached_image_pending_test.dart`, `http_sync_transport_test.dart` (putImage) | Phase 3 image uploads: eligibility, lost-response idempotency, backoff, failed/retry, cancel, hash_mismatch, auth, staged image shown first |
| `test/core/sync/convergence_test.dart` | bootstrap-in-the-middle, rows written between pages, faults |
| `test/core/offline/first_setup_screen_test.dart`, `offline_status_setup_test.dart` | first-setup screen + readiness gate |
| `test/core/offline/offline_db_v11/v12/v13/v14_test.dart` | schema steps (v13 drops `offline_assets`, `sync_metadata`; v14 adds outbox `depends_on_json`) |
| `test/core/sync/outbox_dependencies_test.dart` | multi-dependency block/unblock/fail, sale/stock/inbound dependencies, `retry` ordering |
| `test/core/sync/catalog_push_results_test.dart`, `outbox_catalog_cascade_test.dart` | catalog push results (adopt version, merged, conflict_unique + error_entity_id, entity_deleted, forbidden/limit/validation), same-entity cascade, retry revival, lost-response delete |
| `test/core/sync/fake_sync_server_catalog_test.dart` | FakeSyncServer mirrors the BE catalog handlers, cashier gate, in-batch dependency_failed, image PUT |
| `test/features/products/product_bloc_local_test.dart`, `category/category_bloc_local_test.dart`, `inventory/vendors_bloc_local_test.dart` | Phase 3 catalog blocs: SQLite reads, notifier re-read, local add/edit/delete, one-write auto category + opening stock, category image staging, markers, cashier refusal |
| `test/core/sync/catalog_pull_keeps_local_edit_test.dart` | Review Focus 4: a pull (push answered `retry`) keeps a pending edit/create; the edit then merges with another device's change |
| `test/features/catalog/no_rest_catalog_writer_test.dart`, `cashier_entry_points_test.dart` | no REST catalog writer/endpoint in `lib/`; cashier entry points hidden |
| `test/core/offline/offline_cached_image_test.dart` | image widget lookup |
| `test/features/sync/catalog_conflict_service_test.dart` | Review Focus 5/6: merge rewrites every audited table and leaves no old id (schema grep + whitelist), merge atomic at every stage, preview = merge, refused without `conflict_entity_id`; discard of a create (row, outbox, files) / update (server_json + later edits) / delete; dependents stay failed; edit and retry |
| `test/features/sync/pending_sync_catalog_test.dart` | pending-sync bloc + view: labels, merge only with a conflict id, confirm with counts, edit and retry, catalog discard path, failed upload retry (en + ar) |
| `test/features/catalog/catalog_refresh_sync_test.dart`, `test/core/sync/asset_triggers_test.dart` (review M1) | pull to refresh calls sync-now; a `pending_uploads` change starts an upload run |
| `test/features/lifecycle/catalog_lifecycle_test.dart` | offline day of catalog work on the real stack -> exact server state, one image, second device pulls it; SKU conflict on two devices -> merge -> convergence |

## Phase 4: customers and refunds (local-first)

- **Customers:** `CustomerService` (create / update / `setActive`) writes the `customers` row and its outbox row in one `LocalWriter.write`; `CustomerRepoImpl` reads the local table (search, active filter, paging in Dart) and shows a "Not synced" / "Sync failed" marker from the outbox. `loyalty_points` is server-owned and never sent. Sales do NOT depend on an unsent customer create (a rejected customer must not fail a sale; the outbox seq sends the create first). Merge-into-existing for a duplicate phone is not built for customers yet (BE_GAPS Phase 4).
- **Refunds:** `RefundService.refund` writes a `sale_refunds` row (`sync_state` pending|synced|rejected, client `reference`), recomputes the sale status and enqueues `sale.refund` (entity `sale`, entity id = sale id) in one write. The line guard counts synced + pending refunds. `SaleApplier.onPushResult` settles it (`applied`/`duplicate` -> synced, server `refund_total` adopted, stock re-based only on `applied`); `refund_exceeds_sold` (or any rejection, a cascade failure, or a user discard) VOIDS it: the row stays flagged `rejected`, excluded from dashboard totals, sale status and the returnable quantity. `RefundApplier` replaces the local twin when the server refund (same `(sale, reference)`) is pulled, so a refund counts once. `OutboxStore` keeps `sale_refunds` in step on cascade-fail, discard, revive and retry.
- A refund of a not-yet-synced sale is allowed; it queues behind the sale create and the BE answers `retry dependency_pending` if it ever arrives first.
- Returns and sale detail read the local tables only (`LocalSalesHistory.byId`); there is no REST refund or REST sale read left.
