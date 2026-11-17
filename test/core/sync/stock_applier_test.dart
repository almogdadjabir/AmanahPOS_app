import 'dart:convert';

import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/core/sync/appliers/stock_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/features/inventory/data/local/stock_local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/engine_harness.dart';
import 'support/test_db.dart';

const _p = 'prod1';
const _s = 'shop1';
const _scope = 'u1|t1';
const _sid = '8c1f0a52-0000-4000-8000-000000000001';

void main() {
  late OfflineDb odb;
  late Database db;
  late OutboxStore outbox;
  late StockApplier applier;
  const store = StockLocalStore();

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
    outbox = OutboxStore(odb);
    applier = StockApplier();
    await db.insert('products', {
      'id': _p,
      'name': 'P',
      'stock_level': 0.0,
      'json': '{"id":"$_p","stock_level":0.0}',
    });
  });

  tearDown(() async {
    await db.close();
  });

  Future<OutboxEntry> enqueueStock(
    String op,
    String delta, {
    OutboxStatus status = OutboxStatus.pending,
    String product = _p,
    String shop = _s,
  }) async {
    final e = await outbox.enqueue(
      db,
      entity: 'stock',
      op: op,
      entityId: '$product:$shop',
      payload: {'product_id': product, 'shop_id': shop, 'delta': delta},
      scope: _scope,
    );
    if (status != OutboxStatus.pending) {
      await db.update(
        'outbox',
        {'status': status.name},
        where: 'mutation_id = ?',
        whereArgs: [e.mutationId],
      );
      e.status = status;
    }
    return e;
  }

  Future<OutboxEntry> enqueueSale(
    List<Map<String, dynamic>> items, {
    String shop = _s,
    OutboxStatus status = OutboxStatus.pending,
  }) async {
    final e = await outbox.enqueue(
      db,
      entity: 'sale',
      op: 'create',
      entityId: 'sale-${items.length}-${DateTime.now().microsecondsSinceEpoch}',
      payload: {'shop': shop, 'items': items},
      scope: _scope,
    );
    if (status != OutboxStatus.pending) {
      await db.update(
        'outbox',
        {'status': status.name},
        where: 'mutation_id = ?',
        whereArgs: [e.mutationId],
      );
    }
    return e;
  }

  PullChange pull(String quantity, {String op = 'upsert'}) => PullChange(
    seq: 1,
    entity: 'stock',
    op: op,
    id: _sid,
    data: op == 'delete'
        ? null
        : {'product_id': _p, 'shop_id': _s, 'quantity': quantity},
  );

  Future<void> doApply(PullChange c) =>
      db.transaction((txn) => applier.apply(txn, c));

  Future<void> doPush(OutboxEntry sent, PushResult r) =>
      db.transaction((txn) => applier.onPushResult(txn, sent, r));

  Future<Map<String, Object?>> stockRow() async {
    final r = await db.query(
      'stock',
      where: 'product_id = ? AND shop_id = ?',
      whereArgs: [_p, _s],
    );
    return r.single;
  }

  Future<double> productLevel() async =>
      ((await db.query(
                'products',
                where: 'id = ?',
                whereArgs: [_p],
              )).single['stock_level']
              as num)
          .toDouble();

  PushResult result(
    OutboxEntry e,
    PushStatus status, {
    String? after,
    String? code,
  }) => PushResult(
    mutationId: e.mutationId,
    status: status,
    code: code,
    stockAfter: after == null
        ? const []
        : [StockAfter(productId: _p, shopId: _s, quantity: after)],
  );

  Future<void> markDone(OutboxEntry e, OutboxStatus st) => db.update(
    'outbox',
    {'status': st.name},
    where: 'mutation_id = ?',
    whereArgs: [e.mutationId],
  );

  test('applier metadata', () {
    expect(applier.entity, 'stock');
    expect(applier.skipWhenLocalPending, isFalse);
    expect(applier.tables, {'stock', 'products'});
  });

  group('pull', () {
    test('no pending: quantity equals pulled value', () async {
      await doApply(pull('10'));
      final r = await stockRow();
      expect(r['base_quantity'], '10');
      expect((r['quantity'] as num).toDouble(), 10.0);
      expect(await productLevel(), 10.0);
    });

    test('pending -3: pulled 10 shows 7', () async {
      await enqueueStock('remove', '3');
      await doApply(pull('10'));
      final r = await stockRow();
      expect(r['base_quantity'], '10');
      expect((r['quantity'] as num).toDouble(), 7.0);
      expect(await productLevel(), 7.0);
    });

    test('products.json stock_level and stock.json stay in sync', () async {
      await enqueueStock('remove', '3');
      await doApply(pull('10'));
      final pj = (await db.query('products')).single['json'] as String;
      expect(pj, contains('"stock_level":7.0'));
      final sj = (await stockRow())['json'] as String;
      expect(sj, contains('"quantity":7.0'));
    });

    test('pending states pending|inflight|blocked count; done|rejected do '
        'not', () async {
      await enqueueStock('remove', '1');
      await enqueueStock('remove', '2', status: OutboxStatus.inflight);
      await enqueueStock('remove', '4', status: OutboxStatus.blocked);
      await enqueueStock('remove', '8', status: OutboxStatus.done);
      await enqueueStock('remove', '16', status: OutboxStatus.rejected);
      await doApply(pull('10'));
      expect((await stockRow())['quantity'], 3.0);
    });

    test(
      'delete with UUID id and no data removes the row, product 0',
      () async {
        await doApply(pull('10'));
        await doApply(pull('0', op: 'delete'));
        expect(await db.query('stock'), isEmpty);
        expect(await productLevel(), 0.0);
      },
    );

    test(
      'delete recomputes products.stock_level as sum of remaining shops',
      () async {
        await doApply(pull('10'));
        await doApply(
          const PullChange(
            seq: 2,
            entity: 'stock',
            op: 'upsert',
            id: 'uuid-2',
            data: {'product_id': _p, 'shop_id': 'shop2', 'quantity': '4'},
          ),
        );
        expect(await productLevel(), 14.0);
        await doApply(pull('0', op: 'delete'));
        expect(await productLevel(), 4.0);
        expect((await db.query('stock')).single['shop_id'], 'shop2');
      },
    );

    test('upsert inserts a new row with the server id', () async {
      await doApply(pull('10'));
      expect((await stockRow())['id'], _sid);
    });

    test('legacy-id row adopts the server id (no UNIQUE violation)', () async {
      await db.insert('stock', {
        'id': '$_p-$_s',
        'product_id': _p,
        'shop_id': _s,
        'quantity': 1.0,
        'base_quantity': '1',
        'json': '{}',
      });
      await doApply(pull('10'));
      final rows = await db.query('stock');
      expect(rows, hasLength(1));
      expect(rows.single['id'], _sid);
      expect(rows.single['base_quantity'], '10');
    });

    test('malformed quantity is skipped, does not throw', () async {
      await doApply(pull('10'));
      await doApply(pull('abc'));
      expect((await stockRow())['base_quantity'], '10');
    });

    test('second pull replaces base (idempotent on replay)', () async {
      await enqueueStock('add', '2');
      await doApply(pull('10'));
      await doApply(pull('10'));
      await doApply(pull('4'));
      final r = await stockRow();
      expect(r['base_quantity'], '4');
      expect((r['quantity'] as num).toDouble(), 6.0);
    });
  });

  // Same rule as the BE `StockLevel.is_low_stock` (REST rows):
  // quantity <= product.min_stock_level, so out-of-stock rows count as low.
  group('is_low_stock (BE rule qty <= min)', () {
    Future<bool?> lowAfterPull(String q, {int min = 5}) async {
      await db.update(
        'products',
        {'json': '{"id":"$_p","stock_level":0.0,"min_stock_level":$min}'},
        where: 'id = ?',
        whereArgs: [_p],
      );
      await doApply(pull(q));
      final sj = (await stockRow())['json'] as String;
      return (jsonDecode(sj) as Map<String, dynamic>)['is_low_stock'] as bool?;
    }

    test('0 <= min: low (out-of-stock counts as low)', () async {
      expect(await lowAfterPull('0'), isTrue);
    });
    test('negative: low', () async {
      expect(await lowAfterPull('-2'), isTrue);
    });
    test('equal to min: low', () async {
      expect(await lowAfterPull('5'), isTrue);
    });
    test('above min: not low', () async {
      expect(await lowAfterPull('5.001'), isFalse);
    });
    test('min 0 and qty 0: low (BE: 0 <= 0)', () async {
      expect(await lowAfterPull('0', min: 0), isTrue);
    });

    // F8: a missing / non-numeric min never keeps a stale value; the legacy
    // rule qty <= (min ?? 0) applies; a numeric string is parsed.
    Future<bool?> lowWithMinJson(String q, String minJson) async {
      await db.update(
        'products',
        {'json': '{"id":"$_p","stock_level":0.0$minJson}'},
        where: 'id = ?',
        whereArgs: [_p],
      );
      await doApply(pull(q));
      final sj = (await stockRow())['json'] as String;
      return (jsonDecode(sj) as Map<String, dynamic>)['is_low_stock'] as bool?;
    }

    test('missing min after a low value: recomputed with min 0', () async {
      expect(await lowAfterPull('0'), isTrue); // stale true would stay
      expect(await lowWithMinJson('3', ''), isFalse);
      expect(await lowWithMinJson('0', ''), isTrue);
    });
    test('null / non-numeric min: legacy rule qty <= 0', () async {
      expect(await lowAfterPull('0'), isTrue);
      expect(await lowWithMinJson('2', ',"min_stock_level":null'), isFalse);
      expect(await lowWithMinJson('-1', ',"min_stock_level":"abc"'), isTrue);
    });
    test('numeric-string min is parsed', () async {
      expect(await lowWithMinJson('4', ',"min_stock_level":"5.000"'), isTrue);
      expect(await lowWithMinJson('6', ',"min_stock_level":"5.000"'), isFalse);
    });
  });

  group('pending delta sum', () {
    test('add +delta, remove -abs(delta), adjust signed', () async {
      await enqueueStock('add', '5');
      await enqueueStock('remove', '-2'); // abs -> -2
      await enqueueStock('remove', '1');
      await enqueueStock('adjust', '-4');
      await enqueueStock('adjust', '0.5');
      expect(await store.pendingDeltaSum(db, _p, _s), '-1.5');
    });

    test('count and transfer rows are ignored without crashing', () async {
      await enqueueStock('count', '9');
      await enqueueStock('transfer', '3');
      await enqueueStock('add', '1');
      expect(await store.pendingDeltaSum(db, _p, _s), '1');
    });

    test('0.1 x3 deltas sum exactly 0.3', () async {
      await enqueueStock('add', '0.1');
      await enqueueStock('add', '0.1');
      await enqueueStock('add', '0.1');
      expect(await store.pendingDeltaSum(db, _p, _s), '0.3');
      await doApply(pull('0.2'));
      final r = await stockRow();
      expect(r['base_quantity'], '0.2');
      expect(r['quantity'], 0.5);
    });

    test('other product or shop rows are not counted', () async {
      await enqueueStock('remove', '1', product: 'other');
      await enqueueStock('remove', '1', shop: 'shop2');
      expect(await store.pendingDeltaSum(db, _p, _s), '0');
    });

    test('pending sale.create counts items, ignores custom lines and other '
        'shops', () async {
      await enqueueSale([
        {'product_id': _p, 'quantity': '2.000', 'unit_price': '5.00'},
        {'custom': true, 'name': 'Misc', 'quantity': '9', 'unit_price': '1'},
        {'product_id': 'other', 'quantity': '4', 'unit_price': '1'},
      ]);
      await enqueueSale([
        {'product_id': _p, 'quantity': '1', 'unit_price': '5.00'},
      ], shop: 'shop2');
      await enqueueSale([
        {'product_id': _p, 'quantity': '7', 'unit_price': '5.00'},
      ], status: OutboxStatus.done);
      await enqueueStock('remove', '1');
      expect(await store.pendingDeltaSum(db, _p, _s), '-3');
      await doApply(pull('10'));
      expect((await stockRow())['quantity'], 7.0);
    });
  });

  group('push results', () {
    test('applied: stock_after becomes base; other pending -1 -> 11', () async {
      await doApply(pull('10'));
      final sent = await enqueueStock('remove', '3');
      await enqueueStock('remove', '1');
      await markDone(sent, OutboxStatus.done); // engine marks done first
      await doPush(sent, result(sent, PushStatus.applied, after: '12'));
      final r = await stockRow();
      expect(r['base_quantity'], '12');
      expect((r['quantity'] as num).toDouble(), 11.0);
      expect(await productLevel(), 11.0);
    });

    test('duplicate with stale stock_after leaves base and quantity '
        'unchanged', () async {
      await enqueueStock('remove', '1');
      await doApply(pull('12'));
      final sent = await enqueueStock('remove', '3');
      await markDone(sent, OutboxStatus.done);
      final before = await stockRow();
      await doPush(sent, result(sent, PushStatus.duplicate, after: '2'));
      final after = await stockRow();
      expect(after['base_quantity'], before['base_quantity']);
      expect(after['quantity'], before['quantity']);
      expect(after['base_quantity'], '12');
      expect(after['quantity'], 11.0);
      expect(await productLevel(), 11.0);
    });

    // Found by the Task 12 convergence test: the server applied the
    // remove, its response was lost, the next pull brought the server level
    // (already WITH the remove) while the row was still pending, so the
    // remove was counted twice. The replay answers `duplicate`: the row is
    // done now, and the displayed stock must drop the double count (base
    // untouched: the stale stock_after is never used).
    test('duplicate after the server level was already pulled: displayed '
        'stock no longer double counts the delta', () async {
      await doApply(pull('10'));
      final sent = await enqueueStock('remove', '3');
      await doApply(pull('7')); // server already applied it
      expect((await stockRow())['quantity'], 4.0); // 7 - 3 pending
      await markDone(sent, OutboxStatus.done);
      await doPush(sent, result(sent, PushStatus.duplicate, after: '7'));
      final r = await stockRow();
      expect(r['base_quantity'], '7');
      expect((r['quantity'] as num).toDouble(), 7.0);
      expect(await productLevel(), 7.0);
    });

    test('rejected stock.remove drops its delta', () async {
      await doApply(pull('10'));
      final sent = await enqueueStock('remove', '3');
      // simulate the optimistic local state: 10 - 3
      await db.update('stock', {'quantity': 7.0});
      await markDone(sent, OutboxStatus.rejected);
      await doPush(
        sent,
        result(sent, PushStatus.rejected, code: 'validation_error'),
      );
      final r = await stockRow();
      expect(r['base_quantity'], '10');
      expect((r['quantity'] as num).toDouble(), 10.0);
      expect(await productLevel(), 10.0);
    });

    test('applied without stock_after changes nothing', () async {
      await doApply(pull('10'));
      final sent = await enqueueStock('remove', '3');
      await markDone(sent, OutboxStatus.done);
      await doPush(sent, result(sent, PushStatus.applied));
      expect((await stockRow())['base_quantity'], '10');
    });
  });

  test('engine ordering: the sent row is already done when onPushResult '
      'runs, only applied re-bases', () async {
    final h = await EngineHarness.create();
    addTearDown(h.dispose);
    final seenStatuses = <String>[];
    final spy = _SpyApplier(applier, seenStatuses);
    h.registry.register(spy);
    await h.db.insert('products', {
      'id': _p,
      'name': 'P',
      'stock_level': 0.0,
      'json': '{}',
    });
    // Local state: base 10, two pending removals (same entity id, so the
    // engine sends them one at a time in order).
    final a = await h.outbox.enqueue(
      h.db,
      entity: 'stock',
      op: 'remove',
      entityId: '$_p:$_s',
      payload: {'product_id': _p, 'shop_id': _s, 'delta': '3'},
      scope: EngineHarness.scope,
    );
    final b = await h.outbox.enqueue(
      h.db,
      entity: 'stock',
      op: 'remove',
      entityId: '$_p:$_s',
      payload: {'product_id': _p, 'shop_id': _s, 'delta': '1'},
      scope: EngineHarness.scope,
    );
    await h.db.transaction((t) => applier.apply(t, pull('10')));
    expect(
      ((await h.db.query('stock')).single['quantity'] as num).toDouble(),
      6.0,
    );
    h.transport.scripted[a.mutationId] = result(
      a,
      PushStatus.applied,
      after: '12',
    );
    h.transport.scripted[b.mutationId] = PushResult(
      mutationId: b.mutationId,
      status: PushStatus.retry,
    );
    final engine = h.build();
    await engine.syncNow();
    expect(seenStatuses.first, 'done', reason: 'row a is done at callback');
    final r = (await h.db.query('stock')).single;
    expect(r['base_quantity'], '12');
    expect((r['quantity'] as num).toDouble(), 11.0);
  });

  group('legacy bootstrap writers preserve pending deltas', () {
    test(
      'saveStockToCache: base = server, quantity = base + pending',
      () async {
        await enqueueStock('remove', '3');
        await enqueueSale([
          {'product_id': _p, 'quantity': '1.5', 'unit_price': '1'},
        ]);
        await OfflineLocalCache(odb).saveStockToCache([
          const StockData(id: 'st1', product: _p, shop: _s, quantity: '10'),
        ]);
        final r = await stockRow();
        expect(r['base_quantity'], '10');
        expect((r['quantity'] as num).toDouble(), 5.5);
        expect(await productLevel(), 5.5);
      },
    );

    test('saveStockToCache with no pending: quantity = server', () async {
      await OfflineLocalCache(odb).saveStockToCache([
        const StockData(id: 'st1', product: _p, shop: _s, quantity: '0.3'),
      ]);
      final r = await stockRow();
      expect(r['base_quantity'], '0.3');
      expect(r['quantity'], 0.3);
    });
  });

  group('upgrade and bootstrap', () {
    test('v7 -> v8 adds base_quantity and backfills from quantity', () async {
      sqfliteFfiInit();
      final old = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      addTearDown(old.close);
      await old.execute('''
        CREATE TABLE stock (
          id TEXT PRIMARY KEY, product_id TEXT NOT NULL, shop_id TEXT NOT NULL,
          quantity REAL NOT NULL DEFAULT 0, json TEXT NOT NULL, updated_at TEXT,
          UNIQUE(product_id, shop_id))''');
      await old.insert('stock', {
        'id': 'a',
        'product_id': 'p1',
        'shop_id': 's',
        'quantity': 12.5,
        'json': '{}',
      });
      await old.insert('stock', {
        'id': 'b',
        'product_id': 'p2',
        'shop_id': 's',
        'quantity': 0.0,
        'json': '{}',
      });
      await old.insert('stock', {
        'id': 'c',
        'product_id': 'p3',
        'shop_id': 's',
        'quantity': -2.0,
        'json': '{}',
      });
      await OfflineDb.onUpgrade(old, 7, 8);
      await OfflineDb.onUpgrade(old, 7, 8); // idempotent
      final rows = {
        for (final r in await old.query('stock')) r['id']: r['base_quantity'],
      };
      expect(rows, {'a': '12.5', 'b': '0', 'c': '-2'});
    });

    test('fresh onCreate has base_quantity', () async {
      final cols = await db.rawQuery('PRAGMA table_info(stock)');
      expect(cols.any((c) => c['name'] == 'base_quantity'), isTrue);
      expect(OfflineDb.schemaVersion, greaterThanOrEqualTo(8));
    });
  });
}

/// Records the outbox status of the sent row at callback time, then delegates.
class _SpyApplier extends StockApplier {
  _SpyApplier(this._inner, this._seen);
  final StockApplier _inner;
  final List<String> _seen;

  @override
  String get entity => 'stock';

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
    await _inner.onPushResult(txn, sent, result);
  }
}
