import 'package:flutter_test/flutter_test.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';

import 'support/fake_sync_server.dart';

int _n = 0;

OutboxEntry m(
  String entity,
  String op,
  String id,
  Map<String, dynamic> payload, {
  int? seq,
  String? mutationId,
  int? baseVersion,
}) => OutboxEntry(
  seq: seq ?? ++_n,
  mutationId: mutationId ?? 'mut-${++_n}',
  entity: entity,
  op: op,
  entityId: id,
  baseVersion: baseVersion,
  occurredAt: DateTime.utc(2026, 11, 16),
  payload: payload,
);

Future<PushResponse> push(FakeSyncServer s, List<OutboxEntry> e) =>
    s.push(deviceId: s.deviceId, appVersion: '1.0.0', mutations: e);

void main() {
  late FakeSyncServer s;
  setUp(() => s = FakeSyncServer());

  test('replay of same mutation_id returns duplicate, one row', () async {
    final e = m('product', 'create', 'p1', {'name': 'A'}, mutationId: 'x');
    final r1 = await push(s, [e]);
    final r2 = await push(s, [e]);
    expect(r1.results.single.status, PushStatus.applied);
    expect(r2.results.single.status, PushStatus.duplicate);
    expect(r2.results.single.version, r1.results.single.version);
    expect(s.tables['product']!.length, 1);
    expect(s.feed.length, 1);
  });

  test('applies in seq order regardless of list order', () async {
    final upd = m('product', 'update', 'p1', {'name': 'B'}, seq: 2);
    final cre = m('product', 'create', 'p1', {'name': 'A'}, seq: 1);
    final r = await push(s, [upd, cre]);
    expect(r.results.map((e) => e.status), [
      PushStatus.applied,
      PushStatus.applied,
    ]);
    expect(r.results.first.mutationId, cre.mutationId);
    expect(s.tables['product']!['p1']!['name'], 'B');
    expect(s.tables['product']!['p1']!['version'], 2);
  });

  test('dropResponseAfterApply applies yet throws timeout', () async {
    s.dropResponseAfterApply = 1;
    final e = m('product', 'create', 'p1', {'name': 'A'});
    await expectLater(
      push(s, [e]),
      throwsA(
        isA<SyncTransportException>().having(
          (x) => x.kind,
          'kind',
          SyncTransportKind.timeout,
        ),
      ),
    );
    expect(s.tables['product']!.length, 1);
    final r = await push(s, [e]);
    expect(r.results.single.status, PushStatus.duplicate);
    expect(s.tables['product']!.length, 1);
  });

  test('down throws network; failNextWith throws once', () async {
    s.down = true;
    await expectLater(
      s.ping(),
      throwsA(
        isA<SyncTransportException>().having(
          (x) => x.kind,
          'k',
          SyncTransportKind.network,
        ),
      ),
    );
    s.down = false;
    s.failNextWith = 'tokenExpired';
    await expectLater(
      s.pull(),
      throwsA(
        isA<SyncTransportException>().having(
          (x) => x.kind,
          'k',
          SyncTransportKind.tokenExpired,
        ),
      ),
    );
    expect((await s.ping()).ok, isTrue);
  });

  test('pull paging with cursor and hasMore', () async {
    await push(s, [
      for (var i = 0; i < 5; i++) m('category', 'create', 'c$i', {'n': '$i'}),
    ]);
    final p1 = await s.pull(limit: 2);
    expect(p1.changes.length, 2);
    expect(p1.hasMore, isTrue);
    final p2 = await s.pull(cursor: p1.nextCursor, limit: 2);
    expect(p2.changes.map((c) => c.id), ['c2', 'c3']);
    expect(p2.hasMore, isTrue);
    final p3 = await s.pull(cursor: p2.nextCursor, limit: 2);
    expect(p3.changes.map((c) => c.id), ['c4']);
    expect(p3.hasMore, isFalse);
    final p4 = await s.pull(cursor: p3.nextCursor);
    expect(p4.changes, isEmpty);
    expect(p4.nextCursor, p3.nextCursor);
  });

  test('device views share state and carry origin', () async {
    final a = s.forDevice('A');
    final b = s.forDevice('B');
    await push(a, [
      m('product', 'create', 'p1', {'name': 'A'}),
    ]);
    final pulled = await b.pull();
    expect(pulled.changes.single.originDeviceId, 'A');
    expect(b.tables['product']!.containsKey('p1'), isTrue);
  });

  test('stock +5 from A then -3 from B -> 2, stockAfter returned', () async {
    final a = s.forDevice('A');
    final b = s.forDevice('B');
    await push(a, [
      m('stock', 'add', 's1', {
        'product_id': 'p1',
        'shop_id': 'sh',
        'delta': '5',
      }),
    ]);
    final r = await push(b, [
      m('stock', 'remove', 's2', {
        'product_id': 'p1',
        'shop_id': 'sh',
        'delta': '-3',
      }),
    ]);
    expect(r.results.single.stockAfter.single.quantity, '2');
    expect(s.stockQuantity('p1', 'sh'), '2');
  });

  test('decimal-safe stock arithmetic', () async {
    await push(s, [
      m('stock', 'add', 's1', {
        'product_id': 'p',
        'shop_id': 'sh',
        'delta': '0.1',
      }),
      m('stock', 'add', 's2', {
        'product_id': 'p',
        'shop_id': 'sh',
        'delta': '0.2',
      }),
    ]);
    expect(s.stockQuantity('p', 'sh'), '0.3');
  });

  test('sale create always applied, negative stock warns', () async {
    final r = await push(s, [
      m('sale', 'create', 'sale1', {
        'shop_id': 'sh',
        'items': [
          {'product_id': 'p1', 'quantity': '2'},
        ],
      }),
    ]);
    final x = r.results.single;
    expect(x.status, PushStatus.applied);
    expect(x.warnings, contains('negative_stock'));
    expect(x.stockAfter.single.quantity, '-2');
  });

  test('dependency_failed after rejected create; unique barcode', () async {
    await push(s, [
      m('product', 'create', 'p1', {'barcode': '123'}),
    ]);
    final r = await push(s, [
      m('product', 'create', 'p2', {'barcode': '123'}),
      m('sale', 'create', 'sale1', {
        'shop_id': 'sh',
        'items': [
          {'product_id': 'p2', 'quantity': '1'},
        ],
      }),
      m('stock', 'add', 's', {
        'product_id': 'p2',
        'shop_id': 'sh',
        'delta': '1',
      }),
    ]);
    expect(r.results[0].status, PushStatus.rejected);
    expect(r.results[0].code, 'conflict_unique');
    expect(r.results[0].serverState!['id'], 'p1');
    expect(r.results[1].code, 'dependency_failed');
    expect(r.results[2].code, 'dependency_failed');
    expect(s.tables['sale'] ?? {}, isEmpty);
  });

  test(
    'update of deleted entity -> entity_deleted; stale base merges',
    () async {
      await push(s, [
        m('product', 'create', 'p1', {'name': 'A'}),
        m('product', 'update', 'p1', {'name': 'B'}),
      ]);
      final r = await push(s, [
        m('product', 'update', 'p1', {'price': '9'}, baseVersion: 1),
      ]);
      expect(r.results.single.status, PushStatus.applied);
      expect(r.results.single.merged, isTrue);
      expect(r.results.single.warnings, isNot(contains('merged')));
      expect(r.results.single.serverState!['name'], 'B');
      expect(r.results.single.serverState!['price'], '9');
      await push(s, [m('product', 'delete', 'p1', {})]);
      final r2 = await push(s, [
        m('product', 'update', 'p1', {'name': 'C'}),
      ]);
      expect(r2.results.single.status, PushStatus.rejected);
      expect(r2.results.single.code, 'entity_deleted');
      final pull = await s.pull();
      expect(pull.changes.last.op, 'delete');
    },
  );

  test('ping knobs and fullResyncRequired', () async {
    s.minAppVersion = '2.0.0';
    s.capabilities = {'push'};
    final p = await s.ping();
    expect(p.minAppVersion, '2.0.0');
    expect(p.capabilities, {'push'});
    s.fullResyncRequired = true;
    expect((await s.pull()).fullResyncRequired, isTrue);
  });

  test('flakyRate 1.0 always fails before applying', () async {
    s.flakyRate = 1.0;
    await expectLater(
      push(s, [m('product', 'create', 'p1', {})]),
      throwsA(isA<SyncTransportException>()),
    );
    expect(s.tables['product'] ?? {}, isEmpty);
  });

  test('lostResponseRate: applied then thrown; replay is duplicate', () async {
    s.lostResponseRate = 0.5;
    final lost = <OutboxEntry>[];
    for (var i = 0; i < 30; i++) {
      final e = m('category', 'create', 'lc$i', {});
      try {
        await push(s, [e]);
      } on SyncTransportException catch (x) {
        expect(x.kind, SyncTransportKind.timeout);
        expect(s.tables['category']!.containsKey('lc$i'), isTrue);
        lost.add(e);
      }
    }
    expect(lost, isNotEmpty);
    expect(lost.length, lessThan(30));
    s.lostResponseRate = 0;
    final r = await push(s, lost);
    expect(r.results.every((x) => x.status == PushStatus.duplicate), isTrue);
  });

  test('flakyRate throws timeout or network, seeded', () async {
    s.flakyRate = 1.0;
    final kinds = <SyncTransportKind>{};
    for (var i = 0; i < 20; i++) {
      try {
        await s.pull();
      } on SyncTransportException catch (x) {
        kinds.add(x.kind);
      }
    }
    expect(kinds, {SyncTransportKind.timeout, SyncTransportKind.network});
  });

  test('malformed mutations are isolated, nothing half-applied', () async {
    final r = await push(s, [
      m('stock', 'add', 'g1', {
        'product_id': 'p',
        'shop_id': 'a',
        'delta': '4',
      }),
      m('sale', 'create', 'bad', {
        'shop_id': 'a',
        'items': [
          {'product_id': 'p', 'quantity': '1'},
          {'product_id': 'p', 'quantity': 'abc'},
        ],
      }),
      m('stock', 'transfer', 'bt', {
        'product_id': 'p',
        'from_shop': 'a',
        'quantity': '2',
      }),
      m('stock', 'add', 'g2', {
        'product_id': 'p',
        'shop_id': 'a',
        'delta': '1',
      }),
    ]);
    expect(r.results.map((e) => e.status), [
      PushStatus.applied,
      PushStatus.rejected,
      PushStatus.rejected,
      PushStatus.applied,
    ]);
    expect(r.results[1].code, 'validation_error');
    expect(r.results[2].code, 'validation_error');
    expect(s.stockQuantity('p', 'a'), '5');
    expect(s.stockQuantity('p', 'b'), '0');
  });

  test('replay of rejected returns same rejected result', () async {
    await push(s, [
      m('product', 'create', 'p1', {'barcode': '1'}),
    ]);
    final e = m('product', 'create', 'p2', {'barcode': '1'}, mutationId: 'rj');
    final r1 = (await push(s, [e])).results.single;
    final r2 = (await push(s, [e])).results.single;
    expect(r2.status, PushStatus.rejected);
    expect(r2.code, r1.code);
    expect(r2.message, r1.message);
  });

  test('fault knobs are per device view', () async {
    final a = s.forDevice('A');
    final b = s.forDevice('B');
    a.down = true;
    await expectLater(a.ping(), throwsA(isA<SyncTransportException>()));
    expect((await b.ping()).ok, isTrue);
    s.minAppVersion = '3.0.0';
    expect((await b.ping()).minAppVersion, '3.0.0');
    expect(a.down, isTrue);
    expect(s.down, isFalse);
  });

  test('injectable clock and clockSkew', () async {
    final t = DateTime.utc(2026, 1, 1, 12);
    final c = FakeSyncServer(now: () => t);
    expect((await c.ping()).serverTime, t);
    c.clockSkew = const Duration(hours: 3);
    expect((await c.ping()).serverTime, t.add(const Duration(hours: 3)));
    expect((await c.pull()).serverTime, t.add(const Duration(hours: 3)));
    expect((await push(c, [])).serverTime, t.add(const Duration(hours: 3)));
  });

  test('pull rejects bad limit and garbage cursor', () async {
    await expectLater(s.pull(limit: 0), throwsArgumentError);
    await expectLater(s.pull(cursor: '%%%'), throwsFormatException);
    await expectLater(
      s.pull(cursor: 'bm90LWEtY3Vyc29y'),
      throwsFormatException,
    );
  });

  test('sale.create idempotent by sale id across mutation ids', () async {
    Map<String, dynamic> sale() => {
      'shop_id': 'a',
      'customer_id': 'gone',
      'items': [
        {'product_id': 'p', 'quantity': '2'},
      ],
    };
    final r1 = await push(s, [m('sale', 'create', 'S', sale())]);
    final r2 = await push(s, [m('sale', 'create', 'S', sale())]);
    expect(r1.results.single.status, PushStatus.applied);
    expect(r2.results.single.status, PushStatus.duplicate);
    expect(s.stockQuantity('p', 'a'), '-2');
  });

  test('sale with missing customer nulls customer_id', () async {
    await push(s, [m('customer', 'create', 'c1', {})]);
    await push(s, [m('customer', 'delete', 'c1', {})]);
    final r = await push(s, [
      m('sale', 'create', 'S', {
        'shop_id': 'a',
        'customer_id': 'c1',
        'items': <Map<String, dynamic>>[],
      }),
    ]);
    expect(r.results.single.warnings, contains('customer_missing'));
    expect(s.tables['sale']!['S']!['customer_id'], isNull);
  });

  test('stock deltas commute across orders and interleaving', () async {
    Map<String, dynamic> d(String v) => {
      'product_id': 'p',
      'shop_id': 'sh',
      'delta': v,
    };
    Future<String> run(List<List<(String, String)>> plan) async {
      final srv = FakeSyncServer();
      for (final batch in plan) {
        for (final (dev, v) in batch) {
          await push(srv.forDevice(dev), [m('stock', 'add', 'x', d(v))]);
        }
      }
      return srv.stockQuantity('p', 'sh');
    }

    final ab = await run([
      [('A', '5'), ('B', '-3')],
    ]);
    final ba = await run([
      [('B', '-3'), ('A', '5')],
    ]);
    final inter = await run([
      [('A', '5')],
      [('B', '-3'), ('A', '-1')],
      [('B', '1.5')],
    ]);
    expect(ab, '2');
    expect(ba, '2');
    expect(inter, '2.5');
  });
}
