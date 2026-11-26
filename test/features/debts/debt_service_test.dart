import 'dart:convert';

import 'package:amana_pos/core/features/business_features.dart';
import 'package:amana_pos/features/debts/data/debt_store.dart';
import 'package:amana_pos/features/debts/domain/debt.dart';
import 'package:amana_pos/features/debts/domain/debt_service.dart';
import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

BigInt c(String s) => Cents.parse(s)!;

const owner = DebtActor(id: kCashier, name: 'Sara', canManage: true);
const cashier = DebtActor(id: kP1, name: 'Omar', canManage: false);

Future<void> sale(
  Database db,
  String id,
  String at, {
  String customer = 'c1',
  String status = 'completed',
  String sync = 'synced',
  String net = '100',
  String? method,
  List<(String, String)> payments = const [],
}) async {
  await db.insert('sales', {
    'id': id,
    'shop_id': kShop,
    'customer_id': customer,
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

void main() {
  late SaleFixture f;
  late BusinessFeatures features;
  DebtActor? actor;
  late DebtService svc;
  const store = DebtStore();

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    features = const BusinessFeatures(onAccount: true);
    actor = owner;
    svc = DebtService(
      writer: f.writer,
      features: () => features,
      actor: () => actor,
      shopId: () => kShop,
      now: () => f.clock,
    );
    await f.db.insert('customers', {
      'id': 'c1',
      'name': 'Sara Ali',
      'json': '{}',
    });
    await sale(f.db, 's1', '2020-01-01T10:00:00.000Z', net: '1500', payments: [('credit', '1500')]);
  });
  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  DebtError? err(DebtResult r) => r is DebtFailed ? r.error : null;

  group('balance', () {
    test('credit parts add, payments and write-offs take', () async {
      expect(await store.balance(f.db, 'c1'), c('1500'));
      await svc.receivePayment(customerId: 'c1', amount: c('300'), method: 'cash');
      await svc.writeOff(customerId: 'c1', amount: c('200'));
      expect(await store.balance(f.db, 'c1'), c('1000'));
    });

    test('only the credit part of a split counts', () async {
      await sale(f.db, 's2', '2026-11-21T10:00:00.000Z',
          net: '500', payments: [('cash', '200'), ('credit', '300')]);
      expect(await store.balance(f.db, 'c1'), c('1800'));
    });

    test('an old single credit sale without parts counts its net', () async {
      await sale(f.db, 's3', '2026-11-21T10:00:00.000Z', net: '70', method: 'credit');
      expect(await store.balance(f.db, 'c1'), c('1570'));
    });

    test('cancelled and rejected sales do not count', () async {
      await sale(f.db, 's4', '2026-11-21T10:00:00.000Z',
          net: '50', status: 'cancelled', payments: [('credit', '50')]);
      await sale(f.db, 's5', '2026-11-21T11:00:00.000Z',
          net: '60', sync: 'rejected', payments: [('credit', '60')]);
      expect(await store.balance(f.db, 'c1'), c('1500'));
    });

    test('other customers are separate', () async {
      await sale(f.db, 's6', '2026-11-21T10:00:00.000Z',
          customer: 'c2', net: '80', payments: [('credit', '80')]);
      expect(await store.balance(f.db, 'c1'), c('1500'));
      expect(await store.balance(f.db, 'c2'), c('80'));
    });
  });

  group('receivePayment', () {
    test('writes the row and one debt.payment outbox row', () async {
      final r = await svc.receivePayment(
        customerId: 'c1',
        amount: c('1200'),
        method: 'cash',
      );
      expect((r as DebtDone).balanceAfter, c('300'));
      final row = (await f.db.query('debt_entries')).single;
      expect(row['kind'], 'payment');
      expect(row['amount'], '1200.00');
      expect(row['method'], 'cash');
      expect(row['shop_id'], kShop);
      expect(row['sync_state'], 'pending');
      final o = (await f.db.query('outbox')).single;
      expect(o['entity'], 'debt');
      expect(o['op'], 'payment');
      expect(o['entity_id'], row['id']);
      final p = jsonDecode(o['payload_json'] as String) as Map<String, dynamic>;
      expect(p['customer'], 'c1');
      expect(p['amount'], '1200.00');
      expect(p['method'], 'cash');
      expect(p.containsKey('occurred_at'), isTrue);
    });

    test('never above the balance, never zero, nothing queued on refusal', () async {
      expect(err(await svc.receivePayment(customerId: 'c1', amount: c('1500.01'), method: 'cash')),
          DebtError.exceedsBalance);
      expect(err(await svc.receivePayment(customerId: 'c1', amount: BigInt.zero, method: 'cash')),
          DebtError.amountInvalid);
      expect(err(await svc.receivePayment(customerId: 'c1', amount: c('1'), method: 'card')),
          DebtError.methodInvalid);
      expect(await f.db.query('outbox'), isEmpty);
      expect(await f.db.query('debt_entries'), isEmpty);
    });

    test('a customer who owes nothing', () async {
      expect(err(await svc.receivePayment(customerId: 'c9', amount: c('1'), method: 'cash')),
          DebtError.nothingOwed);
    });

    test('paying the whole debt leaves zero and a second payment is refused', () async {
      await svc.receivePayment(customerId: 'c1', amount: c('1500'), method: 'bankak');
      expect(await store.balance(f.db, 'c1'), BigInt.zero);
      expect(err(await svc.receivePayment(customerId: 'c1', amount: c('1'), method: 'cash')),
          DebtError.nothingOwed);
    });

    test('switched off', () async {
      features = const BusinessFeatures(onAccount: false);
      expect(err(await svc.receivePayment(customerId: 'c1', amount: c('1'), method: 'cash')),
          DebtError.disabled);
    });

    test('no session', () async {
      actor = null;
      expect(err(await svc.receivePayment(customerId: 'c1', amount: c('1'), method: 'cash')),
          DebtError.noSession);
    });
  });

  group('writeOff', () {
    test('queues debt.writeoff with the note and no method', () async {
      await svc.writeOff(customerId: 'c1', amount: c('500'), note: ' bad debt ');
      final o = (await f.db.query('outbox')).single;
      expect(o['op'], 'writeoff');
      final p = jsonDecode(o['payload_json'] as String) as Map<String, dynamic>;
      expect(p['note'], 'bad debt');
      expect(p.containsKey('method'), isFalse);
    });

    test('a cashier cannot', () async {
      actor = cashier;
      expect(err(await svc.writeOff(customerId: 'c1', amount: c('5'))), DebtError.notAllowed);
      expect(await f.db.query('outbox'), isEmpty);
    });

    test('a cashier can still receive a payment', () async {
      actor = cashier;
      expect(await svc.receivePayment(customerId: 'c1', amount: c('5'), method: 'cash'), isA<DebtDone>());
    });
  });

  group('ledger and debtors', () {
    test('ledger is newest first and marks rejected rows', () async {
      await svc.receivePayment(customerId: 'c1', amount: c('100'), method: 'cash');
      await f.db.update('debt_entries', {'sync_state': 'rejected'});
      final l = await store.ledger(f.db, 'c1');
      expect(l.first.kind, DebtLedgerKind.payment);
      expect(l.first.rejected, isTrue);
      expect(l.last.kind, DebtLedgerKind.sale);
      expect(await store.balance(f.db, 'c1'), c('1500'));
    });

    test('debtors are those who owe, biggest first', () async {
      await sale(f.db, 's7', '2026-11-22T10:00:00.000Z',
          customer: 'c2', net: '2000', payments: [('credit', '2000')]);
      await f.db.insert('customers', {'id': 'c2', 'name': 'Khalid', 'json': '{}'});
      await sale(f.db, 's8', '2026-11-22T10:00:00.000Z',
          customer: 'c3', net: '10', payments: [('credit', '10')]);
      await f.db.insert('debt_entries', {
        'id': 'd9', 'customer_id': 'c3', 'kind': 'payment', 'amount': '10.00',
        'method': 'cash', 'occurred_at': '2026-11-23T10:00:00.000Z',
      });
      final d = await store.debtors(f.db);
      expect([for (final x in d) x.name], ['Khalid', 'Sara Ali']);
      expect(d.first.balance, c('2000'));
    });

    test('cash payments feed a shift range, bankak and other shops do not', () async {
      await svc.receivePayment(customerId: 'c1', amount: c('100'), method: 'cash');
      await svc.receivePayment(customerId: 'c1', amount: c('50'), method: 'bankak');
      final at = f.clock.toUtc().toIso8601String().substring(0, 19);
      final got = await store.cashPaymentsIn(f.db,
          shopId: kShop, from: '2000-01-01T00:00:00', to: '2100-01-01T00:00:00');
      expect(got, c('100'));
      expect(at, isNotEmpty);
      expect(await store.cashPaymentsIn(f.db,
          shopId: 'other', from: '2000-01-01T00:00:00', to: '2100-01-01T00:00:00'), BigInt.zero);
    });
  });
}
