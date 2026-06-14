part of 'theme_bloc.dart';

class ThemeState extends Equatable {
  final ScreenMode? mode;
  final bool isDarkTheme;
  final bool isBigFontSize;
  final bool isLoaded;
  final AnimationPreference animationPreference;
  final bool animationsEnabled;

  const ThemeState({
    this.mode = ScreenMode.light,
    this.isDarkTheme = false,
    this.isBigFontSize = false,
    this.isLoaded = false,
    this.animationPreference = AnimationPreference.auto,
    this.animationsEnabled = true,
  });

  factory ThemeState.initial() {
    return const ThemeState(
      mode: ScreenMode.light,
      isDarkTheme: false,
      isBigFontSize: false,
      isLoaded: false,
      animationPreference: AnimationPreference.auto,
      animationsEnabled: true,
    );
  }

  ThemeState copyWith({
    ScreenMode? mode,
    bool? isDarkTheme,
    bool? isBigFontSize,
    bool? isLoaded,
    AnimationPreference? animationPreference,
    bool? animationsEnabled,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      isBigFontSize: isBigFontSize ?? this.isBigFontSize,
      isLoaded: isLoaded ?? this.isLoaded,
      animationPreference: animationPreference ?? this.animationPreference,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        isDarkTheme,
        isBigFontSize,
        isLoaded,
        animationPreference,
        animationsEnabled,
      ];
}
