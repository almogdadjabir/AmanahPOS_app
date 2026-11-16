import 'dart:convert';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:sqflite/sqflite.dart';

abstract class DashboardLocalDataSource {
  Future<void> saveSummary({
    required DashboardSummaryDto dto,
    String? businessId,
    String? shopId,
    required String date,
  });

  Future<DashboardSummaryDto?> getCachedSummary({
    String? businessId,
    String? shopId,
    required String date,
  });

  /// Timezone and currency the server last reported for [businessId]
  /// (from the cached remote summary); nulls when never fetched.
  Future<({String? timezone, String? currency})> lastKnownMeta({
    String? businessId,
  });
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  final OfflineDb offlineDb;

  const DashboardLocalDataSourceImpl({required this.offlineDb});

  static const String _cacheTable = 'dashboard_summary_cache';

  @override
  Future<void> saveSummary({
    required DashboardSummaryDto dto,
    String? businessId,
    String? shopId,
    required String date,
  }) async {
    final db = await offlineDb.database;
    await _ensureCacheTable(db);

    await db.insert(_cacheTable, {
      'cache_key': _cacheKey(
        businessId: businessId,
        shopId: shopId,
        date: date,
      ),
      'business_id': businessId,
      'shop_id': shopId,
      'date': date,
      'currency': dto.currency,
      'json': jsonEncode(dto.toJson()),
      'server_time': dto.serverTime,
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<DashboardSummaryDto?> getCachedSummary({
    String? businessId,
    String? shopId,
    required String date,
  }) async {
    final db = await offlineDb.database;
    await _ensureCacheTable(db);

    final rows = await db.query(
      _cacheTable,
      where: 'cache_key = ?',
      whereArgs: [
        _cacheKey(businessId: businessId, shopId: shopId, date: date),
      ],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final rawJson = rows.first['json']?.toString();
    if (rawJson == null || rawJson.isEmpty) return null;

    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return DashboardSummaryDto.fromJson(decoded);
  }

  @override
  Future<({String? timezone, String? currency})> lastKnownMeta({
    String? businessId,
  }) async {
    try {
      final db = await offlineDb.database;
      if (!await _tableExists(db, _cacheTable)) {
        return (timezone: null, currency: null);
      }
      final rows = await db.query(
        _cacheTable,
        columns: ['json', 'currency'],
        where: businessId == null ? null : 'business_id = ?',
        whereArgs: businessId == null ? null : [businessId],
        orderBy: 'cached_at DESC',
        limit: 1,
      );
      if (rows.isEmpty) return (timezone: null, currency: null);
      final decoded = jsonDecode(rows.first['json'].toString());
      final tz = decoded is Map ? decoded['timezone']?.toString() : null;
      return (
        timezone: (tz == null || tz.isEmpty) ? null : tz,
        currency: rows.first['currency']?.toString(),
      );
    } catch (_) {
      return (timezone: null, currency: null);
    }
  }

  Future<void> _ensureCacheTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_cacheTable (
        cache_key TEXT PRIMARY KEY,
        business_id TEXT,
        shop_id TEXT,
        date TEXT NOT NULL,
        currency TEXT,
        json TEXT NOT NULL,
        server_time TEXT,
        cached_at TEXT NOT NULL
      )
    ''');
  }

  String _cacheKey({String? businessId, String? shopId, required String date}) {
    return '${businessId ?? 'default'}:${shopId ?? 'all'}:$date';
  }

  Future<bool> _tableExists(Database db, String table) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );

    return rows.isNotEmpty;
  }
}
