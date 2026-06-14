import 'package:amana_pos/common/locale_bloc/locale_bloc.dart';
import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/config/providers/providers.dart';
import 'package:amana_pos/config/router/app_router.dart';
import 'package:amana_pos/config/router/route_observer.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final AppRouter _router = AppRouter();
  static final APPRouterObserver _routeObserver = APPRouterObserver();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: getAppProviders(context),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        buildWhen: (previous, current) =>
            previous.isDarkTheme != current.isDarkTheme ||
            previous.isBigFontSize != current.isBigFontSize,
        builder: (context, themeState) {
          return BlocBuilder<LocaleBloc, LocaleState>(
            buildWhen: (previous, current) =>
                previous.locale != current.locale,
            builder: (context, localeState) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Amana POS',
                navigatorKey: Constants.navigatorKey,
                navigatorObservers: [_routeObserver],
                initialRoute: RouteStrings.splash,
                onGenerateRoute: _router.onGenerateRoute,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeState.isDarkTheme
                    ? ThemeMode.dark
                    : ThemeMode.light,
                locale: localeState.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                // Desktop OSes can apply system-level text scaling that
                // pushes the factor above 1.0, causing overflows in
                // mobile-designed widgets. Lock to 1.0 on desktop.
                builder: (context, child) {
                  Widget result = child!;
                  if (Platform.isMacOS || Platform.isWindows) {
                    result = MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.noScaling,
                      ),
                      child: result,
                    );
                  }
                  return ValueListenableBuilder<bool>(
                    valueListenable: Motion.animationsEnabled,
                    builder: (context, enabled, mqChild) {
                      return MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(disableAnimations: !enabled),
                        child: mqChild!,
                      );
                    },
                    child: result,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
