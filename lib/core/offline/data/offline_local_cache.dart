import 'dart:convert';

import 'package:amana_pos/core/offline/models/offline_asset_manifest_dto.dart';
import 'package:amana_pos/core/offline/models/offline_bootstrap_dto.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:sqflite/sqflite.dart';

class OfflineLocalCache {
  OfflineLocalCache(this._db);

  final OfflineDb _db;

  Future<bool> hasBootstrapCache() => _db.hasBootstrapCache();

  Future<void> saveBootstrap(OfflineBootstrapDto dto) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      await txn.delete('businesses');
      await txn.delete('shops');
      await txn.delete('categories');
      await txn.delete('products');
      await txn.delete('customers');
      await txn.delete('stock');

      for (final business in dto.businesses) {
        final id = business.id;
        if (id == null || id.isEmpty) continue;

        await txn.insert(
          'businesses',
          {
            'id': id,
            'json': jsonEncode(business.toJson()),
            'updated_at': business.updatedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final shop in dto.shops) {
        final id = shop.id;
        if (id == null || id.isEmpty) continue;

        await txn.insert(
          'shops',
          {
            'id': id,
            'business_id': shop.business,
            'json': jsonEncode(shop.toJson()),
            'updated_at': shop.updatedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final business in dto.businesses) {
        for (final shop in business.shops ?? const <Shops>[]) {
          final id = shop.id;
          if (id == null || id.isEmpty) continue;

          await txn.insert(
            'shops',
            {
              'id': id,
              'business_id': shop.business ?? business.id,
              'json': jsonEncode(shop.toJson()),
              'updated_at': shop.updatedAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      Future<void> saveCategory(CategoryData category) async {
        final id = category.id;
        if (id == null || id.isEmpty) return;

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
          await saveCategory(child);
        }
      }

      for (final category in dto.categories) {
        await saveCategory(category);
      }

      for (final product in dto.products) {
        final id = product.id;
        if (id == null || id.isEmpty) continue;

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

      for (final customer in dto.customers) {
        final id = customer.id;
        if (id == null || id.isEmpty) continue;

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

      for (final item in dto.stock) {
        final productId = item.product;
        final shopId = item.shop;
        if (productId == null || productId.isEmpty) continue;
        if (shopId == null || shopId.isEmpty) continue;

        await txn.insert(
          'stock',
          {
            'id': item.id ?? '$productId-$shopId',
            'product_id': productId,
            'shop_id': shopId,
            'quantity': item.qty,
            'json': jsonEncode(_stockToJson(item)),
            'updated_at': item.updatedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await txn.insert(
        'sync_metadata',
        {
          'key': 'bootstrap_last_synced_at',
          'value': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (dto.serverTime != null) {
        await txn.insert(
          'sync_metadata',
          {
            'key': 'bootstrap_server_time',
            'value': dto.serverTime,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> saveAssetManifest(OfflineAssetManifestDto dto) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      for (final asset in dto.assets.where((e) => e.isValid)) {
        await txn.insert(
          'offline_assets',
          {
            'id': asset.id,
            'type': asset.type,
            'url': asset.url,
            'hash': asset.hash,
            'updated_at': asset.updatedAt,
            'local_path': null,
            'downloaded_at': null,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await txn.insert(
        'sync_metadata',
        {
          'key': 'asset_manifest_version',
          'value': dto.version ?? '',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<BusinessData>> getBusinesses() async {
    final rows = await _db.getJsonList('businesses');
    return rows.map(BusinessData.fromJson).toList();
  }

  Future<List<Shops>> getShops() async {
    final rows = await _db.getJsonList('shops');
    return rows.map(Shops.fromJson).toList();
  }

  Future<List<CategoryData>> getCategories() async {
    final db = await _db.database;
    final rows = await db.query('categories', orderBy: 'name COLLATE NOCASE ASC');
    return rows
        .map((row) => CategoryData.fromJson(jsonDecode(row['json'] as String)))
        .toList();
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

    final cleanSearch = search?.trim();
    if (cleanSearch != null && cleanSearch.isNotEmpty) {
      where.add('(name LIKE ? OR sku LIKE ? OR barcode LIKE ?)');
      args.addAll(['%$cleanSearch%', '%$cleanSearch%', '%$cleanSearch%']);
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

  Future<List<CustomerData>> getCustomers({String? search}) async {
    final db = await _db.database;

    final cleanSearch = search?.trim();

    final rows = await db.query(
      'customers',
      where: cleanSearch == null || cleanSearch.isEmpty
          ? null
          : '(name LIKE ? OR phone LIKE ? OR email LIKE ?)',
      whereArgs: cleanSearch == null || cleanSearch.isEmpty
          ? null
          : ['%$cleanSearch%', '%$cleanSearch%', '%$cleanSearch%'],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows
        .map((row) => CustomerData.fromJson(jsonDecode(row['json'] as String)))
        .toList();
  }

  Future<List<StockData>> getStock({String? shopId}) async {
    final db = await _db.database;

    final rows = await db.query(
      'stock',
      where: shopId == null || shopId.isEmpty ? null : 'shop_id = ?',
      whereArgs: shopId == null || shopId.isEmpty ? null : [shopId],
    );

    return rows
        .map((row) => StockData.fromJson(jsonDecode(row['json'] as String)))
        .toList();
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