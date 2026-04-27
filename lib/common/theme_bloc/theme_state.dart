part of 'theme_bloc.dart';

class ThemeState extends Equatable {
  final ScreenMode? mode;
  final bool isDarkTheme;
  final bool isBigFontSize;
  final bool isLoaded;

  const ThemeState({
    this.mode = ScreenMode.light,
    this.isDarkTheme = false,
    this.isBigFontSize = false,
    this.isLoaded = false,
  });

  factory ThemeState.initial() {
    return const ThemeState(
      mode: ScreenMode.light,
      isDarkTheme: false,
      isBigFontSize: false,
      isLoaded: false,
    );
  }

  ThemeState copyWith({
    ScreenMode? mode,
    bool? isDarkTheme,
    bool? isBigFontSize,
    bool? isLoaded,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      isBigFontSize: isBigFontSize ?? this.isBigFontSize,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    isDarkTheme,
    isBigFontSize,
    isLoaded,
  ];
}