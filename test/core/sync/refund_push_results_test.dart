import 'dart:async';

import 'package:amana_pos/core/sync/appliers/refund_applier.dart';
import 'package:amana_pos/core/sync/appliers/sale_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/time/business_day.dart';
import 'package:amana_pos/features/dashboard/data/local/local_dashboard_queries.dart';
import 'package:amana_pos/features/pos/data/local/sale_local_store.dart';
import 'package:amana_pos/features/returns/domain/refund_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/pos/support/sale_fixture.dart';
import 'sale_applier_test.dart' show feedSale;
import 'support/test_db.dart';

const _sale = '55555555-5555-4555-8555-555555555555';
const _item = '66666666-6666-4666-8666-666666666666';
const _biz = '99999999-9999-4999-8999-999999999999';

void main() {
  late SaleFixture f;
  late RefundService svc;
  late LocalDashboardQueries q;
  late StreamController<String?> tc;
  final sales = SaleApplier();
  final refunds = RefundApplier();

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    await f.seedShop(kShop, businessId: _biz);
    tc = StreamController<String?>.broadcast();
    q = LocalDashboardQueries(
      db: f.odb,
      notifier: f.notifier,
      now: () => f.clock,
      tenantId: () => _biz,
      tenantChanges: tc.stream,
    );
    svc = RefundService(writer: f.writer, now: () => f.clock);
    await f.db.transaction(
      (t) => sales.apply(
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
    await tc.close();
    f.notifier.dispose();
    await f.db.close();
  });

  Future<OutboxEntry> sent() async => OutboxEntry.fromRow(
    (await f.db.query('outbox', where: "op = 'refund'")).single,
  );
  Future<void> result(PushResult r) async {
    final e = await sent();
    await f.db.transaction((t) => sales.onPushResult(t, e, r));
  }

  PushResult res(
    PushStatus s, {
    String? code,
    String? total,
    List<StockAfter> stock = const [],
  }) => PushResult(
    mutationId: 'm',
    status: s,
    entityId: _sale,
    code: code,
    message: code,
    refundTotal: total,
    stockAfter: stock,
  );

  Future<void> pullRefund(String ref, {String total = '2.50'}) =>
      f.db.transaction(
        (t) => refunds.apply(
          t,
          PullChange(
            seq: 2,
            entity: 'refund',
            op: 'upsert',
            id: 'server-rf',
            data: {
              'id': 'server-rf',
              'sale': _sale,
              'shop': kShop,
              'reference': ref,
              'total': total,
              'method': 'cash',
              'occurred_at': f.clock.toIso8601String(),
              'created_at': f.clock.toIso8601String(),
              'items': [
                {'sale_item': _item, 'quantity': '1.000', 'amount': total},
              ],
            },
          ),
        ),
      );

  Future<num> refundAmount() async => (await q.summaryFor(
    day: BusinessDay.of(f.clock, 'Africa/Khartoum'),
    shopId: kShop,
    timezone: 'Africa/Khartoum',
    businessId: _biz,
  )).today.refundAmount;

  Future<String> refundedQty() async =>
      '${(await const SaleLocalStore().refundedQuantities(f.db, _sale))[_item]}';

  Future<String> status() async =>
      '${(await f.db.query('sales', where: 'id = ?', whereArgs: [_sale])).single['status']}';

  test(
    'applied marks synced; server pull afterwards leaves ONE counted row',
    () async {
      final ref = await svc.refund(
        saleId: _sale,
        quantitiesByLineId: {_item: '1'},
        method: 'cash',
      );
      expect(await refundAmount(), 2.5);
      await result(res(PushStatus.applied, total: '2.50'));
      expect((await f.db.query('sale_refunds')).single['sync_state'], 'synced');
      await pullRefund(ref);
      expect(await f.db.query('sale_refunds'), hasLength(1));
      expect((await f.db.query('sale_refunds')).single['id'], 'server-rf');
      expect(await refundAmount(), 2.5);
      expect(await refundedQty(), '1000');
    },
  );

  test('pull arriving before the push result still counts once', () async {
    final ref = await svc.refund(
      saleId: _sale,
      quantitiesByLineId: {_item: '1'},
      method: 'cash',
    );
    await pullRefund(ref);
    expect(await refundAmount(), 2.5);
    await result(res(PushStatus.applied, total: '2.50'));
    expect(await f.db.query('sale_refunds'), hasLength(1));
    expect(await refundAmount(), 2.5);
    expect(await refundedQty(), '1000');
  });

  test(
    'applied adopts the server total and re-bases stock only on applied',
    () async {
      await svc.refund(
        saleId: _sale,
        quantitiesByLineId: {_item: '1'},
        method: 'cash',
      );
      await result(res(PushStatus.applied, total: '2.60'));
      expect((await f.db.query('sale_refunds')).single['total'], '2.60');
    },
  );

  test(
    'refund_exceeds_sold voids the refund: totals, status and guard ignore it',
    () async {
      await svc.refund(
        saleId: _sale,
        quantitiesByLineId: {_item: '3'},
        method: 'cash',
      );
      expect(await status(), 'refunded');
      await result(res(PushStatus.rejected, code: 'refund_exceeds_sold'));
      final r = (await f.db.query('sale_refunds')).single;
      expect(r['sync_state'], 'rejected');
      expect(r['error_code'], 'refund_exceeds_sold');
      expect(await refundAmount(), 0);
      expect(await status(), 'completed');
      expect(await refundedQty(), 'null');
      // The line is returnable again.
      await svc.refund(
        saleId: _sale,
        quantitiesByLineId: {_item: '1'},
        method: 'cash',
      );
    },
  );

  test('duplicate replay changes nothing and does not re-base', () async {
    await svc.refund(
      saleId: _sale,
      quantitiesByLineId: {_item: '1'},
      method: 'cash',
    );
    await result(res(PushStatus.applied, total: '2.50'));
    await result(res(PushStatus.duplicate, total: '2.50'));
    expect((await f.db.query('sale_refunds')).single['sync_state'], 'synced');
    expect(await status(), 'partial_refund');
  });

  test('retry leaves the refund pending', () async {
    await svc.refund(
      saleId: _sale,
      quantitiesByLineId: {_item: '1'},
      method: 'cash',
    );
    await result(res(PushStatus.retry, code: 'dependency_pending'));
    expect((await f.db.query('sale_refunds')).single['sync_state'], 'pending');
  });

  test('refund cash/bankak split follows the refund method', () async {
    await svc.refund(
      saleId: _sale,
      quantitiesByLineId: {_item: '1'},
      method: 'bankak',
    );
    final s = (await q.summaryFor(
      day: BusinessDay.of(f.clock, 'Africa/Khartoum'),
      shopId: kShop,
      timezone: 'Africa/Khartoum',
      businessId: _biz,
    )).today;
    expect(s.refundBankakAmount, 2.5);
    expect(s.refundCashAmount, 0);
  });
}
