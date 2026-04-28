part of 'dashboard_bloc.dart';

class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class SetCategoryEvent extends DashboardEvent {
  final String categoryId;
  const SetCategoryEvent({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

class SetSearchQueryEvent extends DashboardEvent {
  final String query;
  const SetSearchQueryEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

class SetCartExpandedEvent extends DashboardEvent {
  final bool expanded;
  const SetCartExpandedEvent({required this.expanded});

  @override
  List<Object?> get props => [expanded];
}

class SetMenuOpenEvent extends DashboardEvent {
  final bool open;
  const SetMenuOpenEvent({required this.open});

  @override
  List<Object?> get props => [open];
}