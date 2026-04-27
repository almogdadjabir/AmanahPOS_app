import 'dart:async';

import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final CacheStorage cacheStorage;

  SplashBloc({
    required this.cacheStorage,
  }) : super(const SplashState.initial()) {
    on<SplashStarted>(_onSplashStarted);
  }

  Future<void> _onSplashStarted(
      SplashStarted event,
      Emitter<SplashState> emit,
      ) async {
    emit(state.copyWith(status: SplashStatus.loading));

    try {
      // Keep splash visible for smooth animation.
      await Future<void>.delayed(const Duration(milliseconds: 1800));

      final token = await cacheStorage.getValue(Constants.authToken);

      final bool isLoggedIn = token != null && token.toString().trim().isNotEmpty;

      emit(
        state.copyWith(
          status: isLoggedIn
              ? SplashStatus.authenticated
              : SplashStatus.unauthenticated,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: SplashStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}