import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/appliers/debt_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/sync_appliers.dart';
import 'package:amana_pos/features/pos/domain/sale.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/shifts/data/shift_store.dart';
import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

OutboxEntry sent(String op, String id) => OutboxEntry(
  mutationId: 'm',
  entity: 'debt',
  op: op,
  entityId: id,
  occurredAt: DateTime.utc(2026),
  payload: const {},
);

PushResult res(PushStatus s, {String? code}) =>
    PushResult(mutationId: 'm', status: s, code: code);

void main() {
  test('fresh db is v16 with debt_entries', () async {
    expect(OfflineDb.schemaVersion, greaterThanOrEqualTo(16));
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    final cols = (await db.rawQuery('PRAGMA table_info(debt_entries)'))
        .map((r) => r['name'])
        .toList();
    expect(
      cols,
      containsAll([
        'id', 'customer_id', 'shop_id', 'kind', 'amount', 'method', 'note',
        'occurred_at', 'user_id', 'user_name', 'sync_state',
      ]),
    );
    await OfflineDb.createV16Schema(db); // idempotent
  });

  test('applier is registered and push results set sync_state', () async {
    expect(buildSyncAppliers().of('debt'), isA<DebtApplier>());
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    for (final id in ['a', 'b']) {
      await db.insert('debt_entries', {
        'id': id, 'customer_id': 'c', 'kind': 'payment', 'amount': '1.00',
        'occurred_at': '2026-01-01T00:00:00Z',
      });
    }
    final ap = DebtApplier.debt();
    await db.transaction((t) async {
      await ap.onPushResult(t, sent('payment', 'a'), res(PushStatus.applied));
      await ap.onPushResult(
        t, sent('writeoff', 'b'), res(PushStatus.rejected, code: 'forbidden'));
    });
    final a = (await db.query('debt_entries', where: "id='a'")).single;
    final b = (await db.query('debt_entries', where: "id='b'")).single;
    expect(a['sync_state'], 'synced');
    expect(b['sync_state'], 'rejected');
    expect(b['error_code'], 'forbidden');
  });

  group('sale on account', () {
    late SaleFixture f;
    late SaleService service;
    setUp(() async {
      f = await SaleFixture.on(await openTestDb());
      service = f.service();
    });
    tearDown(() async {
      f.notifier.dispose();
      await f.db.close();
    });

    SaleDraft draft({String method = 'credit', String? customer, List<SalePaymentPart>? payments}) =>
        SaleDraft(
          shopId: kShop,
          customerId: customer,
          paymentMethod: method,
          payments: payments,
          lines: const [
            SaleDraftLine.product(
              productId: kP1, productName: 'Tea', quantity: '1', unitPrice: '10.00',
            ),
          ],
        );

    test('credit without a customer is refused and nothing is written', () async {
      await expectLater(
        service.createSale(draft()),
        throwsA(isA<SaleValidationException>()),
      );
      expect(await f.count('sales'), 0);
      expect(await f.count('outbox'), 0);
    });

    test('a credit part of a split also needs a customer', () async {
      await expectLater(
        service.createSale(draft(method: 'split', payments: const [
          SalePaymentPart(method: 'cash', amount: '4.00'),
          SalePaymentPart(method: 'credit', amount: '6.00'),
        ])),
        throwsA(isA<SaleValidationException>()),
      );
    });

    test('credit with a customer is saved with its customer', () async {
      final s = await service.createSale(draft(customer: 'c1'));
      expect(s.customerId, 'c1');
      expect((await f.db.query('sale_payments')).single['method'], 'credit');
    });
  });

  test('cash debt payments land in the shift drawer figures', () async {
    final odb = await openTestDb();
    final db = await odb.database;
    addTearDown(db.close);
    await db.insert('shifts', {
      'id': 'sh', 'shop_id': 's1', 'opened_at': '2026-01-01T08:00:00.000Z',
      'closed_at': '2026-01-01T20:00:00.000Z', 'opening_cash': '100',
      'origin': 'manual', 'sync_state': 'synced',
    });
    Future<void> debt(String id, String at, String method, String amt, {String shop = 's1'}) =>
        db.insert('debt_entries', {
          'id': id, 'customer_id': 'c', 'shop_id': shop, 'kind': 'payment',
          'amount': amt, 'method': method, 'occurred_at': at,
        });
    await debt('d1', '2026-01-01T10:00:00.000Z', 'cash', '30.00');
    await debt('d2', '2026-01-01T11:00:00.000Z', 'bankak', '99.00');
    await debt('d3', '2026-01-02T10:00:00.000Z', 'cash', '7.00');
    await debt('d4', '2026-01-01T12:00:00.000Z', 'cash', '5.00', shop: 'other');
    const store = ShiftStore();
    final fig = await store.figures(db, (await store.byId(db, 'sh'))!);
    expect(fig.parts.debtPayments, Cents.parse('30')!);
    expect(CashExpectation.expected(fig.parts), Cents.parse('130')!);
  });
}
