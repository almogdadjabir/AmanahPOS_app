# Offline-First System

## Overview

The app is designed to work fully offline after the first online session.
SQLite (`sqflite`) stores all product, category, customer, business, and stock data locally.
Pending sales are queued and synced when the device comes back online.

## Files

```
lib/core/offline/
├── offline_db.dart                    ← SQLite DB singleton (OfflineDb.instance)
├── offline_first_manager.dart         ← orchestrates refresh + asset download
├── offline_asset_downloader.dart
├── offline_constants.dart             ← table name constants
├── data/
│   ├── offline_local_cache.dart       ← all read/write to SQLite
│   └── offline_remote_data_source.dart ← fetches bootstrap from API
├── models/
│   ├── offline_bootstrap_dto.dart
│   ├── offline_asset_manifest_dto.dart
│   └── offline_asset_record.dart
└── presentation/
    └── bloc/
        ├── offline_status_bloc.dart
        ├── offline_status_event.dart
        └── offline_status_state.dart

lib/core/network/
└── network_monitor.dart               ← wraps connectivity_plus, emits bool stream

lib/core/sync/
└── sync_manager.dart                  ← syncs pending offline sales to API
```

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

Main interface for all local data reads/writes.
Wraps `OfflineDb` (SQLite).

Key methods:
```dart
Future<bool> hasBootstrapCache()
Future<void> saveBootstrap(OfflineBootstrapDto dto)
Future<void> clearAllOnLogout()

Future<List<BusinessData>> getBusinesses()
Future<List<CategoryData>> getCategories()
Future<List<ProductData>> getProducts({String? categoryId})
Future<void> saveProductsToCache(List<ProductData> products)
Future<void> saveCategoriesToCache(List<CategoryData> categories)
```

## OfflineFirstManager

Orchestrates the two-phase refresh:
1. `refreshBootstrap()` — fetches products, categories, customers, stock from API → saves to SQLite.
2. `refreshAssetManifest(silent: bool)` — downloads product images.

## OfflineStatusBloc

Singleton in GetIt. Provided at root via `BlocProvider(create: (_) => getIt<OfflineStatusBloc>())`.

### State (`OfflineStatusState`)

```dart
OfflineConnectionStatus connectionStatus  // unknown | online | offline
OfflineBootstrapStatus  bootstrapStatus   // initial | loading | success | failure
OfflineAssetStatus      assetStatus       // initial | loading | success | failure
OfflineSalesSyncStatus  salesSyncStatus   // idle | syncing | success | failure
bool    hasCache
bool    canUseAppOffline
int     pendingSalesCount
DateTime? lastBootstrapSyncAt
DateTime? lastAssetSyncAt
DateTime? lastSalesSyncAt
String? errorMessage

// Derived:
bool get isOnline
bool get isOffline
bool get isBusy
bool get hasFailure
String get statusLabel
String get connectionLabel
```

### Events

| Event | Who dispatches it |
|---|---|
| `OnOfflineStatusStarted` | `AuthBloc._onLoadBusinessEvent` (after business loads) |
| `OnOfflineStatusRefreshRequested` | Pull-to-refresh, background refresh |
| `OnOfflineStatusSyncSalesRequested` | Manual refresh of the unsynced outbox count |
| `OnOfflineConnectionChanged(isOnline)` | Internally from `NetworkMonitor` stream |
| `OnOfflinePendingSalesCountChanged(count)` | After a connection change (outbox count) |
| `OnOfflineStatusResetRequested` | Logout |

### `_onStarted` Logic

```
hasBootstrapCache()
├── no cache + offline  → bootstrapStatus: failure (first-time offline error)
├── no cache + online   → _refreshAll() (first-time setup)
├── has cache + online  → unawaited(_backgroundRefresh())
└── has cache + offline → ready (canUseAppOffline: true)
```

### `_onConnectionChanged` Logic

When `isOnline` becomes true:
- `unawaited(_backgroundRefresh())` — silently refreshes bootstrap.
- `unawaited(_backgroundSyncSales())` — refreshes the unsynced outbox count
  (`pendingSalesCount`); pushing is the sync engine's job.

**Does NOT re-trigger `AuthBloc`.** If business failed to load while offline, that is handled by a listener in `OfflinePreparationListener` (Fix 1).

## Pending sales count and logout gate

