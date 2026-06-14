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

class OnAnimationsPreferenceChanged extends ThemeEvent {
  final AnimationPreference preference;
  const OnAnimationsPreferenceChanged(this.preference);

  @override
  List<Object?> get props => [preference];
}

class OnAnimationsLoadedEvent extends ThemeEvent {
  final AnimationPreference preference;
  final bool animationsEnabled;
  const OnAnimationsLoadedEvent({
    required this.preference,
    required this.animationsEnabled,
  });

  @override
  List<Object?> get props => [preference, animationsEnabled];
}