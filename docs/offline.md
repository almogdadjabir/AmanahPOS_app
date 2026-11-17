# Offline-First System

## Overview

The app is designed to work fully offline after the first online session.
SQLite (`sqflite`) stores the catalog (business, shops, categories, products,
customers, vendors, stock), sales, refunds and images locally. Since Phase 2
the sync core (`lib/core/sync/`) is the ONLY way server data enters the
device: a resumable paged first setup (bootstrap), a pull applier for every
feed entity, and images downloaded by change token. Local writes (sales,
stock edits, inbound) go through the outbox and sync when the device is back
online. REST-refreshing blocs still write some legacy tables (Phases 3-5
retire them).

## Files

```
lib/core/offline/
├── offline_db.dart                    ← SQLite DB singleton (OfflineDb.instance), schema v13
├── offline_constants.dart             ← table name constants
├── data/
│   └── offline_local_cache.dart       ← legacy-shaped reads + REST writers of the cache tables
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
shapes) and holds the REST writers the blocs still use. Wraps `OfflineDb`.

Key methods:
```dart
Future<void> clearAllOnLogout()      // catalog wipe + every scope's setup keys
Future<List<BusinessData>> getBusinesses()
Future<List<ShopData>> getShops()
Future<List<CategoryData>> getCategories()
Future<List<ProductData>> getProducts({String? categoryId, String? search})
Future<List<StockData>> getStock({String? shopId})
Future<List<VendorData>> getVendors()
Future<String?> getSyncedAssetPathByUrl(String? url)   // image widget
Future<void> saveProductsToCache(List<ProductData> products)        // REST
Future<void> saveCategoriesToCache(List<CategoryData> categories)   // REST
Future<void> saveVendors(List<VendorData> vendors)  // REST, UPSERT only
Future<void> removeVendorFromCache(String id)       // REST delete
```

`saveVendors` never deletes: the REST vendor list is active-only and paged,
so a delete-all would erase vendors the `VendorApplier` wrote (inactive
vendors, inbound vendor names). An existing row keeps its feed `version`
(the REST content is the current server state), so an older feed row can
never roll it back. A vendor deleted through REST is removed with
`removeVendorFromCache`; vendors deleted elsewhere disappear when the feed's
`delete` arrives.

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

## Offline-First Data Pattern in Blocs

All data blocs (`ProductBloc`, `CategoryBloc`) follow this pattern:

```dart
// 1. Try cache first → emit immediately if found
final cached = await offlineLocalCache.getXxx();
if (cached.isNotEmpty) {
  emittedCachedData = true;
  emit(state.copyWith(status: success, data: cached, isFromCache: true));
} else {
  emit(state.copyWith(status: loading));
}

// 2. Fetch from API
final response = await useCase.getXxx();
response.fold(
  (error) {
    if (emittedCachedData) {
      emit(state.copyWith(status: success, responseError: error, isFromCache: true));
      return;
    }
    emit(state.copyWith(status: failure, responseError: error));
  },
  (result) {
    emit(state.copyWith(status: success, data: result.data, isFromCache: false));
  },
);
```

Rule: if cache was shown, a network error does NOT replace the UI with an error state — it shows the cached data with a soft error in state.

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

Limitation: per-entity ordering and `depends_on` are resolved within one scope. Another user's unsynced create is not seen as a dependency (Task 3's logout gate makes this rare).

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
periodic 5 min while foreground, manual `syncNow`. Triggers during a run
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
| `test/core/sync/convergence_test.dart` | bootstrap-in-the-middle, rows written between pages, faults |
| `test/core/offline/first_setup_screen_test.dart`, `offline_status_setup_test.dart` | first-setup screen + readiness gate |
| `test/core/offline/offline_db_v11/v12/v13_test.dart` | schema steps (v13 drops `offline_assets`, `sync_metadata`) |
| `test/core/offline/save_vendors_test.dart` | REST `saveVendors` never erases synced vendors |
| `test/core/offline/offline_cached_image_test.dart` | image widget lookup |
