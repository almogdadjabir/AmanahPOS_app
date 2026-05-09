part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override List<Object?> get props => [];
}

class OnLoadProfileEvent extends AuthEvent {
  final User? user;
  const OnLoadProfileEvent({this.user});
  @override List<Object?> get props => [user];
}

class OnLoadBusinessEvent extends AuthEvent {
  const OnLoadBusinessEvent();
}

class OnLogoutEvent extends AuthEvent {
  const OnLogoutEvent();
}

class OnProfileUpdated extends AuthEvent {
  final User user;
  const OnProfileUpdated(this.user);
  @override List<Object?> get props => [user];
}