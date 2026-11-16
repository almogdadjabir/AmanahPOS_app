import 'dart:convert';

import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/appliers/inbound_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/features/inventory/data/local/stock_local_store.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/pos/support/sale_fixture.dart';
import 'support/engine_harness.dart';
import 'support/test_db.dart';

const _vendor = '88888888-8888-4888-8888-888888888888';
const _otherInbound = '99999999-9999-4999-8999-999999999999';

const _request = CreateInboundRequestDto(
  shopId: kShop,
  reference: 'INV-7',
  vendorId: _vendor,
  items: [
    CreateInboundItemRequestDto(productId: kP1, quantity: '3'),
    CreateInboundItemRequestDto(productId: kP2, quantity: '2'),
  ],
);

void main() {
  late SaleFixture f;
  late StockService service;
  final applier = InboundApplier();

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    service = StockService(
      writer: f.writer,
      actor: () => const StockActor(
        businessType: AppBusinessType.shop,
        role: AppUserRole.owner,
        shopId: null,
      ),
      now: () => f.clock,
    );
  });

  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  Future<OutboxEntry> sentRow() async =>
      OutboxEntry.fromRow((await f.db.query('outbox')).single);

  Future<void> markOutbox(String status) =>
      f.db.update('outbox', {'status': status});

  Future<void> push(OutboxEntry e, PushResult r) =>
      f.db.transaction((t) => applier.onPushResult(t, e, r));

  Future<double> qty(String p) async =>
      ((await f.stock(p))['quantity'] as num).toDouble();

  test('metadata', () {
    expect(applier.entity, 'inbound');
    expect(applier.skipWhenLocalPending, isTrue);
    expect(
      applier.tables,
      containsAll({'stock', 'products', 'inbound_transactions'}),
    );
  });

  test('localVersion is null (inbound has no version)', () async {
    final v = await f.db.transaction(
      (t) => applier.localVersion(
        t,
        const PullChange(seq: 1, entity: 'inbound', op: 'upsert', id: 'x'),
      ),
    );
    expect(v, isNull);
  });

  group('push results', () {
    test('pending inbound is counted in local stock', () async {
      await service.receiveInbound(_request);
      expect(await qty(kP1), 13.0);
      expect(await qty(kP2), 7.0);
    });

    test('applied: re-base from stock_after; quantity = base + other '
        'pending', () async {
      await service.receiveInbound(_request);
      final sent = await sentRow();
      // Another, still pending, stock removal of 1 on P1.
      await service.remove(productId: kP1, shopId: kShop, delta: '1');
      expect(await qty(kP1), 12.0);
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
          entityId: sent.entityId,
          // Server had 11 for P1 (another device added 1) + our 3.
          stockAfter: const [
            StockAfter(productId: kP1, shopId: kShop, quantity: '14'),
            StockAfter(productId: kP2, shopId: kShop, quantity: '7'),
          ],
        ),
      );
      final s1 = await f.stock(kP1);
      expect(s1['base_quantity'], '14');
      expect((s1['quantity'] as num).toDouble(), 13.0, reason: '14 - 1');
      expect((await f.stock(kP2))['base_quantity'], '7');
      expect(await qty(kP2), 7.0);
      expect(await f.level(kP1), 13.0);
    });

    test('duplicate replay never re-bases (stale stock_after)', () async {
      await service.receiveInbound(_request);
      final sent = await sentRow();
      await markOutbox('done');
      final before = await f.stock(kP1);
      await push(
        sent,
        PushResult(
          mutationId: sent.mutationId,
          status: PushStatus.duplicate,
          entityId: sent.entityId,
          stockAfter: const [
            StockAfter(productId: kP1, shopId: kShop, quantity: '99'),
          ],
        ),
      );
      final after = await f.stock(kP1);
      expect(after['base_quantity'], before['base_quantity']);
      expect(after['base_quantity'], '10');
      // Not pending any more: quantity = base + remaining pending (none);
      // the following pull brings the server level. 99 is never used.
      expect(before['quantity'], 13.0);
      expect(after['quantity'], 10.0);
    });

    // Task 12 convergence finding (see the stock applier test of the same
    // name).
    test('duplicate after the server level was already pulled: displayed '
        'stock no longer double counts the receipt', () async {
      await service.receiveInbound(_request);
      final sent = await sentRow();
      await f.db.transaction(
        (t) => const StockLocalStore().upsertServerBase(
          t,
          'srv-stock-1',
          kP1,
          kShop,
          '13.000',
        ),
      );
      expect(await qty(kP1), 16.0); // 13 + 3 still pending
      await markOutbox('done');
      await push(
        sent,
        PushResult(
          mutationId: sent.mutationId,
          status: PushStatus.duplicate,
          entityId: sent.entityId,
          stockAfter: const [
            StockAfter(productId: kP1, shopId: kShop, quantity: '13.000'),
          ],
        ),
      );
      expect((await f.stock(kP1))['base_quantity'], '13');
      expect(await qty(kP1), 13.0);
    });

    test('rejected: its stock effect is dropped (quantity back to base); '
        'the local history row is removed', () async {
      await service.receiveInbound(_request);
      expect(await qty(kP1), 13.0);
      expect(await f.count('inbound_transactions'), 1);
      final sent = await sentRow();
      await markOutbox('rejected');
      await push(
        sent,
        PushResult(
          mutationId: sent.mutationId,
          status: PushStatus.rejected,
          code: 'conflict_unique',
          message: 'Inbound reference already exists.',
        ),
      );
      expect(await qty(kP1), 10.0);
      expect(await qty(kP2), 5.0);
      expect((await f.stock(kP1))['base_quantity'], '10');
      expect(await f.count('inbound_transactions'), 0);
    });
  });

  group('pull', () {
    Map<String, dynamic> feed() => {
      'id': _otherInbound,
      'shop': kShop,
      'vendor': _vendor,
      'reference': 'INV-REMOTE',
      'notes': '',
      'created_by': 'u2',
      'created_at': '2026-11-16T08:00:00Z',
      'items': [
        {
          'product': kP1,
          'quantity': '4.000',
          'unit_cost': '1.00',
          'expiry_date': null,
          'batch_number': '',
        },
      ],
    };

    Future<void> doApply(PullChange c) =>
        f.db.transaction((t) => applier.apply(t, c));

    test('upsert writes the history row and never touches stock', () async {
      await doApply(
        PullChange(
          seq: 1,
          entity: 'inbound',
          op: 'upsert',
          id: _otherInbound,
          data: feed(),
          shopId: kShop,
        ),
      );
      expect(await qty(kP1), 10.0);
      expect((await f.stock(kP1))['base_quantity'], '10');
      final row = (await f.db.query('inbound_transactions')).single;
      expect(row['id'], _otherInbound);
      expect(row['shop_id'], kShop);
      final j = jsonDecode(row['json'] as String) as Map<String, dynamic>;
      expect(j['reference'], 'INV-REMOTE');
      expect(j['vendor_id'], _vendor);
      expect(j['item_count'], 1);
      expect(j['total_quantity'], '4');
      expect((j['items'] as List).single['product'], kP1);
    });

    test('delete removes the history row', () async {
      await doApply(
        PullChange(
          seq: 1,
          entity: 'inbound',
          op: 'upsert',
          id: _otherInbound,
          data: feed(),
        ),
      );
      await doApply(
        const PullChange(
          seq: 2,
          entity: 'inbound',
          op: 'delete',
          id: _otherInbound,
        ),
      );
      expect(await f.count('inbound_transactions'), 0);
    });

    test('malformed change is skipped without throwing', () async {
      await doApply(
        const PullChange(
          seq: 1,
          entity: 'inbound',
          op: 'upsert',
          id: _otherInbound,
          data: null,
        ),
      );
      expect(await f.count('inbound_transactions'), 0);
    });
  });

  test('engine: inbound result reaches InboundApplier with the row already '
      'done; applied re-bases stock', () async {
    final h = await EngineHarness.create();
    addTearDown(h.dispose);
    final seen = <String>[];
    h.registry.register(_SpyInboundApplier(seen));
    final hf = await SaleFixture.on(h.odb);
    expect(hf, isNotNull);
    final s = StockService(
      writer: h.writer,
      actor: () => const StockActor(
        businessType: AppBusinessType.shop,
        role: AppUserRole.manager,
        shopId: kShop,
      ),
    );
    final created = await s.receiveInbound(_request);
    final sent = OutboxEntry.fromRow((await h.db.query('outbox')).single);
    expect(sent.entityId, created.id);
    h.transport.scripted[sent.mutationId] = PushResult(
      mutationId: sent.mutationId,
      status: PushStatus.applied,
      entityId: sent.entityId,
      stockAfter: const [
        StockAfter(productId: kP1, shopId: kShop, quantity: '20'),
        StockAfter(productId: kP2, shopId: kShop, quantity: '9'),
      ],
    );
    await h.build().syncNow();
    expect(seen, ['done']);
    final st = (await h.db.query(
      'stock',
      where: 'product_id = ?',
      whereArgs: [kP1],
    )).single;
    expect(st['base_quantity'], '20');
    expect((st['quantity'] as num).toDouble(), 20.0);
  });
}

class _SpyInboundApplier extends InboundApplier {
  _SpyInboundApplier(this._seen);
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
