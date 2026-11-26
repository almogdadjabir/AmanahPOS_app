import 'package:amana_pos/features/shifts/data/shift_store.dart';
import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
import 'package:amana_pos/features/shifts/domain/shift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/sync/support/test_db.dart';

BigInt c(String s) => Cents.parse(s)!;

Future<void> sale(
  Database db,
  String id,
  String at, {
  String shop = 's1',
  String status = 'completed',
  String sync = 'synced',
  String net = '100',
  String? method,
  List<(String, String)> payments = const [],
}) async {
  await db.insert('sales', {
    'id': id,
    'shop_id': shop,
    'status': status,
    'payment_method': method,
    'subtotal': net,
    'discount': '0',
    'tax_amount': '0',
    'net_amount': net,
    'occurred_at': at,
    'sync_state': sync,
  });
  var i = 0;
  for (final p in payments) {
    await db.insert('sale_payments', {
      'sale_id': id,
      'position': i++,
      'method': p.$1,
      'amount': p.$2,
    });
  }
}

Future<void> refund(
  Database db,
  String id,
  String at,
  String total,
  String method, {
  String state = 'synced',
}) => db.insert('sale_refunds', {
  'id': id,
  'sale_id': 'x',
  'shop_id': 's1',
  'total': total,
  'occurred_at': at,
  'method': method,
  'sync_state': state,
});

Future<void> shiftRow(
  Database db,
  String id,
  String opened, {
  String? closed,
  String opening = '500',
  String? counted,
  String? expected,
  String shop = 's1',
}) => db.insert('shifts', {
  'id': id,
  'shop_id': shop,
  'opened_at': opened,
  'closed_at': closed,
  'opening_cash': opening,
  'counted_cash': counted,
  'expected_cash': expected,
  'origin': 'manual',
  'sync_state': 'synced',
});

