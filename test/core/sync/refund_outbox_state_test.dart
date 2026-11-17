import 'package:amana_pos/core/sync/appliers/sale_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/features/customers/domain/customer_service.dart';
import 'package:amana_pos/features/returns/domain/refund_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/pos/support/sale_fixture.dart';
import 'sale_applier_test.dart' show feedSale;
import 'support/test_db.dart';

const _sale = '55555555-5555-4555-8555-555555555555';
const _item = '66666666-6666-4666-8666-666666666666';

void main() {
  late SaleFixture f;
  late RefundService svc;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    svc = RefundService(writer: f.writer, now: () => f.clock);
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

  Future<String> state() async =>
      '${(await f.db.query('sale_refunds')).single['sync_state']}';
  Future<String> status() async =>
      '${(await f.db.query('sales', where: 'id = ?', whereArgs: [_sale])).single['status']}';
  Future<String> mutation() async =>
      '${(await f.db.query('outbox', where: "op = 'refund'")).single['mutation_id']}';

  test('discarding a queued refund voids it and restores the sale status', () async {
    await svc.refund(saleId: _sale, quantitiesByLineId: {_item: '3'}, method: 'cash');
    expect(await status(), 'refunded');
    await f.outbox.discard(await mutation());
    expect(await state(), 'rejected');
    expect(await status(), 'completed');
  });

  test('retrying a rejected refund makes it pending (counted) again', () async {
    await svc.refund(saleId: _sale, quantitiesByLineId: {_item: '1'}, method: 'cash');
    final m = await mutation();
    await f.db.update('outbox', {'status': 'rejected', 'error_code': 'x'});
    await f.db.update('sale_refunds', {'sync_state': 'rejected'});
    await f.outbox.retryRejected(m);
    expect(await state(), 'pending');
    expect(await status(), 'partial_refund');
  });

  test('discarding a never-sent customer create leaves no ghost row', () async {
    final c = CustomerService(writer: f.writer, now: () => f.clock);
    final id = await c.create(name: 'Ali');
    final m = (await f.db.query('outbox', where: "entity = 'customer'")).single['mutation_id'] as String;
    await f.outbox.discard(m);
    expect(await f.db.query('customers', where: 'id = ?', whereArgs: [id]), isEmpty);
  });
}
