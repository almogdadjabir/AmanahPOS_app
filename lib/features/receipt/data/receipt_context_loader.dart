import 'dart:convert';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/appliers/applier_support.dart'
    show localUserName;
import 'package:amana_pos/features/receipt/domain/receipt_doc.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';

/// Business, settings and names a receipt needs beyond the sale itself.
class ReceiptContext {
  final ReceiptBusiness business;
  final ReceiptSettings settings;
  final String? cashierName;
  final String? customerName;

  /// What the customer owes now. Null when it cannot be known on this device.
  final double? customerOwes;

  const ReceiptContext({
    required this.business,
    required this.settings,
    this.cashierName,
    this.customerName,
    this.customerOwes,
  });
}

/// Reads the receipt's business row, receipt settings, cashier and customer
/// from the local database (offline first: nothing here touches the network).
class ReceiptContextLoader {
  ReceiptContextLoader(this._db);

  final OfflineDb _db;

  Future<ReceiptContext> load(SaleHistoryItem sale) async {
    final db = await _db.database;
    final feed = await _json(
      db.query(
        'synced_entities',
        columns: ['json'],
        where: 'entity = ?',
        whereArgs: ['business'],
        limit: 1,
      ),
    );
    final legacy = feed.isEmpty
        ? await _json(db.query('businesses', columns: ['json'], limit: 1))
        : const <String, dynamic>{};
    final row = feed.isNotEmpty ? feed : legacy;

    final paper = row['receipt_paper_width'];
    final footer = (row['receipt_footer'] as String? ?? '').trim();
    final settings = ReceiptSettings(
      paperMm: ReceiptSettings.normalizePaper(
        paper is num ? paper.toInt() : int.tryParse('$paper') ?? 80,
      ),
      showLogo: row['receipt_show_logo'] != false,
      footer: footer.length > ReceiptSettings.footerMaxLength
          ? footer.substring(0, ReceiptSettings.footerMaxLength)
          : footer,
    );

    final business = ReceiptBusiness(
      name: (row['name'] as String? ?? '').trim(),
      phone: (row['phone'] as String? ?? '').trim(),
      currency: (row['currency'] as String? ?? '').trim(),
      timezone: row['timezone'] as String?,
    );

    final saleRow = await db.query(
      'sales',
      columns: ['cashier_id', 'customer_id'],
      where: 'id = ?',
      whereArgs: [sale.id],
      limit: 1,
    );
    final cashierId = saleRow.isEmpty
        ? null
        : saleRow.first['cashier_id'] as String?;
    final customerId = saleRow.isEmpty
        ? sale.customerId
        : saleRow.first['customer_id'] as String?;

    String? customerName;
    if (customerId != null && customerId.isNotEmpty) {
      final c = await db.query(
        'customers',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [customerId],
        limit: 1,
      );
      customerName = c.isEmpty ? null : c.first['name'] as String?;
    }

    return ReceiptContext(
      business: business,
      settings: settings,
      cashierName: await localUserName(db, cashierId),
      customerName: customerName,
    );
  }

  Future<Map<String, dynamic>> _json(
    Future<List<Map<String, Object?>>> query,
  ) async {
    final rows = await query;
    if (rows.isEmpty) return const {};
    final raw = rows.first['json'];
    if (raw is! String) return const {};
    try {
      final d = jsonDecode(raw);
      return d is Map<String, dynamic> ? d : const {};
    } on FormatException {
      return const {};
    }
  }
}
