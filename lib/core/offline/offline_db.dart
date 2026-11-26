import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/pos/data/local/sale_local_store.dart';
import '../sync/sync_schema.dart';
import '../sync/sync_state_store.dart';

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
  static const int _dbVersion = 15;

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
    // FULL, not NORMAL (review I5): this DB holds finished sales (money).
    // With WAL, NORMAL may lose the last commits on power loss / OS crash,
    // i.e. a sale that was confirmed and printed. FULL fsyncs the WAL on
    // every commit (a few ms more per write; still one commit per sale).
    await db.execute('PRAGMA synchronous = FULL');
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

    // v11 (Phase 2): version/image_hash columns the pull appliers need and
    // the generic `synced_entities` table. Additive and idempotent.
    if (oldVersion < 11 && newVersion >= 11) {
      await createV11Schema(db);
    }

    // v12 (Phase 2, Task 9): hash-driven image sync table. Additive and
    // idempotent.
    if (oldVersion < 12 && newVersion >= 12) {
      await createV12Schema(db);
    }

    // v13 (Phase 2, Task 12): the legacy bulk bootstrap / asset manifest is
    // retired; its tables have no reader or writer left. Zero users, so
    // nothing is migrated.
    if (oldVersion < 13 && newVersion >= 13) {
      await dropLegacyBootstrapTables(db);
    }

    // v14 (Phase 3): see [createV14Schema]. Additive and idempotent.
    if (oldVersion < 14 && newVersion >= 14) {
      await createV14Schema(db);
    }

    // v15 (Phase 3 of the desktop parity work): shifts and cash movements.
    if (oldVersion < 15 && newVersion >= 15) {
      await createV15Schema(db);
    }
  }

  /// Shifts and the pay-in/pay-out rows of the cash drawer. `sync_state` is
  /// `pending|synced|rejected` like local refunds. Money is a decimal string.
  /// Safe to run on a fresh or an upgraded database.
  static Future<void> createV15Schema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shifts (
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        opened_by TEXT,
        opened_by_name TEXT,
        closed_by TEXT,
        closed_by_name TEXT,
        opening_cash TEXT NOT NULL DEFAULT '0',
        expected_cash TEXT,
        counted_cash TEXT,
        note TEXT,
        origin TEXT NOT NULL DEFAULT 'manual',
        sync_state TEXT NOT NULL DEFAULT 'pending',
        error_code TEXT,
        error_message TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_shifts_shop_opened '
      'ON shifts(shop_id, opened_at)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cash_movements (
        id TEXT PRIMARY KEY,
        shift_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        amount TEXT NOT NULL,
        reason TEXT NOT NULL DEFAULT '',
        occurred_at TEXT NOT NULL,
        user_id TEXT,
        user_name TEXT,
        sync_state TEXT NOT NULL DEFAULT 'pending',
        error_code TEXT,
        error_message TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_cash_movements_shift '
      'ON cash_movements(shift_id, occurred_at)',
    );
  }

  /// Phase 3 (catalog writes) additions, safe to run on a fresh or an
  /// upgraded database; every step must stay idempotent. Later Phase 3
  /// tasks extend THIS function (one v14 step).
  /// - outbox `depends_on_json` (multi-dependency list, backfilled from
  ///   `depends_on_entity_id`).
  /// - `pending_uploads` (staged catalog images waiting to upload). Like the
  ///   outbox it is user data: neither logout nor
  ///   [clearAllLocalOfflineData] deletes it.
  /// - outbox `error_entity_id` (the server's `conflict_entity_id`),
  ///   `claimed_at` (first claim by a sync run; "may have been sent") and
  ///   `failed_by_entity_id` (whose failed create failed this row).
  /// - `server_json` on `categories`, `products`, `vendors`: the last server
  ///   state of the row (feed-shaped `data` + `version`), written by the
  ///   pull appliers and by `adoptServerRow` on push results; NULL for a
  ///   never-synced local create. Used to restore a row on discard.
  static Future<void> createV14Schema(DatabaseExecutor db) async {
    await SyncSchema.addOutboxDependsOnList(db);
    await SyncSchema.createPendingUploads(db);
    await SyncSchema.addOutboxErrorEntityId(db);
    await SyncSchema.addOutboxClaimedAt(db);
    await SyncSchema.addOutboxFailedBy(db);
    for (final t in catalogServerJsonTables) {
      // A bare test DB (outbox only) has no catalog tables.
      if ((await db.rawQuery('PRAGMA table_info($t)')).isEmpty) continue;
      await _addColumnIfMissing(db, t, 'server_json', 'TEXT');
    }
    // Phase 4: local-first refunds. `sync_state` pending|synced|rejected
    // (pulled rows are `synced`); a `rejected` row is voided: kept for the
    // flag but excluded from every total.
    if ((await db.rawQuery('PRAGMA table_info(sale_refunds)')).isNotEmpty) {
      await _addColumnIfMissing(db, 'sale_refunds', 'reference', 'TEXT');
      await _addColumnIfMissing(
        db,
        'sale_refunds',
        'sync_state',
        "TEXT NOT NULL DEFAULT 'synced'",
      );
      await _addColumnIfMissing(db, 'sale_refunds', 'error_code', 'TEXT');
      await _addColumnIfMissing(db, 'sale_refunds', 'error_message', 'TEXT');
      await _addColumnIfMissing(db, 'sale_refunds', 'reason', 'TEXT');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sale_refunds_sale_state '
        'ON sale_refunds(sale_id, sync_state)',
      );
    }
  }

  /// Catalog tables that keep their last server state in `server_json`.
  static const List<String> catalogServerJsonTables = [
    'categories',
    'products',
    'vendors',
    'customers',
  ];

  /// Tables of the retired legacy bulk bootstrap (`sync_metadata`) and asset
  /// manifest (`offline_assets`; images now live in `synced_assets`).
  /// Idempotent.
  static const List<String> legacyBootstrapTables = [
    'offline_assets',
    'sync_metadata',
  ];

  static Future<void> dropLegacyBootstrapTables(DatabaseExecutor db) async {
    await db.execute('DROP INDEX IF EXISTS idx_offline_assets_url');
    for (final t in legacyBootstrapTables) {
      await db.execute('DROP TABLE IF EXISTS $t');
    }
  }

  /// `synced_assets`: one row per (type, id, variant `thumb|full`) image the
  /// feed references. `expected_hash` is the feed `image_hash` = a CHANGE
  /// TOKEN (ruling T1-a), `local_hash` the token the local file was
  /// downloaded for. Written by `registerAsset` (appliers) and `AssetSync`.
  /// The only image table: the legacy `offline_assets` is dropped in v13.
  static Future<void> createV12Schema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS synced_assets (
        type TEXT NOT NULL,
        id TEXT NOT NULL,
        variant TEXT NOT NULL,
        url TEXT NOT NULL,
        expected_hash TEXT,
        local_path TEXT,
        local_hash TEXT,
        bytes INTEGER,
        state TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        next_attempt_at TEXT,
        PRIMARY KEY(type, id, variant)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_synced_assets_due '
      'ON synced_assets(state, next_attempt_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_synced_assets_url '
      'ON synced_assets(url)',
    );
  }

  /// Phase 2 additions, safe to run on a fresh or an upgraded database.
  static Future<void> createV11Schema(DatabaseExecutor db) async {
    for (final t in const [
      'businesses',
      'shops',
      'categories',
      'products',
      'customers',
      'vendors',
    ]) {
      await _addColumnIfMissing(db, t, 'version', 'INTEGER');
    }
    for (final t in const ['categories', 'products']) {
      await _addColumnIfMissing(db, t, 'image_hash', 'TEXT');
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS synced_entities (
        entity TEXT NOT NULL,
        id TEXT NOT NULL,
        version INTEGER,
        json TEXT NOT NULL,
        updated_at TEXT,
        PRIMARY KEY(entity, id)
      )
    ''');
    // Pulled refunds (RefundApplier). The dashboard nets them on
    // `occurred_at` = the BE refund `created_at` (UTC ISO); `total` is the
    // wire money string. Server-only data kept beside `sales` (never wiped
    // with the catalog, like sales; visibility via the shop filter).
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_refunds (
        id TEXT PRIMARY KEY,
        sale_id TEXT,
        shop_id TEXT,
        total TEXT,
        occurred_at TEXT,
        method TEXT,
        json TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_refunds_occurred '
      'ON sale_refunds(occurred_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sale_refunds_sale '
      'ON sale_refunds(sale_id)',
    );
  }

  static Future<void> _addColumnIfMissing(
    DatabaseExecutor db,
    String table,
    String column,
    String type,
  ) async {
    final cols = await db.rawQuery('PRAGMA table_info($table)');
    if (cols.any((c) => c['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
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
  }

  static Future<void> onCreate(Database db, int version) async {
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

    await _createPremiumTables(db);

    await _createPerformanceIndexes(db);

    await SyncSchema.createAll(db);

    await SaleLocalStore.createTables(db);

    await createV11Schema(db);

    await createV12Schema(db);

    await createV14Schema(db);

    await createV15Schema(db);
  }

  Future<int> countRows(String table) async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getJsonList(String table) async {
    final db = await database;
    final rows = await db.query(table);
    return rows
        .map((row) => jsonDecode(row['json'] as String) as Map<String, dynamic>)
        .toList();
  }

  /// Clears reference/cache data. Never deletes `outbox` nor
  /// `pending_uploads` (an unsent image belongs to an unsent create); of
  /// `sync_state`
  /// only every scope's setup keys (cursor, `bootstrapped`, bootstrap
  /// progress, see [SyncStateStore.resetSetupOfAllScopes]) go with the rows.
  /// Local `sales` and `sale_refunds` are never deleted here (see
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
      await txn.delete('synced_assets');
      await txn.delete('vendors');
      await txn.delete('premium_summary');
      await txn.delete('inbound_transactions');
      await txn.delete('synced_entities');
      // The rows are gone: so is every scope's setup (ruling T1-d).
      await SyncStateStore.resetSetupOfAllScopes(txn);
    });
    notifyTablesChanged(const {'shops', 'synced_assets', SyncTables.syncState});
  }
}
