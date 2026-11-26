import 'package:amana_pos/features/debts/data/debt_store.dart';
import 'package:amana_pos/core/time/business_day.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/cash_expectation.dart';
import '../domain/shift.dart';

/// Read side of shifts and the row mapping. Money for a shift is worked out
/// from local sales, payments, refunds and pay-in/out rows over the shift's
/// time range `[opened_at, closed_at)` (or up to now while open), exactly
/// like desktop. Every method takes the executor so a writer can read inside
/// its own transaction.
class ShiftStore {
  const ShiftStore();

  static ShiftInfo fromRow(Map<String, Object?> r) => ShiftInfo(
    id: r['id'] as String,
    shopId: r['shop_id'] as String,
    openedAt: DateTime.parse(r['opened_at'] as String).toUtc(),
    openedByName: r['opened_by_name'] as String?,
    origin: ShiftOrigin.parse(r['origin']),
    openingCash: Cents.parse('${r['opening_cash'] ?? '0'}') ?? BigInt.zero,
    closedAt: r['closed_at'] == null
        ? null
        : DateTime.parse(r['closed_at'] as String).toUtc(),
    closedByName: r['closed_by_name'] as String?,
    counted: r['counted_cash'] == null
        ? null
        : Cents.parse('${r['counted_cash']}'),
    expected: r['expected_cash'] == null
        ? null
        : Cents.parse('${r['expected_cash']}'),
    note: r['note'] as String?,
    syncState: (r['sync_state'] as String?) ?? 'pending',
  );

  Future<ShiftInfo?> open(DatabaseExecutor db, String shopId) async {
    final r = await db.query(
      'shifts',
      where: 'shop_id = ? AND closed_at IS NULL AND sync_state != ?',
      whereArgs: [shopId, 'rejected'],
      orderBy: 'opened_at DESC',
      limit: 1,
    );
    return r.isEmpty ? null : fromRow(r.first);
  }

  /// The most recently opened shift in any state.
  Future<ShiftInfo?> latest(DatabaseExecutor db, String shopId) async {
    final r = await db.query(
      'shifts',
      where: 'shop_id = ? AND sync_state != ?',
      whereArgs: [shopId, 'rejected'],
      orderBy: 'opened_at DESC',
      limit: 1,
    );
    return r.isEmpty ? null : fromRow(r.first);
  }

  Future<ShiftInfo?> byId(DatabaseExecutor db, String id) async {
    final r = await db.query('shifts', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : fromRow(r.first);
  }

  /// What the next shift starts with: the last closed shift's count, or its
  /// expected cash when it was never counted.
  Future<BigInt?> carryOverCash(DatabaseExecutor db, String shopId) async {
    final r = await db.query(
      'shifts',
      where: 'shop_id = ? AND closed_at IS NOT NULL AND sync_state != ?',
      whereArgs: [shopId, 'rejected'],
      orderBy: 'opened_at DESC',
      limit: 1,
    );
    if (r.isEmpty) return null;
    final s = fromRow(r.first);
    return s.counted ?? s.expected;
  }

  /// Newest first. [beforeOpenedAt] pages: pass the last row's `openedAt`.
  Future<List<ShiftInfo>> list(
    DatabaseExecutor db,
    String shopId, {
    int limit = 30,
    DateTime? beforeOpenedAt,
  }) async {
    final r = await db.query(
      'shifts',
      where: beforeOpenedAt == null
          ? 'shop_id = ? AND sync_state != ?'
          : 'shop_id = ? AND sync_state != ? AND opened_at < ?',
      whereArgs: [
        shopId,
        'rejected',
        if (beforeOpenedAt != null) beforeOpenedAt.toUtc().toIso8601String(),
      ],
      orderBy: 'opened_at DESC',
      limit: limit,
    );
    return [for (final x in r) fromRow(x)];
  }

  Future<int> countNeedingCount(DatabaseExecutor db, String shopId) async {
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM shifts WHERE shop_id = ? '
      'AND closed_at IS NOT NULL AND counted_cash IS NULL '
      "AND sync_state != 'rejected'",
      [shopId],
    );
    return (r.first['n'] as int?) ?? 0;
  }

