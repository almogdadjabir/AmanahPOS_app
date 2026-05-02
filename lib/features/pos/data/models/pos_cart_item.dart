import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';

class PosCartItem {
  final ProductData product;
  final int quantity;

  const PosCartItem({
    required this.product,
    required this.quantity,
  });

  PosCartItem copyWith({
    ProductData? product,
    int? quantity,
  }) {
    return PosCartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  double get price {
    final value = product.price;
    if (value == null) return 0;
    // if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  double get lineTotal => price * quantity;
}