import 'package:amana_pos/barcode_scanner/data/services/barcode_permission_service.dart';
import 'package:amana_pos/barcode_scanner/presentation/bloc/barcode_scanner_bloc.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/common/services/notifications/fcm_token_service.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/features/business/domain/usecases/business_usecase.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/customers/domain/usecases/customer_usecase.dart';
import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/inventory/data/offline/offline_inbound_queue.dart';
import 'package:amana_pos/features/notification/domain/usecase/notification_usecases.dart';
import 'package:amana_pos/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/expiry_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:amana_pos/features/login/presentation/bloc/login_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/pos/domain/usecases/pos_usecase.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/products/domain/usecases/product_usecase.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/registration/domain/usecases/registration_usecase.dart';
import 'package:amana_pos/features/registration/presentation/bloc/registration_bloc.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/features/splash/domain/blocs/splash_bloc.dart';
import 'package:amana_pos/features/users/domain/usecases/users_usecase.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

getProviders(BuildContext context) => [
  BlocProvider(create: (context) => getIt<AuthBloc>()),
  BlocProvider(
    create: (context) => NavigationBloc(
      authBloc: getIt<AuthBloc>(),
    ),
  ),

  BlocProvider(create: (context) => getIt<OfflineStatusBloc>()),
  BlocProvider(create: (context) => ThemeBloc(cacheStorage: getIt<CacheStorage>())),
  BlocProvider(
    create: (context) => SplashBloc(
        cacheStorage: getIt<CacheStorage>()
    ),
  ),
  BlocProvider(
    create: (context) => RegistrationBloc(
      useCase: getIt<RegistrationUseCase>(),
    ),
  ),
  BlocProvider(
    create: (context) => LoginBloc(
      useCase: getIt<LoginUseCase>(),
      cacheStorage: getIt<CacheStorage>(),
    fcmTokenService: getIt<FcmTokenService>(),
    ),
  ),

  BlocProvider(
    create: (context) => PosBloc(
        useCase: getIt<PosUseCase>(),
    ),
  ),

  BlocProvider(
    create: (context) => BusinessBloc(
      useCase: getIt<BusinessUseCase>(),
      offlineLocalCache: getIt<OfflineLocalCache>(),
    ),
  ),
  BlocProvider(
    create: (context) => UserBloc(
      useCase: getIt<UsersUseCase>(),
    ),
  ),
  BlocProvider(
    create: (context) => CategoryBloc(
      useCase: getIt<CategoryUseCase>(),
      productUseCase: getIt<ProductUseCase>(),
      offlineLocalCache: getIt<OfflineLocalCache>(),
    ),
  ),
  BlocProvider(
    create: (context) => ProductBloc(
      useCase: getIt<ProductUseCase>(),
      offlineLocalCache: getIt<OfflineLocalCache>(),
      categoryUseCase: getIt<CategoryUseCase>(),
    ),
  ),
  BlocProvider(
    create: (context) => InventoryBloc(
      useCase: getIt<InventoryUseCase>(),
      offlineLocalCache: getIt<OfflineLocalCache>(),
      offlineInboundQueue: getIt<OfflineInboundQueue>(),
      isOnline: () async {
        final dynamic result = await getIt<Connectivity>().checkConnectivity();

        if (result is List<ConnectivityResult>) {
          return result.any((item) => item != ConnectivityResult.none);
        }

        if (result is ConnectivityResult) {
          return result != ConnectivityResult.none;
        }

        return false;
      },
    ),
  ),
  BlocProvider(
    create: (context) => ExpiryBloc(
      useCase: getIt<InventoryUseCase>(),
    ),
  ),
  BlocProvider(
    create: (context) => SettingsBloc(
      useCase: getIt<LoginUseCase>(),
          authBloc: getIt<AuthBloc>(),

    ),
  ),
  BlocProvider(
    create: (context) => CustomersBloc(
      useCase: getIt<CustomerUseCase>(),
    ),
  ),
  BlocProvider(
    create: (context) => NotificationBloc(
      useCases: getIt<NotificationUseCases>(),
      cacheStorage: getIt<CacheStorage>(),
    ),
  ),
  BlocProvider(
    create: (context) => BarcodeScannerBloc(
      permissionService: getIt<BarcodePermissionService>(),
    ),
  ),
  BlocProvider(
    create: (context) => DashboardSummaryBloc(
      getDashboardSummaryUseCase: getIt<GetDashboardSummaryUseCase>(),
    ),
  ),
];
