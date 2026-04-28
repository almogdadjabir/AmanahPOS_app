part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class OnLoadProfileEvent extends AuthEvent {
  final User? user;
  const OnLoadProfileEvent({this.user});
}

class OnLogoutEvent extends AuthEvent {
  const OnLogoutEvent();
}