import 'dart:async';
import 'dart:developer';
import 'package:amana_pos/common/auth_bloc/auth_bloc.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/features/login/data/models/login_request.dart';
import 'package:amana_pos/features/login/data/models/login_response.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_request.dart';
import 'package:amana_pos/features/login/data/models/otp_verify_response.dart';
import 'package:amana_pos/features/login/domain/usecase/login_usecase.dart';
import 'package:amana_pos/widgets/phone_number_field.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  static const int _otpLength = 6;

  Timer? _debounceTimer;
  Timer? _resendTimer;

  final LoginUseCase useCase;
  final CacheStorage cacheStorage;

  LoginBloc({
    required this.useCase,
    required this.cacheStorage,
  }) : super(LoginState.initial()) {
    _initializeEvents();
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _resendTimer?.cancel();
    return super.close();
  }

  void _initializeEvents() {
    on<OnMobileChangedEvent>(_onMobileChanged);
    on<OnLoginSubmitEvent>(_onLoginSubmit);
    on<OnChangeOtpEvent>(_onChangeOtp);
    on<OnSubmitOtpEvent>(_onSubmitOtp);
    on<OnResendOtpEvent>(_onResendOtp);
    on<OnResetEvent>(_onReset);
    on<OnOtpTimerTickEvent>(_onOtpTimerTick);
  }


  void _onMobileChanged(
      OnMobileChangedEvent event,
      Emitter<LoginState> emit,
      ) {
    final digits = event.mobile.replaceAll(RegExp(r'\D'), '');
    final expectedLength = phoneMaxLength(digits);
    final isValid = digits.length == expectedLength;

    emit(state.copyWith(
      phoneNumber: event.mobile,
      isMobileValid: isValid,
      isFormValid: isValid,
      clearMobileError: true,
    ));
  }


  Future<void> _onLoginSubmit(
      OnLoginSubmitEvent event,
      Emitter<LoginState> emit,
      ) async {
    final digits = (state.phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');

    if (digits.length < phoneMaxLength(digits)) {
      emit(state.copyWith(
        mobileError: 'Please enter a valid mobile number.',
        status: PageStatus.failure,
      ));
      return;
    }

    emit(state.copyWith(
      isLoading: true,
      status: PageStatus.loading,
      clearMobileError: true,
    ));

    try {
      final response = await useCase.userLogin(
        LoginRequest(phone: '+249$digits'),
      );

      if (emit.isDone) return;

      // ── No async lambdas — handle inline ──
      final String? error = response.isLeft()
          ? response.getLeft().toNullable()
          : null;

      if (error != null) {
        emit(state.copyWith(
          isLoading: false,
          status: PageStatus.failure,
          responseError: error,
        ));
        return;
      }

      _startResendTimer();
      emit(state.copyWith(
        isLoading: false,
        status: PageStatus.success,
        loginStatus: LoginStatus.otp,
        otpResendSeconds: 45,
      ));

    } catch (e) {
      if (emit.isDone) return;
      log('LoginBloc._onLoginSubmit error: $e');
      emit(state.copyWith(
        isLoading: false,
        status: PageStatus.failure,
        responseError: e.toString(),
      ));
    }
  }


  void _onChangeOtp(
      OnChangeOtpEvent event,
      Emitter<LoginState> emit,
      ) {
    emit(state.copyWith(
      otp: event.otpCode,
      clearOtpError: true,
    ));

    // Auto-submit when all digits are filled
    if (event.otpCode.length == _otpLength) {
      add( OnSubmitOtpEvent());
    }
  }

  Future<void> _onSubmitOtp(
      OnSubmitOtpEvent event,
      Emitter<LoginState> emit,
      ) async {
    final code = state.otp ?? '';
    if (code.length < _otpLength || state.isLoading || state.isPinMatched) return;

    emit(state.copyWith(
      isLoading: true,
      status: PageStatus.loading,
      clearOtpError: true,
    ));

    try {
      final digits = (state.phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');

      final response = await useCase.otpVerify(
        OtpVerifyRequest(phone: '+249$digits', otp: code),
      );

      if (emit.isDone) return;

      final String? error = response.isLeft()
          ? response.getLeft().toNullable()
          : null;
      final OtpVerifyResponse? loginResponse = response.isRight()
          ? response.getRight().toNullable()
          : null;

      if (error != null) {
        emit(state.copyWith(
          isLoading: false,
          status: PageStatus.failure,
          otpError: error.isEmpty ? 'Invalid code. Please try again.' : error,
          otp: '',
        ));
        return;
      }

      final authBloc = getIt<AuthBloc>();
      authBloc.add(OnLoadProfileEvent(user: loginResponse?.loginData?.user));

      emit(state.copyWith(
        isLoading: false,
        status: PageStatus.success,
        isPinMatched: true,
      ));

      await _storeTokens(
        loginResponse?.loginData?.access,
        loginResponse?.loginData?.refresh,
      );

      await Future.delayed(const Duration(milliseconds: 600));
      if (emit.isDone) return;

      emit(state.copyWith(loginStatus: LoginStatus.competed));

    } catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(
        isLoading: false,
        status: PageStatus.failure,
        otpError: e.toString(),
        otp: '',
      ));
    }
  }

  Future<void> _storeTokens(String? accessToken, String? refreshToken) async {
    await cacheStorage.save(Constants.authToken, accessToken);
    await cacheStorage.save(Constants.refreshToken, refreshToken);
  }

  Future<void> _onResendOtp(
      OnResendOtpEvent event,
      Emitter<LoginState> emit,
      ) async {
    emit(state.copyWith(isLoading: true, clearOtpError: true));

    try {
      // TODO: replace with your actual resend call
      // e.g. await useCase.resendOtp(identifier: state.otpIdentifierId!);
      await Future.delayed(const Duration(milliseconds: 500)); // ← remove when real

      if (emit.isDone) return;

      _startResendTimer();
      emit(state.copyWith(
        isLoading: false,
        otpResendSeconds: 45,
      ));
    } catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(
        isLoading: false,
        otpError: e.toString(),
      ));
    }
  }

  // ─── Timer ────────────────────────────────────────────────────────────────

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) add(const OnOtpTimerTickEvent());
    });
  }

  void _onOtpTimerTick(
      OnOtpTimerTickEvent event,
      Emitter<LoginState> emit,
      ) {
    if (state.otpResendSeconds <= 0) {
      _resendTimer?.cancel();
      return;
    }
    emit(state.copyWith(otpResendSeconds: state.otpResendSeconds - 1));
  }

  // ─── Reset ────────────────────────────────────────────────────────────────

  void _onReset(OnResetEvent event, Emitter<LoginState> emit) {
    _resendTimer?.cancel();
    if (event.isPhoneChange == true) {
      // Go back to phone page, preserve the phone number
      emit(state.copyWith(
        loginStatus: LoginStatus.form,
        status: PageStatus.initial,
        isLoading: false,
        clearOtpError: true,
        isPinMatched: false,
        otp: '',
        otpResendSeconds: 45,
      ));
    } else {
      emit(LoginState.initial());
    }
  }
}