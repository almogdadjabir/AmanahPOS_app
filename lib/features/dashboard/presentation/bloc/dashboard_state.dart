part of 'dashboard_bloc.dart';

class DashboardState extends Equatable {
  final String activeCategory;
  final String searchQuery;
  final bool cartExpanded;

  const DashboardState({
    required this.activeCategory,
    required this.searchQuery,
    required this.cartExpanded,
  });

  factory DashboardState.initial() => DashboardState(
    activeCategory: MockData.allCategoryId,
    searchQuery: '',
    cartExpanded: false,
  );

  DashboardState copyWith({
    String? activeCategory,
    String? searchQuery,
    bool? cartExpanded,
  }) {
    return DashboardState(
      activeCategory: activeCategory ?? this.activeCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      cartExpanded: cartExpanded ?? this.cartExpanded,
    );
  }

  @override
  List<Object?> get props => [activeCategory, searchQuery, cartExpanded];
}