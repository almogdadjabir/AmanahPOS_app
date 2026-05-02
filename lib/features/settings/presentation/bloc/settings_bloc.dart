import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:amana_pos/features/settings/data/models/set_password_request_dto.dart';
import 'package:amana_pos/features/settings/data/models/update_profile_request_dto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final LoginUseCase useCase;

  SettingsBloc({
    required this.useCase,
  }) : super(SettingsState.initial()) {
    on<OnSettingsInitial>(_initial);
    on<OnUpdateProfile>(_updateProfile);
    on<OnSetPassword>(_setPassword);
  }

  Future<void> _initial(
      OnSettingsInitial event,
      Emitter<SettingsState> emit,
      ) async {
    emit(state.copyWith(status: SettingsStatus.loading, responseError: null));

    try {
      final response = await useCase.getProfile();
      final error = response.getLeft().toNullable();
      final result = response.getRight().toNullable();

      if (error != null) {
        emit(state.copyWith(
          status: SettingsStatus.failure,
          responseError: error,
        ));
        return;
      }

      emit(state.copyWith(
        status: SettingsStatus.success,
        profile: result?.user!,
        responseError: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SettingsStatus.failure,
        responseError: e.toString(),
      ));
    }
  }

  Future<void> _updateProfile(
      OnUpdateProfile event,
      Emitter<SettingsState> emit,
      ) async {
    emit(state.copyWith(
      submitStatus: SettingsSubmitStatus.loading,
      submitError: null,
    ));

    try {
      final response = await useCase.updateProfile(event.dto);
      final error = response.getLeft().toNullable();
      final result = response.getRight().toNullable();

      if (error != null) {
        emit(state.copyWith(
          submitStatus: SettingsSubmitStatus.failure,
          submitError: error,
        ));
        return;
      }

      emit(state.copyWith(
        profile: result?.user ?? state.profile,
        submitStatus: SettingsSubmitStatus.success,
        submitError: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        submitStatus: SettingsSubmitStatus.failure,
        submitError: e.toString(),
      ));
    }
  }

  Future<void> _setPassword(
      OnSetPassword event,
      Emitter<SettingsState> emit,
      ) async {
    emit(state.copyWith(
      passwordStatus: SettingsSubmitStatus.loading,
      passwordError: null,
    ));

    try {
      final response = await useCase.setPassword(event.dto);
      final error = response.getLeft().toNullable();

      if (error != null) {
        emit(state.copyWith(
          passwordStatus: SettingsSubmitStatus.failure,
          passwordError: error,
        ));
        return;
      }

      emit(state.copyWith(
        passwordStatus: SettingsSubmitStatus.success,
        passwordError: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        passwordStatus: SettingsSubmitStatus.failure,
        passwordError: e.toString(),
      ));
    }
  }
}