import 'dart:convert';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:flutter/foundation.dart';
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

  Future<PendingSalesDelta> getPendingSalesDelta({
    String? shopId,
    required DateTime date,
  });
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  final OfflineDb offlineDb;

  const DashboardLocalDataSourceImpl({
    required this.offlineDb,
  });

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

    await db.insert(
      _cacheTable,
      {
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
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
        _cacheKey(
          businessId: businessId,
          shopId: shopId,
          date: date,
        ),
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
  Future<PendingSalesDelta> getPendingSalesDelta({
    String? shopId,
    required DateTime date,
  }) async {
    final db = await offlineDb.database;

    final hasPendingSales = await _tableExists(db, 'pending_sales');
    if (!hasPendingSales) return PendingSalesDelta.empty();

    final salesColumns = await _columns(db, 'pending_sales');

    final rows = await db.query('pending_sales');

    if (rows.isEmpty) return PendingSalesDelta.empty();

    double grossAmount = 0;
    double cashAmount = 0;
    double bankakAmount = 0;
    int salesCount = 0;

    final sparklineMap = <String, SparklinePoint>{};
    final pendingSaleIds = <String>[];

    for (final row in rows) {
      if (!_isPendingRow(row)) continue;

      if (shopId != null && shopId.isNotEmpty) {
        final rowShopId = _firstString(row, const [
          'shop_id',
          'shop',
          'selected_shop_id',
        ]);

        if (rowShopId != null && rowShopId != shopId) continue;
      }

      final createdAt = _rowDateTime(row);
      if (createdAt != null && !_sameDate(createdAt.toLocal(), date)) {
        continue;
      }

      final total = _firstDouble(row, const [
        'total_amount',
        'total',
        'grand_total',
        'amount',
      ]);

      final paymentMethod = _firstString(row, const [
        'payment_method',
        'payment',
      ]);

      final saleId = _firstString(row, const [
        'id',
        'local_id',
        'client_sale_id',
      ]);

      if (saleId != null) pendingSaleIds.add(saleId);

      grossAmount += total;
      salesCount += 1;

      if (paymentMethod == 'bankak') {
        bankakAmount += total;
      } else {
        cashAmount += total;
      }

      final label = _hourLabel(createdAt ?? DateTime.now());
      final old = sparklineMap[label];

      sparklineMap[label] = SparklinePoint(
        label: label,
        amount: (old?.amount ?? 0) + total,
        salesCount: (old?.salesCount ?? 0) + 1,
      );
    }

    final topSellers = await _pendingTopSellers(
      db: db,
      pendingSaleIds: pendingSaleIds,
      salesColumns: salesColumns,
    );

    final sparkline = sparklineMap.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    debugPrint(
      '[DashboardLocalDelta] shop=$shopId '
          'gross=$grossAmount '
          'count=$salesCount '
          'cash=$cashAmount '
          'bankak=$bankakAmount',
    );

    return PendingSalesDelta(
      grossAmount: grossAmount,
      netAmount: grossAmount,
      salesCount: salesCount,
      cashAmount: cashAmount,
      bankakAmount: bankakAmount,
      sparklinePoints: sparkline,
      topSellers: topSellers,
    );
  }

  Future<List<TopSeller>> _pendingTopSellers({
    required Database db,
    required List<String> pendingSaleIds,
    required Set<String> salesColumns,
  }) async {
    final hasItems = await _tableExists(db, 'pending_sale_items');
    if (!hasItems || pendingSaleIds.isEmpty) return const [];

    final rows = await db.query('pending_sale_items');

    final map = <String, TopSeller>{};

    for (final row in rows) {
      final saleId = _firstString(row, const [
        'sale_id',
        'pending_sale_id',
        'client_sale_id',
      ]);

      if (saleId == null || !pendingSaleIds.contains(saleId)) continue;

      final productId = _firstString(row, const [
        'product_id',
        'product',
      ]) ??
          'unknown';

      final name = _firstString(row, const [
        'product_name',
        'name',
      ]) ??
          'Product';

      final qty = _firstDouble(row, const [
        'quantity',
        'qty',
      ]);

      final subtotal = _firstDouble(row, const [
        'subtotal',
        'line_total',
        'total',
      ]);

      final old = map[productId];

      if (old == null) {
        map[productId] = TopSeller(
          productId: productId,
          name: name,
          quantitySold: qty,
          grossAmount: subtotal,
          thumbnailUrl: _firstString(row, const [
            'thumbnail_url',
            'image',
          ]),
        );
      } else {
        map[productId] = old.copyWith(
          quantitySold: old.quantitySold + qty,
          grossAmount: old.grossAmount + subtotal,
        );
      }
    }

    final result = map.values.toList()
      ..sort((a, b) {
        final qtyCompare = b.quantitySold.compareTo(a.quantitySold);
        if (qtyCompare != 0) return qtyCompare;
        return b.grossAmount.compareTo(a.grossAmount);
      });

    return result.take(5).toList();
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

  String _cacheKey({
    String? businessId,
    String? shopId,
    required String date,
  }) {
    return '${businessId ?? 'default'}:${shopId ?? 'all'}:$date';
  }

  Future<bool> _tableExists(Database db, String table) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [table],
    );

    return rows.isNotEmpty;
  }

  Future<Set<String>> _columns(Database db, String table) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.map((e) => e['name'].toString()).toSet();
  }

  bool _isPendingRow(Map<String, Object?> row) {
    final status = _firstString(row, const [
      'sync_status',
      'status',
      'syncStatus',
    ])?.toLowerCase();

    final serverSaleId = _firstString(row, const [
      'server_sale_id',
      'serverSaleId',
      'remote_id',
      'remoteId',
      'sale_id',
    ]);

    final syncedAt = _firstString(row, const [
      'synced_at',
      'syncedAt',
    ]);

    // If this row already has a server reference, do not add it on top of API.
    if (serverSaleId != null && serverSaleId.isNotEmpty) {
      return false;
    }

    // If it has sync timestamp, it is already included in API or should be soon.
    if (syncedAt != null && syncedAt.isNotEmpty) {
      return false;
    }

    // Important:
    // Unknown/null status should NOT be counted.
    // This was the reason stale rows could inflate dashboard totals.
    if (status == null || status.isEmpty) {
      return false;
    }

    return status == 'pending' ||
        status == 'queued' ||
        status == 'syncing' ||
        status == 'failed' ||
        status == 'retry';
  }

  DateTime? _rowDateTime(Map<String, Object?> row) {
    final raw = _firstString(row, const [
      'created_at',
      'client_created_at',
      'createdAt',
      'local_created_at',
      'updated_at',
    ]);

    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _hourLabel(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    return '$hour:00';
  }

  String? _firstString(
      Map<String, Object?> row,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }

    return null;
  }

  double _firstDouble(
      Map<String, Object?> row,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;

      if (value is num) return value.toDouble();

      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
    }

    return 0;
  }
}