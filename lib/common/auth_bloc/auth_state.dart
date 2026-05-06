part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, success, failure }
enum BusinessStatus { initial, loading, success, failure}


class AuthStateUpdate {
  final bool? isLoggedIn;
  final bool? isLoading;
  final User? profile;
  final AuthStatus? authStatus;
  final String? responseError;
  final bool? hideBalance;
  final BusinessStatus? businessStatus;
  final BusinessData? defaultBusiness;

  const AuthStateUpdate({
    this.isLoggedIn,
    this.isLoading,
    this.profile,
    this.authStatus,
    this.responseError,
    this.hideBalance,
    this.businessStatus = BusinessStatus.initial,
    this.defaultBusiness,
  });
}

class AuthState extends Equatable {
  final bool isLoggedIn;
  final bool isLoading;
  final User? profile;
  final AuthStatus authStatus;
  final String? responseError;
  final bool hideBalance;
  final BusinessStatus businessStatus;
  final BusinessData? defaultBusiness;


  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.profile,
    this.authStatus = AuthStatus.initial,
    this.responseError,
    this.hideBalance = false,
    this.businessStatus = BusinessStatus.initial,
    this.defaultBusiness,
  });

  factory AuthState.initial() => const AuthState();

  AuthState copyWith(AuthStateUpdate u) {
    return AuthState(
      isLoggedIn: u.isLoggedIn ?? isLoggedIn,
      isLoading: u.isLoading ?? isLoading,
      profile: u.profile ?? profile,
      authStatus: u.authStatus ?? authStatus,
      responseError: u.responseError,
      hideBalance: u.hideBalance ?? hideBalance,
      businessStatus: u.businessStatus ?? businessStatus,
      defaultBusiness: u.defaultBusiness ?? defaultBusiness,
    );
  }

  UserRole get userRole => UserRole.fromString(profile?.role);

  bool get isOwner => userRole == UserRole.owner;

  bool get isManager => userRole == UserRole.manager;

  bool get isCashier => userRole == UserRole.cashier;

  bool get isOwnerOrManager => isOwner || isManager;

  bool get canManageBusiness => isOwner || isManager;

  bool get canManageUsers => isOwner;

  bool get canViewReports => isOwner || isManager;

  bool get canSell => isOwner || isManager || isCashier;

  @override
  List<Object?> get props => [
    isLoggedIn, isLoading, profile, authStatus, responseError, hideBalance,
    businessStatus, defaultBusiness,
  ];
}