import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/features/dashboard/domain/usecases/dashboard_usecase.dart';
import 'package:amana_pos/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:amana_pos/features/login/presentation/bloc/login_bloc.dart';
import 'package:amana_pos/features/registration/domain/usecases/registration_usecase.dart';
import 'package:amana_pos/features/registration/presentation/bloc/registration_bloc.dart';
import 'package:amana_pos/features/splash/domain/blocs/splash_bloc.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

getProviders(BuildContext context) => [
  // BlocProvider(create: (context) => getIt<AuthBloc>()),
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
    create: (context) => DashboardBloc(
        useCase: getIt<DashboardUseCase>(),
    ),
  ),
];
