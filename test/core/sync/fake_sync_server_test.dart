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

Future<PushResponse> push(FakeSyncServer s, List<OutboxEntry> e) => s.push(
  deviceId: s.deviceId,
  appVersion: '1.0.0',
  mutations: e,
  scope: 'u1|t1',
);

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
      s.pull(scope: 'u1|t1'),
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
    final p1 = await s.pull(limit: 2, scope: 'u1|t1');
    expect(p1.changes.length, 2);
    expect(p1.hasMore, isTrue);
    final p2 = await s.pull(cursor: p1.nextCursor, limit: 2, scope: 'u1|t1');
    expect(p2.changes.map((c) => c.id), ['c2', 'c3']);
    expect(p2.hasMore, isTrue);
    final p3 = await s.pull(cursor: p2.nextCursor, limit: 2, scope: 'u1|t1');
    expect(p3.changes.map((c) => c.id), ['c4']);
    expect(p3.hasMore, isFalse);
    final p4 = await s.pull(cursor: p3.nextCursor, scope: 'u1|t1');
    expect(p4.changes, isEmpty);
    expect(p4.nextCursor, p3.nextCursor);
  });

  test('device views share state and carry origin', () async {
    final a = s.forDevice('A');
    final b = s.forDevice('B');
    await push(a, [
      m('product', 'create', 'p1', {'name': 'A'}),
    ]);
    final pulled = await b.pull(scope: 'u1|t1');
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
    // BE: StockLevel.quantity is DecimalField(decimal_places=3).
    expect(r.results.single.stockAfter.single.quantity, '2.000');
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
        'shop': 'sh',
        'items': [
          {'product_id': 'p1', 'quantity': '2'},
        ],
      }),
    ]);
    final x = r.results.single;
    expect(x.status, PushStatus.applied);
    expect(x.warnings, contains('negative_stock'));
    expect(x.stockAfter.single.quantity, '-2.000');
  });

  test('dependency_failed after rejected create; unique barcode', () async {
    await push(s, [
      m('product', 'create', 'p1', {'barcode': '123'}),
    ]);
    final r = await push(s, [
      m('product', 'create', 'p2', {'barcode': '123'}),
      m('sale', 'create', 'sale1', {
        'shop': 'sh',
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
      final pull = await s.pull(scope: 'u1|t1');
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
    expect((await s.pull(scope: 'u1|t1')).fullResyncRequired, isTrue);
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
        await s.pull(scope: 'u1|t1');
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
    expect(
      (await c.pull(scope: 'u1|t1')).serverTime,
      t.add(const Duration(hours: 3)),
    );
    expect((await push(c, [])).serverTime, t.add(const Duration(hours: 3)));
  });

  test('pull rejects bad limit and garbage cursor', () async {
    await expectLater(s.pull(limit: 0, scope: 'u1|t1'), throwsArgumentError);
    await expectLater(
      s.pull(cursor: '%%%', scope: 'u1|t1'),
      throwsFormatException,
    );
    await expectLater(
      s.pull(cursor: 'bm90LWEtY3Vyc29y', scope: 'u1|t1'),
      throwsFormatException,
    );
  });

  test('sale.create idempotent by sale id across mutation ids', () async {
    Map<String, dynamic> sale() => {
      'shop': 'a',
      'customer_id': 'gone',
      'items': [
        {'product_id': 'p', 'quantity': '2'},
      ],
    };
    final r1 = await push(s, [m('sale', 'create', 'S', sale())]);
    final r2 = await push(s, [m('sale', 'create', 'S', sale())]);
    expect(r1.results.single.status, PushStatus.applied);
    // BE sale_create: a sale id already known (other mutation_id) answers
    // `applied` with the same receipt and NO stock_after; stock untouched.
    expect(r2.results.single.status, PushStatus.applied);
    expect(r2.results.single.stockAfter, isEmpty);
    expect(r2.results.single.receiptNumber, r1.results.single.receiptNumber);
    expect(s.stockQuantity('p', 'a'), '-2');
    expect(s.tables['sale'], hasLength(1));
  });

  test('sale with missing customer nulls customer_id', () async {
    await push(s, [m('customer', 'create', 'c1', {})]);
    await push(s, [m('customer', 'delete', 'c1', {})]);
    final r = await push(s, [
      m('sale', 'create', 'S', {
        'shop': 'a',
        'customer': 'c1',
        // BE OfflineSaleInputSerializer: items min_length=1.
        'items': [
          {'product_id': 'p', 'quantity': '1'},
        ],
      }),
    ]);
    expect(r.results.single.warnings, contains('customer_missing'));
    expect(s.tables['sale']!['S']!['customer'], isNull);
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
          // adjust: BE `stock.add` refuses a delta <= 0.
          await push(srv.forDevice(dev), [m('stock', 'adjust', 'x', d(v))]);
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

  group('BE fidelity (apps/sync/handlers.py, apps/sales/services.py)', () {
    const shop = '11111111-1111-4111-8111-111111111111';
    const tea = '22222222-2222-4222-8222-222222222222';
    const loose = '33333333-3333-4333-8333-333333333333';
    const ghost = '44444444-4444-4444-8444-444444444444';
    const sale1 = 'aaaaaaaa-0000-4000-8000-000000000001';
    const sale2 = 'aaaaaaaa-0000-4000-8000-000000000002';
    const line1 = 'bbbbbbbb-0000-4000-8000-000000000001';
    const line2 = 'bbbbbbbb-0000-4000-8000-000000000002';
    const vendor = 'cccccccc-0000-4000-8000-000000000001';
    const inb = 'dddddddd-0000-4000-8000-000000000001';
    final now = DateTime.utc(2026, 11, 16, 12);
    late FakeSyncServer f;

    setUp(() {
      f = FakeSyncServer(now: () => now)..strictCatalog = true;
      f.seedProduct(tea, name: 'Tea', price: '2.50');
      f.seedProduct(loose, name: 'Loose', price: '1', trackInventory: false);
      f.seedVendor(vendor);
      f.seedStock(tea, shop, '10');
    });

    Map<String, dynamic> sale({
      List<Map<String, dynamic>>? items,
      List<Map<String, dynamic>>? payments,
      String? discount,
      String? taxRate,
      bool inclusive = false,
      String? occurredAt,
    }) => {
      'shop': shop,
      'payment_method': 'cash',
      'discount_amount': ?discount,
      'items':
          items ??
          [
            {
              'id': line1,
              'product_id': tea,
              'quantity': '3',
              'unit_price': '2.50',
            },
          ],
      'tax_rate': ?taxRate,
      if (taxRate != null) 'tax_inclusive': inclusive,
      'payments': ?payments,
      'occurred_at': ?occurredAt,
    };

    test(
      'totals, payments, item ids, stock_after and ser_sale feed row',
      () async {
        final r = (await push(f, [
          m(
            'sale',
            'create',
            sale1,
            sale(
              items: [
                {
                  'id': line1,
                  'product_id': tea,
                  'quantity': '3',
                  'unit_price': '2.50',
                },
                {
                  'id': line2,
                  'custom': true,
                  'quantity': '1',
                  'unit_price': '4.00',
                },
              ],
              payments: [
                {'method': 'cash', 'amount': '10.00'},
                {'method': 'card', 'amount': '1.50'},
              ],
            ),
          ),
        ])).results.single;
        expect(r.status, PushStatus.applied);
        expect(r.entityId, sale1);
        expect(r.version, isNull); // Sale is unversioned on the BE
        expect(r.receiptNumber, matches(RegExp(r'^REC-20261116-[0-9A-F]{8}$')));
        expect(r.warnings, isEmpty);
        // Custom lines never touch stock nor appear in stock_after.
        expect(r.stockAfter.map((a) => [a.productId, a.shopId, a.quantity]), [
          [tea, shop, '7.000'],
        ]);
        final change = f.feed.firstWhere((c) => c.entity == 'sale');
        expect(change.version, 0);
        final d = change.data!;
        expect(d['total_amount'], '11.50');
        expect(d['net_amount'], '11.50');
        expect(d['status'], 'completed');
        expect(d['shop'], shop);
        expect(d['payments'], [
          {'method': 'cash', 'amount': '10.00'},
          {'method': 'card', 'amount': '1.50'},
        ]);
        final items = (d['items'] as List).cast<Map<String, dynamic>>();
        expect({for (final i in items) i['id']}, {line1, line2});
        final custom = items.firstWhere((i) => i['is_custom'] == true);
        expect(custom['product'], isNull);
        expect(custom['subtotal'], '4.00');
        final stock = f.feed.lastWhere((c) => c.entity == 'stock');
        expect(stock.id, f.stockLevelId(tea, shop));
        expect(stock.version, 0);
        expect(stock.data, containsPair('quantity', '7.000'));
      },
    );

    test('payments off by more than 0.01 -> validation_error, nothing '
        'applied; within 0.01 is accepted', () async {
      final bad = (await push(f, [
        m(
          'sale',
          'create',
          sale1,
          sale(
            payments: [
              {'method': 'cash', 'amount': '7.48'},
            ],
          ),
        ),
      ])).results.single;
      expect(bad.status, PushStatus.rejected);
      expect(bad.code, 'validation_error');
      expect(f.tables['sale'] ?? {}, isEmpty);
      expect(f.stockQuantity(tea, shop), '10');
      final ok = (await push(f, [
        m(
          'sale',
          'create',
          sale2,
          sale(
            payments: [
              {'method': 'cash', 'amount': '7.49'},
            ],
          ),
        ),
      ])).results.single;
      expect(ok.status, PushStatus.applied);
    });

    test(
      'tax snapshot: exclusive adds, inclusive extracts (half up)',
      () async {
        final ex = (await push(f, [
          m(
            'sale',
            'create',
            sale1,
            sale(
              taxRate: '15',
              discount: '0.50',
              payments: [
                {'method': 'cash', 'amount': '8.05'},
              ],
            ),
          ),
        ])).results.single;
        expect(ex.status, PushStatus.applied);
        final a = f.tables['sale']![sale1]!;
        expect(
          [a['total_amount'], a['tax_amount'], a['net_amount']],
          ['7.50', '1.05', '8.05'],
        );
        final inc = (await push(f, [
          m(
            'sale',
            'create',
            sale2,
            sale(
              items: [
                {
                  'id': line2,
                  'product_id': tea,
                  'quantity': '1',
                  'unit_price': '10.00',
                },
              ],
              taxRate: '15',
              inclusive: true,
              payments: [
                {'method': 'cash', 'amount': '10.00'},
              ],
            ),
          ),
        ])).results.single;
        expect(inc.status, PushStatus.applied);
        final b = f.tables['sale']![sale2]!;
        // 10 - 10/1.15 = 1.3043... -> 1.30
        expect(
          [b['total_amount'], b['tax_amount'], b['net_amount']],
          ['10.00', '1.30', '10.00'],
        );
      },
    );

    test(
      'accept always: negative stock, missing product, untracked product',
      () async {
        final r = (await push(f, [
          m(
            'sale',
            'create',
            sale1,
            sale(
              items: [
                {
                  'id': line1,
                  'product_id': tea,
                  'quantity': '12',
                  'unit_price': '2.50',
                },
                {
                  'id': line2,
                  'product_id': ghost,
                  'quantity': '1',
                  'unit_price': '1.00',
                },
                {'product_id': loose, 'quantity': '2', 'unit_price': '1.00'},
              ],
            ),
          ),
        ])).results.single;
        expect(r.status, PushStatus.applied);
        expect(r.warnings, ['negative_stock', 'product_missing']);
        // Ghost line has no product (not listed); untracked + no level -> "0".
        expect(r.stockAfter.map((a) => '${a.productId}=${a.quantity}'), [
          '$tea=-2.000',
          '$loose=0',
        ]);
        expect(f.stockQuantity(loose, shop), '0');
      },
    );

    test(
      'reused line id -> forbidden; bad precision -> validation_error',
      () async {
        await push(f, [m('sale', 'create', sale1, sale())]);
        final r = (await push(f, [
          m('sale', 'create', sale2, sale()),
        ])).results.single;
        expect(r.code, 'forbidden');
        final p = (await push(f, [
          m(
            'sale',
            'create',
            sale2,
            sale(
              items: [
                {'product_id': tea, 'quantity': '1.5000', 'unit_price': '2.50'},
              ],
            ),
          ),
        ])).results.single;
        expect(p.code, 'validation_error');
      },
    );

    test('occurred_at > 7 days ahead -> occurred_at_suspect, reported at '
        'server time', () async {
      final r = (await push(f, [
        m(
          'sale',
          'create',
          sale1,
          sale(occurredAt: now.add(const Duration(days: 8)).toIso8601String()),
        ),
        m(
          'sale',
          'create',
          sale2,
          sale(
            items: [
              {
                'id': line2,
                'product_id': tea,
                'quantity': '1',
                'unit_price': '2.50',
              },
            ],
            occurredAt: now.subtract(const Duration(days: 2)).toIso8601String(),
          ),
        ),
      ])).results;
      expect(r[0].warnings, ['occurred_at_suspect']);
      expect(r[1].warnings, isEmpty);
      final s1 = f.tables['sale']![sale1]!;
      expect(
        [s1['occurred_at_suspect'], s1['created_at']],
        [true, now.toIso8601String()],
      );
      final s2 = f.tables['sale']![sale2]!;
      expect(
        s2['created_at'],
        now.subtract(const Duration(days: 2)).toIso8601String(),
      );
    });

    test('stock ops: add > 0 only, remove takes |delta|, unknown product '
        'not_found, entity_id is the product', () async {
      Map<String, dynamic> d(String v, [String p = tea]) => {
        'product_id': p,
        'shop_id': shop,
        'delta': v,
      };
      final r = (await push(f, [
        m('stock', 'add', 'eeeeeeee-0000-4000-8000-000000000001', d('0')),
        m('stock', 'remove', 'eeeeeeee-0000-4000-8000-000000000002', d('3')),
        m(
          'stock',
          'adjust',
          'eeeeeeee-0000-4000-8000-000000000003',
          d('-0.25'),
        ),
        m(
          'stock',
          'add',
          'eeeeeeee-0000-4000-8000-000000000004',
          d('1', ghost),
        ),
      ])).results;
      expect(r[0].code, 'validation_error');
      expect(r[1].entityId, tea);
      expect(r[1].stockAfter.single.quantity, '7.000');
      expect(r[2].stockAfter.single.quantity, '6.750');
      expect(r[3].code, 'not_found');
      expect(f.stockQuantity(tea, shop), '6.75');
    });

    test(
      'inbound.create raises stock with stock_after; reference unique',
      () async {
        Map<String, dynamic> body(String ref) => {
          'shop_id': shop,
          'reference': ref,
          'vendor_id': vendor,
          'items': [
            {'product_id': tea, 'quantity': '4.5', 'unit_cost': '1.20'},
          ],
        };
        final r = (await push(f, [
          m('inbound', 'create', inb, body('PO-1')),
        ])).results.single;
        expect(r.status, PushStatus.applied);
        expect(r.stockAfter.single.quantity, '14.500');
        final dup = (await push(f, [
          m(
            'inbound',
            'create',
            'dddddddd-0000-4000-8000-000000000002',
            body('PO-1'),
          ),
        ])).results.single;
        expect(dup.code, 'conflict_unique');
        expect(f.stockQuantity(tea, shop), '14.5');
        final row = f.feed.firstWhere((c) => c.entity == 'inbound');
        expect(row.version, 0);
        expect(row.data!['items'], [
          {
            'product': tea,
            'quantity': '4.500',
            'unit_cost': '1.20',
            'expiry_date': null,
            'batch_number': '',
          },
        ]);
      },
    );
  });
}
