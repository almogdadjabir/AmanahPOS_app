import 'dart:convert';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/decimal3.dart';
import 'package:amana_pos/features/inventory/data/local/stock_local_store.dart';
import 'package:sqflite/sqflite.dart';

/// A product the shelf can be counted against. [system] is what the app shows
/// for the shop (the synced quantity plus this phone's waiting changes), in
/// thousandths.
class CountProduct {
  const CountProduct({
    required this.id,
    required this.name,
    required this.barcode,
    required this.sku,
    required this.tracked,
    required this.system,
  });

  final String id;
  final String name;
  final String barcode;
  final String sku;
  final bool tracked;
  final BigInt system;

  String get systemText => Decimal3.format(system);
}

/// Reads products for a stock count from the local database.
class StockCountReader {
  StockCountReader({required OfflineDb db}) : _db = db;

  final OfflineDb _db;
  static const _stock = StockLocalStore();

  /// "Add all products" loads at most this many (same cap as the product grid).
  static const int addAllLimit = 1000;

  Future<CountProduct?> _build(
    Database db,
    Map<String, Object?> row,
    String shopId,
  ) async {
    Map<String, dynamic> j = const {};
    try {
      final d = jsonDecode(row['json'] as String);
      if (d is Map) j = Map<String, dynamic>.from(d);
    } on FormatException {
      return null;
    }
    if (j['is_active'] == false) return null;
    final id = row['id'] as String;
    return CountProduct(
      id: id,
      name: (row['name'] as String?) ?? '',
      barcode: (row['barcode'] as String?) ?? '',
      sku: (row['sku'] as String?) ?? '',
      tracked: j['track_inventory'] == true,
      system: await _stock.currentUnits(db, id, shopId),
    );
  }

  /// Exact barcode or SKU. Returns the product even when it does not track
  /// stock, so the screen can say so.
  Future<CountProduct?> byCode(String code, String shopId) async {
    final c = code.trim();
    if (c.isEmpty) return null;
    final db = await _db.database;
    final rows = await db.query(
      'products',
      where: 'barcode = ? OR sku = ?',
      whereArgs: [c, c],
      limit: 1,
    );
    return rows.isEmpty ? null : _build(db, rows.first, shopId);
  }

  /// Active, stock-tracking products whose name, barcode or SKU contain
  /// [query].
  Future<List<CountProduct>> search(
    String query,
    String shopId, {
    int limit = 8,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final db = await _db.database;
    final like = '%${q.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
    final rows = await db.query(
      'products',
      where:
          "name LIKE ? ESCAPE '\\' OR barcode LIKE ? ESCAPE '\\' OR sku LIKE ? ESCAPE '\\'",
      whereArgs: [like, like, like],
      orderBy: 'name COLLATE NOCASE',
      limit: limit * 4,
    );
    final out = <CountProduct>[];
    for (final r in rows) {
      final p = await _build(db, r, shopId);
      if (p != null && p.tracked) out.add(p);
      if (out.length >= limit) break;
    }
    return out;
  }

  Future<List<CountProduct>> all(String shopId) async {
    final db = await _db.database;
    final rows = await db.query(
      'products',
      orderBy: 'name COLLATE NOCASE',
      limit: addAllLimit * 2,
    );
    final out = <CountProduct>[];
    for (final r in rows) {
      final p = await _build(db, r, shopId);
      if (p != null && p.tracked) out.add(p);
      if (out.length >= addAllLimit) break;
    }
    return out;
  }
}
