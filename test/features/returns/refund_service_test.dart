import 'dart:convert';

import 'package:amana_pos/core/sync/appliers/sale_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/features/pos/data/local/sale_local_store.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/returns/domain/refund_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/sale_applier_test.dart' show feedSale;
import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

const _sale = '55555555-5555-4555-8555-555555555555';
const _item = '66666666-6666-4666-8666-666666666666';

void main() {
  late SaleFixture f;
  late RefundService svc;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    svc = RefundService(writer: f.writer, now: () => f.clock);
    // A synced sale of 3 x 2.50 = 7.50, line id _item.
    await f.db.transaction(
      (t) => SaleApplier().apply(
        t,
        PullChange(
          seq: 1,
          entity: 'sale',
          op: 'upsert',
          id: _sale,
          version: 1,
          data: feedSale(),
          shopId: kShop,
        ),
      ),
    );
  });
  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  Future<List<Map<String, Object?>>> refunds() => f.db.query('sale_refunds');
  Future<Map<String, Object?>> saleRow() async =>
      (await f.db.query('sales', where: 'id = ?', whereArgs: [_sale])).single;

  test(
    'refund writes pending row, outbox sale.refund and status in one write',
    () async {
      final ref = await svc.refund(
        saleId: _sale,
        quantitiesByLineId: {_item: '1'},
        method: 'cash',
        reason: 'damaged',
      );
      final r = (await refunds()).single;
      expect(r['sync_state'], 'pending');
      expect(r['reference'], ref);
      expect(r['total'], '2.50');
      expect(await saleRow().then((s) => s['status']), 'partial_refund');
      final o = (await f.db.query('outbox')).single;
      expect(o['entity'], 'sale');
      expect(o['op'], 'refund');
      final p = jsonDecode(o['payload_json'] as String) as Map;
      expect(p['reference'], ref);
      expect(p['method'], 'cash');
      expect(p['reason'], 'damaged');
      expect(p['items'], [
        {'sale_item_id': _item, 'quantity': '1'},
      ]);
      expect(p.containsKey('occurred_at'), isTrue);
    },
  );

  test('full return makes the sale refunded', () async {
    await svc.refund(
      saleId: _sale,
      quantitiesByLineId: {_item: '3'},
      method: 'cash',
    );
    expect((await saleRow())['status'], 'refunded');
  });

  test('refund rejects quantity above sold minus already refunded', () async {
    await svc.refund(
      saleId: _sale,
      quantitiesByLineId: {_item: '2'},
      method: 'cash',
    );
    await expectLater(
      svc.refund(
        saleId: _sale,
        quantitiesByLineId: {_item: '1.5'},
        method: 'cash',
      ),
      throwsA(isA<RefundValidationException>()),
    );
    expect(await refunds(), hasLength(1));
    expect(await f.db.query('outbox'), hasLength(1));
  });

  test('two queued refunds of the same line cannot exceed sold', () async {
    await svc.refund(
      saleId: _sale,
      quantitiesByLineId: {_item: '2'},
      method: 'cash',
    );
    await svc.refund(
      saleId: _sale,
      quantitiesByLineId: {_item: '1'},
      method: 'cash',
    );
    await expectLater(
      svc.refund(
        saleId: _sale,
        quantitiesByLineId: {_item: '0.001'},
        method: 'cash',
      ),
      throwsA(isA<RefundValidationException>()),
    );
  });

  test('rejected (voided) refund does not count against the line', () async {
    await svc.refund(
      saleId: _sale,
      quantitiesByLineId: {_item: '3'},
      method: 'cash',
    );
    await f.db.update('sale_refunds', {'sync_state': 'rejected'});
    final q = await const SaleLocalStore().refundedQuantities(f.db, _sale);
    expect(q, isEmpty);
  });

  test(
    'refund of an unsent sale is queued behind the sale create (same entity)',
    () async {
      final sale = await f.service().createSale(
        const SaleDraft(
          shopId: kShop,
          paymentMethod: 'cash',
          lines: [
            SaleDraftLine.product(
              productId: kP1,
              productName: 'Tea',
              quantity: '3',
              unitPrice: '2.50',
            ),
          ],
        ),
      );
      final line = (await f.db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [sale.id],
      )).first;
      await svc.refund(
        saleId: sale.id,
        quantitiesByLineId: {line['id'] as String: '1'},
        method: 'cash',
      );
      final rows = await f.db.query('outbox', orderBy: 'seq');
      expect(rows.map((r) => r['op']), ['create', 'refund']);
      expect(rows.map((r) => r['entity_id']), [sale.id, sale.id]);
    },
  );

  test('rolls back everything when the sale is unknown', () async {
    await expectLater(
      svc.refund(
        saleId: 'nope',
        quantitiesByLineId: {_item: '1'},
        method: 'cash',
      ),
      throwsA(isA<RefundValidationException>()),
    );
    expect(await refunds(), isEmpty);
    expect(await f.db.query('outbox'), isEmpty);
  });

  test('cancelled sale cannot be refunded', () async {
    await f.db.update('sales', {'status': 'cancelled'});
    await expectLater(
      svc.refund(
        saleId: _sale,
        quantitiesByLineId: {_item: '1'},
        method: 'cash',
      ),
      throwsA(isA<RefundValidationException>()),
    );
  });

  test(
    'successive partial refunds of one line sum exactly to its line total',
    () async {
      await f.db.update('sale_items', {'quantity': '2', 'line_total': '0.05'});
      await svc.refund(
        saleId: _sale,
        quantitiesByLineId: {_item: '1'},
        method: 'cash',
      );
      await svc.refund(
        saleId: _sale,
        quantitiesByLineId: {_item: '1'},
        method: 'cash',
      );
      final totals = [for (final r in await refunds()) '${r['total']}'];
      final sum = totals
          .map((t) => (double.parse(t) * 100).round())
          .reduce((a, b) => a + b);
      expect(sum, 5, reason: '$totals');
    },
  );

  test(
    'a server-set refunded status is not downgraded when no local refund counts',
    () async {
      await f.db.update('sales', {'status': 'partial_refund'});
      await const SaleLocalStore().recomputeRefundStatus(f.db, _sale);
      expect((await saleRow())['status'], 'partial_refund');
      await f.db.insert('sale_refunds', {
        'id': 'v',
        'sale_id': _sale,
        'sync_state': 'rejected',
        'json': '{}',
      });
      await const SaleLocalStore().recomputeRefundStatus(f.db, _sale);
      expect((await saleRow())['status'], 'completed');
    },
  );
}
