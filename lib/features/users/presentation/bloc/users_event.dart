part of 'users_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object?> get props => [];
}

class OnUserInitial extends UserEvent {
  /// Keep the current list on screen while reloading (pull to refresh,
  /// refresh after a change).
  final bool silent;
  const OnUserInitial({this.silent = false});
  @override
  List<Object?> get props => [silent];
}

class OnAddUser extends UserEvent {
  final String phone;
  final String fullName;
  final String role;
  final String? shopId;

  const OnAddUser({
    required this.phone,
    required this.fullName,
    required this.role,
    this.shopId,
  });

  @override
  List<Object?> get props => [phone, fullName, role, shopId];
}

/// Updates name, role, active flag and/or branch. Null fields are untouched.
class OnUpdateUser extends UserEvent {
  final String userId;
  final String? fullName;
  final String? role;
  final bool? isActive;
  final String? shopId;

  const OnUpdateUser({
    required this.userId,
    this.fullName,
    this.role,
    this.isActive,
    this.shopId,
  });

  @override
  List<Object?> get props => [userId, fullName, role, isActive, shopId];
}

class OnDeactivateUser extends UserEvent {
  final String userId;
  const OnDeactivateUser(this.userId);
  @override
  List<Object?> get props => [userId];
}

/// PATCH is_active true.
class OnReactivateUser extends UserEvent {
  final String userId;
  const OnReactivateUser(this.userId);
  @override
  List<Object?> get props => [userId];
}

/// "Apply mine again" on a refused role/shop change.
class OnApplyUserConflict extends UserEvent {
  final String mutationId;
  const OnApplyUserConflict(this.mutationId);
  @override
  List<Object?> get props => [mutationId];
}

/// "Dismiss" on a refused team change.
class OnDismissUserConflict extends UserEvent {
  final String mutationId;
  const OnDismissUserConflict(this.mutationId);
  @override
  List<Object?> get props => [mutationId];
}
