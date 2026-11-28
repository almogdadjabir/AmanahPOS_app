part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class OnLoadProfileEvent extends AuthEvent {
  final User? user;
  const OnLoadProfileEvent({this.user});
  @override
  List<Object?> get props => [user];
}

class OnLoadBusinessEvent extends AuthEvent {
  const OnLoadBusinessEvent();
}

class OnLogoutEvent extends AuthEvent {
  /// Local-only sign-out, used ONLY by the blocking first-setup screen: the
  /// device may be offline there (nothing synced yet), so the online
  /// requirement is skipped. Still refused while any outbox row is unsynced;
  /// sync is still paused before the wipe. No server call is made.
  final bool localOnly;
  const OnLogoutEvent({this.localOnly = false});
  @override
  List<Object?> get props => [localOnly];
}

class OnProfileUpdated extends AuthEvent {
  final User user;
  const OnProfileUpdated(this.user);
  @override
  List<Object?> get props => [user];
}
