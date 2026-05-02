part of 'pos_bloc.dart';

sealed class PosEvent extends Equatable {
  const PosEvent();

  @override
  List<Object?> get props => [];
}

class PosSearchChanged extends PosEvent {
  final String query;

  const PosSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class PosCategoryChanged extends PosEvent {
  final String? categoryId;

  const PosCategoryChanged(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class PosPaymentMethodChanged extends PosEvent {
  final String paymentMethod;

  const PosPaymentMethodChanged(this.paymentMethod);

  @override
  List<Object?> get props => [paymentMethod];
}

class PosAddProduct extends PosEvent {
  final ProductData product;

  const PosAddProduct(this.product);

  @override
  List<Object?> get props => [product];
}

class PosIncrementItem extends PosEvent {
  final String productId;

  const PosIncrementItem(this.productId);

  @override
  List<Object?> get props => [productId];
}

class PosDecrementItem extends PosEvent {
  final String productId;

  const PosDecrementItem(this.productId);

  @override
  List<Object?> get props => [productId];
}

class PosRemoveItem extends PosEvent {
  final String productId;

  const PosRemoveItem(this.productId);

  @override
  List<Object?> get props => [productId];
}

class PosClearCart extends PosEvent {
  const PosClearCart();
}

class PosCheckoutSubmitted extends PosEvent {
  final String shopId;
  final String? customerId;

  const PosCheckoutSubmitted({
    required this.shopId,
    this.customerId,
  });

  @override
  List<Object?> get props => [shopId, customerId];
}

class PosAcknowledgeSubmit extends PosEvent {
  const PosAcknowledgeSubmit();
}