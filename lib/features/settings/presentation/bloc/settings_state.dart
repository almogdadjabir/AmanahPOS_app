part of 'settings_bloc.dart';

enum SettingsStatus { initial, loading, success, failure }

enum SettingsSubmitStatus { idle, loading, success, failure }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final User? profile;
  final String? responseError;

  final SettingsSubmitStatus submitStatus;
  final String? submitError;

  final SettingsSubmitStatus passwordStatus;
  final String? passwordError;

  const SettingsState({
    required this.status,
    this.profile,
    this.responseError,
    required this.submitStatus,
    this.submitError,
    required this.passwordStatus,
    this.passwordError,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      status: SettingsStatus.initial,
      submitStatus: SettingsSubmitStatus.idle,
      passwordStatus: SettingsSubmitStatus.idle,
    );
  }

  SettingsState copyWith({
    SettingsStatus? status,
    User? profile,
    String? responseError,
    SettingsSubmitStatus? submitStatus,
    String? submitError,
    SettingsSubmitStatus? passwordStatus,
    String? passwordError,
  }) {
    return SettingsState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      responseError: responseError,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: submitError,
      passwordStatus: passwordStatus ?? this.passwordStatus,
      passwordError: passwordError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile,
    responseError,
    submitStatus,
    submitError,
    passwordStatus,
    passwordError,
  ];
}