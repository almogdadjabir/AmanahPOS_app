part of 'dashboard_bloc.dart';

class DashboardState extends Equatable {
  final String activeCategory;
  final String searchQuery;
  final bool cartExpanded;
  final bool menuOpen;

  const DashboardState({
    required this.activeCategory,
    required this.searchQuery,
    required this.cartExpanded,
    required this.menuOpen,
  });

  factory DashboardState.initial() => DashboardState(
    activeCategory: MockData.allCategoryId,
    searchQuery: '',
    cartExpanded: false,
    menuOpen: false,
  );

  DashboardState copyWith({
    String? activeCategory,
    String? searchQuery,
    bool? cartExpanded,
    bool? menuOpen,
  }) {
    return DashboardState(
      activeCategory: activeCategory ?? this.activeCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      cartExpanded: cartExpanded ?? this.cartExpanded,
      menuOpen: menuOpen ?? this.menuOpen,
    );
  }

  @override
  List<Object?> get props => [activeCategory, searchQuery, cartExpanded, menuOpen];
}