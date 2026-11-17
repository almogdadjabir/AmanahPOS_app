import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/features/inventory/data/local/stock_local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'support/test_db.dart';

/// Phase 1 T9-12 review I1 / I2 / M4: user discard and retry of outbox rows
/// never race the push, keep local stock exact and change the sale row in
/// the same transaction as the outbox row.
void main() {
  const scope = 'u1|t1';
  const stock = StockLocalStore();
  late OfflineDb odb;
  late Database db;
  late OutboxStore store;

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
    store = OutboxStore(odb);
    await db.insert('products', {'id': 'p1', 'name': 'Tea', 'json': '{}'});
    await db.insert('stock', {
      'id': 'st-p1-s1',
      'product_id': 'p1',
      'shop_id': 's1',
      'quantity': 10.0,
      'base_quantity': '10.000',
      'json': '{}',
      'updated_at': 'x',
    });
  });
  tearDown(() async => db.close());

  Future<double> qty() async =>
      (await db.query('stock', where: "product_id = 'p1'")).single['quantity']
          as double;

  Future<String?> saleState(String id) async =>
      (await db.query(
            'sales',
            where: 'id = ?',
            whereArgs: [id],
          )).single['sync_state']
          as String?;

  Future<int> outboxRows(String mutationId) async => (await db.query(
    'outbox',
    where: 'mutation_id = ?',
    whereArgs: [mutationId],
  )).length;

  /// A local sale of 2 x p1 in shop s1, written like SaleService does
  /// (sale row + outbox row + stock recompute).
  Future<OutboxEntry> sale(String id) async {
    await db.insert('sales', {
      'id': id,
      'shop_id': 's1',
      'status': 'completed',
      'subtotal': '20.00',
      'discount': '0.00',
      'tax_amount': '0.00',
      'net_amount': '20.00',
      'occurred_at': '2026-01-01T00:00:00Z',
      'sync_state': 'pending',
    });
    final e = await store.enqueue(
      db,
      entity: 'sale',
      op: 'create',
      entityId: id,
      scope: scope,
      payload: {
        'shop': 's1',
        'items': [
          {'product_id': 'p1', 'quantity': '2'},
        ],
      },
    );
    await stock.recompute(db, 'p1', 's1');
    return e;
  }

  Future<void> rejectAsServer(OutboxEntry e) async {
    await store.applyResult(
      db,
      e.mutationId,
      status: OutboxStatus.rejected,
      code: 'insufficient_stock',
      message: 'nope',
    );
    await db.update(
      'sales',
      {'sync_state': 'rejected', 'error_code': 'insufficient_stock'},
      where: 'id = ?',
      whereArgs: [e.entityId],
    );
    await stock.recompute(db, 'p1', 's1');
  }

  group('I1: discard never races the push', () {
    test(
      'a row claimed by a sync run is refused; row and sale intact',
      () async {
        final e = await sale('sale1');
        final claimed = await store.claimBatch(scope: scope);
        expect(claimed.single.mutationId, e.mutationId);

        expect(await store.discard(e.mutationId), DiscardOutcome.sending);
        expect(await outboxRows(e.mutationId), 1);
        expect(await saleState('sale1'), 'pending');
        expect(await qty(), 8.0);
      },
    );

    test('a row the server already confirmed is refused', () async {
      final e = await sale('sale1');
      await store.applyResult(db, e.mutationId, status: OutboxStatus.done);
      expect(await store.discard(e.mutationId), DiscardOutcome.alreadySynced);
      expect(await outboxRows(e.mutationId), 1);
      expect(await saleState('sale1'), 'pending');
    });

    test('an unknown row reports notFound', () async {
      expect(await store.discard('nope'), DiscardOutcome.notFound);
    });
  });

  group('I2: stock stays exact', () {
    test('discarding a pending sale restores the local quantity and marks '
        'the sale rejected/discarded', () async {
      final e = await sale('sale1');
      expect(await qty(), 8.0);

      expect(await store.discard(e.mutationId), DiscardOutcome.discarded);

      expect(await outboxRows(e.mutationId), 0);
      expect(await qty(), 10.0);
      final row = (await db.query('sales', where: "id = 'sale1'")).single;
      expect(row['sync_state'], 'rejected');
      expect(row['error_code'], 'discarded');
      final p = (await db.query('products', where: "id = 'p1'")).single;
      expect(p['stock_level'], 10.0);
    });

    test('discarding a pending stock.remove restores the quantity', () async {
      final e = await store.enqueue(
        db,
        entity: 'stock',
        op: 'remove',
        entityId: 'st-p1-s1',
        scope: scope,
        payload: {'product_id': 'p1', 'shop_id': 's1', 'delta': '3'},
      );
      await stock.recompute(db, 'p1', 's1');
      expect(await qty(), 7.0);
      expect(await store.discard(e.mutationId), DiscardOutcome.discarded);
      expect(await qty(), 10.0);
    });

    test('discarding a pending inbound.create removes its +quantity', () async {
      final e = await store.enqueue(
        db,
        entity: 'inbound',
        op: 'create',
        entityId: 'in1',
        scope: scope,
        payload: {
          'shop_id': 's1',
          'items': [
            {'product_id': 'p1', 'quantity': '5'},
          ],
        },
      );
      await stock.recompute(db, 'p1', 's1');
      expect(await qty(), 15.0);
      expect(await store.discard(e.mutationId), DiscardOutcome.discarded);
      expect(await qty(), 10.0);
    });

    test('dependents rejected by a discard lose their stock effect', () async {
      final parent = await store.enqueue(
        db,
        entity: 'product',
        op: 'create',
        entityId: 'p1',
        scope: scope,
        payload: const {},
      );
      final child = await store.enqueue(
        db,
        entity: 'stock',
        op: 'add',
        entityId: 'st-p1-s1',
        scope: scope,
        dependsOn: const ['p1'],
        payload: {'product_id': 'p1', 'shop_id': 's1', 'delta': '4'},
      );
      expect(child.status, OutboxStatus.blocked);
      await stock.recompute(db, 'p1', 's1');
      expect(await qty(), 14.0);
      expect(await store.discard(parent.mutationId), DiscardOutcome.discarded);
      expect(await qty(), 10.0);
    });

    test('retrying a rejected sale puts it back to pending and counts its '
        'stock effect exactly once', () async {
      final e = await sale('sale1');
      await rejectAsServer(e);
      expect(await qty(), 10.0); // a rejected sale has no stock effect

      expect(await store.retryRejected(e.mutationId), isTrue);

      expect(await qty(), 8.0);
      final row = (await db.query('sales', where: "id = 'sale1'")).single;
      expect(row['sync_state'], 'pending');
      expect(row['error_code'], isNull);

      // A second retry is a no-op (not rejected any more).
      expect(await store.retryRejected(e.mutationId), isFalse);
      expect(await qty(), 8.0);
    });
  });

  group('M4: one transaction', () {
    test('if the outbox delete fails, the sale is NOT marked rejected and '
        'stock is unchanged', () async {
      final e = await sale('sale1');
      await db.execute(
        'CREATE TRIGGER t_fail BEFORE DELETE ON outbox '
        "BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );
      await expectLater(store.discard(e.mutationId), throwsA(anything));
      expect(await saleState('sale1'), 'pending');
      expect(await outboxRows(e.mutationId), 1);
      expect(await qty(), 8.0);
    });

    test('discardAll marks the scope sales rejected, skips claimed rows and '
        'recomputes stock', () async {
      final a = await sale('sale1');
      await store.claimBatch(scope: scope); // sale1 is now being sent
      final b = await sale('sale2');
      expect(await qty(), 6.0);

      expect(await store.discardAll(scope: scope), 1);

      expect(await outboxRows(a.mutationId), 1);
      expect(await outboxRows(b.mutationId), 0);
      expect(await saleState('sale1'), 'pending');
      expect(await saleState('sale2'), 'rejected');
      expect(await qty(), 8.0);
    });
  });

  group('fix round 1: single-row scope check', () {
    test(
      'a row of another scope is refused when a current scope is set',
      () async {
        final e = await store.enqueue(
          db,
          entity: 'stock',
          op: 'add',
          entityId: 'st-p1-s1',
          scope: 'u2|t1',
          payload: {'product_id': 'p1', 'shop_id': 's1', 'delta': '1'},
        );
        expect(
          await store.discard(e.mutationId, currentScope: scope),
          DiscardOutcome.otherScope,
        );
        expect(await outboxRows(e.mutationId), 1);
        expect(
          await store.discard(e.mutationId, currentScope: 'u2|t1'),
          DiscardOutcome.discarded,
        );
      },
    );
  });
}
