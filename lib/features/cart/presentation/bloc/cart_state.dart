part of 'cart_bloc.dart';

enum CartStatus { idle, charged }

class CartState extends Equatable {
  static const double vatRate = 0.10;

  final List<CartItem> items;
  final Discount discount;
  final CartStatus status;
  final num lastChargedTotal;

  const CartState({
    required this.items,
    required this.discount,
    required this.status,
    required this.lastChargedTotal,
  });

  factory CartState.initial() => const CartState(
    items: [],
    discount: Discount.none(),
    status: CartStatus.idle,
    lastChargedTotal: 0,
  );

  // ── Computed getters (mirrors CartController) ──────────────────────
  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (sum, i) => sum + i.qty);
  num get subtotal => items.fold<num>(0, (sum, i) => sum + i.lineTotal);
  num get discountAmount => discount.amountFor(subtotal);
  num get taxable => subtotal - discountAmount;
  num get vat => taxable * vatRate;
  num get total => taxable + vat;

  int qtyOf(String productId) {
    for (final i in items) {
      if (i.product.id == productId) return i.qty;
    }
    return 0;
  }

  CartState copyWith({
    List<CartItem>? items,
    Discount? discount,
    CartStatus? status,
    num? lastChargedTotal,
  }) {
    return CartState(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      status: status ?? this.status,
      lastChargedTotal: lastChargedTotal ?? this.lastChargedTotal,
    );
  }

  @override
  List<Object?> get props => [items, discount, status, lastChargedTotal];
}