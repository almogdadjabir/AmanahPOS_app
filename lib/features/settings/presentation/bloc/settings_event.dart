part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class OnSettingsInitial extends SettingsEvent {
  const OnSettingsInitial();
}

class OnUpdateProfile extends SettingsEvent {
  final UpdateProfileRequestDto dto;

  const OnUpdateProfile({
    required this.dto,
  });

  @override
  List<Object?> get props => [dto];
}

class OnSetPassword extends SettingsEvent {
  final SetPasswordRequestDto dto;

  const OnSetPassword({
    required this.dto,
  });

  @override
  List<Object?> get props => [dto];
}