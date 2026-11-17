import 'dart:convert';
import 'dart:io';
import 'package:amana_pos/core/sync/catalog_stash.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/core/offline/data/local_image_resolver.dart';
import 'package:amana_pos/core/offline/offline_constants.dart';
import 'package:amana_pos/features/inventory/data/models/responses/inbound_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/premium_summary_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/vendor_response_dto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/catalog_sync_marks.dart';
import 'package:amana_pos/core/sync/decimal3.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/features/inventory/data/local/stock_local_store.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:sqflite/sqflite.dart';

class OfflineLocalCache {
  OfflineLocalCache(this._db);

  final OfflineDb _db;
  static const _stockStore = StockLocalStore();

  /// Exact server base of a legacy stock DTO: the raw decimal string when it
  /// parses, else the (already parsed) double.
  static BigInt _baseUnits(StockData item) =>
      Decimal3.tryParse(item.quantity) ??
      Decimal3.tryParse(item.qty) ??
      BigInt.zero;

  Future<List<BusinessData>> getBusinesses() async {
    final rows = await _db.getJsonList(OfflineConstants.businessesTable);
    return rows.map(BusinessData.fromJson).toList();
  }

  Future<List<ShopData>> getShops() async {
    final rows = await _db.getJsonList(OfflineConstants.shopsTable);
    return rows.map(ShopData.fromJson).toList();
  }

  /// Soft-deleted categories (`is_active == false`, a local delete waiting to
  /// sync) are hidden unless [includeInactive].
  Future<List<CategoryData>> getCategories({
    bool includeInactive = false,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      OfflineConstants.categoriesTable,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    final all = rows
        .map((row) => jsonDecode(row['json'] as String))
        .where((j) => includeInactive || j is! Map || j['is_active'] != false);
    return all.map((j) => CategoryData.fromJson(j)).toList();
  }

  /// Local products by name. [isActive]: null = all rows, true = active
  /// only (lists and pickers: a local delete is `is_active == false` until
  /// the server confirms it), false = inactive only (the inactive filter;
  /// history stays resolvable). [limit] caps the rows read (first page).
  Future<List<ProductData>> getProducts({
    String? categoryId,
    String? search,
    bool? isActive,
    int? limit,
  }) async {
    if (limit != null && isActive != null) {
      // limit is applied in SQL, before the isActive filter: a page of
      // inactive rows would hide active ones.
      throw ArgumentError('limit cannot be combined with isActive');
    }
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
      // A page, not the catalog: callers that show a screenful pass it
      // (perf budget, Phase 7). Null = everything, as before. With an
      // [isActive] filter the limit applies before it, so use it only
      // with isActive == null or a pre-filtered query.
      limit: limit,
    );

    final all = rows.map(
      (row) => ProductData.fromJson(jsonDecode(row['json'] as String)),
    );
    if (isActive == null) return all.toList();
    return all.where((p) => (p.isActive != false) == isActive).toList();
  }

