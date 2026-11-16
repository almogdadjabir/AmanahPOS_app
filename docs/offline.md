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
| `OnOfflineStatusSyncSalesRequested` | Manual sync trigger |
| `OnOfflineConnectionChanged(isOnline)` | Internally from `NetworkMonitor` stream |
| `OnOfflinePendingSalesCountChanged(count)` | After background sales sync |
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
- `unawaited(_backgroundSyncSales())` — syncs pending sales.

**Does NOT re-trigger `AuthBloc`.** If business failed to load while offline, that is handled by a listener in `OfflinePreparationListener` (Fix 1).

## SyncManager

```dart
Future<int> pendingSalesCount()
Future<void> syncPendingSales()   // sends pending sales to API, marks synced
```

## OfflineSalesQueue (SQLite)

Stores sales that were created while offline.
Each entry has: `clientSaleId`, `payload`, `status` (pending/syncing/synced/failed).

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
          → _syncSales()
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

New outbox-based sync core under `lib/core/sync/`. It is **off by default** and
does not change any user-visible behaviour yet: no feature writes through it in
Phase 0, and the legacy `SyncManager` / `OfflineSalesQueue` path above still
handles sales. Spec: `docs/superpowers/specs/2026-11-16-offline-first-sync-design.md`.
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

### Triggers

`SyncTriggers`: start kick, app resume, connectivity false→true, outbox change
(first notification opens a 5 s window; runs only if rows are `pending`),
periodic 5 min while foreground, manual `syncNow`. Triggers during a run
collapse into one follow-up. `alreadyRunning` from another runner → exactly
one retry after the lock TTL (2 min). `backoff` → wait for the engine's
`nextRetryAt` (manual always runs; connectivity may cut a network backoff
short, never a maintenance window). Nothing runs before `start()` or after
`stop()`.

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
3. Register it: `getIt<ChangeApplierRegistry>().register(MyApplier())`
   (empty in Phase 0).
4. Write through `LocalWriter` + `scope.enqueue(...)` in the repository.
5. Add the entity to the convergence test's random actions.

### Flags and URLs

* `--dart-define=SYNC_ENGINE=true` turns the core on (default off). When on,
  `main.dart` calls `DependenciesProvider.startSyncIfEnabled()`; triggers start
  when `AuthBloc` has a signed-in user with a business and stop on logout.
  Every run is also gated on a stored access token and on `sync/ping`
  advertising `push` and `pull`. The device is registered (`POST
  api/v1/sync/devices/`) when the server advertises `devices`.
* Backend base URL (`--dart-define=API_BASE=...`, trailing slash):
  local LAN `http://192.168.1.168:8000/`, Android emulator `http://10.0.2.2:8000/`.
  Example: `flutter run --dart-define=SYNC_ENGINE=true --dart-define=API_BASE=http://10.0.2.2:8000/`.

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
