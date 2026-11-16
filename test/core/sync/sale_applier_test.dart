import 'dart:convert';

import 'package:amana_pos/core/sync/appliers/sale_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/features/inventory/data/local/stock_local_store.dart';
import 'package:amana_pos/features/pos/data/local/sale_local_store.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/pos/support/sale_fixture.dart';
import 'support/engine_harness.dart';
import 'support/test_db.dart';

const _otherSale = '55555555-5555-4555-8555-555555555555';
const _otherItem = '66666666-6666-4666-8666-666666666666';

/// Sale as the BE feed serialises it (apps/sync/feed.py ser_sale).
Map<String, dynamic> feedSale({
  String id = _otherSale,
  String status = 'completed',
  List<Map<String, dynamic>>? items,
}) => {
  'id': id,
  'shop': kShop,
  'cashier': 'u2',
  'customer': null,
  'receipt_number': 'REC-0042',
  'local_receipt_number': 'L-ffff-000007',
  'client_sale_id': id,
  'device_id': 'ffff0000-0000-4000-8000-000000000000',
  'total_amount': '7.50',
  'discount_amount': '0.00',
  'tax_amount': '0.00',
  'tax_rate': '0.00',
  'tax_inclusive': false,
  'tax_name': '',
  'net_amount': '7.50',
  'payment_method': 'cash',
  'bankak_account_snapshot': '',
  'status': status,
  'notes': '',
  'occurred_at': '2026-11-16T08:00:00Z',
  'received_at': '2026-11-16T08:05:00Z',
  'occurred_at_suspect': false,
  'created_at': '2026-11-16T08:00:00Z',
  'updated_at': '2026-11-16T08:05:00Z',
  'refunded_amount': '0.00',
  'payments': [
    {'method': 'cash', 'amount': '7.50'},
  ],
  'items':
      items ??
      [
        {
          'id': _otherItem,
          'product': kP1,
          'product_name': 'Tea',
          'is_custom': false,
          'note': '',
          'quantity': '3.000',
          'unit_price': '2.50',
          'unit_cost': '1.20',
          'discount': '0.00',
          'subtotal': '7.50',
          'returned_quantity': '0',
        },
      ],
};

