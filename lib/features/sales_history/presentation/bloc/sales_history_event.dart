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

class SalesHistoryItemReturnProcessed extends SalesHistoryEvent {
  final String saleId;
  final bool   isPartial;

  const SalesHistoryItemReturnProcessed({
    required this.saleId,
    required this.isPartial,
  });

  @override
  List<Object?> get props => [saleId, isPartial];
}