part of 'settings_bloc.dart';

// SettingsStatus REMOVED — no more separate settings loading state.
enum SettingsSubmitStatus { idle, loading, success, failure }

class SettingsState extends Equatable {
  // Mutation state only — profile lives in AuthBloc
  final SettingsSubmitStatus submitStatus;
  final String?              submitError;

  const SettingsState({
    this.submitStatus   = SettingsSubmitStatus.idle,
    this.submitError,
  });

  factory SettingsState.initial() => const SettingsState();

  SettingsState copyWith({
    SettingsSubmitStatus? submitStatus,
    String?              submitError,
  }) {
    return SettingsState(
      submitStatus:   submitStatus   ?? this.submitStatus,
      submitError:    submitError,   // null clears the error
    );
  }

  @override
  List<Object?> get props => [
    submitStatus, submitError,
  ];
}