void main() {
  late SaleFixture f;
  late SaleService service;
  final applier = SaleApplier();

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    service = f.service();
  });

  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  PullChange change(
    Map<String, dynamic>? data, {
    int version = 1,
    String op = 'upsert',
    String id = _otherSale,
  }) => PullChange(
    seq: version,
    entity: 'sale',
    op: op,
    id: id,
    version: version,
    data: data,
    shopId: kShop,
  );

  Future<void> doApply(PullChange c) =>
      f.db.transaction((t) => applier.apply(t, c));

  Future<OutboxEntry> sentRow() async =>
      OutboxEntry.fromRow((await f.db.query('outbox')).single);

  Future<void> markOutbox(String status) =>
      f.db.update('outbox', {'status': status});

  Future<void> push(OutboxEntry e, PushResult r) =>
      f.db.transaction((t) => applier.onPushResult(t, e, r));

  Future<Map<String, Object?>> saleRow(String id) async =>
      (await f.db.query('sales', where: 'id = ?', whereArgs: [id])).single;

  Future<double> qty(String p) async =>
      ((await f.stock(p))['quantity'] as num).toDouble();

  Future<Sale> sell(String quantity) => service.createSale(
    SaleDraft(
      shopId: kShop,
      paymentMethod: 'cash',
      lines: [
        SaleDraftLine.product(
          productId: kP1,
          productName: 'Tea',
          quantity: quantity,
          unitPrice: '2.50',
          snapshot: const {'id': kP1, 'name': 'Tea'},
        ),
      ],
    ),
  );

  test('metadata', () {
    expect(applier.entity, 'sale');
    expect(applier.skipWhenLocalPending, isTrue);
    expect(
      applier.tables,
      containsAll({'sales', 'sale_items', 'sale_payments'}),
    );
  });

  group('pull', () {
    test(
      'a sale from another device appears and leaves stock untouched',
      () async {
        await doApply(change(feedSale(), version: 2));
        final row = await saleRow(_otherSale);
        expect(row['receipt_number'], 'REC-0042');
        expect(row['local_receipt_number'], 'L-ffff-000007');
        expect(row['net_amount'], '7.50');
        expect(row['subtotal'], '7.50');
        expect(row['cashier_id'], 'u2');
        expect(row['version'], 2);
        expect(row['sync_state'], 'synced');
        expect(row['occurred_at'], '2026-11-16T08:00:00.000Z');
        final it = (await f.db.query('sale_items')).single;
        expect(it['id'], _otherItem);
        expect(it['product_id'], kP1);
        expect(it['quantity'], '3.000');
        expect(it['line_total'], '7.50');
        expect((await f.db.query('sale_payments')).single['amount'], '7.50');
        // StockApplier owns stock; a pulled sale never moves it.
        expect(await qty(kP1), 10.0);
        expect((await f.stock(kP1))['base_quantity'], '10');
      },
    );

    test('occurred_at_suspect: the server reporting time (created_at) is '
        'used as the local occurred_at', () async {
      final d = feedSale()
        ..['occurred_at'] = '2027-03-01T08:00:00Z'
        ..['occurred_at_suspect'] = true
        ..['received_at'] = '2026-11-16T08:05:00Z'
        ..['created_at'] = '2026-11-16T08:05:00Z';
      await doApply(change(d, version: 2));
      expect(
        (await saleRow(_otherSale))['occurred_at'],
        '2026-11-16T08:05:00.000Z',
      );
    });

    test('a pulled older version is ignored', () async {
      await doApply(change(feedSale(status: 'refunded'), version: 3));
      await doApply(change(feedSale(status: 'completed'), version: 2));
      expect((await saleRow(_otherSale))['status'], 'refunded');
      expect((await saleRow(_otherSale))['version'], 3);
    });

    // BE apps/sync/tracking.py: Sale is NOT versioned, every sale change in
    // the feed carries version 0. A later change (cancel / refund on another
    // device or the web) must still replace the earlier one; the feed's seq
    // order is the only ordering there is.
    test('unversioned BE sale (version 0): a later pulled change replaces '
        'the earlier one, directly and through the deferred path', () async {
      await doApply(change(feedSale(), version: 0));
      await doApply(change(feedSale(status: 'cancelled'), version: 0));
      expect((await saleRow(_otherSale))['status'], 'cancelled');
      // The engine's deferred path skips a change when
      // version <= localVersion: version 0 must never count as a version.
      final v = await f.db.transaction(
        (t) => applier.localVersion(t, change(feedSale(), version: 0)),
      );
      expect(v, isNull);
    });

    test('localVersion reads sales.version', () async {
      await doApply(change(feedSale(), version: 4));
      final v = await f.db.transaction(
        (t) => applier.localVersion(t, change(feedSale())),
      );
      expect(v, 4);
      final none = await f.db.transaction(
        (t) => applier.localVersion(t, change(feedSale(), id: 'nope')),
      );
      expect(none, isNull);
    });

    test('a newer version replaces children atomically', () async {
      await doApply(change(feedSale(), version: 1));
      await doApply(
        change(
          feedSale(
            items: [
              {
                'id': '77777777-7777-4777-8777-777777777777',
                'product': null,
                'product_name': '',
                'is_custom': true,
                'note': 'Fee',
                'quantity': '1.000',
                'unit_price': '7.50',
                'unit_cost': null,
                'discount': '0.00',
                'subtotal': '7.50',
              },
            ],
          ),
          version: 2,
        ),
      );
      final items = await f.db.query('sale_items');
      expect(items, hasLength(1));
      expect(items.single['is_custom'], 1);
      expect(items.single['product_id'], isNull);
      expect(items.single['product_name'], 'Fee');
      expect(await f.count('sale_payments'), 1);
    });

    test('delete removes the sale and its children', () async {
      await doApply(change(feedSale(), version: 1));
      await doApply(change(null, op: 'delete', version: 2));
      expect(await f.count('sales'), 0);
      expect(await f.count('sale_items'), 0);
      expect(await f.count('sale_payments'), 0);
    });

    test(
      'pulled copy of our own synced sale keeps the line snapshots',
      () async {
        final sale = await sell('3');
        await markOutbox('done');
        final mine = await const SaleLocalStore().read(f.db, sale.id);
        final data = feedSale(
          id: sale.id,
          items: [
            {
              'id': mine!.items.single.id,
              'product': kP1,
              'product_name': 'Tea (renamed)',
              'is_custom': false,
              'quantity': '3.000',
              'unit_price': '2.50',
              'unit_cost': null,
              'discount': '0.00',
              'subtotal': '7.50',
            },
          ],
        );
        await doApply(change(data, id: sale.id, version: 1));
        final read = await const SaleLocalStore().read(f.db, sale.id);
        expect(read!.items.single.snapshot['name'], 'Tea');
        expect(read.localReceiptNumber, 'L-ffff-000007');
        // Pull never moves stock: still base 10 (the sale is done locally,
        // its effect is in the server base only after a stock pull/re-base).
        expect((await f.stock(kP1))['base_quantity'], '10');
      },
    );
  });

  group('push results', () {
    test('applied: synced, receipt, warnings; re-base from stock_after and '
        'quantity = base + other pending', () async {
      final sale = await sell('3'); // 10 -> 7
      final sent = await sentRow();
      // Another, still pending, stock removal of 1.
      await f.outbox.enqueue(
        f.db,
        entity: 'stock',
        op: 'remove',
        entityId: '$kP1:$kShop',
        payload: {'product_id': kP1, 'shop_id': kShop, 'delta': '1'},
        scope: kScope,
      );
      await const StockLocalStore().recompute(f.db, kP1, kShop);
      expect(await qty(kP1), 6.0);
      await f.db.update(
        'outbox',
        {'status': 'done'},
        where: 'mutation_id = ?',
        whereArgs: [sent.mutationId],
      );
      await push(
        sent,
        PushResult(
          mutationId: sent.mutationId,
          status: PushStatus.applied,
          entityId: sale.id,
          receiptNumber: 'REC-1001',
          warnings: const ['negative_stock'],
          // The server had 9 (another device sold 1), minus our 3.
          stockAfter: const [
            StockAfter(productId: kP1, shopId: kShop, quantity: '6'),
          ],
        ),
      );
      final row = await saleRow(sale.id);
      expect(row['sync_state'], 'synced');
      expect(row['receipt_number'], 'REC-1001');
      expect(jsonDecode(row['warnings_json'] as String), ['negative_stock']);
      final s = await f.stock(kP1);
      expect(s['base_quantity'], '6');
      expect((s['quantity'] as num).toDouble(), 5.0, reason: '6 - 1 pending');
      expect(await f.level(kP1), 5.0);
    });

    test('duplicate replay: synced without touching stock (stale '
        'stock_after)', () async {
      final sale = await sell('3');
      final sent = await sentRow();
      await markOutbox('done');
      final before = await f.stock(kP1);
      await push(
        sent,
        PushResult(
          mutationId: sent.mutationId,
          status: PushStatus.duplicate,
          entityId: sale.id,
          receiptNumber: 'REC-1001',
          stockAfter: const [
            StockAfter(productId: kP1, shopId: kShop, quantity: '99'),
          ],
        ),
      );
      final row = await saleRow(sale.id);
      expect(row['sync_state'], 'synced');
      expect(row['receipt_number'], 'REC-1001');
      final after = await f.stock(kP1);
      expect(after['base_quantity'], before['base_quantity']);
      // Not pending any more: quantity = base + remaining pending (none).
      // The pull that follows the push brings the server level (7); the
      // stale stock_after (99) is never used.
      expect(before['quantity'], 7.0);
      expect(after['quantity'], 10.0);
    });

    // Task 12 convergence finding (see the stock applier test of the same
    // name): pulled server level already includes the sale, then the replay
    // answers `duplicate`.
    test('duplicate after the server level was already pulled: displayed '
        'stock no longer double counts the sale', () async {
      final sale = await sell('3');
      final sent = await sentRow();
      await f.db.transaction(
        (t) => const StockLocalStore().upsertServerBase(
          t,
          'srv-stock-1',
          kP1,
          kShop,
          '7.000',
        ),
      );
      expect(await qty(kP1), 4.0); // 7 - 3 still pending
      await markOutbox('done');
      await push(
        sent,
        PushResult(
          mutationId: sent.mutationId,
          status: PushStatus.duplicate,
          entityId: sale.id,
          stockAfter: const [
            StockAfter(productId: kP1, shopId: kShop, quantity: '7.000'),
          ],
        ),
      );
      expect((await f.stock(kP1))['base_quantity'], '7');
      expect(await qty(kP1), 7.0);
      expect(await f.level(kP1), 7.0);
    });

    test('rejected: row kept as rejected with the error; its stock effect '
        'is dropped', () async {
      final sale = await sell('3');
      expect(await qty(kP1), 7.0);
      final sent = await sentRow();
      await markOutbox('rejected');
      await push(
        sent,
        PushResult(
          mutationId: sent.mutationId,
          status: PushStatus.rejected,
          code: 'validation_error',
          message: 'Payment parts do not add up',
        ),
      );
      final row = await saleRow(sale.id);
      expect(row['sync_state'], 'rejected');
      expect(row['error_code'], 'validation_error');
      expect(row['error_message'], 'Payment parts do not add up');
      expect(await f.count('sale_items'), 1, reason: 'never delete a sale');
      expect(await qty(kP1), 10.0);
      expect((await f.stock(kP1))['base_quantity'], '10');
    });

    test('applied result for a sale row that no longer exists does not '
        'throw', () async {
      final sale = await sell('1');
      final sent = await sentRow();
      await f.db.delete('sales');
      await markOutbox('done');
      await push(
        sent,
        PushResult(
          mutationId: sent.mutationId,
          status: PushStatus.applied,
          entityId: sale.id,
        ),
      );
    });
  });

  test('engine: sale result reaches SaleApplier with the row already done; '
      'applied re-bases stock (review I2)', () async {
    final h = await EngineHarness.create();
    addTearDown(h.dispose);
    final seen = <String>[];
    h.registry.register(_SpySaleApplier(seen));
    final hf = await SaleFixture.on(h.odb);
    final s = SaleService(
      writer: h.writer,
      state: hf.state,
      cashierId: () => 'u1',
    );
    final sale = await s.createSale(
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
    final sent = OutboxEntry.fromRow((await h.db.query('outbox')).single);
    h.transport.scripted[sent.mutationId] = PushResult(
      mutationId: sent.mutationId,
      status: PushStatus.applied,
      entityId: sale.id,
      receiptNumber: 'REC-9',
      stockAfter: const [
        StockAfter(productId: kP1, shopId: kShop, quantity: '4'),
      ],
    );
    await h.build().syncNow();
    expect(seen, ['done']);
    final st = (await h.db.query(
      'stock',
      where: 'product_id = ?',
      whereArgs: [kP1],
    )).single;
    expect(st['base_quantity'], '4');
    expect((st['quantity'] as num).toDouble(), 4.0);
    final row = (await h.db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [sale.id],
    )).single;
    expect(row['sync_state'], 'synced');
    expect(row['receipt_number'], 'REC-9');
  });
}

class _SpySaleApplier extends SaleApplier {
  _SpySaleApplier(this._seen);
  final List<String> _seen;

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {
    final r = await txn.query(
      'outbox',
      columns: ['status'],
      where: 'mutation_id = ?',
      whereArgs: [sent.mutationId],
    );
    _seen.add(r.single['status'] as String);
    await super.onPushResult(txn, sent, result);
  }
}