void main() {
  late Database db;
  late ShiftStore store;

  setUp(() async {
    final odb = await openTestDb();
    db = await odb.database;
    store = const ShiftStore();
  });
  tearDown(() => db.close());

  test('open and latest for a shop', () async {
    await shiftRow(db, 'a', '2026-01-01T08:00:00.000Z',
        closed: '2026-01-01T22:00:00.000Z', counted: '510', expected: '500');
    await shiftRow(db, 'b', '2026-01-02T08:00:00.000Z');
    await shiftRow(db, 'o', '2026-01-02T09:00:00.000Z', shop: 'other');
    expect((await store.open(db, 's1'))!.id, 'b');
    expect((await store.latest(db, 's1'))!.id, 'b');
    expect(await store.open(db, 'none'), isNull);
    final a = (await store.list(db, 's1')).last;
    expect(a.state, ShiftState.counted);
    expect(a.difference, c('10'));
  });

  test('closed without count needs a count', () async {
    await shiftRow(db, 'a', '2026-01-01T08:00:00.000Z',
        closed: '2026-01-01T22:00:00.000Z', expected: '500');
    expect(await store.countNeedingCount(db, 's1'), 1);
    expect((await store.byId(db, 'a'))!.state, ShiftState.needsCount);
  });

  test('carry over: last count, else last expected, else null', () async {
    expect(await store.carryOverCash(db, 's1'), isNull);
    await shiftRow(db, 'a', '2026-01-01T08:00:00.000Z',
        closed: '2026-01-01T22:00:00.000Z', expected: '480');
    expect(await store.carryOverCash(db, 's1'), c('480'));
    await shiftRow(db, 'b', '2026-01-02T08:00:00.000Z',
        closed: '2026-01-02T22:00:00.000Z', counted: '495', expected: '500');
    expect(await store.carryOverCash(db, 's1'), c('495'));
  });

  test('figures: cash from payments, legacy method, other methods, refunds',
      () async {
    await shiftRow(db, 'a', '2026-01-02T08:00:00.000Z');
    // inside
    await sale(db, 's-cash', '2026-01-02T09:00:00.000Z',
        net: '100', payments: [('cash', '100')]);
    await sale(db, 's-legacy', '2026-01-02T09:10:00.000Z',
        net: '40', method: 'cash');
    await sale(db, 's-split', '2026-01-02T09:20:00.000Z',
        net: '90', payments: [('cash', '30'), ('card', '60')]);
    await sale(db, 's-bank', '2026-01-02T09:30:00.000Z',
        net: '25', payments: [('bankak', '25')]);
    await sale(db, 's-credit', '2026-01-02T09:40:00.000Z',
        net: '70', payments: [('credit', '70')]);
    // excluded
    await sale(db, 's-cancel', '2026-01-02T09:50:00.000Z',
        net: '999', status: 'cancelled', payments: [('cash', '999')]);
    await sale(db, 's-rej', '2026-01-02T09:55:00.000Z',
        net: '888', sync: 'rejected', payments: [('cash', '888')]);
    await sale(db, 's-before', '2026-01-02T07:59:59.000Z',
        net: '777', payments: [('cash', '777')]);
    await sale(db, 's-shop', '2026-01-02T10:00:00.000Z',
        net: '666', shop: 'other', payments: [('cash', '666')]);
    await refund(db, 'r1', '2026-01-02T11:00:00.000Z', '20', 'cash');
    await refund(db, 'r2', '2026-01-02T11:05:00.000Z', '15', 'card');
    await refund(db, 'r3', '2026-01-02T11:10:00.000Z', '50', 'cash',
        state: 'rejected');
    await db.insert('cash_movements', {
      'id': 'm1', 'shift_id': 'a', 'kind': 'pay_in', 'amount': '50',
      'reason': 'float', 'occurred_at': '2026-01-02T12:00:00.000Z',
    });
    await db.insert('cash_movements', {
      'id': 'm2', 'shift_id': 'a', 'kind': 'pay_out', 'amount': '125',
      'reason': 'supplier', 'occurred_at': '2026-01-02T12:30:00.000Z',
    });

    final f = await store.figures(db, (await store.byId(db, 'a'))!,
        now: DateTime.utc(2026, 1, 2, 13));
    expect(f.parts.opening, c('500'));
    expect(f.parts.cashSales, c('170')); // 100 + 40 + 30
    expect(f.parts.refunds, c('20'));
    expect(f.parts.payIns, c('50'));
    expect(f.parts.payOuts, c('125'));
    expect(f.parts.debtPayments, BigInt.zero);
    expect(f.expected, c('575')); // 500+170+50-20-125
    final other = {for (final o in f.other) o.method: o.amount};
    expect(other, {'card': c('60'), 'bankak': c('25')});
    expect(f.salesCount, 5);
    expect(f.salesTotal, c('325')); // 100+40+90+25+70
  });

  test('a closed shift ends at its close time (half open)', () async {
    await shiftRow(db, 'a', '2026-01-02T08:00:00.000Z',
        closed: '2026-01-02T10:00:00.000Z');
    await sale(db, 'in', '2026-01-02T09:59:59.500Z',
        net: '10', payments: [('cash', '10')]);
    await sale(db, 'out', '2026-01-02T10:00:00.000Z',
        net: '20', payments: [('cash', '20')]);
    final f = await store.figures(db, (await store.byId(db, 'a'))!);
    expect(f.parts.cashSales, c('10'));
  });

  test('movements are listed in time order', () async {
    await shiftRow(db, 'a', '2026-01-02T08:00:00.000Z');
    await db.insert('cash_movements', {
      'id': 'm2', 'shift_id': 'a', 'kind': 'pay_out', 'amount': '5',
      'reason': 'b', 'occurred_at': '2026-01-02T12:30:00.000Z',
    });
    await db.insert('cash_movements', {
      'id': 'm1', 'shift_id': 'a', 'kind': 'pay_in', 'amount': '7',
      'reason': 'a', 'occurred_at': '2026-01-02T12:00:00.000Z',
    });
    final m = await store.movements(db, 'a');
    expect(m.map((e) => e.id), ['m1', 'm2']);
    expect(m.first.kind, CashMovementKind.payIn);
    expect(m.first.amount, c('7'));
  });
}
