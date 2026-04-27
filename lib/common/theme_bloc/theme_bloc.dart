import 'dart:ui';

import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final CacheStorage cacheStorage;

  ThemeBloc({required this.cacheStorage}) : super(ThemeState.initial()) {
    on<OnThemeChangeEvent>(_changeTheme);
    on<OnChangeFontSizeEvent>(_onChangeFontSizeEvent);
    on<OnThemeLoadedEvent>(_onThemeLoaded);

    _loadAccessibilitySettings();
  }

  Future<void> _loadAccessibilitySettings() async {
    final results = await Future.wait([
      cacheStorage.getBool(Constants.isDarkTheme),
      cacheStorage.getBool(Constants.isBigFontSize),
    ]);
    add(OnThemeLoadedEvent(
      isDarkTheme: results[0] ?? false,
      isBigFontSize: results[1] ?? false,
    ));
  }

  Future<void> _onThemeLoaded(OnThemeLoadedEvent event, Emitter<ThemeState> emit) async {
    final modeString = await cacheStorage.getValue(Constants.appTheme);

    final mode = ScreenMode.values.firstWhere(
          (e) => e.name == modeString,
      orElse: () => ScreenMode.device,
    );

    add(OnThemeChangeEvent(mode: mode));

    emit(state.copyWith(
      isDarkTheme: event.isDarkTheme,
      isBigFontSize: event.isBigFontSize,
      isLoaded: true,
    ));
  }

  void _changeTheme(OnThemeChangeEvent event, Emitter<ThemeState> emit) {
    bool isDarkTheme;

    switch (event.mode) {
      case ScreenMode.dark:
        isDarkTheme = true;
        break;

      case ScreenMode.light:
        isDarkTheme = false;
        break;

      case ScreenMode.device:
        final brightness =
            PlatformDispatcher.instance.platformBrightness;
        isDarkTheme = brightness == Brightness.dark;
        break;
    }

    cacheStorage.setBool(Constants.isDarkTheme, isDarkTheme);
    cacheStorage.save(Constants.appTheme, event.mode.name);
    Constants.currentSelectedMode = event.mode;
    emit(state.copyWith(isDarkTheme: isDarkTheme, mode: event.mode));
  }

  void _onChangeFontSizeEvent(OnChangeFontSizeEvent event, Emitter<ThemeState> emit) {
    cacheStorage.setBool(Constants.isBigFontSize, event.isBigFontSize);
    emit(state.copyWith(isBigFontSize: event.isBigFontSize));
  }
}