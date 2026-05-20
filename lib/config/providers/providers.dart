import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/features/business/domain/usecases/business_usecase.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_summary_bloc.dart';
import 'package:amana_pos/features/main_screen/presentation/bloc/navigation_bloc.dart';
import 'package:amana_pos/features/notification/domain/usecase/notification_usecases.dart';
import 'package:amana_pos/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:amana_pos/features/pos/domain/usecases/pos_usecase.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/products/domain/usecases/product_usecase.dart';
import 'package:amana_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:amana_pos/features/users/domain/usecases/users_usecase.dart';
import 'package:amana_pos/features/users/presentation/bloc/users_bloc.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

List<BlocProvider> getAppProviders(BuildContext context) {
  return [
    BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>(),
    ),

    BlocProvider<ThemeBloc>(
      create: (_) => ThemeBloc(
        cacheStorage: getIt<CacheStorage>(),
      ),
    ),

    BlocProvider<OfflineStatusBloc>(
      create: (_) => getIt<OfflineStatusBloc>(),
    ),

    BlocProvider<NavigationBloc>(
      create: (_) => NavigationBloc(
        authBloc: getIt<AuthBloc>(),
      ),
    ),

    BlocProvider<BusinessBloc>(
      create: (_) => BusinessBloc(
        useCase: getIt<BusinessUseCase>(),
        offlineLocalCache: getIt<OfflineLocalCache>(),
      ),
    ),

    BlocProvider<PosBloc>(
      create: (_) => PosBloc(
        useCase: getIt<PosUseCase>(),
      ),
    ),

    BlocProvider<ProductBloc>(
      create: (_) => ProductBloc(
        useCase: getIt<ProductUseCase>(),
        offlineLocalCache: getIt<OfflineLocalCache>(),
        categoryUseCase: getIt<CategoryUseCase>(),
      ),
    ),

    BlocProvider<DashboardSummaryBloc>(
      create: (_) => DashboardSummaryBloc(
        getDashboardSummaryUseCase: getIt<GetDashboardSummaryUseCase>(),
      ),
    ),

    // Keep global because OfflinePreparationListener + PosAppBar use it.
    BlocProvider<NotificationBloc>(
      create: (_) => NotificationBloc(
        useCases: getIt<NotificationUseCases>(),
        cacheStorage: getIt<CacheStorage>(),
      ),
    ),

    // Keep global because Business workspace reads it directly.
    BlocProvider<UserBloc>(
      create: (_) => UserBloc(
        useCase: getIt<UsersUseCase>(),
      ),
    ),
  ];
}