  /// "Waiting to sync" / "Sync failed" row markers of a catalog [entity]
  /// (`product`, `category`, `vendor`), from the outbox and staged uploads.
  Future<CatalogSyncMarks> getCatalogSyncMarks(String entity) async =>
      CatalogSyncMarks.load(
        await _db.database,
        entity,
        scope: SyncScope.current,
      );

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
        // BE rule (StockLevel.is_low_stock): out-of-stock is also low.
        isLowStock: qty <= (product.minStockLevel ?? 0),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
    }).toList();
  }

  /// Local file of a downloaded image in `synced_assets` (AssetSync), by
  /// url. Feed urls carry `?v=<hash12>`, so the url is matched without its
  /// query: an exact match wins, then the newest row (rowid) of the same
  /// path. Any row whose `local_path` file exists, whatever its state:
  /// AssetSync only ever sets `local_path` to a completed, verified final
  /// file (never a temp), and a `pending` row keeps the PREVIOUS good file
  /// until the new one is adopted, so offline still shows an image.
  /// Null when none.
  Future<String?> getSyncedAssetPathByUrl(String? url) async {
    final raw = url?.trim();
    if (raw == null || raw.isEmpty) return null;
    final q = raw.indexOf('?');
    final base = q < 0 ? raw : raw.substring(0, q);
    if (base.isEmpty) return null;

    final db = await _db.database;
    // `base?...` sorts between `base?` and `base@` ('?' 0x3F, '@' 0x40):
    // an index range on url instead of LIKE (no wildcard escaping).
    final rows = await db.rawQuery(
      'SELECT local_path FROM synced_assets '
      'WHERE local_path IS NOT NULL '
      'AND (url = ? OR url = ? OR (url >= ? AND url < ?)) '
      'ORDER BY CASE WHEN url = ? THEN 0 ELSE 1 END, rowid DESC '
      'LIMIT 4',
      [raw, base, '$base?', '$base@', raw],
    );
    for (final r in rows) {
      final path = r['local_path']?.toString();
      if (path == null || path.isEmpty) continue;
      if (await File(path).exists()) return path;
    }
    return null;
  }

  /// Every `synced_assets` row holding a file, newest first: the single
  /// query behind the shared image resolver ([LocalImageResolver]).
  Future<List<SyncedAssetPath>> getSyncedAssetPaths() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT url, local_path FROM synced_assets '
      'WHERE local_path IS NOT NULL ORDER BY rowid DESC',
    );
    return [
      for (final r in rows)
        if (r['url'] is String && r['local_path'] is String)
          (url: r['url'] as String, path: r['local_path'] as String),
    ];
  }

  Future<void> saveStockToCache(List<StockData> stockList) async {
    final db = await _db.database;

    await db.transaction((txn) async {
      for (final stock in stockList) {
        final productId = stock.product;
        final shopId = stock.shop;

        if (productId == null || productId.isEmpty) continue;
        if (shopId == null || shopId.isEmpty) continue;

        final base = _baseUnits(stock);
        final pending = await _stockStore.pendingDeltaUnits(
          txn,
          productId,
          shopId,
        );
        final double quantity = Decimal3.toDouble(base + pending);
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
            'base_quantity': Decimal3.format(base),
            'json': jsonEncode(stockJson),
            'updated_at': stock.updatedAt ?? now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // products.stock_level = sum over shops (never one shop's value).
        await _stockStore.recompute(txn, productId, shopId);
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

        for (final shop in business.shops ?? const <ShopData>[]) {
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
    _db.notifyTablesChanged(const {OfflineConstants.shopsTable});
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
      // M1: catalog rows with unsynced outbox rows come back when the same
      // account signs in again (restored at the end of its bootstrap).
      try {
        await CatalogStash.stashForLogout(txn);
      } catch (_) {
        // Never block logout on the stash (outbox is kept either way).
      }
      await safeDeleteTable(txn, OfflineConstants.businessesTable);
      await safeDeleteTable(txn, OfflineConstants.shopsTable);
      await safeDeleteTable(txn, OfflineConstants.categoriesTable);
      await safeDeleteTable(txn, OfflineConstants.productsTable);
      await safeDeleteTable(txn, OfflineConstants.customersTable);
      await safeDeleteTable(txn, OfflineConstants.stockTable);

      // Files are removed by the next AssetSync orphan sweep.
      await safeDeleteTable(txn, 'synced_assets');
      await safeDeleteTable(txn, 'synced_entities');

      // Unsynced data is never destroyed here: the sync outbox, deferred
      // pulls and `pending_uploads` (staged images of unsent creates/edits,
      // and their files under pending_images/) are untouched (explicit
      // discard is OutboxStore.discardAll).
      await safeDeleteTable(txn, OfflineConstants.vendorsTable);
      await safeDeleteTable(txn, OfflineConstants.premiumSummaryTable);
      await safeDeleteTable(txn, OfflineConstants.inboundTransactionsTable);

      // Same transaction as the rows: every scope's cursor, `bootstrapped`
      // flag and bootstrap progress go too (ruling T1-d), so the next login
      // sets up again instead of pulling on top of an empty catalog. Outbox,
      // deferred pulls, sales and sale_refunds are kept (T5-a).
      await SyncStateStore.resetSetupOfAllScopes(txn);
    });
    _db.notifyTablesChanged(const {
      OfflineConstants.shopsTable,
      'synced_assets',
      SyncTables.syncState,
    });

    await _deleteLegacyAssetsDirectory();
  }

  /// Active vendors only. Inactive rows (a local delete/deactivation waiting
  /// to sync, or written by the sync `VendorApplier`) stay in the table so
  /// inbound history keeps its vendor names; they are just not listed.
  Future<List<VendorData>> getVendors() async {
    final rows = await _db.getJsonList(OfflineConstants.vendorsTable);
    return rows
        .where((r) => r['is_active'] != false)
        .map(VendorData.fromJson)
        .toList();
  }

  Future<PremiumSummaryData?> getPremiumSummary({String? shopId}) async {
    final db = await _db.database;
    final key = shopId ?? 'default';
    final rows = await db.query(
      OfflineConstants.premiumSummaryTable,
      where: 'shop_id = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PremiumSummaryData.fromJson(
      jsonDecode(rows.first['json'] as String) as Map<String, dynamic>,
    );
  }

  Future<void> savePremiumSummary(
    PremiumSummaryData data, {
    String? shopId,
  }) async {
    final db = await _db.database;
    final key = shopId ?? 'default';
    await db.insert(
      OfflineConstants.premiumSummaryTable,
      {
        'shop_id': key,
        'json': jsonEncode(data.toJson()),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<InboundTransactionData>> getInboundTransactions({
    int limit = 50,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      OfflineConstants.inboundTransactionsTable,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows
        .map(
          (row) => InboundTransactionData.fromJson(
            jsonDecode(row['json'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> saveInboundTransactions(
    List<InboundTransactionData> transactions,
  ) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Keep local receipts not yet on the server (open inbound.create
      // outbox row, sync engine path): the REST list cannot contain them.
      await txn.delete(
        OfflineConstants.inboundTransactionsTable,
        where:
            "id NOT IN (SELECT entity_id FROM outbox WHERE entity = 'inbound' "
            "AND op = 'create' AND status != 'done')",
      );
      for (final tx in transactions) {
        final id = tx.id;
        if (id == null || id.isEmpty) continue;
        await txn.insert(
          OfflineConstants.inboundTransactionsTable,
          {
            'id': id,
            'shop_id': tx.shop,
            'json': jsonEncode(tx.toJson()),
            'created_at': tx.createdAt,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Removes the folder the retired legacy downloader used (`offline_assets`)
  /// if an earlier build left one behind. Nothing writes it any more.
  Future<void> _deleteLegacyAssetsDirectory() async {
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
