import 'dart:convert';
import 'dart:io';
import 'package:amana_pos/core/offline/models/offline_asset_record.dart';
import 'package:amana_pos/core/offline/offline_constants.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
      await txn.delete(OfflineConstants.businessesTable);
      await txn.delete(OfflineConstants.shopsTable);
      await txn.delete(OfflineConstants.categoriesTable);
      await txn.delete(OfflineConstants.productsTable);
      await txn.delete(OfflineConstants.customersTable);
      await txn.delete(OfflineConstants.stockTable);

      for (final business in dto.businesses) {
        final id = business.id;
        if (id == null || id.isEmpty) continue;

        await txn.insert(
          OfflineConstants.businessesTable,
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
          OfflineConstants.shopsTable,
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
            OfflineConstants.shopsTable,
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
          OfflineConstants.categoriesTable,
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
          OfflineConstants.productsTable,
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
          OfflineConstants.customersTable,
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
          OfflineConstants.stockTable,
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

      final stockRows = await txn.query(OfflineConstants.stockTable);

      for (final row in stockRows) {
        final productId = row['product_id']?.toString();
        if (productId == null || productId.isEmpty) continue;

        final quantity = (row['quantity'] as num?)?.toDouble() ?? 0;

        final productRows = await txn.query(
          OfflineConstants.productsTable,
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );

        if (productRows.isEmpty) continue;

        final productJsonRaw = productRows.first['json'] as String;
        final productJson = jsonDecode(productJsonRaw) as Map<String, dynamic>;

        productJson['stock_level'] = quantity;

        await txn.update(
          OfflineConstants.productsTable,
          {
            'stock_level': quantity,
            'json': jsonEncode(productJson),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [productId],
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
    final rows = await _db.getJsonList(OfflineConstants.businessesTable);
    return rows.map(BusinessData.fromJson).toList();
  }

  Future<List<Shops>> getShops() async {
    final rows = await _db.getJsonList(OfflineConstants.shopsTable);
    return rows.map(Shops.fromJson).toList();
  }

  Future<List<CategoryData>> getCategories() async {
    final db = await _db.database;
    final rows = await db.query(OfflineConstants.categoriesTable, orderBy: 'name COLLATE NOCASE ASC');
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
      OfflineConstants.productsTable,
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
      OfflineConstants.customersTable,
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
      OfflineConstants.stockTable,
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

  Future<void> saveCategoriesToCache(List<CategoryData> categories) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      Future<void> saveOne(CategoryData category) async {
        final id = category.id;
        if (id == null || id.isEmpty) return;

        await txn.insert(
          OfflineConstants.categoriesTable,
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

  Future<List<StockData>> getStockFallbackFromProducts() async {
    final products = await getProducts();
    final shops = await getShops();

    if (products.isEmpty || shops.isEmpty) return [];

    final shop = shops.first;
    final shopId = shop.id;
    if (shopId == null || shopId.isEmpty) return [];

    return products.map((product) {
      final qty = product.stockLevel ?? 0;

      return StockData(
        id: '${product.id}-$shopId',
        product: product.id,
        productName: product.name,
        productSku: product.sku,
        shop: shopId,
        shopName: shop.name,
        quantity: qty.toStringAsFixed(2),
        isOutOfStock: qty <= 0,
        isLowStock: qty > 0 && qty <= (product.minStockLevel ?? 0),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
    }).toList();
  }

  Future<void> saveAssetManifestPreservingDownloads(
      OfflineAssetManifestDto dto,
      ) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      for (final asset in dto.assets.where((e) => e.isValid)) {
        final existing = await txn.query(
          'offline_assets',
          where: 'id = ? AND type = ?',
          whereArgs: [asset.id, asset.type],
          limit: 1,
        );

        String? localPath;
        String? downloadedAt;

        if (existing.isNotEmpty) {
          final oldHash = existing.first['hash']?.toString();
          final oldUrl = existing.first['url']?.toString();
          final oldLocalPath = existing.first['local_path']?.toString();

          final sameAsset = oldHash == asset.hash && oldUrl == asset.url;

          if (sameAsset && oldLocalPath != null && oldLocalPath.isNotEmpty) {
            final file = File(oldLocalPath);
            if (await file.exists()) {
              localPath = oldLocalPath;
              downloadedAt = existing.first['downloaded_at']?.toString();
            }
          }
        }

        await txn.insert(
          'offline_assets',
          {
            'id': asset.id,
            'type': asset.type,
            'url': asset.url,
            'hash': asset.hash,
            'updated_at': asset.updatedAt,
            'local_path': localPath,
            'downloaded_at': downloadedAt,
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

  Future<List<OfflineAssetRecord>> getAssetsMissingLocalFiles({
    int limit = 50,
  }) async {
    final db = await _db.database;

    final rows = await db.query(
      'offline_assets',
      where: 'local_path IS NULL OR local_path = ?',
      whereArgs: [''],
      limit: limit,
    );

    return rows.map(OfflineAssetRecord.fromDb).toList();
  }

  Future<List<OfflineAssetRecord>> getAllAssets() async {
    final db = await _db.database;

    final rows = await db.query('offline_assets');

    return rows.map(OfflineAssetRecord.fromDb).toList();
  }

  Future<void> markAssetDownloaded({
    required String id,
    required String type,
    required String localPath,
  }) async {
    final db = await _db.database;

    await db.update(
      'offline_assets',
      {
        'local_path': localPath,
        'downloaded_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'id = ? AND type = ?',
      whereArgs: [id, type],
    );
  }

  Future<String?> getLocalAssetPathByUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return null;

    final db = await _db.database;

    final rows = await db.query(
      'offline_assets',
      columns: ['local_path'],
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final path = rows.first['local_path']?.toString();
    if (path == null || path.isEmpty) return null;

    final file = File(path);
    if (!await file.exists()) return null;

    return path;
  }

  Future<Directory> getOfflineAssetsDirectory() async {
    final dir = await getApplicationSupportDirectory();
    final assetsDir = Directory(p.join(dir.path, 'offline_assets'));

    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }

    return assetsDir;
  }

  Future<void> updateProductStockLevel({
    required String productId,
    required double stockLevel,
  }) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      final rows = await txn.query(
        OfflineConstants.productsTable,
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final jsonRaw = rows.first['json'] as String;
        final jsonMap = jsonDecode(jsonRaw) as Map<String, dynamic>;

        jsonMap['stock_level'] = stockLevel;

        await txn.update(
          OfflineConstants.productsTable,
          {
            'stock_level': stockLevel,
            'json': jsonEncode(jsonMap),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [productId],
        );
      }
    });
  }

  Future<void> saveProductsToCache(List<ProductData> products) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      for (final product in products) {
        final id = product.id;
        if (id == null || id.isEmpty) continue;

        final stockRows = await txn.query(
          OfflineConstants.stockTable,
          columns: ['quantity'],
          where: 'product_id = ?',
          whereArgs: [id],
          limit: 1,
        );

        final cachedStock = stockRows.isEmpty
            ? null
            : (stockRows.first['quantity'] as num?)?.toDouble();

        final resolvedStockLevel = cachedStock ?? product.stockLevel ?? 0.0;

        final normalizedProduct = product.copyWith(
          stockLevel: resolvedStockLevel,
        );

        final existingRows = await txn.query(
          OfflineConstants.productsTable,
          columns: ['thumbnail_url'],
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );

        final oldThumbnailUrl = existingRows.isEmpty
            ? null
            : existingRows.first['thumbnail_url']?.toString();

        final newThumbnailUrl = product.thumbnailUrl;

        if (oldThumbnailUrl != null && oldThumbnailUrl.isNotEmpty) {
          if (oldThumbnailUrl != newThumbnailUrl) {
            await txn.update(
              'offline_assets',
              {'local_path': null, 'downloaded_at': null},
              where: 'url = ?',
              whereArgs: [oldThumbnailUrl],
            );
          }
        }

        if (newThumbnailUrl != null && newThumbnailUrl.isNotEmpty) {
          await txn.update(
            'offline_assets',
            {'local_path': null, 'downloaded_at': null},
            where: 'url = ?',
            whereArgs: [newThumbnailUrl],
          );
        }

        await txn.insert(
          OfflineConstants.productsTable,
          {
            'id': id,
            'category_id': product.category,
            'name': product.name,
            'sku': product.sku,
            'barcode': product.barcode,
            'price': product.price,
            'stock_level': resolvedStockLevel,
            'thumbnail_url': newThumbnailUrl,
            'image_url': product.image,
            'json': jsonEncode(_productToJson(normalizedProduct)),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> saveStockToCache(List<StockData> stockList) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      for (final stock in stockList) {
        final productId = stock.product;
        final shopId = stock.shop;

        if (productId == null || productId.isEmpty) continue;
        if (shopId == null || shopId.isEmpty) continue;

        double quantity = stock.qty;
        final now = DateTime.now().toUtc().toIso8601String();

        final stockJson = _stockToJson(stock);
        stockJson['quantity'] = quantity;
        stockJson['is_out_of_stock'] = quantity <= 0;
        stockJson['updated_at'] = stock.updatedAt ?? now;

        await txn.insert(
          OfflineConstants.stockTable,
          {
            'id': stock.id ?? '$productId-$shopId',
            'product_id': productId,
            'shop_id': shopId,
            'quantity': quantity,
            'json': jsonEncode(stockJson),
            'updated_at': stock.updatedAt ?? now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        await _updateProductStockInsideTxn(
          txn: txn,
          productId: productId,
          quantity: quantity,
          updatedAt: now,
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
      OfflineConstants.stockTable,
      columns: ['quantity'],
      where: 'product_id = ? AND shop_id = ?',
      whereArgs: [productId, shopId],
      limit: 1,
    );

    if (rows.isEmpty) return 0;

    return (rows.first['quantity'] as num?)?.toDouble() ?? 0;
  }

  Future<void> updateStockQuantity({
    required String productId,
    required String shopId,
    required double quantity,
  }) async {
    final db = await _db.database;
    final safeQty = quantity < 0 ? 0.0 : quantity;
    final now = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      await _upsertStockQuantityInsideTxn(
        txn: txn,
        productId: productId,
        shopId: shopId,
        quantity: safeQty,
        updatedAt: now,
      );

      await _updateProductStockInsideTxn(
        txn: txn,
        productId: productId,
        quantity: safeQty,
        updatedAt: now,
      );
    });
  }

  Future<void> deductStockQuantity({
    required String productId,
    required String shopId,
    required double quantity,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      final rows = await txn.query(
        OfflineConstants.stockTable,
        columns: ['quantity'],
        where: 'product_id = ? AND shop_id = ?',
        whereArgs: [productId, shopId],
        limit: 1,
      );

      final currentQty = rows.isEmpty
          ? 0.0
          : (rows.first['quantity'] as num?)?.toDouble() ?? 0.0;

      final nextQty = currentQty - quantity;
      final safeQty = nextQty < 0 ? 0.0 : nextQty;

      await _upsertStockQuantityInsideTxn(
        txn: txn,
        productId: productId,
        shopId: shopId,
        quantity: safeQty,
        updatedAt: now,
      );

      await _updateProductStockInsideTxn(
        txn: txn,
        productId: productId,
        quantity: safeQty,
        updatedAt: now,
      );
    });
  }

  Future<void> _upsertStockQuantityInsideTxn({
    required Transaction txn,
    required String productId,
    required String shopId,
    required double quantity,
    required String updatedAt,
  }) async {
    final rows = await txn.query(
      OfflineConstants.stockTable,
      where: 'product_id = ? AND shop_id = ?',
      whereArgs: [productId, shopId],
      limit: 1,
    );

    if (rows.isEmpty) {
      final stockJson = <String, dynamic>{
        'id': '$productId-$shopId',
        'product': productId,
        'shop': shopId,
        'quantity': quantity,
        'is_low_stock': false,
        'is_out_of_stock': quantity <= 0,
        'updated_at': updatedAt,
      };

      await txn.insert(
        OfflineConstants.stockTable,
        {
          'id': '$productId-$shopId',
          'product_id': productId,
          'shop_id': shopId,
          'quantity': quantity,
          'json': jsonEncode(stockJson),
          'updated_at': updatedAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return;
    }

    final rawJson = rows.first['json']?.toString();
    final jsonMap = rawJson == null || rawJson.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(rawJson) as Map<String, dynamic>;

    jsonMap['product'] = jsonMap['product'] ?? productId;
    jsonMap['shop'] = jsonMap['shop'] ?? shopId;
    jsonMap['quantity'] = quantity;
    jsonMap['is_out_of_stock'] = quantity <= 0;
    jsonMap['updated_at'] = updatedAt;

    await txn.update(
      OfflineConstants.stockTable,
      {
        'quantity': quantity,
        'json': jsonEncode(jsonMap),
        'updated_at': updatedAt,
      },
      where: 'product_id = ? AND shop_id = ?',
      whereArgs: [productId, shopId],
    );
  }

  Future<void> _updateProductStockInsideTxn({
    required Transaction txn,
    required String productId,
    required double quantity,
    required String updatedAt,
  }) async {
    final productRows = await txn.query(
      OfflineConstants.productsTable,
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );

    if (productRows.isEmpty) return;

    final rawJson = productRows.first['json']?.toString();
    final jsonMap = rawJson == null || rawJson.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(rawJson) as Map<String, dynamic>;

    jsonMap['stock_level'] = quantity;

    await txn.update(
      OfflineConstants.productsTable,
      {
        'stock_level': quantity,
        'json': jsonEncode(jsonMap),
        'updated_at': updatedAt,
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  Future<void> transferStockLocally({
    required String productId,
    required String fromShopId,
    required String toShopId,
    required double quantity,
  }) async {
    final fromQty = await getStockQuantity(
      productId: productId,
      shopId: fromShopId,
    );

    final toQty = await getStockQuantity(
      productId: productId,
      shopId: toShopId,
    );

    final nextFromQty = fromQty - quantity;
    final nextToQty = toQty + quantity;

    await updateStockQuantity(
      productId: productId,
      shopId: fromShopId,
      quantity: nextFromQty < 0 ? 0 : nextFromQty,
    );

    await updateStockQuantity(
      productId: productId,
      shopId: toShopId,
      quantity: nextToQty,
    );
  }

  Future<void> saveBusinessesToCache(List<BusinessData> businesses) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      for (final business in businesses) {
        final id = business.id;
        if (id == null || id.isEmpty) continue;

        await txn.insert(
          OfflineConstants.businessesTable,
          {
            'id': id,
            'json': jsonEncode(business.toJson()),
            'updated_at': business.updatedAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        for (final shop in business.shops ?? const <Shops>[]) {
          final shopId = shop.id;
          if (shopId == null || shopId.isEmpty) continue;

          await txn.insert(
            OfflineConstants.shopsTable,
            {
              'id': shopId,
              'business_id': shop.business ?? business.id,
              'json': jsonEncode(shop.toJson()),
              'updated_at': shop.updatedAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<void> clearAllOnLogout() async {
    final db = await _db.database;

    Future<void> safeDeleteTable(Transaction txn, String table) async {
      try {
        await txn.delete(table);
      } catch (_) {
        // Table may not exist in older versions.
        // Do not crash logout because of cleanup.
      }
    }

    await db.transaction((txn) async {
      await safeDeleteTable(txn, OfflineConstants.businessesTable);
      await safeDeleteTable(txn, OfflineConstants.shopsTable);
      await safeDeleteTable(txn, OfflineConstants.categoriesTable);
      await safeDeleteTable(txn, OfflineConstants.productsTable);
      await safeDeleteTable(txn, OfflineConstants.customersTable);
      await safeDeleteTable(txn, OfflineConstants.stockTable);

      await safeDeleteTable(txn, 'offline_assets');
      await safeDeleteTable(txn, 'sync_metadata');

      // Important:
      // Do NOT delete offline sales / pending sales tables here.
      // Logout is blocked before this method if pending sales exist.
    });

    await _deleteOfflineAssetsDirectory();
  }

  Future<void> _deleteOfflineAssetsDirectory() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final assetsDir = Directory(p.join(dir.path, 'offline_assets'));

      if (await assetsDir.exists()) {
        await assetsDir.delete(recursive: true);
      }
    } catch (_) {
      // Do not block logout if file cleanup fails.
    }
  }
}