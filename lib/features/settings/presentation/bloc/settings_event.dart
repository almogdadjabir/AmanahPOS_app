part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override List<Object?> get props => [];
}

// OnSettingsInitial intentionally removed.
// Profile is fetched once at login and lives in AuthBloc.

class OnUpdateProfile extends SettingsEvent {
  final UpdateProfileRequestDto dto;
  const OnUpdateProfile({required this.dto});
  @override List<Object?> get props => [dto];
}

class OnSetPassword extends SettingsEvent {
  final SetPasswordRequestDto dto;
  const OnSetPassword({required this.dto});
  @override List<Object?> get props => [dto];
}