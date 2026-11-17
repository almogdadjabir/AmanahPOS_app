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
import 'package:amana_pos/core/offline/data/local_image_resolver.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/common/services/device/device_info_service.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/core/sync/assets/asset_sync.dart';
import 'package:amana_pos/core/sync/audit/checksum_audit.dart';
import 'package:amana_pos/core/sync/audit/checksum_repair.dart';
import 'package:amana_pos/core/sync/audit/local_checksum_queries.dart';
import 'package:amana_pos/core/sync/assets/asset_sync_wiring.dart';
import 'package:amana_pos/core/sync/background/background_entry.dart';
import 'package:amana_pos/core/sync/sync_appliers.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrap_controller.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_coordinator.dart';
import 'package:amana_pos/core/sync/sync_device_registrar.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_flags.dart';
import 'package:amana_pos/core/sync/sync_session_guard.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
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
import 'package:amana_pos/core/time/business_day.dart';
import 'package:amana_pos/features/dashboard/data/local/dashboard_parity.dart';
import 'package:amana_pos/features/dashboard/data/local/local_dashboard_queries.dart';
import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:amana_pos/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:amana_pos/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:amana_pos/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:amana_pos/features/returns/data/repository_impl/returns_repo_impl.dart';
import 'package:amana_pos/features/customers/domain/customer_service.dart';
import 'package:amana_pos/features/returns/domain/refund_service.dart';
import 'package:amana_pos/features/returns/domain/repositories/returns_repository.dart';
import 'package:amana_pos/features/returns/domain/usecases/returns_usecase.dart';
import 'package:amana_pos/features/sales_history/data/local/local_sales_history.dart';
import 'package:amana_pos/features/sales_history/data/repository_impl/sales_history_repo_impl.dart';
import 'package:amana_pos/features/sales_history/domain/repositories/sales_history_repository.dart';
import 'package:amana_pos/features/sales_history/domain/usecases/sales_history_usecase.dart';
import 'package:amana_pos/features/sync/domain/catalog_conflict_service.dart';
import 'package:amana_pos/features/sync/presentation/bloc/pending_sync_bloc.dart';
import 'package:amana_pos/features/sync/presentation/bloc/sync_badge_cubit.dart';
import 'package:amana_pos/features/business/data/repository_impl/business_repo_impl.dart';
import 'package:amana_pos/features/business/domain/repositories/business_repository.dart';
import 'package:amana_pos/features/business/domain/usecases/business_usecase.dart';
import 'package:amana_pos/features/category/data/repository_impl/category_repo_impl.dart';
import 'package:amana_pos/features/category/domain/repositories/category_repository.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/customers/data/repository_impl/customer_repo_impl.dart';
import 'package:amana_pos/features/customers/domain/repositories/customer_repository.dart';
import 'package:amana_pos/features/customers/domain/usecases/customer_usecase.dart';
import 'package:amana_pos/features/inventory/data/repository_impl/inventory_repo_impl.dart';
import 'package:amana_pos/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:amana_pos/features/login/data/repository_impl/login_repo_impl.dart';
import 'package:amana_pos/features/login/domain/repository/login_repository.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:amana_pos/features/pos/data/repository_impl/pos_repo_impl.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/inventory/domain/vendor_service.dart';
import 'package:amana_pos/features/category/domain/category_service.dart';
import 'package:amana_pos/features/products/domain/product_service.dart';
import 'package:amana_pos/core/sync/images/pending_upload_store.dart';
import 'package:amana_pos/core/sync/images/image_uploader.dart';
import 'package:amana_pos/core/sync/images/image_uploader_wiring.dart';
import 'package:amana_pos/core/sync/images/pending_image_resolver.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
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
import 'package:amana_pos/features/users/data/local/user_local_store.dart';
import 'package:amana_pos/features/users/domain/user_conflict_service.dart';
import 'package:amana_pos/features/users/domain/user_service.dart';
import 'package:amana_pos/features/users/data/repository_impl/users_repo_impl.dart';
import 'package:amana_pos/features/users/domain/repositories/users_repository.dart';
import 'package:amana_pos/features/users/domain/usecases/users_usecase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, visibleForTesting;
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';

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
        interceptors: [AppInterceptors(getIt<Dio>())],
      ),
    );

    getIt.registerLazySingleton<RequestHandler>(
      () => RequestHandler(getIt<DioClient>()),
    );

    getIt.registerLazySingleton<Connectivity>(() => Connectivity());

    getIt.registerLazySingleton<NetworkMonitor>(
      () => NetworkMonitor(getIt<Connectivity>()),
    );

    // Offline-first core
    getIt.registerLazySingleton<OfflineDb>(
      () => OfflineDb.instance
        // Legacy cache writes (e.g. `shops`) reach live local queries.
        ..onTablesChanged = (tables) {
          if (getIt.isRegistered<DbChangeNotifier>()) {
            getIt<DbChangeNotifier>().notify(tables);
          }
        },
    );

    getIt.registerLazySingleton<OfflineLocalCache>(
      () => OfflineLocalCache(getIt<OfflineDb>()),
    );

    getIt.registerLazySingleton<PendingSyncBloc>(
      () => PendingSyncBloc(
        outbox: getIt<OutboxStore>(),
        db: getIt<OfflineDb>(),
        notifier: getIt<DbChangeNotifier>(),
        // Existing manual sync-now (none with the kill switch).
        syncNow: appSyncNow(),
        conflicts: getIt<CatalogConflictService>(),
        uploads: getIt<PendingUploadStore>(),
        // The uploader notifies pending_uploads; the triggers start the
        // upload run from that (none with the kill switch).
        retryUpload: kSyncEngineEnabled
            ? (entity, id) async => (await getIt.getAsync<ImageUploader>())
                  .retryFailed(entity, id)
            : null,
      ),
    );

    // App-wide progress signal (thin line under the main app bar).
    getIt.registerLazySingleton<AppProgressCubit>(() => AppProgressCubit());

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

    getIt.registerLazySingleton<BlePrinterChannel>(() => BlePrinterChannel());

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
      () => PrinterUseCase(repository: getIt<PrinterRepository>()),
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
      () => UsersRepoImpl(
        store: getIt<UserLocalStore>(),
        service: () => getIt<UserService>(),
        conflicts: () => getIt<UserConflictService>(),
      ),
    );

    // Catalog (Phase 3): local writes only (row + outbox); no REST client.
    getIt.registerLazySingleton<CategoryRepository>(
      () => CategoryRepoImpl(service: () => getIt<CategoryService>()),
    );

    getIt.registerLazySingleton<ProductRepository>(
      () => ProductRepoImpl(service: () => getIt<ProductService>()),
    );

    getIt.registerLazySingleton<InventoryRepository>(
      () => InventoryRepoImpl(
        getIt<RequestHandler>(),
        // The only stock write path (local + outbox).
        stockService: () => getIt<StockService>(),
        // The only vendor write path (local + outbox).
        vendorService: () => getIt<VendorService>(),
      ),
    );

    getIt.registerLazySingleton<PosRepository>(
      // The only sale write path (local + outbox).
      () => PosRepoImpl(saleService: () => getIt<SaleService>()),
    );

    getIt.registerLazySingleton<CustomerRepository>(
      () => CustomerRepoImpl(
        writer: getIt<LocalWriter>(),
        service: () => getIt<CustomerService>(),
      ),
    );

    getIt.registerLazySingleton<NotificationRepository>(
      () => NotificationRepoImpl(getIt<RequestHandler>()),
    );

    getIt.registerLazySingleton<NotificationUseCases>(
      () => NotificationUseCases(repository: getIt<NotificationRepository>()),
    );

    getIt.registerLazySingleton<DashboardRemoteDataSource>(
      () => DashboardRemoteDataSourceImpl(dio: getIt<Dio>()),
    );

    getIt.registerLazySingleton<DashboardLocalDataSource>(
      () => DashboardLocalDataSourceImpl(offlineDb: getIt<OfflineDb>()),
    );

    getIt.registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(
        remoteDataSource: getIt<DashboardRemoteDataSource>(),
        localDataSource: getIt<DashboardLocalDataSource>(),
        // Today's summary comes from the local sales tables (reactive, no
        // REST call).
        localQueries: LocalDashboardQueries(
          db: getIt<OfflineDb>(),
          notifier: getIt<DbChangeNotifier>(),
          // Only the active business's shops' sales are visible; live
          // summaries re-run when the business changes/loads.
          tenantId: () => getIt<AuthBloc>().state.defaultBusiness?.id,
          tenantChanges: getIt<AuthBloc>().stream
              .map((s) => s.defaultBusiness?.id)
              .distinct(),
        ),
        shiftCashierId: () {
          final s = getIt<AuthBloc>().state;
          return s.permissions.role == AppUserRole.cashier
              ? s.profile?.id
              : null;
        },
      ),
    );

    // Use cases
    getIt.registerLazySingleton<RegistrationUseCase>(
      () => RegistrationUseCase(repository: getIt<RegistrationRepository>()),
    );

    getIt.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(
        repository: getIt<LoginRepository>(),
        cacheStorage: getIt<CacheStorage>(),
      ),
    );

    getIt.registerLazySingleton<BusinessUseCase>(
      () => BusinessUseCase(repository: getIt<BusinessRepository>()),
    );

    getIt.registerLazySingleton<UsersUseCase>(
      () => UsersUseCase(repository: getIt<UsersRepository>()),
    );

    getIt.registerLazySingleton<CategoryUseCase>(
      () => CategoryUseCase(repository: getIt<CategoryRepository>()),
    );

    getIt.registerLazySingleton<ProductUseCase>(
      () => ProductUseCase(repository: getIt<ProductRepository>()),
    );

    getIt.registerLazySingleton<InventoryUseCase>(
      () => InventoryUseCase(repository: getIt<InventoryRepository>()),
    );

    getIt.registerLazySingleton<PosUseCase>(
      () => PosUseCase(repository: getIt<PosRepository>()),
    );

    getIt.registerLazySingleton<CustomerUseCase>(
      () => CustomerUseCase(repository: getIt<CustomerRepository>()),
    );
    getIt.registerLazySingleton<GetDashboardSummaryUseCase>(
      () =>
          GetDashboardSummaryUseCase(repository: getIt<DashboardRepository>()),
    );

    // Sales History
    getIt.registerLazySingleton<SalesHistoryRepository>(
      () => SalesHistoryRepoImpl(
        requestHandler: getIt<RequestHandler>(),
        networkMonitor: getIt<NetworkMonitor>(),
        // The list reads the local sales tables.
        localHistory: LocalSalesHistory(
          db: getIt<OfflineDb>(),
          tenantId: () => getIt<AuthBloc>().state.defaultBusiness?.id,
        ),
        businessTimezone: () async =>
            (await getIt<DashboardLocalDataSource>().lastKnownMeta()).timezone,
      ),
    );
    getIt.registerLazySingleton<SalesHistoryUseCase>(
      () => SalesHistoryUseCase(repository: getIt<SalesHistoryRepository>()),
    );

    // Returns
    getIt.registerLazySingleton<ReturnsRepository>(
      () => ReturnsRepoImpl(refunds: getIt<RefundService>()),
    );
    getIt.registerLazySingleton<ReturnsUseCase>(
      () => ReturnsUseCase(repository: getIt<ReturnsRepository>()),
    );

    // Blocs
    getIt.registerLazySingleton<OfflineStatusBloc>(
      () => OfflineStatusBloc(
        networkMonitor: getIt<NetworkMonitor>(),
        outboxUnsyncedCount: () => getIt<OutboxStore>().unsyncedCount(),
        // Readiness = the scope's `bootstrapped` flag (spec phase 2,
        // section 2). Kill switch: no sync core, never blocks.
        firstSetup: kSyncEngineEnabled
            ? () => getIt.getAsync<BootstrapController>()
            : null,
      ),
    );

    getIt.registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        useCase: getIt<LoginUseCase>(),
        businessUseCase: getIt<BusinessUseCase>(),
        offlineLocalCache: getIt<OfflineLocalCache>(),
        offlineStatusBloc: getIt<OfflineStatusBloc>(),
      ),
    );

    _registerSyncCore();
  }

  // ---------------------------------------------------------------- sync core
  //
  // Offline-first sync core. Every registration is LAZY. The local write path
  // (LocalWriter, OutboxStore, SaleService, StockService) is always used;
  // only the engine / triggers / background worker are gated by
  // kSyncEngineEnabled (kill switch: `--dart-define=SYNC_ENGINE=false`).

  static const String syncDioName = 'syncDio';

  /// Plain Dio for image downloads (no interceptors, no default headers).
  static const String assetDioName = 'assetDio';

  static void _registerSyncCore() {
    Future<String?> readAccessToken() =>
        getIt<CacheStorage>().getValue(Constants.authToken);
    Future<String?> readTenantId() =>
        getIt<CacheStorage>().getValue(Constants.xTenantID);
    Future<String?> readDeviceId() => getIt<SyncStateStore>().deviceId();
    // Live AuthBloc state, NOT SyncScope.current: the coordinator publishes
    // the scope with a delay, while token/tenant headers change immediately.
    Future<String?> readSessionKey() async =>
        _syncSessionOf(getIt<AuthBloc>().state)?.key;

    getIt.registerLazySingleton<DbChangeNotifier>(() => DbChangeNotifier());

    // One app-wide url -> local file resolver for every OfflineCachedImage:
    // one synced_assets query per notify instead of one per image.
    getIt.registerLazySingleton<LocalImageResolver>(
      () => LocalImageResolver(
        changes: getIt<DbChangeNotifier>().changes,
        load: () => getIt<OfflineLocalCache>().getSyncedAssetPaths(),
      ),
      dispose: (r) => r.dispose(),
    );

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
        readSessionKey: readSessionKey,
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

    getIt.registerLazySingleton<Dio>(
      createAssetDio,
      instanceName: assetDioName,
    );

    // Images by change token (spec phase 2, section 4). ONE instance (its
    // single-flight is per instance), own folder `<appSupport>/synced_assets`,
    // BE headers read at call time and sent only to the BE host. Only the
    // triggers start it, so the kill switch (no triggers) builds none.
    getIt.registerLazySingletonAsync<AssetSync>(() async {
      return buildAssetSync(
        db: getIt<OfflineDb>(),
        notifier: getIt<DbChangeNotifier>(),
        scopeProvider: () => SyncScope.current,
        appSupportPath: (await getApplicationSupportDirectory()).path,
        baseUrl: baseUrl,
        readAccessToken: readAccessToken,
        readTenantId: readTenantId,
        dio: getIt<Dio>(instanceName: assetDioName),
      );
    });

    getIt.registerLazySingleton<ServerReachability>(
      () => ServerReachability(getIt<SyncTransport>()),
    );

    // Same list as the background worker (sync_appliers.dart).
    getIt.registerLazySingleton<ChangeApplierRegistry>(buildSyncAppliers);

    // The only writer of local stock edits / inbound receipts (outbox +
    // stock, one txn). Role, shop and business type come from the live
    // session, mirroring the BE checks.
    getIt.registerLazySingleton<StockService>(
      () => StockService(
        writer: getIt<LocalWriter>(),
        actor: () {
          final s = getIt<AuthBloc>().state;
          final perms = s.permissions;
          return StockActor(
            businessType: perms.businessType,
            role: perms.role,
            shopId: s.profile?.defaultShopId,
          );
        },
      ),
    );

    // Catalog writers (category, vendor): owner/manager only, role from the
    // live session like StockService.
    CatalogActor catalogActor() {
      final perms = getIt<AuthBloc>().state.permissions;
      return CatalogActor(businessType: perms.businessType, role: perms.role);
    }

    getIt.registerLazySingleton<CategoryService>(
      () => CategoryService(
        writer: getIt<LocalWriter>(),
        actor: catalogActor,
        uploads: getIt<PendingUploadStore>(),
      ),
    );
    getIt.registerLazySingleton<VendorService>(
      () => VendorService(writer: getIt<LocalWriter>(), actor: catalogActor),
    );
    // Pending-sync screen actions on rejected catalog rows (merge, discard,
    // edit and retry).
    getIt.registerLazySingleton<CatalogConflictService>(
      () => CatalogConflictService(
        db: getIt<OfflineDb>(),
        writer: getIt<LocalWriter>(),
        outbox: getIt<OutboxStore>(),
        uploads: getIt<PendingUploadStore>(),
      ),
    );
    // Staged catalog images: <appSupport>/pending_images (foreground only).
    getIt.registerLazySingleton<PendingUploadStore>(
      () => PendingUploadStore(
        baseDir: () async => (await getApplicationSupportDirectory()).path,
      ),
    );
    // Staged image of an entity, shown first by OfflineCachedImage (one
    // pending_uploads query per notify for every image on screen).
    getIt.registerLazySingleton<PendingImageResolver>(
      () => buildPendingImageResolver(
        db: getIt<OfflineDb>(),
        store: getIt<PendingUploadStore>(),
        notifier: getIt<DbChangeNotifier>(),
        scopeProvider: () => SyncScope.current,
      ),
      dispose: (r) => r.dispose(),
    );
    getIt.registerLazySingleton<ProductService>(
      () => ProductService(
        writer: getIt<LocalWriter>(),
        actor: catalogActor,
        uploads: getIt<PendingUploadStore>(),
        categories: getIt<CategoryService>(),
      ),
    );

    // The only writer of local sales (sale rows + outbox + stock, one txn).
    getIt.registerLazySingleton<SaleService>(
      () => SaleService(
        writer: getIt<LocalWriter>(),
        state: getIt<SyncStateStore>(),
        cashierId: () {
          final scope = SyncScope.current;
          if (scope == null) return null;
          final i = scope.indexOf('|');
          return i <= 0 ? null : scope.substring(0, i);
        },
      ),
    );

    // Team (Phase 5): local writes only (row + outbox); no REST client.
    getIt.registerLazySingleton<UserLocalStore>(
      () => UserLocalStore(getIt<LocalWriter>()),
    );
    getIt.registerLazySingleton<UserService>(
      () => UserService(writer: getIt<LocalWriter>()),
    );
    getIt.registerLazySingleton<UserConflictService>(
      () => UserConflictService(
        writer: getIt<LocalWriter>(),
        outbox: getIt<OutboxStore>(),
      ),
    );

    getIt.registerLazySingleton<CustomerService>(
      () => CustomerService(writer: getIt<LocalWriter>()),
    );

    // The only writer of local refunds (refund row + sale status + outbox).
    getIt.registerLazySingleton<RefundService>(
      () => RefundService(writer: getIt<LocalWriter>()),
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
        scopeProvider: () => SyncScope.current,
        readSessionKey: () async =>
            _syncSessionOf(getIt<AuthBloc>().state)?.key,
        reachability: getIt<ServerReachability>(),
        appliers: getIt<ChangeApplierRegistry>(),
        notifier: getIt<DbChangeNotifier>(),
        appVersion: await _syncAppVersion(),
        refreshToken: refresher.refresh,
      );
    });

    // First setup (foreground app only; the OS worker never builds one).
    // Same DB, transport, state, appliers, notifier and token rules as the
    // engine; only the triggers run it (single flight with the engine).
    getIt.registerLazySingletonAsync<Bootstrapper>(() async {
      final engine = await getIt.getAsync<SyncEngine>();
      return Bootstrapper(
        db: getIt<OfflineDb>(),
        transport: getIt<SyncTransport>(),
        state: getIt<SyncStateStore>(),
        appliers: getIt<ChangeApplierRegistry>(),
        notifier: getIt<DbChangeNotifier>(),
        scopeProvider: () => SyncScope.current,
        // No DB access here: it also runs inside page transactions. The
        // bootstrapper itself checks SyncScope.current == its run scope.
        assertScope: () async {
          if (await readSessionKey() != SyncScope.current) {
            throw SyncTransportException(kind: SyncTransportKind.scopeChanged);
          }
        },
        capabilities: _bootstrapCapabilities,
        authedFor: engine.authedFor,
      );
    });

    // Checksum self-audit (foreground only): runs after a completed, drained
    // sync; owner is told only when a targeted repair did not fix drift.
    getIt.registerLazySingletonAsync<ChecksumAudit>(() async {
      final engine = await getIt.getAsync<SyncEngine>();
      final db = getIt<OfflineDb>();
      return ChecksumAudit(
        transport: getIt<SyncTransport>(),
        local: LocalChecksumQueries(db),
        repair: ChecksumRepair(
          db: db,
          transport: getIt<SyncTransport>(),
          appliers: getIt<ChangeApplierRegistry>(),
          notifier: getIt<DbChangeNotifier>(),
          authedFor: engine.authedFor,
          assertScope: () async {
            if (await readSessionKey() != SyncScope.current) {
              throw SyncTransportException(
                kind: SyncTransportKind.scopeChanged,
              );
            }
          },
        ),
        state: getIt<SyncStateStore>(),
        notifier: getIt<DbChangeNotifier>(),
        authedFor: engine.authedFor,
        scopeProvider: () => SyncScope.current,
        // Nothing the server still has to learn: no pending / in-flight /
        // blocked outbox row for this scope (rejected rows are not on the
        // server and are excluded from the local totals).
        idle: () async {
          final scope = SyncScope.current;
          if (scope == null) return false;
          final r = await (await db.database).rawQuery(
            "SELECT COUNT(*) AS c FROM outbox WHERE scope = ? "
            "AND status IN ('pending','inflight','blocked')",
            [scope],
          );
          return ((r.first['c'] as int?) ?? 0) == 0;
        },
        capabilities: _bootstrapCapabilities,
        // Debug builds only: log local vs REST dashboard differences.
        debugParity: kDebugMode ? _debugDashboardParity : null,
      );
    });

    // Catalog image uploads (foreground only; only the triggers start it).
    // Same transport (HttpSyncTransport is also the ImageUploadTransport)
    // and token rules (engine.authedFor) as the rest of sync.
    getIt.registerLazySingletonAsync<ImageUploader>(() async {
      final engine = await getIt.getAsync<SyncEngine>();
      final uploader = buildImageUploader(
        db: getIt<OfflineDb>(),
        store: getIt<PendingUploadStore>(),
        transport: getIt<SyncTransport>(),
        notifier: getIt<DbChangeNotifier>(),
        scopeProvider: () => SyncScope.current,
        authedFor: engine.authedFor,
      );
      if (uploader == null) {
        throw StateError('SyncTransport is not an ImageUploadTransport');
      }
      return uploader;
    });

    getIt.registerLazySingletonAsync<SyncTriggers>(() async {
      return SyncTriggers(
        await getIt.getAsync<SyncEngine>(),
        getIt<NetworkMonitor>(),
        getIt<OutboxStore>(),
        getIt<DbChangeNotifier>(),
        canSync: _syncGate,
        // Backgrounded with unsynced rows: ask the OS worker to sync soon.
        onBackgroundWork: BackgroundSync.requestSoon,
        // A background run may have changed these while we were away.
        resumeRefreshTables: syncedLocalTables(getIt<ChangeApplierRegistry>()),
        bootstrapper: await getIt.getAsync<Bootstrapper>(),
        // Resolved on first use (not here): building it needs the app
        // support folder.
        assetSync: () => getIt.getAsync<AssetSync>(),
        imageUploader: () => getIt.getAsync<ImageUploader>(),
        assetsReachable: () async =>
            await getIt<ServerReachability>().check() != null,
      );
    });

    // UI accessor for the first-setup screen (Task 11). Readiness reads the
    // LIVE session (AuthBloc), not SyncScope.current: the coordinator
    // publishes the scope asynchronously, after OfflineStatusBloc asks.
    getIt.registerLazySingletonAsync<BootstrapController>(() async {
      return BootstrapController(
        bootstrapper: await getIt.getAsync<Bootstrapper>(),
        state: getIt<SyncStateStore>(),
        scopeProvider: () => _syncSessionOf(getIt<AuthBloc>().state)?.key,
        retry: () async => (await getIt.getAsync<SyncTriggers>()).syncNow(),
      );
    });

    getIt.registerLazySingletonAsync<SyncBadgeCubit>(() async {
      final engine = await getIt.getAsync<SyncEngine>();
      return SyncBadgeCubit(
        status: engine.status,
        initial: engine.current,
        unsyncedCount: () => getIt<OutboxStore>().unsyncedCount(),
        tableChanges: getIt<DbChangeNotifier>().changes,
      );
    });

    getIt.registerLazySingletonAsync<SyncSessionGuard>(() async {
      return SyncSessionGuard(
        (await getIt.getAsync<SyncEngine>()).status,
        hasSession: () => SyncScope.current != null,
      );
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
        bootstrapper: await getIt.getAsync<Bootstrapper>(),
      );
    });
  }

  /// Starts the sync core after login when the build enables it. With
  /// kSyncEngineEnabled false (kill switch) no engine is constructed; only
  /// [SyncScope.current] follows the session so local sales/stock edits still
  /// save to the outbox (they sync once the engine is back on).
  ///
  /// If the core fails to start (any DI / async error), the session scope is
  /// still followed without an engine (review I4): otherwise
  /// [SyncScope.current] stays null and every sale write throws for the
  /// whole session. Rows then wait in the outbox for the next launch.
  /// [startCore] replaces the real start in tests.
  static Future<void> startSyncIfEnabled({
    @visibleForTesting Future<void> Function()? startCore,
  }) async {
    if (!kSyncEngineEnabled) {
      _followScopeWithoutEngine();
      return;
    }
    try {
      await (startCore ?? _startSyncCore)();
    } catch (e, st) {
      developer.log(
        'sync core failed to start; following the session scope only',
        name: 'DependenciesProvider',
        error: e,
        stackTrace: st,
      );
      try {
        _followScopeWithoutEngine();
      } catch (e2, st2) {
        developer.log(
          'scope fallback failed',
          name: 'DependenciesProvider',
          error: e2,
          stackTrace: st2,
        );
      }
    }
  }

  static Future<void> _debugDashboardParity() async {
    final businessId = getIt<AuthBloc>().state.defaultBusiness?.id;
    final remote = await getIt<DashboardRepository>().getDashboardSummary(
      businessId: businessId,
      forceRefresh: true,
    );
    if (remote.source != DashboardSummarySource.remote) return; // offline
    final queries = LocalDashboardQueries(
      db: getIt<OfflineDb>(),
      notifier: getIt<DbChangeNotifier>(),
      tenantId: () => businessId,
    );
    final local = await queries.summaryFor(
      day: BusinessDay.of(DateTime.now(), remote.timezone),
      shopId: null,
      timezone: remote.timezone,
      businessId: businessId,
    );
    const parity = DashboardParity();
    parity.log(parity.diff(local: local, remote: remote));
  }

  static Future<void> _startSyncCore() async {
    final coordinator = await getIt.getAsync<SyncCoordinator>();
    await coordinator.attach();
    final engine = await getIt.getAsync<SyncEngine>();
    final audit = await getIt.getAsync<ChecksumAudit>();
    engine.afterSyncCompleted = () async {
      await audit.maybeRun();
    };
  }

  /// Logout: stop sync for the signed-in scope before the table wipe
  /// (ledger T7 M2). Bounded: a slow in-flight page never holds the logout
  /// longer than [timeout] (the wipe then proceeds as before). Never throws.
  static Future<void> pauseSyncForWipe({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (!kSyncEngineEnabled || !getIt.isRegistered<SyncCoordinator>()) return;
    try {
      final coordinator = await getIt.getAsync<SyncCoordinator>();
      await coordinator.pauseForWipe().timeout(timeout);
    } catch (e, st) {
      developer.log(
        'pause sync before wipe failed',
        name: 'DependenciesProvider',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// The logout failed after [pauseSyncForWipe]: restart sync. Never throws.
  static Future<void> resumeSyncAfterFailedWipe() async {
    if (!kSyncEngineEnabled || !getIt.isRegistered<SyncCoordinator>()) return;
    try {
      (await getIt.getAsync<SyncCoordinator>()).resumeAfterFailedWipe();
    } catch (e, st) {
      developer.log(
        'resume sync after failed wipe failed',
        name: 'DependenciesProvider',
        error: e,
        stackTrace: st,
      );
    }
  }

  static StreamSubscription<AuthState>? _scopeOnlySub;

  @visibleForTesting
  static void resetScopeFollowerForTesting() {
    _scopeOnlySub?.cancel();
    _scopeOnlySub = null;
  }

  static void _followScopeWithoutEngine() {
    if (_scopeOnlySub != null) return;
    final auth = getIt<AuthBloc>();
    SyncScope.current = _syncSessionOf(auth.state)?.key;
    _scopeOnlySub = auth.stream.listen(
      (s) => SyncScope.current = _syncSessionOf(s)?.key,
    );
  }

  static SyncSession? _syncSessionOf(AuthState s) {
    final userId = s.profile?.id;
    final tenantId = s.defaultBusiness?.id;
    if (!s.isLoggedIn || userId == null || tenantId == null) return null;
    return SyncSession(userId: userId, tenantId: tenantId);
  }

  static Future<String> _syncAppVersion() async {
    try {
      final v = await DeviceInfoService.instance.getAppVersion();
      unawaited(BackgroundSync.rememberAppVersion(v));
      return v;
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

  /// Server capabilities for the bootstrapper's `bootstrap_paged` gate.
  /// Unreachable is "offline" (interrupted, retried), never "server not
  /// ready" (blocked).
  static Future<Set<String>> _bootstrapCapabilities() async {
    final ping = await getIt<ServerReachability>().check();
    if (ping == null) {
      throw SyncTransportException(kind: SyncTransportKind.network);
    }
    return ping.capabilities;
  }

  static T provide<T extends Object>() {
    return getIt.get<T>();
  }
}

/// The app's manual sync-now for UI callers (pending-sync "Send now", pull
/// to refresh on the catalog screens); null with the kill switch.
Future<void> Function()? appSyncNow() => kSyncEngineEnabled
    ? () async {
        await (await getIt.getAsync<SyncTriggers>()).syncNow();
      }
    : null;
