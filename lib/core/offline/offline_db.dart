import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class OfflineDb {
  OfflineDb._();

  static final OfflineDb instance = OfflineDb._();

  static const String _dbName = 'amana_pos_offline.db';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
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

    await db.execute('CREATE INDEX idx_products_category ON products(category_id)');
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
        json TEXT NOT NULL,
        updated_at TEXT,
        UNIQUE(product_id, shop_id)
      )
    ''');

    await db.execute('CREATE INDEX idx_stock_product_shop ON stock(product_id, shop_id)');

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

    await db.execute('''
      CREATE TABLE pending_sales (
        client_sale_id TEXT PRIMARY KEY,
        server_sale_id TEXT,
        shop_id TEXT NOT NULL,
        customer_id TEXT,
        payment_method TEXT NOT NULL,
        discount_amount TEXT,
        tax_amount TEXT,
        subtotal TEXT NOT NULL,
        total TEXT NOT NULL,
        status TEXT NOT NULL,
        error_message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_pending_sales_status ON pending_sales(status)');

    await db.execute('''
      CREATE TABLE pending_sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT,
        quantity REAL NOT NULL,
        unit_price TEXT NOT NULL,
        line_total TEXT NOT NULL,
        product_snapshot_json TEXT NOT NULL,
        FOREIGN KEY(client_sale_id) REFERENCES pending_sales(client_sale_id) ON DELETE CASCADE
      )
    ''');
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
    await db.insert(
      'sync_metadata',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
  }

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
      await txn.delete('pending_sale_items');
      await txn.delete('pending_sales');
      await txn.delete('sync_metadata');
    });
  }
}