`OfflineStatusBloc` takes `outboxUnsyncedCount` (`OutboxStore.unsyncedCount()`,
every scope, rejected included). `pendingSalesCount` and the logout gate
(`blockingPendingOfflineSalesCount`) are exactly that count. The legacy
`SyncManager` / `OfflineSalesQueue` / `OfflineInboundQueue` and their tables
(`pending_sales`, `pending_sale_items`, `pending_inbound_transactions`) were
removed in Phase 1 (DB v10 drops the tables; zero production users, nothing
migrated).

## Bootstrap Flow (first launch online)

```
SplashBloc → authenticated
  → AuthBloc.add(OnLoadProfileEvent)
    → _onLoadProfile → profile loaded
    → AuthBloc.add(OnLoadBusinessEvent)
      → business loaded → emit AuthState with defaultBusiness
      → offlineStatusBloc.add(OnOfflineStatusStarted)
        → hasCache = false, isOnline = true
        → _refreshAll()
          → offlineFirstManager.refreshBootstrap()
            → downloads all data → saves to SQLite
          → bootstrapStatus: success, hasCache: true
          → offlineFirstManager.refreshAssetManifest()
          → _syncSales()   (refreshes the outbox count only)
```

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
├── contract/sync_contract.dart  ← wire DTOs
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
  transaction, and never orders by wall clock. A device with no cursor gets
  `needsBootstrap` (bootstrap arrives in Phase 2).
* Session rules: `token_expired` → one refresh per run. Only an explicit
  refresh rejection (401 / 400 `token_not_valid` from the refresh endpoint)
  blocks with `needsLogin`. Offline / timeout / 5xx never end the session.
  `account_disabled` / `device_revoked` block. The engine itself never logs
  out; `SyncCoordinator` uses the app's existing forced-logout path
  (`AppInterceptors.forceLogout`), which keeps offline data and the outbox.
  Quarantine/export of unsynced rows on a forced sign-out is a Phase 1 TODO.
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
* Refunds: subtracted on the refund date from `sale_refunds` once Phase 4
  creates it; until then the query sees no table and returns zero.
  **Phase 4 must land before real use: local refunds are not tracked yet**
  (a REST return changes the server totals, the local dashboard keeps the
  sale at full value until the pulled sale status changes, and refund
  figures stay 0).
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
  outside `LocalWriter`, so every shops writer (`saveBootstrap`,
  `saveBusinessesToCache`, `clearAllOnLogout`, `clearAllLocalOfflineData`,
  `clearBootstrapCache`) calls `OfflineDb.notifyTablesChanged({'shops'})`
  after its commit. DI sets `OfflineDb.onTablesChanged` to
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
  for the one-off `amana.sync.now` (expedited on Android, falls back to normal
  work when out of quota) when the app is paused with `pending` outbox rows,
  or a write lands while paused; once per background period.
* A run: session key from storage (`user_id` claim of the stored access token
  `|` stored `X-Tenant-ID`; none → nothing is built or sent) → capability gate
  (`push`+`pull`) → the SAME engine and appliers as the app
  (`buildSyncAppliers()`) on the same database file → `syncNow(background)`
  with a 25 s budget (`engine.cancel()` stops between batches/pages; a call
  still hanging 3 s later is abandoned and recovered by the claim lease).
  `backoff`/`blocked`/partial → the OS retries; `alreadyRunning` (the app
  holds `sync_lock`) → success, nothing done.
* The database is opened with `busy_timeout` 5 s and WAL. The worker never
  closes it (sqflite shares the native connection across isolates).
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
3. Register it in `buildSyncAppliers()` (`lib/core/sync/sync_appliers.dart`),
   the one list shared by the app and the background worker.
4. Write through `LocalWriter` + `scope.enqueue(...)` in the repository.
5. Add the entity to the convergence test's random actions.

### Flags and URLs

* The engine is ON by default; `--dart-define=SYNC_ENGINE=false` is the kill
  switch. `main.dart` always calls `DependenciesProvider.startSyncIfEnabled()`:
  with the engine on, triggers start when `AuthBloc` has a signed-in user with
  a business and stop on logout; with the kill switch it only keeps
  `SyncScope.current` following the session (so sales/stock edits still save
  to the outbox) and builds no engine, triggers or background worker.
  Every run is also gated on a stored access token and on `sync/ping`
  advertising `push` and `pull`. The device is registered (`POST
  api/v1/sync/devices/`) when the server advertises `devices`.
* Backend base URL (`--dart-define=API_BASE=...`, trailing slash):
  local LAN `http://192.168.1.168:8000/`, Android emulator `http://10.0.2.2:8000/`.
  Example: `flutter run --dart-define=API_BASE=http://10.0.2.2:8000/`.

### Tests

```
flutter test test/core/sync                       # whole sync core suite
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
