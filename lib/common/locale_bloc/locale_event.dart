part of 'locale_bloc.dart';

class LocaleEvent extends Equatable {
  const LocaleEvent();

  @override
  List<Object?> get props => [];
}

class OnLocaleLoaded extends LocaleEvent {
  final String languageCode;
  const OnLocaleLoaded({required this.languageCode});

  @override
  List<Object?> get props => [languageCode];
}

class OnLocaleChanged extends LocaleEvent {
  final String languageCode;
  const OnLocaleChanged({required this.languageCode});

  @override
  List<Object?> get props => [languageCode];
}
