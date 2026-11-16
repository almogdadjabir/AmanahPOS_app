import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/pos/data/local/sale_local_store.dart';
import '../sync/sync_schema.dart';

class OfflineDb {
  OfflineDb._();

  OfflineDb.forTesting(Database db) : _database = db;

  static final OfflineDb instance = OfflineDb._();

  /// "Tables changed" hook for writers that do not go through `LocalWriter`
  /// (the legacy cache: `shops` rows decide which local sales are visible).
  /// Set by DI to `DbChangeNotifier.notify` when the sync engine is on;
  /// null (flag off): a no-op.
  void Function(Set<String> tables)? onTablesChanged;

  /// Calls [onTablesChanged] after a commit; a listener failure never fails
  /// the write that already committed.
  void notifyTablesChanged(Set<String> tables) {
    try {
      onTablesChanged?.call(tables);
    } catch (_) {
      // Listeners are best-effort.
    }
  }

  static const String _dbName = 'amana_pos_offline.db';
  static const int _dbVersion = 10;

  static const int schemaVersion = _dbVersion;

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: onConfigure,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );

    return _database!;
  }

  /// How long a statement waits for a lock held by another connection (the
  /// background sync isolate / the app) before failing with SQLITE_BUSY.
  static const int busyTimeoutMs = 5000;

  static Future<void> onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');

    // The foreground app and the background sync worker may open this file
    // at the same time. Both PRAGMAs return a row, so they go through
    // rawQuery: `execute` of journal_mode=WAL throws "not an error" on
    // sqflite/iOS. Best effort: a failure here must never block the open.
    try {
      await db.rawQuery('PRAGMA busy_timeout = $busyTimeoutMs');
    } catch (_) {}
    try {
      await db.rawQuery('PRAGMA journal_mode = WAL');
    } catch (_) {}
    await db.execute('PRAGMA synchronous = NORMAL');
    await db.execute('PRAGMA temp_store = MEMORY');
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 3) {
      await _createPremiumTables(db);
    }

    if (oldVersion < 4) {
      await _createPerformanceIndexes(db);
    }

    if (oldVersion < 6) {
      await SyncSchema.createAll(db);
    }

    if (oldVersion < 7) {
      await SyncSchema.addOutboxScope(db);
    }

    if (oldVersion < 8) {
      await SyncSchema.addStockBaseQuantity(db);
    }

    if (oldVersion < 9) {
      await SaleLocalStore.createTables(db);
    }

    // v10: the legacy sale / inbound queues are gone (the sync outbox is the
    // only write path). Zero production users, so nothing is migrated.
    if (oldVersion < 10 && newVersion >= 10) {
      await dropLegacyQueueTables(db);
    }
  }

  /// Legacy queue tables removed in v10. Idempotent.
  static const List<String> legacyQueueTables = [
    'pending_sale_items',
    'pending_sales',
    'pending_inbound_transactions',
  ];

  static Future<void> dropLegacyQueueTables(DatabaseExecutor db) async {
    for (final t in legacyQueueTables) {
      await db.execute('DROP TABLE IF EXISTS $t');
    }
  }

  static Future<void> _createPremiumTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vendors (
        id TEXT PRIMARY KEY,
        json TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS premium_summary (
        shop_id TEXT NOT NULL,
        json TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY(shop_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS inbound_transactions (
        id TEXT PRIMARY KEY,
        shop_id TEXT,
        json TEXT NOT NULL,
        created_at TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inbound_shop ON inbound_transactions(shop_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_inbound_created ON inbound_transactions(created_at)',
    );
  }

  static Future<void> _createPerformanceIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_category_name ON products(category_id, name)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_products_updated_at ON products(updated_at)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_shop ON stock(shop_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_product ON stock(product_id)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_phone_name ON customers(phone, name)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_offline_assets_url ON offline_assets(url)',
    );
  }

  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE businesses (
        id TEXT PRIMARY KEY,
        json TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE shops (
        id TEXT PRIMARY KEY,
        business_id TEXT,
        json TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        tenant_id TEXT,
        parent_id TEXT,
        name TEXT,
        json TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        category_id TEXT,
        name TEXT,
        sku TEXT,
        barcode TEXT,
        price TEXT,
        stock_level REAL,
        thumbnail_url TEXT,
        image_url TEXT,
        json TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_products_category ON products(category_id)',
    );
    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');

    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT,
        phone TEXT,
        email TEXT,
        json TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_customers_name ON customers(name)');
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');

    await db.execute('''
      CREATE TABLE stock (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        shop_id TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        base_quantity TEXT NOT NULL DEFAULT '0',
        json TEXT NOT NULL,
        updated_at TEXT,
        UNIQUE(product_id, shop_id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_stock_product_shop ON stock(product_id, shop_id)',
    );

    await db.execute('''
      CREATE TABLE offline_assets (
        id TEXT NOT NULL,
        type TEXT NOT NULL,
        url TEXT NOT NULL,
        hash TEXT,
        updated_at TEXT,
        local_path TEXT,
        downloaded_at TEXT,
        PRIMARY KEY(id, type)
      )
    ''');

    await _createPremiumTables(db);

    await _createPerformanceIndexes(db);

    await SyncSchema.createAll(db);

    await SaleLocalStore.createTables(db);
  }

  Future<int> countRows(String table) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> hasBootstrapCache() async {
    final businessCount = await countRows('businesses');
    final productCount = await countRows('products');
    final categoryCount = await countRows('categories');

    return businessCount > 0 || productCount > 0 || categoryCount > 0;
  }

  Future<void> setMetadata(String key, String value) async {
    final db = await database;
    await db.insert('sync_metadata', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getMetadata(String key) async {
    final db = await database;
    final rows = await db.query(
      'sync_metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first['value']?.toString();
  }

  Future<List<Map<String, dynamic>>> getJsonList(String table) async {
    final db = await database;
    final rows = await db.query(table);
    return rows
        .map((row) => jsonDecode(row['json'] as String) as Map<String, dynamic>)
        .toList();
  }

  Future<void> clearBootstrapCache() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('businesses');
      await txn.delete('shops');
      await txn.delete('categories');
      await txn.delete('products');
      await txn.delete('customers');
      await txn.delete('stock');
      await txn.delete('offline_assets');
      await txn.delete('sync_metadata');
    });
    notifyTablesChanged(const {'shops'});
  }

  /// Clears reference/cache data. Never deletes `outbox` / `sync_state`.
  /// Local `sales` are never deleted here (see
  /// [SaleLocalStore.visibleShopSql]).
  Future<void> clearAllLocalOfflineData() async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('businesses');
      await txn.delete('shops');
      await txn.delete('categories');
      await txn.delete('products');
      await txn.delete('customers');
      await txn.delete('stock');
      await txn.delete('offline_assets');
      await txn.delete('vendors');
      await txn.delete('premium_summary');
      await txn.delete('inbound_transactions');
      await txn.delete('sync_metadata');
    });
    notifyTablesChanged(const {'shops'});
  }
}
