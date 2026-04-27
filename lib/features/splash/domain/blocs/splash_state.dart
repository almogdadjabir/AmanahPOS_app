part of 'splash_bloc.dart';

enum SplashStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  failure,
}

class SplashState extends Equatable {
  final SplashStatus status;
  final String? errorMessage;

  const SplashState({
    this.status = SplashStatus.initial,
    this.errorMessage,
  });

  const SplashState.initial()
      : status = SplashStatus.initial,
        errorMessage = null;

  SplashState copyWith({
    SplashStatus? status,
    String? errorMessage,
  }) {
    return SplashState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
  ];
}