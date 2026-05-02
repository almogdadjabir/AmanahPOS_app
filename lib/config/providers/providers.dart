import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/features/business/domain/usecases/business_usecase.dart';
import 'package:amana_pos/features/business/presentation/bloc/business_bloc.dart';
import 'package:amana_pos/features/category/domain/usecases/category_usecase.dart';
import 'package:amana_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

getProviders(BuildContext context) => [
  BlocProvider(create: (context) => getIt<AuthBloc>()),
  BlocProvider(create: (context) => getIt<NavigationBloc>()),
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
      cacheStorage: getIt<CacheStorage>()
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
    ),
  ),
  BlocProvider(
    create: (context) => ProductBloc(
      useCase: getIt<ProductUseCase>(),
    ),
  ),
  BlocProvider(
    create: (context) => InventoryBloc(
      useCase: getIt<InventoryUseCase>(),
    ),
  ),
  BlocProvider(
    create: (context) => SettingsBloc(
      useCase: getIt<LoginUseCase>(),
    ),
  ),
];
