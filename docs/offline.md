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
