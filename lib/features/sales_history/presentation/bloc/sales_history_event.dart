part of 'sales_history_bloc.dart';

abstract class SalesHistoryEvent extends Equatable {
  const SalesHistoryEvent();

  @override
  List<Object?> get props => [];
}

class SalesHistoryStarted extends SalesHistoryEvent {
  const SalesHistoryStarted();
}

class SalesHistoryLoadMore extends SalesHistoryEvent {
  const SalesHistoryLoadMore();
}

class SalesHistoryRefreshed extends SalesHistoryEvent {
  const SalesHistoryRefreshed();
}

class SalesHistorySearchChanged extends SalesHistoryEvent {
  final String query;
  const SalesHistorySearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class SalesHistoryFiltersChanged extends SalesHistoryEvent {
  final SalesHistoryFilters filters;
  const SalesHistoryFiltersChanged(this.filters);

  @override
  List<Object?> get props => [filters];
}

/// A sale changed elsewhere (for example a return was recorded on it).
class SalesHistoryItemReplaced extends SalesHistoryEvent {
  final SaleHistoryItem sale;
  const SalesHistoryItemReplaced(this.sale);

  @override
  List<Object?> get props => [sale.id, sale.status];
}
