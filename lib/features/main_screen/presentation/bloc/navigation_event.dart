part of 'navigation_bloc.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();
  @override
  List<Object?> get props => [];
}

class NavigationFeatureSelected extends NavigationEvent {
  final AppFeature feature;
  const NavigationFeatureSelected(this.feature);
  @override
  List<Object?> get props => [feature];
}

/// Dispatched internally when AuthBloc permissions change.
/// Can also be dispatched externally if needed (e.g. getProviders seeding).
class NavigationPermissionsChanged extends NavigationEvent {
  final AppPermissions permissions;
  const NavigationPermissionsChanged(this.permissions);
  @override
  List<Object?> get props => [permissions];
}

/// Full reset on logout. Clears feature, flag, and permissions.
class NavigationReset extends NavigationEvent {
  const NavigationReset();
}

class SetMenuOpenEvent extends NavigationEvent {
  final bool? open;
  const SetMenuOpenEvent({this.open});
  @override
  List<Object?> get props => [open];
}
