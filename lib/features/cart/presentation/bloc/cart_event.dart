part of 'cart_bloc.dart';

class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddProductEvent extends CartEvent {
  final Product product;
  const AddProductEvent({required this.product});

  @override
  List<Object?> get props => [product];
}

class IncrementProductEvent extends CartEvent {
  final String productId;
  const IncrementProductEvent({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class DecrementProductEvent extends CartEvent {
  final String productId;
  const DecrementProductEvent({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class RemoveProductEvent extends CartEvent {
  final String productId;
  const RemoveProductEvent({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class SetDiscountEvent extends CartEvent {
  final Discount discount;
  const SetDiscountEvent({required this.discount});

  @override
  List<Object?> get props => [discount];
}

class SeedDemoEvent extends CartEvent {
  final List<CartItem> items;
  const SeedDemoEvent({required this.items});

  @override
  List<Object?> get props => [items];
}

class ChargeCartEvent extends CartEvent {
  const ChargeCartEvent();
}

class AcknowledgeChargeEvent extends CartEvent {
  const AcknowledgeChargeEvent();
}

class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}