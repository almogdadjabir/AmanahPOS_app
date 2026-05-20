import 'package:amana_pos/barcode_scanner/data/services/barcode_permission_service.dart';
import 'package:amana_pos/barcode_scanner/presentation/bloc/barcode_scanner_bloc.dart';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/common/services/notifications/fcm_token_service.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/customers/domain/usecases/customer_usecase.dart';
import 'package:amana_pos/features/customers/presentation/bloc/customers_bloc.dart';
import 'package:amana_pos/features/inventory/data/offline/offline_inbound_queue.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/expiry_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/expiry_report_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inbound_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/premium_inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/stock_levels_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/vendors_bloc.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:amana_pos/features/login/presentation/bloc/login_bloc.dart';
import 'package:amana_pos/features/products/domain/usecases/product_usecase.dart';
import 'package:amana_pos/features/registration/domain/usecases/registration_usecase.dart';
import 'package:amana_pos/features/registration/presentation/bloc/registration_bloc.dart';
import 'package:amana_pos/features/returns/domain/usecases/returns_usecase.dart';
import 'package:amana_pos/features/returns/presentation/bloc/returns_bloc.dart';
import 'package:amana_pos/features/sales_history/domain/usecases/sales_history_usecase.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:amana_pos/features/splash/domain/blocs/splash_bloc.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeatureBlocProviders {
  const FeatureBlocProviders._();

  static Widget splash({required Widget child}) {
    return BlocProvider(
      create: (_) => SplashBloc(
        cacheStorage: getIt<CacheStorage>(),
      ),
      child: child,
    );
  }

  static Widget login({required Widget child}) {
    return BlocProvider(
      create: (_) => LoginBloc(
        useCase: getIt<LoginUseCase>(),
        cacheStorage: getIt<CacheStorage>(),
        fcmTokenService: getIt<FcmTokenService>(),
      ),
      child: child,
    );
  }

  static Widget registration({required Widget child}) {
    return BlocProvider(
      create: (_) => RegistrationBloc(
        useCase: getIt<RegistrationUseCase>(),
      ),
      child: child,
    );
  }

  static Widget categories({required Widget child}) {
    return BlocProvider(
      create: (_) => CategoryBloc(
        useCase: getIt<CategoryUseCase>(),
        productUseCase: getIt<ProductUseCase>(),
        offlineLocalCache: getIt<OfflineLocalCache>(),
      ),
      child: child,
    );
  }

  static Widget customers({required Widget child}) {
    return BlocProvider(
      create: (_) => CustomersBloc(
        useCase: getIt<CustomerUseCase>(),
      ),
      child: child,
    );
  }

  static Widget inventory({required Widget child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => InventoryBloc(
            useCase: getIt<InventoryUseCase>(),
            offlineLocalCache: getIt<OfflineLocalCache>(),
            offlineInboundQueue: getIt<OfflineInboundQueue>(),
            isOnline: () => getIt<OfflineStatusBloc>().isDeviceOnline,
          ),
        ),
        BlocProvider(
          create: (_) => ExpiryBloc(
            useCase: getIt<InventoryUseCase>(),
          ),
        ),
        BlocProvider(
          create: (_) => PremiumInventoryBloc(
            useCase: getIt<InventoryUseCase>(),
            offlineLocalCache: getIt<OfflineLocalCache>(),
            isOnline: () => getIt<OfflineStatusBloc>().isDeviceOnline,
          ),
        ),
        BlocProvider(
          create: (_) => StockLevelsBloc(
            useCase: getIt<InventoryUseCase>(),
          ),
        ),
        BlocProvider(
          create: (_) => InboundBloc(
            useCase: getIt<InventoryUseCase>(),
            offlineLocalCache: getIt<OfflineLocalCache>(),
            offlineInboundQueue: getIt<OfflineInboundQueue>(),
            isOnline: () => getIt<OfflineStatusBloc>().isDeviceOnline,
          ),
        ),
        BlocProvider(
          create: (_) => VendorsBloc(
            useCase: getIt<InventoryUseCase>(),
            offlineLocalCache: getIt<OfflineLocalCache>(),
            isOnline: () => getIt<OfflineStatusBloc>().isDeviceOnline,
          ),
        ),
        BlocProvider(
          create: (_) => ExpiryReportBloc(
            useCase: getIt<InventoryUseCase>(),
          ),
        ),
      ],
      child: child,
    );
  }

  static Widget settings({required Widget child}) {
    return BlocProvider(
      create: (_) => SettingsBloc(
        useCase: getIt<LoginUseCase>(),
        authBloc: getIt<AuthBloc>(),
      ),
      child: child,
    );
  }

  static Widget barcodeScanner({required Widget child}) {
    return BlocProvider(
      create: (_) => BarcodeScannerBloc(
        permissionService: getIt<BarcodePermissionService>(),
      ),
      child: child,
    );
  }

  static Widget expiryAlerts({required Widget child}) {
    return BlocProvider(
      create: (_) => ExpiryBloc(
        useCase: getIt<InventoryUseCase>(),
      ),
      child: child,
    );
  }


  static Widget salesHistory({required Widget child}) {
    return BlocProvider(
      create: (_) => SalesHistoryBloc(
        useCase: getIt<SalesHistoryUseCase>(),
      ),
      child: child,
    );
  }

  static Widget returns({required Widget child}) {
    return BlocProvider(
      create: (_) => ReturnsBloc(
        useCase: getIt<ReturnsUseCase>(),
      ),
      child: child,
    );
  }
}