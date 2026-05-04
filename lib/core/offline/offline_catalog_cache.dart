import 'dart:convert';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:sqflite/sqflite.dart';

class OfflineCatalogCache {
  OfflineCatalogCache(this._db);

  final OfflineDb _db;

  Future<void> saveBusinesses(List<BusinessData> businesses) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final business in businesses) {
        final id = business.id;
        if (id == null) continue;

        await txn.insert(
          'businesses',
          {
            'id': id,
            'json': jsonEncode(business.toJson()),
            'updated_at': business.updatedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        final shops = business.shops ?? [];
        for (final shop in shops) {
          final shopId = shop.id;
          if (shopId == null) continue;

          await txn.insert(
            'shops',
            {
              'id': shopId,
              'business_id': business.id,
              'json': jsonEncode(shop.toJson()),
              'updated_at': shop.updatedAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<List<BusinessData>> getBusinesses() async {
    final rows = await _db.getJsonList('businesses');
    return rows.map(BusinessData.fromJson).toList();
  }

  Future<void> saveCategories(List<CategoryData> categories) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      Future<void> saveOne(CategoryData category) async {
        final id = category.id;
        if (id == null) return;

        await txn.insert(
          'categories',
          {
            'id': id,
            'tenant_id': category.tenant,
            'parent_id': category.parent,
            'name': category.name,
            'json': jsonEncode(_categoryToJson(category)),
            'updated_at': category.updatedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (final child in category.children ?? const <CategoryData>[]) {
          await saveOne(child);
        }
      }

      for (final category in categories) {
        await saveOne(category);
      }
    });
  }

  Future<List<CategoryData>> getCategories() async {
    final db = await _db.database;
    final rows = await db.query('categories', where: 'parent_id IS NULL OR parent_id = ?', whereArgs: ['']);
    final allRows = await db.query('categories');

    final all = allRows
        .map((row) => CategoryData.fromJson(jsonDecode(row['json'] as String)))
        .toList();

    List<CategoryData> buildChildren(CategoryData parent) {
      return all
          .where((item) => item.parent == parent.id)
          .map((item) => item.copyWith(children: buildChildren(item)))
          .toList();
    }

    return rows
        .map((row) => CategoryData.fromJson(jsonDecode(row['json'] as String)))
        .map((item) => item.copyWith(children: buildChildren(item)))
        .toList();
  }

  Future<void> saveProducts(List<ProductData> products) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final product in products) {
        final id = product.id;
        if (id == null) continue;

        await txn.insert(
          'products',
          {
            'id': id,
            'category_id': product.category,
            'name': product.name,
            'sku': product.sku,
            'barcode': product.barcode,
            'price': product.price,
            'stock_level': product.stockLevel,
            'thumbnail_url': product.thumbnailUrl,
            'image_url': product.image,
            'json': jsonEncode(_productToJson(product)),
            'updated_at': product.createdAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<ProductData>> getProducts({
    String? categoryId,
    String? search,
  }) async {
    final db = await _db.database;

    final where = <String>[];
    final args = <Object?>[];

    if (categoryId != null && categoryId.isNotEmpty) {
      where.add('category_id = ?');
      args.add(categoryId);
    }

    final query = search?.trim();
    if (query != null && query.isNotEmpty) {
      where.add('(name LIKE ? OR sku LIKE ? OR barcode LIKE ?)');
      args.addAll(['%$query%', '%$query%', '%$query%']);
    }

    final rows = await db.query(
      'products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows
        .map((row) => ProductData.fromJson(jsonDecode(row['json'] as String)))
        .toList();
  }

  Future<void> saveCustomers(List<CustomerData> customers) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final customer in customers) {
        final id = customer.id;
        if (id == null) continue;

        await txn.insert(
          'customers',
          {
            'id': id,
            'name': customer.name,
            'phone': customer.phone,
            'email': customer.email,
            'json': jsonEncode(_customerToJson(customer)),
            'updated_at': customer.updatedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<CustomerData>> getCustomers({String? search}) async {
    final db = await _db.database;

    final query = search?.trim();
    final rows = await db.query(
      'customers',
      where: query == null || query.isEmpty
          ? null
          : '(name LIKE ? OR phone LIKE ? OR email LIKE ?)',
      whereArgs: query == null || query.isEmpty
          ? null
          : ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows
        .map((row) => CustomerData.fromJson(jsonDecode(row['json'] as String)))
        .toList();
  }

  Future<void> saveStock(List<StockData> stockList) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final stock in stockList) {
        final productId = stock.product;
        final shopId = stock.shop;
        if (productId == null || shopId == null) continue;

        await txn.insert(
          'stock',
          {
            'id': stock.id ?? '$productId-$shopId',
            'product_id': productId,
            'shop_id': shopId,
            'quantity': stock.qty,
            'json': jsonEncode(_stockToJson(stock)),
            'updated_at': stock.updatedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<double> getStockQuantity({
    required String productId,
    required String shopId,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'stock',
      columns: ['quantity'],
      where: 'product_id = ? AND shop_id = ?',
      whereArgs: [productId, shopId],
      limit: 1,
    );

    if (rows.isEmpty) return 0;
    return (rows.first['quantity'] as num?)?.toDouble() ?? 0;
  }

  Future<void> deductLocalStock({
    required String productId,
    required String shopId,
    required double quantity,
  }) async {
    final db = await _db.database;
    await db.rawUpdate(
      '''
      UPDATE stock
      SET quantity = MAX(quantity - ?, 0)
      WHERE product_id = ? AND shop_id = ?
      ''',
      [quantity, productId, shopId],
    );

    await db.rawUpdate(
      '''
      UPDATE products
      SET stock_level = MAX(COALESCE(stock_level, 0) - ?, 0)
      WHERE id = ?
      ''',
      [quantity, productId],
    );
  }

  Map<String, dynamic> _categoryToJson(CategoryData data) {
    return {
      'id': data.id,
      'tenant': data.tenant,
      'parent': data.parent,
      'name': data.name,
      'description': data.description,
      'image': data.image,
      'thumbnail_url': data.thumbnailUrl,
      'is_active': data.isActive,
      'sort_order': data.sortOrder,
      'children': data.children?.map(_categoryToJson).toList(),
      'created_at': data.createdAt,
      'updated_at': data.updatedAt,
    };
  }

  Map<String, dynamic> _productToJson(ProductData data) {
    return {
      'id': data.id,
      'category': data.category,
      'category_name': data.categoryName,
      'name': data.name,
      'description': data.description,
      'sku': data.sku,
      'barcode': data.barcode,
      'price': data.price,
      'cost_price': data.costPrice,
      'image': data.image,
      'unit': data.unit,
      'is_active': data.isActive,
      'track_inventory': data.trackInventory,
      'min_stock_level': data.minStockLevel,
      'stock_level': data.stockLevel,
      'created_at': data.createdAt,
      'thumbnail_url': data.thumbnailUrl,
    };
  }

  Map<String, dynamic> _customerToJson(CustomerData data) {
    return {
      'id': data.id,
      'tenant': data.tenant,
      'name': data.name,
      'phone': data.phone,
      'email': data.email,
      'address': data.address,
      'loyalty_points': data.loyaltyPoints,
      'notes': data.notes,
      'is_active': data.isActive,
      'total_purchases': data.totalPurchases,
      'created_at': data.createdAt,
      'updated_at': data.updatedAt,
    };
  }

  Map<String, dynamic> _stockToJson(StockData data) {
    return {
      'id': data.id,
      'product': data.product,
      'product_name': data.productName,
      'product_sku': data.productSku,
      'shop': data.shop,
      'shop_name': data.shopName,
      'quantity': data.quantity,
      'is_low_stock': data.isLowStock,
      'is_out_of_stock': data.isOutOfStock,
      'updated_at': data.updatedAt,
    };
  }
}