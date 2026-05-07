part of 'navigation_bloc.dart';

class NavigationState extends Equatable {
  final AppFeature     currentFeature;
  final AppPermissions permissions;
  final bool           menuOpen;

  const NavigationState({
    this.currentFeature = AppFeature.pos,
    this.permissions    = AppPermissions.none,
    this.menuOpen       = false,
  });

  factory NavigationState.initial() => const NavigationState();

  Widget get currentScreen => NavigationConfig.screenFor(currentFeature);

  NavigationState copyWith({
    AppFeature?     currentFeature,
    AppPermissions? permissions,
    bool?           menuOpen,
  }) {
    return NavigationState(
      currentFeature: currentFeature ?? this.currentFeature,
      permissions:    permissions    ?? this.permissions,
      menuOpen:       menuOpen       ?? this.menuOpen,
    );
  }

  @override
  List<Object?> get props => [currentFeature, permissions, menuOpen];
}
