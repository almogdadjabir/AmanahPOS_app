part of 'login_bloc.dart';

enum PageStatus { initial, loading, success, failure }

enum LoginStatus {
  form(0),
  otp(1),
  competed(2);

  final int page;
  const LoginStatus(this.page);
}

class LoginState extends Equatable {
  final bool isLoading;
  final String? responseError;
  final PageStatus status;
  final LoginStatus loginStatus;
  final String? phoneNumber;
  final String? mobileError;
  final bool isFormValid;
  final bool isMobileValid;
  final bool validationActive;
  final LoginResponse? loginResponse;

  // OTP
  final String? otp;
  final bool isPinMatched;
  final String? otpError;
  final int otpResendSeconds; // ← NEW

  const LoginState({
    this.isLoading = false,
    this.responseError,
    this.status = PageStatus.initial,
    this.loginStatus = LoginStatus.form,
    this.phoneNumber,
    this.mobileError,
    required this.isFormValid,
    required this.isMobileValid,
    required this.validationActive,
    this.isPinMatched = false,
    this.otp,
    this.loginResponse,
    this.otpError,
    this.otpResendSeconds = 45,
  });

  factory LoginState.initial() {
    return const LoginState(
      status: PageStatus.initial,
      loginStatus: LoginStatus.form,
      isLoading: false,
      responseError: null,
      phoneNumber: null,
      mobileError: null,
      isFormValid: false,
      isMobileValid: false,
      validationActive: false,
      otp: null,
      isPinMatched: false,
      loginResponse: null,

      otpError: null,
      otpResendSeconds: 45, // ← NEW
    );
  }

  static const int maxPasswordAttempts = 3;


  LoginState copyWith({
    PageStatus? status,
    LoginStatus? loginStatus,
    bool? isLoading,
    String? responseError,
    String? password,
    String? pinfl,
    String? phoneNumber,
    String? mobileError,
    bool clearMobileError = false,   // ← NEW: explicit clear flag
    String? passwordError,
    String? pinflError,
    bool? isFormValid,
    bool? isMobileValid,
    bool? isPinflValid,
    bool? isPasswordValid,
    bool? isPasswordValidLength,
    bool? viewPassword,
    bool? validationActive,
    String? otp,
    bool? isPinMatched,
    LoginResponse? loginResponse,
    String? otpIdentifierId,
    int? passwordAttempts,
    bool? showAttemptsWarning,
    int? usernameResetCount,
    int? passwordResetCount,
    String? otpError,
    bool clearOtpError = false,      // ← NEW: explicit clear flag
    int? otpResendSeconds,           // ← NEW
  }) {
    return LoginState(
      status: status ?? this.status,
      loginStatus: loginStatus ?? this.loginStatus,
      isLoading: isLoading ?? this.isLoading,
      responseError: responseError,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      mobileError: clearMobileError ? null : (mobileError ?? this.mobileError),
      isFormValid: isFormValid ?? this.isFormValid,
      isMobileValid: isMobileValid ?? this.isMobileValid,
      validationActive: validationActive ?? this.validationActive,
      otp: otp ?? this.otp,
      otpError: clearOtpError ? null : (otpError ?? this.otpError),
      loginResponse: loginResponse ?? this.loginResponse,
      isPinMatched: isPinMatched ?? this.isPinMatched,
      otpResendSeconds: otpResendSeconds ?? this.otpResendSeconds,
    );
  }

  @override
  List<Object?> get props => [
    status,
    loginStatus,
    isLoading,
    responseError,
    phoneNumber,
    mobileError,
    isFormValid,
    isMobileValid,
    validationActive,
    otp,
    loginResponse,
    isPinMatched,
    otpError,
    otpResendSeconds, // ← NEW
  ];
}