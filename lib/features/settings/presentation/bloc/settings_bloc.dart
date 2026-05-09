import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:amana_pos/features/settings/data/models/set_password_request_dto.dart';
import 'package:amana_pos/features/settings/data/models/update_profile_request_dto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final LoginUseCase useCase;
  final AuthBloc     authBloc; // single source of truth for profile

  SettingsBloc({
    required this.useCase,
    required this.authBloc,
  }) : super(SettingsState.initial()) {
    on<OnUpdateProfile>(_updateProfile);
    on<OnSetPassword>(_setPassword);
    // OnSettingsInitial removed — profile comes from AuthBloc
  }

  Future<void> _updateProfile(
      OnUpdateProfile       event,
      Emitter<SettingsState> emit,
      ) async {
    emit(state.copyWith(
      submitStatus: SettingsSubmitStatus.loading,
      submitError:  null,
    ));

    try {
      final response = await useCase.updateProfile(event.dto);
      final error    = response.getLeft().toNullable();
      final result   = response.getRight().toNullable();

      if (error != null) {
        emit(state.copyWith(
          submitStatus: SettingsSubmitStatus.failure,
          submitError:  error,
        ));
        return;
      }

      // Push updated profile to AuthBloc — single source of truth.
      // AuthBloc._onProfileUpdated emits the new profile without
      // reloading business data or bumping sessionId.
      if (result?.user != null) {
        authBloc.add(OnProfileUpdated(result!.user!));
      }

      emit(state.copyWith(submitStatus: SettingsSubmitStatus.success));
    } catch (e) {
      emit(state.copyWith(
        submitStatus: SettingsSubmitStatus.failure,
        submitError:  e.toString(),
      ));
    }
  }

  Future<void> _setPassword(
      OnSetPassword         event,
      Emitter<SettingsState> emit,
      ) async {
    emit(state.copyWith(
      passwordStatus: SettingsSubmitStatus.loading,
      passwordError:  null,
    ));

    try {
      final response = await useCase.setPassword(event.dto);
      final error    = response.getLeft().toNullable();

      if (error != null) {
        emit(state.copyWith(
          passwordStatus: SettingsSubmitStatus.failure,
          passwordError:  error,
        ));
        return;
      }

      emit(state.copyWith(passwordStatus: SettingsSubmitStatus.success));
    } catch (e) {
      emit(state.copyWith(
        passwordStatus: SettingsSubmitStatus.failure,
        passwordError:  e.toString(),
      ));
    }
  }
}