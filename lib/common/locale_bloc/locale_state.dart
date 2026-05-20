part of 'locale_bloc.dart';

class LocaleState extends Equatable {
  final Locale locale;
  final bool isLoaded;

  const LocaleState({
    this.locale = const Locale('en'),
    this.isLoaded = false,
  });

  factory LocaleState.initial() => const LocaleState();

  LocaleState copyWith({
    Locale? locale,
    bool? isLoaded,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [locale, isLoaded];
}
