import 'package:amana_pos/features/pos/domain/cart_discount.dart';
import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';

class PosCartItem {
  final ProductData product;
  final int quantity;

  /// A discount on this line only (owner/manager). Null = none.
  final CartDiscount? discount;

  const PosCartItem({
    required this.product,
    required this.quantity,
    this.discount,
  });

  PosCartItem copyWith({
    ProductData? product,
    int? quantity,
    CartDiscount? discount,
    bool clearDiscount = false,
  }) {
    return PosCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discount: clearDiscount ? null : (discount ?? this.discount),
    );
  }

  static const String customIdPrefix = 'custom:';

  /// A free-form amount line. Carries a synthetic product so every cart,
  /// receipt and offline-queue path keeps working; the id prefix marks it.
  factory PosCartItem.custom({
    required String id,
    required String name,
    required double price,
  }) {
    return PosCartItem(
      product: ProductData(
        id: '$customIdPrefix$id',
        name: name,
        price: price.toStringAsFixed(2),
        trackInventory: false,
        isActive: true,
      ),
      quantity: 1,
    );
  }

  static bool isCustomId(String? id) =>
      id != null && id.startsWith(customIdPrefix);

  bool get isCustom => isCustomId(product.id);

  double get price {
    final value = product.price;
    if (value == null) return 0;
    // if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  /// Price x quantity, before any discount.
  double get lineGross => price * quantity;

  BigInt get grossCents => BigInt.from((lineGross * 100).round());

  /// What the line discount takes off, in cents (follows the quantity).
  BigInt get discountCents => discount?.cutOf(grossCents) ?? BigInt.zero;

  double get lineDiscount => discountCents.toDouble() / 100;

  /// What the customer pays for this line, after its discount.
  double get lineTotal => discount == null
      ? lineGross
      : (grossCents - discountCents).toDouble() / 100;

  /// Exact discount as a 2-decimal string for the sale draft.
  String get discountText => Cents.format(discountCents);
}