  Future<List<CashMovementInfo>> movements(
    DatabaseExecutor db,
    String shiftId,
  ) async {
    final r = await db.query(
      'cash_movements',
      where: "shift_id = ? AND sync_state != 'rejected'",
      whereArgs: [shiftId],
      orderBy: 'occurred_at ASC',
    );
    return [
      for (final m in r)
        CashMovementInfo(
          id: m['id'] as String,
          shiftId: shiftId,
          kind: m['kind'] == 'pay_in'
              ? CashMovementKind.payIn
              : CashMovementKind.payOut,
          amount: Cents.parse('${m['amount']}') ?? BigInt.zero,
          reason: (m['reason'] as String?) ?? '',
          userName: m['user_name'] as String?,
          at: DateTime.parse(m['occurred_at'] as String).toUtc(),
        ),
    ];
  }

  /// Figures of one shift. [now] is the end of an open shift's range.
  Future<ShiftFigures> figures(
    DatabaseExecutor db,
    ShiftInfo shift, {
    DateTime? now,
  }) async {
    final from = BusinessDay.utcText(shift.openedAt);
    final to = BusinessDay.utcText(
      (shift.closedAt ?? now ?? DateTime.now()).toUtc(),
    );
    // Second-precision bounds: see BusinessDay.utcTextRange.
    const live = "status != 'cancelled' AND sync_state != 'rejected'";
    final sales = await db.rawQuery(
      'SELECT id, payment_method, net_amount FROM sales '
      'WHERE shop_id = ? AND occurred_at >= ? AND occurred_at < ? AND $live',
      [shift.shopId, from, to],
    );
    final payRows = await db.rawQuery(
      'SELECT p.sale_id, p.method, p.amount FROM sale_payments p '
      'JOIN sales s ON s.id = p.sale_id '
      'WHERE s.shop_id = ? AND s.occurred_at >= ? AND s.occurred_at < ? '
      "AND s.status != 'cancelled' AND s.sync_state != 'rejected' "
      'ORDER BY p.sale_id, p.position',
      [shift.shopId, from, to],
    );
    final bySale = <String, List<Map<String, Object?>>>{};
    for (final p in payRows) {
      (bySale[p['sale_id'] as String] ??= []).add(p);
    }
    var cash = BigInt.zero;
    var total = BigInt.zero;
    final other = <String, BigInt>{};
    for (final s in sales) {
      total += Cents.parse('${s['net_amount']}') ?? BigInt.zero;
      final parts = bySale[s['id'] as String];
      if (parts == null || parts.isEmpty) {
        // Legacy / single-method sale without payment rows.
        final m = s['payment_method'] as String?;
        final amt = Cents.parse('${s['net_amount']}') ?? BigInt.zero;
        if (m == 'cash') {
          cash += amt;
        } else if (m != null && m.isNotEmpty && m != 'credit') {
          other[m] = (other[m] ?? BigInt.zero) + amt;
        }
        continue;
      }
      for (final p in parts) {
        final m = p['method'] as String;
        final amt = Cents.parse('${p['amount']}') ?? BigInt.zero;
        if (m == 'cash') {
          cash += amt;
        } else if (m != 'credit') {
          other[m] = (other[m] ?? BigInt.zero) + amt;
        }
      }
    }
    final refundRows = await db.rawQuery(
      'SELECT total FROM sale_refunds WHERE shop_id = ? '
      "AND method = 'cash' AND COALESCE(sync_state, 'synced') != 'rejected' "
      'AND occurred_at >= ? AND occurred_at < ?',
      [shift.shopId, from, to],
    );
    var refunds = BigInt.zero;
    for (final r in refundRows) {
      refunds += Cents.parse('${r['total']}') ?? BigInt.zero;
    }
    final debtCash = await const DebtStore().cashPaymentsIn(
      db,
      shopId: shift.shopId,
      from: from,
      to: to,
    );
    var payIns = BigInt.zero;
    var payOuts = BigInt.zero;
    for (final m in await movements(db, shift.id)) {
      if (m.kind == CashMovementKind.payIn) {
        payIns += m.amount;
      } else {
        payOuts += m.amount;
      }
    }
    final names = other.keys.toList()..sort();
    return ShiftFigures(
      parts: CashParts(
        opening: shift.openingCash,
        cashSales: cash,
        debtPayments: debtCash,
        payIns: payIns,
        refunds: refunds,
        cancels: BigInt.zero,
        payOuts: payOuts,
      ),
      other: [for (final n in names) OtherTaking(n, other[n]!)],
      salesCount: sales.length,
      salesTotal: total,
    );
  }
}
