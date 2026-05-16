part of 'stock_levels_bloc.dart';

abstract class StockLevelsEvent extends Equatable {
  const StockLevelsEvent();
}

class OnStockLevelsStarted extends StockLevelsEvent {
  final bool lowStockOnly;
  const OnStockLevelsStarted({this.lowStockOnly = false});
  @override List<Object?> get props => [lowStockOnly];
}

class OnStockLevelsLoadMore extends StockLevelsEvent {
  const OnStockLevelsLoadMore();
  @override List<Object?> get props => [];
}

class OnStockLevelsFilterChanged extends StockLevelsEvent {
  final StockLevelsFilter filter;
  const OnStockLevelsFilterChanged(this.filter);
  @override List<Object?> get props => [filter];
}

class OnStockLevelsSearchChanged extends StockLevelsEvent {
  final String query;
  const OnStockLevelsSearchChanged(this.query);
  @override List<Object?> get props => [query];
}

class OnStockLevelsReset extends StockLevelsEvent {
  const OnStockLevelsReset();
  @override List<Object?> get props => [];
}
