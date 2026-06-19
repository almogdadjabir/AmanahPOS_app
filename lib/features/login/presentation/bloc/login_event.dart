part of 'login_bloc.dart';

class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props {
    return [];
  }
}


class OnMobileChangedEvent extends LoginEvent {
  final String mobile;

  const OnMobileChangedEvent({required this.mobile});
}


class OnLoginSubmitEvent extends LoginEvent {}

class OnPasswordLoginEvent extends LoginEvent {
  final String password;
  const OnPasswordLoginEvent({required this.password});

  @override
  List<Object?> get props => [password];
}

class OnCountryChangedEvent extends LoginEvent {
  final LoginCountry country;
  const OnCountryChangedEvent({required this.country});

  @override
  List<Object?> get props => [country];
}

class OnResetEvent extends LoginEvent {
  final bool? isPhoneChange;
  const OnResetEvent({this.isPhoneChange});
}

class OnChangeOtpEvent extends LoginEvent {
  final String otpCode;
  const OnChangeOtpEvent({required this.otpCode});
}

class OnSubmitOtpEvent extends LoginEvent {}

class OnResendOtpEvent extends LoginEvent {
  const OnResendOtpEvent();
}

class OnOtpTimerTickEvent extends LoginEvent {
  const OnOtpTimerTickEvent();
}