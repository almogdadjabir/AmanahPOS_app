part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, success, failure }
enum BusinessStatus { initial, loading, success, failure }

class AuthStateUpdate {
  final AuthStatus? authStatus;
  final User? profile;
  final bool? isLoggedIn;
  final String? responseError;
  final BusinessStatus? businessStatus;
  final BusinessData? defaultBusiness;
  final int? sessionId;

  const AuthStateUpdate({
    this.authStatus,
    this.profile,
    this.isLoggedIn,
    this.responseError,
    this.businessStatus,
    this.defaultBusiness,
    this.sessionId,
  });
}

class AuthState extends Equatable {
  final AuthStatus authStatus;
  final User? profile;
  final bool isLoggedIn;
  final String? responseError;
  final BusinessStatus businessStatus;
  final BusinessData? defaultBusiness;

  /// Increments each time a new session starts (login / user switch).
  /// Data BLoCs compare against this to know when to flush in-memory state.
  final int sessionId;

  const AuthState({
    this.authStatus = AuthStatus.initial,
    this.profile,
    this.isLoggedIn = false,
    this.responseError,
    this.businessStatus = BusinessStatus.initial,
    this.defaultBusiness,
    this.sessionId = 0,
  });

  factory AuthState.initial() => const AuthState();

  // ─── Derived permissions ───────────────────────────────────────────────────

  AppPermissions get permissions => AppPermissions.from(
    businessType: defaultBusiness?.businessType,
    userRole: profile?.role,
    enabledFeatures: profile?.enabledFeatures ?? const {},
  );

  // ─── copyWith ─────────────────────────────────────────────────────────────

  AuthState copyWith(AuthStateUpdate u) {
    return AuthState(
      authStatus: u.authStatus ?? authStatus,
      profile: u.profile ?? profile,
      isLoggedIn: u.isLoggedIn ?? isLoggedIn,
      responseError: u.responseError,         // null clears the error
      businessStatus: u.businessStatus ?? businessStatus,
      defaultBusiness: u.defaultBusiness ?? defaultBusiness,
      sessionId: u.sessionId ?? sessionId,
    );
  }

  // ─── Equatable ────────────────────────────────────────────────────────────

  @override
  List<Object?> get props => [
    authStatus,
    profile,
    isLoggedIn,
    responseError,
    businessStatus,
    defaultBusiness,
    sessionId,
  ];
}