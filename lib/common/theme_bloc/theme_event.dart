part of 'theme_bloc.dart';

class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class OnThemeChangeEvent extends ThemeEvent {
  final ScreenMode mode;
  const OnThemeChangeEvent({required this.mode});
}

class OnChangeFontSizeEvent extends ThemeEvent {
  final bool isBigFontSize;
  const OnChangeFontSizeEvent({required this.isBigFontSize});
}

class OnThemeLoadedEvent extends ThemeEvent {
  final bool isDarkTheme;
  final bool isBigFontSize;

  const OnThemeLoadedEvent({
    required this.isDarkTheme,
    required this.isBigFontSize
  });
}