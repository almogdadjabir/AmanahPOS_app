part of 'registration_bloc.dart';

enum RegistrationStatus {
  initial,
  loading,
  success,
  failure,
}

class RegistrationState extends Equatable {
  final bool isLoading;
  final String? responseError;
  final RegistrationStatus registrationStatus;

  const RegistrationState({
    this.isLoading = false,
    this.responseError,
    this.registrationStatus = RegistrationStatus.initial,
  });

  factory RegistrationState.initial() {
    return const RegistrationState(
      isLoading: false,
      responseError: null,
      registrationStatus: RegistrationStatus.initial,
    );
  }

  RegistrationState copyWith({
    bool? isLoading,
    String? responseError,
    RegistrationStatus? registrationStatus,
  }) {
    return RegistrationState(
      isLoading: isLoading ?? this.isLoading,
      responseError: responseError,
      registrationStatus: registrationStatus ?? this.registrationStatus,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    responseError,
    registrationStatus,
  ];
}
