part of 'navigation_bloc.dart';

class NavigationState extends Equatable {
  final int selectedIndex;
  final List<NavigationModel> screens;
  final bool menuOpen;


  NavigationState({
    this.selectedIndex = 0,
    List<NavigationModel>? screens,
    this.menuOpen = false,
  }) : screens = screens ?? NavigationConfig.screens;

  NavigationState copyWith({
    int? selectedIndex,
    List<NavigationModel>? screens,
    bool? menuOpen,
  }) {
    return NavigationState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      screens: screens ?? this.screens,
      menuOpen: menuOpen ?? this.menuOpen,
    );
  }

  @override
  List<Object?> get props => [
    selectedIndex,
    screens,
    menuOpen,
  ];
}
