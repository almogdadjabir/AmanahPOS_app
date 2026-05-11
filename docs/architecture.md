# Architecture

## Entry Point

```
main.dart
  → SharedPreferences.getInstance()
  → CacheStorage.preloadPrefs(prefs)
  → DependenciesProvider.build()       ← registers everything in GetIt
  → runApp(App())
```

## App Widget (`lib/app.dart`)

```dart
MultiBlocProvider(
  providers: getProviders(context),    // lib/config/providers/providers.dart
  child: MaterialApp(
    navigatorKey: Constants.navigatorKey,
    initialRoute: RouteStrings.splash,
    onGenerateRoute: AppRouter().onGenerateRoute,
  ),
)
```

All blocs are provided at the root level — they live for the entire app lifetime.

## Dependency Injection (`lib/utilities/dependencies_provider.dart`)

Single static `DependenciesProvider.build()` call at startup.
Everything registered as `registerLazySingleton`.

Registration order:
1. Core: `CacheStorage`, `Dio`, `DioClient`, `RequestHandler`, `Connectivity`, `NetworkMonitor`
2. Offline core: `OfflineDb`, `OfflineLocalCache`, `OfflineAssetDownloader`, `OfflineRemoteDataSource`, `OfflineSalesQueue`, `SyncManager`, `OfflineFirstManager`
3. Remote data sources: `PosRemoteDataSource`
4. Repositories: one per feature (`CategoryRepository`, `ProductRepository`, etc.)
5. Use cases: one per feature (`CategoryUseCase`, `ProductUseCase`, etc.)
6. Blocs that are singletons: `OfflineStatusBloc`, `AuthBloc`

**Blocs NOT in GetIt** (created fresh in `getProviders`):
`NavigationBloc`, `ThemeBloc`, `SplashBloc`, `RegistrationBloc`, `LoginBloc`,
`PosBloc`, `BusinessBloc`, `UserBloc`, `CategoryBloc`, `ProductBloc`,
`InventoryBloc`, `SettingsBloc`, `CustomersBloc`

To get something: `getIt<SomeType>()` or `DependenciesProvider.provide<SomeType>()`.

## Providers (`lib/config/providers/providers.dart`)

`getProviders(context)` returns a list of `BlocProvider` — called once from `App`.
This is where `ProductBloc`, `CategoryBloc`, etc. are constructed with their `getIt` dependencies.

**Current `ProductBloc` construction:**
```dart
BlocProvider(
  create: (context) => ProductBloc(
    useCase: getIt<ProductUseCase>(),
    offlineLocalCache: getIt<OfflineLocalCache>(),
  ),
),
```

## Routing (`lib/config/router/`)

`AppRouter.onGenerateRoute` handles named routes.
`RouteStrings` contains all route name constants.

Key routes:
| Constant | Screen |
|---|---|
| `RouteStrings.splash` | `SplashScreen` |
| `RouteStrings.login` | `LoginScreen` |
| `RouteStrings.mainScreen` | `MainScreen` |
| `RouteStrings.productScreen` | `ProductsScreen(isWithAppbar: true)` |
| `RouteStrings.settingsScreen` | `SettingsScreen` |

Navigation to welcome/logout: `Constants.navigatorKey.currentState?.pushNamedAndRemoveUntil(...)`.

## Folder Structure

```
lib/
├── app.dart
├── main.dart
├── common/
│   ├── auth_bloc/          ← AuthBloc (singleton in getIt)
│   ├── services/           ← CacheStorage, ImagePicker
│   ├── theme_bloc/
│   └── widgets/
├── config/
│   ├── constants.dart      ← Constants class, navigatorKey
│   ├── enum.dart           ← UserRole, ScreenMode, kUnitsShop, kUnitsRestaurant
│   ├── environment/
│   ├── providers/          ← getProviders()
│   └── router/             ← AppRouter, RouteStrings
├── core/
│   ├── api/                ← RequestHandler
│   ├── network/            ← DioClient, NetworkMonitor, interceptors
│   ├── offline/            ← OfflineDb, OfflineLocalCache, OfflineFirstManager, OfflineStatusBloc
│   ├── permissions/        ← AppPermissions
│   └── sync/               ← SyncManager
├── features/
│   ├── auth/               ← login, registration, splash
│   ├── business/
│   ├── cart/
│   ├── category/
│   ├── customers/
│   ├── feature_menu/       ← sliding menu panel
│   ├── inventory/
│   ├── main_screen/        ← MainScreen, NavigationBloc, OfflinePreparationListener
│   ├── pos/
│   ├── products/
│   ├── settings/
│   └── users/
├── theme/                  ← AppColors, AppTextStyles, AppTheme, AppSpacing
├── utilities/              ← DependenciesProvider, GlobalSnackBar, Format
└── widgets/                ← shared widgets (AppButton, FormField, etc.)
```

## Data Flow Pattern (per feature)

```
UI Widget
  → BlocBuilder / BlocListener
  → Bloc.add(Event)
  → Bloc handler
    → UseCase method
      → Repository method
        → RequestHandler (Dio)  or  OfflineLocalCache (SQLite)
      → Either<String?, ResponseDto>
    → fold(error, success) → emit(state.copyWith(...))
  → UI rebuilds
```

All repository responses are `Either<String?, T>`.
Error is a human-readable string or null. Success is the typed DTO.
