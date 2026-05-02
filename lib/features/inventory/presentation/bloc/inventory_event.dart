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

class OnAdjustStock extends InventoryEvent {
  final String productId;
  final String shopId;
  final String newQuantity;
  final String? notes;

  const OnAdjustStock({
    required this.productId,
    required this.shopId,
    required this.newQuantity,
    this.notes,
  });
  @override List<Object?> get props => [productId, shopId, newQuantity, notes];
}

class OnTransferStock extends InventoryEvent {
  final String productId;
  final String fromShopId;
  final String toShopId;
  final String quantity;

  const OnTransferStock({
    required this.productId,
    required this.fromShopId,
    required this.toShopId,
    required this.quantity,
  });
  @override List<Object?> get props => [productId, fromShopId, toShopId, quantity];
}

class OnAddStock extends InventoryEvent {
  final String productId;
  final String shopId;
  final String quantity;
  final MovementType movementType;
  final String? reference;

  const OnAddStock({
    required this.productId,
    required this.shopId,
    required this.quantity,
    this.movementType = MovementType.in_,
    this.reference,
  });

  @override
  List<Object?> get props =>
      [productId, shopId, quantity, movementType, reference];
}