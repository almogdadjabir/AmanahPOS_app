import 'dart:async';

import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final CacheStorage cacheStorage;
  final PinVaultService vault;

  SplashBloc({required this.cacheStorage, required this.vault})
    : super(const SplashState.initial()) {
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
      final hasVault = await vault.hasAnyEnrolled();

      final SplashStatus next;
      if (hasVault) {
        next = SplashStatus.pinLocked;
      } else if (token != null && token.toString().trim().isNotEmpty) {
        next = SplashStatus.authenticated;
      } else {
        next = SplashStatus.unauthenticated;
      }

      emit(state.copyWith(status: next));
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
