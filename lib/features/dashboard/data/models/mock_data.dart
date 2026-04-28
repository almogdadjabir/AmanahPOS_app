import 'package:flutter/material.dart';
import '../models/product_category.dart';
import '../models/product.dart';

/// Static catalog used in the demo. In production this would come from an API.
class MockData {
  MockData._();

  static const String allCategoryId = 'all';

  static const List<ProductCategory> categories = [
    ProductCategory(id: allCategoryId, name: 'All',        icon: Icons.grid_view_rounded,        color: Color(0xFF475569)),
    ProductCategory(id: 'coffee',      name: 'Coffee',     icon: Icons.coffee_rounded,           color: Color(0xFF92400E)),
    ProductCategory(id: 'tea',         name: 'Tea',        icon: Icons.emoji_food_beverage_rounded, color: Color(0xFF15803D)),
    ProductCategory(id: 'cold',        name: 'Cold',       icon: Icons.local_drink_rounded,      color: Color(0xFF0369A1)),
    ProductCategory(id: 'pastry',      name: 'Pastries',   icon: Icons.bakery_dining_rounded,    color: Color(0xFFB45309)),
    ProductCategory(id: 'sand',        name: 'Sandwiches', icon: Icons.lunch_dining_rounded,     color: Color(0xFFA16207)),
    ProductCategory(id: 'desert',      name: 'Desserts',   icon: Icons.cake_rounded,             color: Color(0xFFBE185D)),
    ProductCategory(id: 'breakfast',   name: 'Breakfast',  icon: Icons.egg_alt_rounded,          color: Color(0xFFC2410C)),
  ];

  static const List<Product> products = [
    // Coffee
    Product(id: 'p1',  name: 'Espresso',           categoryId: 'coffee',    price: 1500, stock: 999, sku: 'CF-001'),
    Product(id: 'p2',  name: 'Cappuccino',         categoryId: 'coffee',    price: 2200, stock: 999, sku: 'CF-002'),
    Product(id: 'p3',  name: 'Latte',              categoryId: 'coffee',    price: 2400, stock: 999, sku: 'CF-003'),
    Product(id: 'p4',  name: 'Americano',          categoryId: 'coffee',    price: 1800, stock: 999, sku: 'CF-004'),
    Product(id: 'p5',  name: 'Mocha',              categoryId: 'coffee',    price: 2700, stock: 8,   sku: 'CF-005'),
    // Tea
    Product(id: 'p6',  name: 'Karak Tea',          categoryId: 'tea',       price: 1200, stock: 999, sku: 'TE-001'),
    Product(id: 'p7',  name: 'Mint Tea',           categoryId: 'tea',       price: 1300, stock: 999, sku: 'TE-002'),
    Product(id: 'p8',  name: 'Hibiscus (Karkadeh)',categoryId: 'tea',       price: 1500, stock: 999, sku: 'TE-003'),
    // Cold
    Product(id: 'p9',  name: 'Iced Latte',         categoryId: 'cold',      price: 2600, stock: 999, sku: 'CD-001'),
    Product(id: 'p10', name: 'Lemon Mint',         categoryId: 'cold',      price: 2200, stock: 6,   sku: 'CD-002'),
    Product(id: 'p11', name: 'Mango Juice',        categoryId: 'cold',      price: 2400, stock: 999, sku: 'CD-003'),
    // Pastries
    Product(id: 'p12', name: 'Chocolate Croissant',categoryId: 'pastry',    price: 1800, stock: 5,   sku: 'PA-001'),
    Product(id: 'p13', name: 'Almond Croissant',   categoryId: 'pastry',    price: 2000, stock: 4,   sku: 'PA-002'),
    Product(id: 'p14', name: 'Cinnamon Roll',      categoryId: 'pastry',    price: 2100, stock: 9,   sku: 'PA-003'),
    // Sandwiches
    Product(id: 'p15', name: 'Falafel Sandwich',   categoryId: 'sand',      price: 2800, stock: 7,   sku: 'SA-001'),
    Product(id: 'p16', name: 'Halloumi Wrap',      categoryId: 'sand',      price: 3400, stock: 5,   sku: 'SA-002'),
    Product(id: 'p17', name: 'Chicken Sandwich',   categoryId: 'sand',      price: 3600, stock: 6,   sku: 'SA-003'),
    // Desserts
    Product(id: 'p18', name: 'Cheesecake',         categoryId: 'desert',    price: 2900, stock: 8,   sku: 'DE-001'),
    Product(id: 'p19', name: 'Brownie',            categoryId: 'desert',    price: 2200, stock: 10,  sku: 'DE-002'),
    // Breakfast
    Product(id: 'p20', name: 'Ful Medames',        categoryId: 'breakfast', price: 2600, stock: 9,   sku: 'BR-001'),
    Product(id: 'p21', name: 'Shakshuka',          categoryId: 'breakfast', price: 3200, stock: 7,   sku: 'BR-002'),
    Product(id: 'p22', name: 'Eggs & Cheese',      categoryId: 'breakfast', price: 2800, stock: 6,   sku: 'BR-003'),
  ];

  /// Filter [products] by category and free-text query.
  static List<Product> filter({String? categoryId, String query = ''}) {
    Iterable<Product> list = products;
    if (categoryId != null && categoryId != allCategoryId) {
      list = list.where((p) => p.categoryId == categoryId);
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q));
    }
    return list.toList(growable: false);
  }
}
