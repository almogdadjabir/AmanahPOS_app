class Product {
  final String id;
  final String name;
  final String categoryId;
  final num price; // SDG
  final int stock;
  final String sku;

  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.stock,
    required this.sku,
  });

  bool get isLowStock => stock <= 10;
}
