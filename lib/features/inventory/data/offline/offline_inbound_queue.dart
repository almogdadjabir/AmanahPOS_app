import 'dart:convert';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/data/offline/offline_inbound_dto.dart';
import 'package:sqflite/sqflite.dart';

class OfflineInboundQueue {
  OfflineInboundQueue({required OfflineDb db}) : _db = db;

  final OfflineDb _db;

  Future<void> enqueue({
    required String clientInboundId,
    required CreateInboundRequestDto request,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toUtc().toIso8601String();

    await db.insert(
      'pending_inbound_transactions',
      {
        'client_inbound_id': clientInboundId,
        'reference': request.reference,
        'shop_id': request.shopId,
        'notes': request.notes,
        'payload_json': jsonEncode(request.toJson()),
        'status': 'pending',
        'error_message': null,
        'created_at': now,
        'updated_at': now,
        'synced_at': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> pendingCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) AS count FROM pending_inbound_transactions WHERE status IN ('pending', 'syncing', 'failed')",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<OfflineInboundDto>> getPending({int limit = 20}) async {
    final db = await _db.database;
    final rows = await db.query(
      'pending_inbound_transactions',
      where: "status IN ('pending', 'failed')",
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return rows.map(_fromRow).toList();
  }

  Future<List<OfflineInboundDto>> getAllNonSynced() async {
    final db = await _db.database;
    final rows = await db.query(
      'pending_inbound_transactions',
      where: "status IN ('pending', 'syncing', 'failed')",
      orderBy: 'created_at DESC',
    );

    return rows.map(_fromRow).toList();
  }

  Future<void> markSyncing(String clientInboundId) async {
    await _updateStatus(clientInboundId, 'syncing');
  }

  Future<void> markSynced(String clientInboundId) async {
    final db = await _db.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      'pending_inbound_transactions',
      {
        'status': 'synced',
        'error_message': null,
        'updated_at': now,
        'synced_at': now,
      },
      where: 'client_inbound_id = ?',
      whereArgs: [clientInboundId],
    );
  }

  Future<void> markFailed({
    required String clientInboundId,
    required String error,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      'pending_inbound_transactions',
      {
        'status': 'failed',
        'error_message': error,
        'updated_at': now,
      },
      where: 'client_inbound_id = ?',
      whereArgs: [clientInboundId],
    );
  }

  Future<void> resetStuckSyncing() async {
    final db = await _db.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.update(
      'pending_inbound_transactions',
      {
        'status': 'pending',
        'updated_at': now,
      },
      where: "status = 'syncing'",
    );
  }

  Future<void> clearAll() async {
    final db = await _db.database;
    await db.delete('pending_inbound_transactions');
  }

  Future<void> _updateStatus(String clientInboundId, String status) async {
    final db = await _db.database;
    await db.update(
      'pending_inbound_transactions',
      {
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      where: 'client_inbound_id = ?',
      whereArgs: [clientInboundId],
    );
  }

  OfflineInboundDto _fromRow(Map<String, Object?> row) {
    final payload = jsonDecode(row['payload_json'] as String) as Map<String, dynamic>;
    final rawItems = payload['items'] as List? ?? const [];

    return OfflineInboundDto(
      clientInboundId: row['client_inbound_id'].toString(),
      status: row['status']?.toString() ?? 'pending',
      errorMessage: row['error_message']?.toString(),
      createdAt: row['created_at']?.toString() ?? '',
      updatedAt: row['updated_at']?.toString() ?? '',
      request: CreateInboundRequestDto(
        shopId: payload['shop_id']?.toString() ?? '',
        reference: payload['reference']?.toString() ?? '',
        notes: payload['notes']?.toString(),
        vendorId: payload['vendor_id']?.toString() ?? '',
        items: rawItems
            .whereType<Map<String, dynamic>>()
            .map((item) => CreateInboundItemRequestDto(
          productId: item['product_id']?.toString() ?? '',
          quantity: item['quantity']?.toString() ?? '0',
          unitCost: item['unit_cost']?.toString(),
          expiryDate: item['expiry_date']?.toString(),
          batchNumber: item['batch_number']?.toString(),
        ))
            .toList(),
      ),
    );
  }
}
