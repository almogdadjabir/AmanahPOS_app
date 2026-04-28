import 'package:amana_pos/api/network/app_interceptors.dart';
import 'package:amana_pos/api/network/dio_client.dart';
import 'package:amana_pos/api/request_handler.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/environment/environment.dart';
import 'package:amana_pos/config/router/app_router.dart';
import 'package:amana_pos/features/business/data/repository_impl/business_repo_impl.dart';
import 'package:amana_pos/features/business/domain/repositories/business_repository.dart';
import 'package:amana_pos/features/business/domain/usecases/business_usecase.dart';
import 'package:amana_pos/features/dashboard/data/repository_impl/dashboard_repo_impl.dart';
import 'package:amana_pos/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:amana_pos/features/dashboard/domain/usecases/dashboard_usecase.dart';
import 'package:amana_pos/features/login/data/repository_impl/login_repo_impl.dart';
import 'package:amana_pos/features/login/domain/repository/login_repository.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/registration/data/repository_impl/registration_repo_impl.dart';
import 'package:amana_pos/features/registration/domain/repositories/registration_repository.dart';
import 'package:amana_pos/features/registration/domain/usecases/registration_usecase.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';


final getIt = GetIt.instance;

class DependenciesProvider {
  DependenciesProvider._();

  static void build() {
    // common
    getIt.registerLazySingleton<CacheStorage>(() => CacheStorage());
    getIt.registerLazySingleton<AppRouter>(() => AppRouter());

    getIt.registerLazySingleton<Dio>(() => Dio());

    getIt.registerLazySingleton<DioClient>(
          () => DioClient(baseUrl, dio: getIt<Dio>(), interceptors: [AppInterceptors(getIt<Dio>())]),
    );

    getIt.registerLazySingleton<RequestHandler>(() => RequestHandler(getIt<DioClient>()));

    ///repository
    // getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt<RequestHandler>()));

    getIt.registerLazySingleton<RegistrationRepository>(
          () => RegistrationRepoImpl(getIt<RequestHandler>()),
    );

    getIt.registerLazySingleton<LoginRepository>(
          () => LoginRepoImpl(getIt<RequestHandler>()),
    );

    getIt.registerLazySingleton<DashboardRepository>(
          () => DashboardRepoImpl(getIt<RequestHandler>()),
    );

    getIt.registerLazySingleton<BusinessRepository>(
          () => BusinessRepoImpl(getIt<RequestHandler>()),
    );

    ///use-cases
    // getIt.registerLazySingleton<AuthUseCase>(
    //       () => AuthUseCase(repository: getIt<AuthRepository>(), cacheStorage: getIt<CacheStorage>()),
    // );

    getIt.registerLazySingleton<RegistrationUseCase>(
          () => RegistrationUseCase(
        repository: getIt<RegistrationRepository>(),
      ),
    );

    getIt.registerLazySingleton<LoginUseCase>(
          () => LoginUseCase(
        repository: getIt<LoginRepository>(), cacheStorage: getIt<CacheStorage>(),
      ),
    );

    getIt.registerLazySingleton<DashboardUseCase>(
          () => DashboardUseCase(
        repository: getIt<DashboardRepository>(),
      ),
    );

    getIt.registerLazySingleton<BusinessUseCase>(
          () => BusinessUseCase(
        repository: getIt<BusinessRepository>(),
      ),
    );




    getIt.registerLazySingleton<AuthBloc>(() => AuthBloc(
      useCase: getIt<LoginUseCase>(),
    ));

    getIt.registerLazySingleton<NavigationBloc>(() => NavigationBloc());

  }

  static T provide<T extends Object>() {
    return getIt.get<T>();
  }
}