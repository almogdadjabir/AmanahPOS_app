part of 'inventory_bloc.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();
}

class OnInventoryInitial extends InventoryEvent {
  const OnInventoryInitial();
  @override List<Object?> get props => [];
}

class OnLoadMoreStock extends InventoryEvent {
  const OnLoadMoreStock();
  @override List<Object?> get props => [];
}

class OnInventoryFilterChanged extends InventoryEvent {
  final StockFilter filter;
  const OnInventoryFilterChanged({required this.filter});
  @override List<Object?> get props => [filter];
}