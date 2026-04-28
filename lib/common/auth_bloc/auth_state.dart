part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, success, failure }

class AuthStateUpdate {
  final bool? isLoggedIn;
  final bool? isLoading;
  final User? profile;
  final AuthStatus? authStatus;
  final String? responseError;
  final bool? hideBalance;

  const AuthStateUpdate({
    this.isLoggedIn,
    this.isLoading,
    this.profile,
    this.authStatus,
    this.responseError,
    this.hideBalance,
  });
}

class AuthState extends Equatable {
  final bool isLoggedIn;
  final bool isLoading;
  final User? profile;
  final AuthStatus authStatus;
  final String? responseError;
  final bool hideBalance;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.profile,
    this.authStatus = AuthStatus.initial,
    this.responseError,
    this.hideBalance = false,
  });

  factory AuthState.initial() => const AuthState();

  AuthState copyWith(AuthStateUpdate u) {
    return AuthState(
      isLoggedIn:    u.isLoggedIn    ?? isLoggedIn,
      isLoading:     u.isLoading     ?? isLoading,
      profile:       u.profile       ?? profile,
      authStatus:    u.authStatus    ?? authStatus,
      responseError: u.responseError,   // null clears the error — intentional
      hideBalance:   u.hideBalance   ?? hideBalance,
    );
  }

  @override
  List<Object?> get props => [
    isLoggedIn, isLoading, profile, authStatus, responseError, hideBalance,
  ];
}