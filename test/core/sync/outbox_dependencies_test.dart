import 'dart:convert';

import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/pos/support/sale_fixture.dart';
import 'support/engine_harness.dart';
import 'support/test_db.dart';

const _scope = 'u1|t1';
const _vendor = '88888888-8888-4888-8888-888888888888';

void main() {
  group('OutboxStore multi-dependency', () {
    late Database db;
    late OutboxStore store;

    setUp(() async {
      final odb = await openTestDb();
      db = await odb.database;
      store = OutboxStore(odb);
    });
    tearDown(() async => db.close());

    Future<OutboxEntry> enq(
      String entityId, {
      String entity = 'product',
      String op = 'create',
      List<String> deps = const [],
      String scope = _scope,
    }) => store.enqueue(
      db,
      entity: entity,
      op: op,
      entityId: entityId,
      payload: const {},
      scope: scope,
      dependsOn: deps,
    );

    Future<Map<String, Object?>> row(OutboxEntry e) async => (await db.query(
      'outbox',
      where: 'mutation_id = ?',
      whereArgs: [e.mutationId],
    )).single;

    Future<String> statusOf(OutboxEntry e) async =>
        (await row(e))['status'] as String;

    Future<void> done(OutboxEntry e) async {
      await store.applyResult(db, e.mutationId, status: OutboxStatus.done);
      await store.unblockDependents(db, e.entityId, scope: e.scope);
    }

    test('blocks while any dependency create is open', () async {
      final p1 = await enq('p1');
      await done(p1);
      await enq('p2'); // open
      final sale = await enq('s1', entity: 'sale', deps: ['p1', 'p2']);
      expect(sale.status, OutboxStatus.blocked);
      // Only the id whose create is still open is recorded.
      expect(sale.dependsOn, ['p2']);
      final r = await row(sale);
      expect(jsonDecode(r['depends_on_json'] as String), ['p2']);
      expect(OutboxEntry.fromRow(r).dependsOn, ['p2']);
    });

    test('unblocks only when the last dependency is done', () async {
      final a = await enq('pa');
      final b = await enq('pb');
      final c = await enq('pc');
      final sale = await enq('s1', entity: 'sale', deps: ['pa', 'pb', 'pc']);
      expect(sale.status, OutboxStatus.blocked);
      await done(b);
      expect(await statusOf(sale), 'blocked');
      await done(a);
      expect(await statusOf(sale), 'blocked');
      await done(c);
      expect(await statusOf(sale), 'pending');
    });

    test(
      'rejected dependency fails the dependent with dependency_failed',
      () async {
        final a = await enq('pa');
        await enq('pb');
        final sale = await enq('s1', entity: 'sale', deps: ['pb', 'pa']);
        // A dependent of the sale (cascade).
        final child = await enq('x1', entity: 'note', deps: ['s1']);
        await store.applyResult(
          db,
          a.mutationId,
          status: OutboxStatus.rejected,
          code: 'conflict_unique',
        );
        await store.failDependents(db, 'pa', scope: _scope);
        final r = await row(sale);
        expect(r['status'], 'rejected');
        expect(r['error_code'], 'dependency_failed');
        expect((await row(child))['error_code'], 'dependency_failed');
      },
    );

    test('a dependency id that only prefixes another does not match', () async {
      await enq('p1');
      await enq('p10');
      final sale = await enq('s1', entity: 'sale', deps: ['p10']);
      await store.failDependents(db, 'p1', scope: _scope);
      expect(await statusOf(sale), 'blocked');
      await store.unblockDependents(db, 'p1', scope: _scope);
      expect(await statusOf(sale), 'blocked');
    });

    test('unknown or already-done dependency does not block', () async {
      final p = await enq('p1');
      await done(p);
      final sale = await enq('s1', entity: 'sale', deps: ['p1', 'ghost']);
      expect(sale.status, OutboxStatus.pending);
      expect(sale.dependsOn, isEmpty);
      expect((await row(sale))['depends_on_json'], isNull);
      // Another scope's open create does not block either.
      await enq('p9', scope: 'u2|t2');
      final other = await enq('s2', entity: 'sale', deps: ['p9']);
      expect(other.status, OutboxStatus.pending);
    });

    test('no dependency stores NULL and reads back as an empty list', () async {
      final e = await enq('p1');
      final r = await row(e);
      expect(r['depends_on_json'], isNull);
      expect(OutboxEntry.fromRow(r).dependsOn, isEmpty);
    });

    test('a discarded product UPDATE does not fail a pending sale naming '
        'the product; a discarded CREATE does', () async {
      final p1 = await enq('p1');
      final sale = await enq('s1', entity: 'sale', deps: ['p1']);
      expect(sale.dependsOn, ['p1']);
      await done(p1);
      expect(await statusOf(sale), 'pending');
      final upd = await enq('p1', op: 'update');
      expect(await store.discard(upd.mutationId), DiscardOutcome.discarded);
      expect(await statusOf(sale), 'pending');
      final del = await enq('p1', op: 'delete');
      expect(await store.discard(del.mutationId), DiscardOutcome.discarded);
      expect(await statusOf(sale), 'pending');

      await enq('p2');
      final sale2 = await enq('s2', entity: 'sale', deps: ['p2']);
      final c2 = (await db.query(
        'outbox',
        where: "entity_id = 'p2' AND op = 'create'",
      )).single;
      expect(
        await store.discard(c2['mutation_id'] as String),
        DiscardOutcome.discarded,
      );
      final r2 = await row(sale2);
      expect(r2['status'], 'rejected');
      expect(r2['error_code'], 'dependency_failed');
    });

    test('a failed non-create dependent does not cascade', () async {
      await enq('pa');
      final st = await enq('st1', entity: 'stock', op: 'add', deps: ['pa']);
      // A row that (hypothetically) lists the stock op's entity id.
      final other = await enq('x1', entity: 'note');
      await db.update(
        'outbox',
        {'depends_on_json': '["st1"]'},
        where: 'mutation_id = ?',
        whereArgs: [other.mutationId],
      );
      await store.failDependents(db, 'pa', scope: _scope);
      expect(await statusOf(st), 'rejected');
      expect(await statusOf(other), 'pending');
      expect(OutboxStore.failsDependents(st), isFalse);
      expect(OutboxStore.failsDependents(other), isTrue);
    });

    test('openCreateIds returns only ids with a not-done create', () async {
      final a = await enq('pa');
      await enq('pb');
      await enq('pc', op: 'update');
      await done(a);
      expect(
        await store.openCreateIds(db, ['pa', 'pb', 'pc', 'zz'], scope: _scope),
        {'pb'},
      );
      expect(await store.openCreateIds(db, const [], scope: _scope), isEmpty);
    });
  });

  group('services declare product / vendor dependencies', () {
    late SaleFixture f;

    setUp(() async {
      f = await SaleFixture.on(await openTestDb());
    });
    tearDown(() async {
      f.notifier.dispose();
      await f.db.close();
    });

    Future<OutboxEntry> productCreate(String id) => f.outbox.enqueue(
      f.db,
      entity: 'product',
      op: 'create',
      entityId: id,
      payload: const {},
      scope: kScope,
    );

    Future<OutboxEntry> rowOf(String entity) async => OutboxEntry.fromRow(
      (await f.db.query(
        'outbox',
        where: 'entity = ?',
        whereArgs: [entity],
      )).single,
    );

    Future<void> markDone(OutboxEntry e) async {
      await f.outbox.applyResult(f.db, e.mutationId, status: OutboxStatus.done);
      await f.outbox.unblockDependents(f.db, e.entityId, scope: e.scope);
    }

    SaleDraft draft(List<SaleDraftLine> lines) => SaleDraft(
      shopId: kShop,
      paymentMethod: 'cash',
      lines: lines,
      taxConfig: const TaxConfig.disabled(),
    );

    StockService stock() => StockService(
      writer: f.writer,
      actor: () => const StockActor(
        businessType: AppBusinessType.shop,
        role: AppUserRole.manager,
        shopId: kShop,
      ),
      now: () => f.clock,
    );

    test('sale with line of product whose create is open is blocked, then '
        'pending after the create is done', () async {
      final create = await productCreate(kP1);
      await f.service().createSale(
        draft([
          const SaleDraftLine.product(
            productId: kP1,
            productName: 'Tea',
            quantity: '1',
            unitPrice: '2.50',
          ),
          const SaleDraftLine.product(
            productId: kP2,
            productName: 'Sugar',
            quantity: '1',
            unitPrice: '1.00',
          ),
        ]),
      );
      var sale = await rowOf('sale');
      expect(sale.status, OutboxStatus.blocked);
      // kP2 has no open create: not recorded.
      expect(sale.dependsOn, [kP1]);
      // A blocked sale still counts against local stock.
      expect(((await f.stock(kP1))['quantity'] as num).toDouble(), 9.0);
      await markDone(create);
      sale = await rowOf('sale');
      expect(sale.status, OutboxStatus.pending);
    });

    test('a sale whose product create is already done has an empty '
        'dependsOn', () async {
      await markDone(await productCreate(kP1));
      await f.service().createSale(
        draft([
          const SaleDraftLine.product(
            productId: kP1,
            productName: 'Tea',
            quantity: '1',
            unitPrice: '2.50',
          ),
        ]),
      );
      final sale = await rowOf('sale');
      expect(sale.dependsOn, isEmpty);
      expect(sale.status, OutboxStatus.pending);
    });

    test('custom lines add no dependency', () async {
      await f.service().createSale(
        draft([SaleDraftLine.custom(name: 'Delivery', unitPrice: '5.00')]),
      );
      final sale = await rowOf('sale');
      expect(sale.dependsOn, isEmpty);
      expect(sale.status, OutboxStatus.pending);
    });

    test('stock op depends on its product', () async {
      final create = await productCreate(kP1);
      await stock().add(productId: kP1, shopId: kShop, delta: '2');
      var row = await rowOf('stock');
      expect(row.dependsOn, [kP1]);
      expect(row.status, OutboxStatus.blocked);
      await markDone(create);
      row = await rowOf('stock');
      expect(row.status, OutboxStatus.pending);
    });

    test('inbound depends on every product and on the vendor', () async {
      final vendor = await f.outbox.enqueue(
        f.db,
        entity: 'vendor',
        op: 'create',
        entityId: _vendor,
        payload: const {},
        scope: kScope,
      );
      await stock().receiveInbound(
        CreateInboundRequestDto(
          shopId: kShop,
          reference: 'INV-1',
          vendorId: _vendor,
          items: [
            CreateInboundItemRequestDto(productId: kP1, quantity: '1'),
            CreateInboundItemRequestDto(productId: kP2, quantity: '1'),
          ],
        ),
      );
      var row = await rowOf('inbound');
      // Products have no open create: only the vendor is recorded.
      expect(row.dependsOn, [_vendor]);
      expect(row.status, OutboxStatus.blocked);
      await markDone(vendor);
      row = await rowOf('inbound');
      expect(row.status, OutboxStatus.pending);
    });
  });

  group('engine ordering (Review Focus 1)', () {
    late EngineHarness h;

    setUp(() async {
      h = await EngineHarness.create();
    });
    tearDown(() async => h.dispose());

    for (final op in const ['update', 'delete']) {
      test('a rejected product ${op.toUpperCase()} leaves the pending sale '
          'naming the product pending (C1)', () async {
        await h.createWidget('p1');
        final sale = await h.createWidget(
          's1',
          entity: 'sale',
          dependsOn: const ['p1'],
          payload: {
            'shop': 'sh1',
            'items': [
              {'product_id': 'p1', 'quantity': '1'},
            ],
          },
        );
        expect(sale.dependsOn, ['p1']);
        final edit = await h.createWidget('p1', op: op);
        // The sale is answered retry (stays unsent), the edit is rejected.
        h.transport.scripted[sale.mutationId] = PushResult(
          mutationId: sale.mutationId,
          status: PushStatus.retry,
          code: 'server_busy',
        );
        h.transport.scripted[edit.mutationId] = PushResult(
          mutationId: edit.mutationId,
          status: PushStatus.rejected,
          entityId: 'p1',
          code: 'validation_error',
          message: 'nope',
        );
        final engine = h.build();
        for (var i = 0; i < 3; i++) {
          await engine.syncNow();
          h.advance(const Duration(hours: 1));
        }
        expect((await h.outboxRow(edit.mutationId))['status'], 'rejected');
        expect(h.transport.pushedIds, contains(sale.mutationId));
        final s = await h.outboxRow(sale.mutationId);
        expect(s['status'], 'pending');
        expect(s['error_code'], isNot('dependency_failed'));
      });
    }

    test('a rejected product CREATE still fails the dependent sale', () async {
      final product = await h.createWidget('p1');
      final sale = await h.createWidget(
        's1',
        entity: 'sale',
        dependsOn: const ['p1'],
        payload: {'shop': 'sh1', 'items': []},
      );
      h.transport.scripted[product.mutationId] = PushResult(
        mutationId: product.mutationId,
        status: PushStatus.rejected,
        entityId: 'p1',
        code: 'conflict_unique',
        message: 'dup',
      );
      await h.build().syncNow();
      final s = await h.outboxRow(sale.mutationId);
      expect(s['status'], 'rejected');
      expect(s['error_code'], 'dependency_failed');
      expect(h.transport.pushedIds, isNot(contains(sale.mutationId)));
    });

    test('product.create answered retry: a sale referencing it is not sent '
        'until the create is done', () async {
      final product = await h.createWidget('p1');
      final sale = await h.createWidget(
        's1',
        entity: 'sale',
        dependsOn: const ['p1'],
        payload: {
          'shop': 'sh1',
          'items': [
            {'product_id': 'p1', 'quantity': '1'},
          ],
        },
      );
      expect(sale.status, OutboxStatus.blocked);

      h.transport.scripted[product.mutationId] = PushResult(
        mutationId: product.mutationId,
        status: PushStatus.retry,
        code: 'server_busy',
      );
      final engine = h.build();
      await engine.syncNow();
      expect((await h.outboxRow(product.mutationId))['status'], 'pending');
      expect((await h.outboxRow(sale.mutationId))['status'], 'blocked');

      // Batch 2: the create is still answered retry; the sale never ships.
      h.advance(const Duration(hours: 1));
      await engine.syncNow();
      expect(h.transport.pushedIds, isNot(contains(sale.mutationId)));
      expect((await h.outboxRow(sale.mutationId))['status'], 'blocked');

      // The create goes through; only then the sale is sent.
      h.transport.scripted.remove(product.mutationId);
      h.advance(const Duration(hours: 1));
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect((await h.outboxRow(product.mutationId))['status'], 'done');
      expect((await h.outboxRow(sale.mutationId))['status'], 'done');
      final ids = h.transport.pushedIds;
      expect(
        ids.indexOf(sale.mutationId),
        greaterThan(ids.lastIndexOf(product.mutationId)),
      );
      // Never in the same batch as any attempt of the create.
      var sent = 0;
      for (final size in h.transport.batchSizes) {
        final batch = ids.sublist(sent, sent + size);
        sent += size;
        expect(
          batch.contains(sale.mutationId) && batch.contains(product.mutationId),
          isFalse,
        );
      }
    });
  });
}
