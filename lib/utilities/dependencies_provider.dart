import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/environment/environment.dart';
import 'package:amana_pos/config/router/app_router.dart';
import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/core/network/app_interceptors.dart';
import 'package:amana_pos/core/network/dio_client.dart';
import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/data/offline_remote_data_source.dart';
import 'package:amana_pos/core/offline/offline_catalog_cache.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/offline/offline_first_manager.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/sync/sync_manager.dart';
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
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
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
import 'package:amana_pos/features/users/data/repository_impl/users_repo_impl.dart';
import 'package:amana_pos/features/users/domain/repositories/users_repository.dart';
import 'package:amana_pos/features/users/domain/usecases/users_usecase.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

class DependenciesProvider {
  DependenciesProvider._();

  static void build() {
    // Core/common
    getIt.registerLazySingleton<CacheStorage>(() => CacheStorage());
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

    // Sync manager
    getIt.registerLazySingleton<SyncManager>(
          () => SyncManager(
        salesQueue: getIt<OfflineSalesQueue>(),
        posRemoteDataSource: getIt<PosRemoteDataSource>(),
      ),
    );

    // Offline-first manager
    getIt.registerLazySingleton<OfflineFirstManager>(
          () => OfflineFirstManager(
        networkMonitor: getIt<NetworkMonitor>(),
        localCache: getIt<OfflineLocalCache>(),
        remoteDataSource: getIt<OfflineRemoteDataSource>(),
        syncManager: getIt<SyncManager>(),
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

    getIt.registerLazySingleton<NavigationBloc>(
          () => NavigationBloc(),
    );


  }

  static T provide<T extends Object>() {
    return getIt.get<T>();
  }
}