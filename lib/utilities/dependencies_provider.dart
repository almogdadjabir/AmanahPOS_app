import 'package:amana_pos/barcode_scanner/data/services/barcode_permission_service.dart';
import 'package:amana_pos/common/app_progress/app_progress_cubit.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/common/services/notifications/fcm_token_service.dart';
import 'package:amana_pos/config/environment/environment.dart';
import 'package:amana_pos/config/router/app_router.dart';
import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/core/network/app_interceptors.dart';
import 'package:amana_pos/core/network/dio_client.dart';
import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/data/offline_remote_data_source.dart';
import 'package:amana_pos/core/offline/offline_asset_downloader.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/offline/offline_first_manager.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/sync/sync_manager.dart';
import 'package:amana_pos/common/services/device/device_info_service.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_coordinator.dart';
import 'package:amana_pos/core/sync/sync_device_registrar.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_flags.dart';
import 'package:amana_pos/core/sync/sync_session_guard.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/core/sync/sync_token_refresher.dart';
import 'package:amana_pos/core/sync/sync_triggers.dart';
import 'package:amana_pos/core/sync/transport/http_sync_transport.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:amana_pos/features/dashboard/data/datasources/dashboard_local_data_source.dart';
import 'package:amana_pos/features/pin/data/biometric_unlock_service.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/features/devices/data/datasources/ble_printer_channel.dart';
import 'package:amana_pos/features/devices/data/datasources/bluetooth_printer_channel.dart';
import 'package:amana_pos/features/devices/data/datasources/network_printer_channel.dart';
import 'package:amana_pos/features/devices/data/repository_impl/printer_repo_impl.dart';
import 'package:amana_pos/features/devices/data/services/printer_permission_service.dart';
import 'package:amana_pos/features/devices/domain/repositories/printer_repository.dart';
import 'package:amana_pos/features/devices/domain/usecases/printer_usecase.dart';
import 'package:amana_pos/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:amana_pos/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:amana_pos/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:amana_pos/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:amana_pos/features/returns/data/repository_impl/returns_repo_impl.dart';
import 'package:amana_pos/features/returns/domain/repositories/returns_repository.dart';
import 'package:amana_pos/features/returns/domain/usecases/returns_usecase.dart';
import 'package:amana_pos/features/sales_history/data/repository_impl/sales_history_repo_impl.dart';
import 'package:amana_pos/features/sales_history/domain/repositories/sales_history_repository.dart';
import 'package:amana_pos/features/sales_history/domain/usecases/sales_history_usecase.dart';
import 'package:amana_pos/features/sync/presentation/bloc/pending_sync_bloc.dart';
import 'package:amana_pos/features/business/data/repository_impl/business_repo_impl.dart';
import 'package:amana_pos/features/business/domain/repositories/business_repository.dart';
import 'package:amana_pos/features/business/domain/usecases/business_usecase.dart';
import 'package:amana_pos/features/category/data/repository_impl/category_repo_impl.dart';
import 'package:amana_pos/features/category/domain/repositories/category_repository.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/customers/data/repository_impl/customer_repo_impl.dart';
import 'package:amana_pos/features/customers/domain/repositories/customer_repository.dart';
import 'package:amana_pos/features/customers/domain/usecases/customer_usecase.dart';
import 'package:amana_pos/features/inventory/data/offline/offline_inbound_queue.dart';
import 'package:amana_pos/features/inventory/data/repository_impl/inventory_repo_impl.dart';
import 'package:amana_pos/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:amana_pos/features/login/data/repository_impl/login_repo_impl.dart';
import 'package:amana_pos/features/login/domain/repository/login_repository.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:amana_pos/features/pos/data/datasources/pos_remote_data_source.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sales_queue.dart';
import 'package:amana_pos/features/pos/data/repository_impl/pos_repo_impl.dart';
import 'package:amana_pos/features/pos/domain/repositories/pos_repository.dart';
import 'package:amana_pos/features/pos/domain/usecases/pos_usecase.dart';
import 'package:amana_pos/features/products/data/repository_impl/product_repo_impl.dart';
import 'package:amana_pos/features/products/domain/repositories/product_repository.dart';
import 'package:amana_pos/features/products/domain/usecases/product_usecase.dart';
import 'package:amana_pos/features/registration/data/repository_impl/registration_repo_impl.dart';
import 'package:amana_pos/features/registration/domain/repositories/registration_repository.dart';
import 'package:amana_pos/features/registration/domain/usecases/registration_usecase.dart';
import 'package:amana_pos/features/notification/data/repository_impl/notification_repo_impl.dart';
import 'package:amana_pos/features/notification/domain/repository/notification_repository.dart';
import 'package:amana_pos/features/notification/domain/usecase/notification_usecases.dart';
import 'package:amana_pos/features/users/data/repository_impl/users_repo_impl.dart';
import 'package:amana_pos/features/users/domain/repositories/users_repository.dart';
import 'package:amana_pos/features/users/domain/usecases/users_usecase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class DependenciesProvider {
  DependenciesProvider._();

  static void build() {
    // Core/common
    getIt.registerLazySingleton<CacheStorage>(() => CacheStorage());
    getIt.registerLazySingleton<PinVaultService>(
      () => PinVaultService(getIt<CacheStorage>()),
    );
    getIt.registerLazySingleton<BiometricUnlockService>(
      () => BiometricUnlockService(
        cache: getIt<CacheStorage>(),
        vault: getIt<PinVaultService>(),
      ),
    );
    getIt.registerLazySingleton<AppRouter>(() => AppRouter());

    getIt.registerLazySingleton<Dio>(() => Dio());

    getIt.registerLazySingleton<DioClient>(
          () => DioClient(
        baseUrl,
        dio: getIt<Dio>(),
        interceptors: [
          AppInterceptors(getIt<Dio>()),
        ],
      ),
    );

    getIt.registerLazySingleton<RequestHandler>(
          () => RequestHandler(getIt<DioClient>()),
    );

    getIt.registerLazySingleton<Connectivity>(
          () => Connectivity(),
    );

    getIt.registerLazySingleton<NetworkMonitor>(
          () => NetworkMonitor(getIt<Connectivity>()),
    );

    // Offline-first core
    getIt.registerLazySingleton<OfflineDb>(
          () => OfflineDb.instance,
    );

    getIt.registerLazySingleton<OfflineLocalCache>(
          () => OfflineLocalCache(getIt<OfflineDb>()),
    );

    getIt.registerLazySingleton<OfflineAssetDownloader>(
          () => OfflineAssetDownloader(
        dio: getIt<Dio>(),
        localCache: getIt<OfflineLocalCache>(),
      ),
    );

    getIt.registerLazySingleton<OfflineRemoteDataSource>(
          () => OfflineRemoteDataSource(getIt<RequestHandler>()),
    );

    // Remote data sources
    getIt.registerLazySingleton<PosRemoteDataSource>(
          () => PosRemoteDataSource(getIt<RequestHandler>()),
    );

    // Offline queues
    getIt.registerLazySingleton<OfflineSalesQueue>(
          () => OfflineSalesQueue(
        db: getIt<OfflineDb>(),
      ),
    );

    getIt.registerLazySingleton<OfflineInboundQueue>(
          () => OfflineInboundQueue(
        db: getIt<OfflineDb>(),
      ),
    );

    // Sync manager
    getIt.registerLazySingleton<SyncManager>(
          () => SyncManager(
        salesQueue: getIt<OfflineSalesQueue>(),
        inboundQueue: getIt<OfflineInboundQueue>(),
        posRemoteDataSource: getIt<PosRemoteDataSource>(),
        requestHandler: getIt<RequestHandler>(),
      ),
    );

    getIt.registerLazySingleton<PendingSyncBloc>(
          () => PendingSyncBloc(syncManager: getIt<SyncManager>()),
    );

    // App-wide progress signal (thin line under the main app bar).
    getIt.registerLazySingleton<AppProgressCubit>(
          () => AppProgressCubit(),
    );

    // Offline-first manager
    getIt.registerLazySingleton<OfflineFirstManager>(
          () => OfflineFirstManager(
        networkMonitor: getIt<NetworkMonitor>(),
        localCache: getIt<OfflineLocalCache>(),
        remoteDataSource: getIt<OfflineRemoteDataSource>(),
        syncManager: getIt<SyncManager>(),
        assetDownloader: getIt<OfflineAssetDownloader>(),
      ),
    );

    getIt.registerLazySingleton<FcmTokenService>(
          () => FcmTokenService(
        cacheStorage: getIt<CacheStorage>(),
        requestHandler: getIt<RequestHandler>(),
      ),
    );

    getIt.registerLazySingleton<BarcodePermissionService>(
          () => BarcodePermissionService(),
    );

    // Receipt printer (Bluetooth + LAN/WiFi)
    getIt.registerLazySingleton<BluetoothPrinterChannel>(
          () => PrintBluetoothThermalChannel(),
    );

    getIt.registerLazySingleton<BlePrinterChannel>(
          () => BlePrinterChannel(),
    );

    getIt.registerLazySingleton<NetworkPrinterChannel>(
          () => NetworkPrinterChannel(),
    );

    getIt.registerLazySingleton<PrinterPermissionService>(
          () => PrinterPermissionService(),
    );

    getIt.registerLazySingleton<PrinterRepository>(
          () => PrinterRepoImpl(
        channel: getIt<BluetoothPrinterChannel>(),
        bleChannel: getIt<BlePrinterChannel>(),
        networkChannel: getIt<NetworkPrinterChannel>(),
        cacheStorage: getIt<CacheStorage>(),
        permissionService: getIt<PrinterPermissionService>(),
      ),
    );

    getIt.registerLazySingleton<PrinterUseCase>(
          () => PrinterUseCase(
        repository: getIt<PrinterRepository>(),
      ),
    );

    // Repositories
    getIt.registerLazySingleton<RegistrationRepository>(
          () => RegistrationRepoImpl(getIt<RequestHandler>()),
    );

    getIt.registerLazySingleton<LoginRepository>(
          () => LoginRepoImpl(getIt<RequestHandler>()),
    );

    getIt.registerLazySingleton<BusinessRepository>(
          () => BusinessRepoImpl(getIt<RequestHandler>()),
    );

    getIt.registerLazySingleton<UsersRepository>(
          () => UsersRepoImpl(getIt<RequestHandler>()),
    );

    getIt.registerLazySingleton<CategoryRepository>(
          () => CategoryRepoImpl(getIt<RequestHandler>()),
    );

    getIt.registerLazySingleton<ProductRepository>(
          () => ProductRepoImpl(getIt<RequestHandler>()),
    );

    getIt.registerLazySingleton<InventoryRepository>(
          () => InventoryRepoImpl(getIt<RequestHandler>()),
    );

    getIt.registerLazySingleton<PosRepository>(
          () => PosRepoImpl(
        networkMonitor: getIt<NetworkMonitor>(),
        offlineSalesQueue: getIt<OfflineSalesQueue>(),
        remoteDataSource: getIt<PosRemoteDataSource>(),
      ),
    );

    getIt.registerLazySingleton<CustomerRepository>(
          () => CustomerRepoImpl(getIt<RequestHandler>()),
    );

    getIt.registerLazySingleton<NotificationRepository>(
          () => NotificationRepoImpl(getIt<RequestHandler>()),
    );

    getIt.registerLazySingleton<NotificationUseCases>(
          () => NotificationUseCases(repository: getIt<NotificationRepository>()),
    );

    getIt.registerLazySingleton<DashboardRemoteDataSource>(
          () => DashboardRemoteDataSourceImpl(
        dio: getIt<Dio>(),
      ),
    );

    getIt.registerLazySingleton<DashboardLocalDataSource>(
          () => DashboardLocalDataSourceImpl(
        offlineDb: getIt<OfflineDb>(),
      ),
    );

    getIt.registerLazySingleton<DashboardRepository>(
          () => DashboardRepositoryImpl(
        remoteDataSource: getIt<DashboardRemoteDataSource>(),
        localDataSource: getIt<DashboardLocalDataSource>(),
      ),
    );


    // Use cases
    getIt.registerLazySingleton<RegistrationUseCase>(
          () => RegistrationUseCase(
        repository: getIt<RegistrationRepository>(),
      ),
    );

    getIt.registerLazySingleton<LoginUseCase>(
          () => LoginUseCase(
        repository: getIt<LoginRepository>(),
        cacheStorage: getIt<CacheStorage>(),
      ),
    );

    getIt.registerLazySingleton<BusinessUseCase>(
          () => BusinessUseCase(
        repository: getIt<BusinessRepository>(),
      ),
    );

    getIt.registerLazySingleton<UsersUseCase>(
          () => UsersUseCase(
        repository: getIt<UsersRepository>(),
      ),
    );

    getIt.registerLazySingleton<CategoryUseCase>(
          () => CategoryUseCase(
        repository: getIt<CategoryRepository>(),
      ),
    );

    getIt.registerLazySingleton<ProductUseCase>(
          () => ProductUseCase(
        repository: getIt<ProductRepository>(),
      ),
    );

    getIt.registerLazySingleton<InventoryUseCase>(
          () => InventoryUseCase(
        repository: getIt<InventoryRepository>(),
      ),
    );

    getIt.registerLazySingleton<PosUseCase>(
          () => PosUseCase(
        repository: getIt<PosRepository>(),
      ),
    );

    getIt.registerLazySingleton<CustomerUseCase>(
          () => CustomerUseCase(
        repository: getIt<CustomerRepository>(),
      ),
    );
    getIt.registerLazySingleton<GetDashboardSummaryUseCase>(
          () => GetDashboardSummaryUseCase(
        repository: getIt<DashboardRepository>(),
      ),
    );

    // Sales History
    getIt.registerLazySingleton<SalesHistoryRepository>(
          () => SalesHistoryRepoImpl(
        requestHandler: getIt<RequestHandler>(),
        offlineDb: getIt<OfflineDb>(),
        networkMonitor: getIt<NetworkMonitor>(),
      ),
    );
    getIt.registerLazySingleton<SalesHistoryUseCase>(
          () => SalesHistoryUseCase(repository: getIt<SalesHistoryRepository>()),
    );

    // Returns
    getIt.registerLazySingleton<ReturnsRepository>(
          () => ReturnsRepoImpl(requestHandler: getIt<RequestHandler>()),
    );
    getIt.registerLazySingleton<ReturnsUseCase>(
          () => ReturnsUseCase(repository: getIt<ReturnsRepository>()),
    );

    // Blocs
    getIt.registerLazySingleton<OfflineStatusBloc>(
          () => OfflineStatusBloc(
        networkMonitor: getIt<NetworkMonitor>(),
        localCache: getIt<OfflineLocalCache>(),
        offlineFirstManager: getIt<OfflineFirstManager>(),
        syncManager: getIt<SyncManager>(),
      ),
    );

    getIt.registerLazySingleton<AuthBloc>(() => AuthBloc(
      useCase: getIt<LoginUseCase>(),
      businessUseCase: getIt<BusinessUseCase>(),
      offlineLocalCache: getIt<OfflineLocalCache>(),
      offlineStatusBloc: getIt<OfflineStatusBloc>(),
    ));

    _registerSyncCore();
  }

  // ---------------------------------------------------------------- sync core
  //
  // Offline-first sync core (Phase 0). Every registration is LAZY: nothing
  // here is constructed unless kSyncEngineEnabled (`--dart-define=
  // SYNC_ENGINE=true`) and [startSyncIfEnabled] runs. With the flag off the
  // app behaves exactly as before.

  static const String syncDioName = 'syncDio';

  static void _registerSyncCore() {
    Future<String?> readAccessToken() =>
        getIt<CacheStorage>().getValue(Constants.authToken);
    Future<String?> readTenantId() =>
        getIt<CacheStorage>().getValue(Constants.xTenantID);
    Future<String?> readDeviceId() => getIt<SyncStateStore>().deviceId();

    getIt.registerLazySingleton<DbChangeNotifier>(() => DbChangeNotifier());

    getIt.registerLazySingleton<OutboxStore>(
          () => OutboxStore(getIt<OfflineDb>()),
    );

    getIt.registerLazySingleton<LocalWriter>(
          () => LocalWriter(
        getIt<OfflineDb>(),
        getIt<OutboxStore>(),
        getIt<DbChangeNotifier>(),
      ),
    );

    getIt.registerLazySingleton<SyncStateStore>(
          () => SyncStateStore(getIt<OfflineDb>()),
    );

    // Same token / tenant storage as AppInterceptors; headers only (no
    // refresh, retry or logout on the sync Dio).
    getIt.registerLazySingleton<SyncTransport>(
          () => HttpSyncTransport.create(
        baseUrl: baseUrl,
        readAccessToken: readAccessToken,
        readTenantId: readTenantId,
        readDeviceId: readDeviceId,
      ),
    );

    getIt.registerLazySingleton<Dio>(
          () => HttpSyncTransport.createDio(
        baseUrl: baseUrl,
        readAccessToken: readAccessToken,
        readTenantId: readTenantId,
        readDeviceId: readDeviceId,
      ),
      instanceName: syncDioName,
    );

    getIt.registerLazySingleton<ServerReachability>(
          () => ServerReachability(getIt<SyncTransport>()),
    );

    // Empty in Phase 0: features register their appliers when they move on
    // to the sync core.
    getIt.registerLazySingleton<ChangeApplierRegistry>(
          () => ChangeApplierRegistry(),
    );

    getIt.registerLazySingleton<SyncTokenRefresher>(
          () => SyncTokenRefresher(
        baseUrl: baseUrl,
        storage: getIt<CacheStorage>(),
        mainRefreshInFlight: () => AppInterceptors.refreshInFlight,
        isLoggingOut: () => AppInterceptors.isLoggingOut,
      ),
    );

    getIt.registerLazySingletonAsync<SyncEngine>(() async {
      final refresher = getIt<SyncTokenRefresher>();
      return SyncEngine(
        db: getIt<OfflineDb>(),
        transport: getIt<SyncTransport>(),
        outbox: getIt<OutboxStore>(),
        state: getIt<SyncStateStore>(),
        reachability: getIt<ServerReachability>(),
        appliers: getIt<ChangeApplierRegistry>(),
        notifier: getIt<DbChangeNotifier>(),
        appVersion: await _syncAppVersion(),
        refreshToken: refresher.refresh,
      );
    });

    getIt.registerLazySingletonAsync<SyncTriggers>(() async {
      return SyncTriggers(
        await getIt.getAsync<SyncEngine>(),
        getIt<NetworkMonitor>(),
        getIt<OutboxStore>(),
        getIt<DbChangeNotifier>(),
        canSync: _syncGate,
      );
    });

    getIt.registerLazySingletonAsync<SyncSessionGuard>(() async {
      return SyncSessionGuard((await getIt.getAsync<SyncEngine>()).status);
    });

    getIt.registerLazySingleton<SyncDeviceRegistrar>(
          () => SyncDeviceRegistrar(
        dio: getIt<Dio>(instanceName: syncDioName),
        state: getIt<SyncStateStore>(),
        capabilities: () async {
          final ping = await getIt<ServerReachability>().check();
          return ping?.capabilities ??
              await getIt<SyncStateStore>().capabilities();
        },
        appVersion: _syncAppVersion,
        platform: kIsWeb ? 'web' : Platform.operatingSystem,
        name: kIsWeb
            ? 'web'
            : '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        fcmToken: () => getIt<FcmTokenService>().getToken(),
      ),
    );

    getIt.registerLazySingletonAsync<SyncCoordinator>(() async {
      final auth = getIt<AuthBloc>();
      return SyncCoordinator(
        triggers: await getIt.getAsync<SyncTriggers>(),
        guard: await getIt.getAsync<SyncSessionGuard>(),
        registrar: getIt<SyncDeviceRegistrar>(),
        outbox: getIt<OutboxStore>(),
        state: getIt<SyncStateStore>(),
        sessions: auth.stream.map(_syncSessionOf),
        initialSession: _syncSessionOf(auth.state),
        // Every session event (explicit refresh rejection, account disabled,
        // device revoked) uses the app's existing forced-logout path: tokens
        // + PIN/biometric cleared, offline data and the outbox KEPT.
        onSessionEnded: (_) => AppInterceptors.forceLogout(),
      );
    });
  }

  /// Starts the sync core after login when the build enables it. With
  /// kSyncEngineEnabled false this is a no-op and nothing is constructed.
  static Future<void> startSyncIfEnabled() async {
    if (!kSyncEngineEnabled) return;
    try {
      final coordinator = await getIt.getAsync<SyncCoordinator>();
      await coordinator.attach();
    } catch (e, st) {
      developer.log(
        'sync core failed to start',
        name: 'DependenciesProvider',
        error: e,
        stackTrace: st,
      );
    }
  }

  static SyncSession? _syncSessionOf(AuthState s) {
    final userId = s.profile?.id;
    final tenantId = s.defaultBusiness?.id;
    if (!s.isLoggedIn || userId == null || tenantId == null) return null;
    return SyncSession(userId: userId, tenantId: tenantId);
  }

  static Future<String> _syncAppVersion() async {
    try {
      return await DeviceInfoService.instance.getAppVersion();
    } catch (_) {
      return ''; // unparseable/empty never blocks sync (engine rule)
    }
  }

  /// Runs before every trigger: a signed-in session and a server that
  /// advertises the sync capabilities (unknown capability = legacy path).
  static Future<bool> _syncGate() async {
    final token = await getIt<CacheStorage>().getValue(Constants.authToken);
    if (token == null || token.isEmpty) return false;
    final ping = await getIt<ServerReachability>().check();
    if (ping == null) return false;
    return ping.capabilities.containsAll(kSyncRequiredCapabilities);
  }

  static T provide<T extends Object>() {
    return getIt.get<T>();
  }
}