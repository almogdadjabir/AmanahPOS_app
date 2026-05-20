import 'dart:ui';

import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'locale_event.dart';
part 'locale_state.dart';

class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  final CacheStorage cacheStorage;

  LocaleBloc({required this.cacheStorage}) : super(LocaleState.initial()) {
    on<OnLocaleLoaded>(_onLocaleLoaded);
    on<OnLocaleChanged>(_onLocaleChanged);

    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final saved = await cacheStorage.getValue(Constants.appLocale);
    add(OnLocaleLoaded(languageCode: saved ?? 'en'));
  }

  void _onLocaleLoaded(OnLocaleLoaded event, Emitter<LocaleState> emit) {
    emit(state.copyWith(
      locale: Locale(event.languageCode),
      isLoaded: true,
    ));
  }

  Future<void> _onLocaleChanged(
      OnLocaleChanged event, Emitter<LocaleState> emit) async {
    await cacheStorage.save(Constants.appLocale, event.languageCode);
    emit(state.copyWith(locale: Locale(event.languageCode)));
  }
}
