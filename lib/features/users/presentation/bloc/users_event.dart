part of 'users_bloc.dart';


abstract class UserEvent extends Equatable {
  const UserEvent();
}

class OnUserInitial extends UserEvent {
  const OnUserInitial();
  @override List<Object?> get props => [];
}

class OnEditUser extends UserEvent {
  final String userId;
  final String fullName;
  final String role;

  const OnEditUser({
    required this.userId,
    required this.fullName,
    required this.role,
  });

  @override
  List<Object?> get props => [userId, fullName, role];
}

class OnDeactivateUser extends UserEvent {
  final String userId;
  const OnDeactivateUser({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class OnAddUser extends UserEvent {
  final String phone;
  final String fullName;
  final String role;

  const OnAddUser({
    required this.phone,
    required this.fullName,
    required this.role,
  });

  @override
  List<Object?> get props => [phone, fullName, role];
}