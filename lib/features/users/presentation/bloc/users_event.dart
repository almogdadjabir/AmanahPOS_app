part of 'users_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override List<Object?> get props => [];
}

class OnUserInitial extends UserEvent {}

class OnAddUser extends UserEvent {
  final String  phone;
  final String  fullName;
  final String  role;
  final String? shopId; // null = auto-assigned by backend (single-shop businesses)

  const OnAddUser({
    required this.phone,
    required this.fullName,
    required this.role,
    this.shopId,
  });

  @override List<Object?> get props => [phone, fullName, role, shopId];
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
  @override List<Object?> get props => [userId, fullName, role];
}

class OnDeactivateUser extends UserEvent {
  final String userId;
  const OnDeactivateUser(this.userId);
  @override List<Object?> get props => [userId];
}

class OnAssignUserShop extends UserEvent {
  final String  userId;
  final String? shopId;
  const OnAssignUserShop({required this.userId, required this.shopId});
  @override List<Object?> get props => [userId, shopId];
}
