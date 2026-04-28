import 'product.dart';

class CartItem {
  final Product product;
  final int qty;

  const CartItem({required this.product, required this.qty});

  num get lineTotal => product.price * qty;

  CartItem copyWith({int? qty}) =>
      CartItem(product: product, qty: qty ?? this.qty);
}
