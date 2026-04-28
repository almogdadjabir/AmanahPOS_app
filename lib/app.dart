import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/config/providers/providers.dart';
import 'package:amana_pos/config/router/app_router.dart';
import 'package:amana_pos/config/router/route_observer.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final AppRouter _router = AppRouter();
  static final APPRouterObserver _routeObserver = APPRouterObserver();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: getProviders(context),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        buildWhen: (previous, current) {
          return previous.isDarkTheme != current.isDarkTheme ||
              previous.isBigFontSize != current.isBigFontSize;
        },
        builder: (context, themeState) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Amana POS',
            navigatorKey: Constants.navigatorKey,
            navigatorObservers: [_routeObserver],
            initialRoute: RouteStrings.splash,
            onGenerateRoute: _router.onGenerateRoute,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            // themeMode: themeState.isDarkTheme ? ThemeMode.dark : ThemeMode.light,
            themeMode: ThemeMode.light,
          );
        },
      ),
    );
  }
}