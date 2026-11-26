part of 'pos_bloc.dart';

abstract class PosEvent extends Equatable {
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

/// Give one cart line a discount, or remove it (null).
class PosLineDiscountSet extends PosEvent {
  final String productId;
  final CartDiscount? discount;
  const PosLineDiscountSet(this.productId, this.discount);
  @override
  List<Object?> get props => [productId, discount];
}

/// Give the whole sale a discount, or remove it (null).
class PosSaleDiscountSet extends PosEvent {
  final CartDiscount? discount;
  const PosSaleDiscountSet(this.discount);
  @override
  List<Object?> get props => [discount];
}

/// A customer was picked for this ticket.
class PosCustomerSelected extends PosEvent {
  final String id;
  final String name;
  const PosCustomerSelected({required this.id, required this.name});
  @override
  List<Object?> get props => [id, name];
}

/// The customer was removed from this ticket. On account falls back to cash.
class PosCustomerCleared extends PosEvent {
  const PosCustomerCleared();
}

/// The split sheet was confirmed: the sale is paid by these parts.
class PosSplitConfirmed extends PosEvent {
  final List<SalePaymentPart> parts;
  const PosSplitConfirmed(this.parts);
  @override
  List<Object?> get props => [for (final p in parts) '${p.method}:${p.amount}'];
}

final class PosAddProduct extends PosEvent {
  final ProductData product;
  final bool ignoreStockLimit;

  const PosAddProduct(this.product, {this.ignoreStockLimit = false});

  @override
  List<Object?> get props => [product, ignoreStockLimit];
}

final class PosAddCustomAmount extends PosEvent {
  final double amount;
  final String note;

  const PosAddCustomAmount({required this.amount, required this.note});

  @override
  List<Object?> get props => [amount, note];
}

final class PosIncrementItem extends PosEvent {
  final String productId;
  final bool ignoreStockLimit;

  const PosIncrementItem(this.productId, {this.ignoreStockLimit = false});

  @override
  List<Object?> get props => [productId, ignoreStockLimit];
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
  const PosCheckoutSubmitted({required this.shopId, this.customerId});
  @override
  List<Object?> get props => [shopId, customerId];
}

class PosAcknowledgeSubmit extends PosEvent {
  const PosAcknowledgeSubmit();
}

class PosCartExpandedChanged extends PosEvent {
  final bool expanded;
  const PosCartExpandedChanged(this.expanded);
  @override
  List<Object?> get props => [expanded];
}

class PosShopSelected extends PosEvent {
  final String shopId;
  final String shopName;
  const PosShopSelected({required this.shopId, required this.shopName});
  @override
  List<Object?> get props => [shopId, shopName];
}

class PosBarcodeScanned extends PosEvent {
  final String barcode;

  const PosBarcodeScanned(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

class PosSessionReset extends PosEvent {
  const PosSessionReset();
}

class PosTaxConfigChanged extends PosEvent {
  final TaxConfig taxConfig;
  const PosTaxConfigChanged(this.taxConfig);
  @override
  List<Object?> get props => [taxConfig];
}

/// Internal: the products table changed; drop cart lines whose product is
/// gone (fix-wave I2).
final class _PosCatalogChanged extends PosEvent {
  const _PosCatalogChanged();
}
