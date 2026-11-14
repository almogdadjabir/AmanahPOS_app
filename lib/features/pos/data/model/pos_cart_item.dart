import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';

class PosCartItem {
  final ProductData product;
  final int quantity;

  const PosCartItem({required this.product, required this.quantity});

  PosCartItem copyWith({ProductData? product, int? quantity}) {
    return PosCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
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

  double get lineTotal => price * quantity;
}
