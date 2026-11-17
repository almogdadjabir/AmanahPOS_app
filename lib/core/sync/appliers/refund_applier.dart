import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../change_applier.dart';
import '../contract/sync_contract.dart';
import '../outbox/outbox_entry.dart';
import 'applier_support.dart';

/// Server refunds (apps/sync/feed.py `ser_refund`) -> `sale_refunds`, the
/// table the local dashboard nets refunds from.
///
/// `occurred_at` (the dashboard's date column) = the refund's BE
/// `created_at` as UTC ISO: the BE windows refunds on `created_at` (always
/// set; equals the device `occurred_at` unless that was > 7 days ahead).
/// The raw feed row, incl. its own `occurred_at`, stays in `json`.
///
/// `ser_refund` carries no `version` and BE refunds are immutable, so a row
/// is simply replaced (idempotent replay). The sale's status is NEVER
/// touched here: the pulled sale row carries it.
class RefundApplier implements ChangeApplier {
  static const String table = 'sale_refunds';

  @override
  String get entity => 'refund';

  @override
  bool get skipWhenLocalPending => true;

  @override
  Set<String> get tables => const {table};

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) async => null;

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    final id = change.id;
    if (id.isEmpty) return logSkip(entity, id, 'empty id');
    if (change.op == 'delete') {
      await txn.delete(table, where: 'id = ?', whereArgs: [id]);
      return;
    }
    final d = change.data;
    if (d == null) return logSkip(entity, id, 'no data');
    final sale = d['sale'];
    final shop = d['shop'] ?? change.shopId;
    final total = d['total'];
    if (sale is! String || sale.isEmpty) {
      return logSkip(entity, id, 'no sale');
    }
    if (shop is! String || shop.isEmpty) {
      return logSkip(entity, id, 'no shop');
    }
    if (total is! String || !decimalOk(total)) {
      return logSkip(entity, id, 'bad total');
    }
    final when = _utcIso(d['created_at']) ?? _utcIso(d['occurred_at']);
    if (when == null) return logSkip(entity, id, 'no date');
    final method = d['method'];
    final reference = d['reference'];
    if (reference is String && reference.isNotEmpty) {
      // The local twin of a refund made on THIS device (same client
      // `reference`, different local id): the server row replaces it, so the
      // refund counts once.
      await txn.delete(
        table,
        where:
            "sale_id = ? AND reference = ? AND id != ? "
            "AND sync_state != 'rejected'",
        whereArgs: [sale, reference, id],
      );
    }
    await txn.insert(table, {
      'id': id,
      'sale_id': sale,
      'shop_id': shop,
      'total': total,
      'occurred_at': when,
      'method': method is String ? method : null,
      'reference': reference is String ? reference : null,
      'sync_state': 'synced',
      'json': jsonEncode({...d, 'id': id}),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {}

  static String? _utcIso(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toUtc().toIso8601String() : null;
}
