part of 'settings_bloc.dart';

// SettingsStatus REMOVED — no more separate settings loading state.
enum SettingsSubmitStatus { idle, loading, success, failure }

class SettingsState extends Equatable {
  // Mutation state only — profile lives in AuthBloc
  final SettingsSubmitStatus submitStatus;
  final String?              submitError;

  final SettingsSubmitStatus passwordStatus;
  final String?              passwordError;

  const SettingsState({
    this.submitStatus   = SettingsSubmitStatus.idle,
    this.submitError,
    this.passwordStatus = SettingsSubmitStatus.idle,
    this.passwordError,
  });

  factory SettingsState.initial() => const SettingsState();

  SettingsState copyWith({
    SettingsSubmitStatus? submitStatus,
    String?              submitError,
    SettingsSubmitStatus? passwordStatus,
    String?              passwordError,
  }) {
    return SettingsState(
      submitStatus:   submitStatus   ?? this.submitStatus,
      submitError:    submitError,   // null clears the error
      passwordStatus: passwordStatus ?? this.passwordStatus,
      passwordError:  passwordError, // null clears the error
    );
  }

  @override
  List<Object?> get props => [
    submitStatus, submitError,
    passwordStatus, passwordError,
  ];
}
