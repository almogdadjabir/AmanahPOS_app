import 'dart:convert';

import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/inventory/data/local/stock_local_store.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

const _otherShop = '77777777-7777-4777-8777-777777777777';
const _vendor = '88888888-8888-4888-8888-888888888888';
const _uuidRe =
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

void main() {
  late SaleFixture f;
  late StockActor actor;
  late StockService service;
  late List<Set<String>> events;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    actor = const StockActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.manager,
      shopId: kShop,
    );
    service = StockService(
      writer: f.writer,
      actor: () => actor,
      now: () => f.clock,
    );
    events = [];
    f.notifier.changes.listen(events.add);
  });

  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  Future<Map<String, Object?>> outboxRow() async =>
      (await f.db.query('outbox')).single;

  Future<Map<String, dynamic>> payload() async =>
      jsonDecode((await outboxRow())['payload_json'] as String)
          as Map<String, dynamic>;

  Future<double> qty(String p) async =>
      ((await f.stock(p))['quantity'] as num).toDouble();

  Future<void> expectNothingWritten() async {
    expect(await f.count('outbox'), 0);
    expect(await qty(kP1), 10.0);
    expect((await f.stock(kP1))['base_quantity'], '10');
    await Future<void>.delayed(Duration.zero);
    expect(events, isEmpty);
  }

  group('stock.add', () {
    test('quantity and product level change immediately; base untouched; '
        'one outbox row with the BE-exact payload; notifier fires', () async {
      final after = await service.add(
        productId: kP1,
        shopId: kShop,
        delta: '3',
        reason: 'Supplier drop',
      );
      expect(after, '13');
      expect(await qty(kP1), 13.0);
      expect((await f.stock(kP1))['base_quantity'], '10');
      expect(await f.level(kP1), 13.0);

      final row = await outboxRow();
      expect(row['entity'], 'stock');
      expect(row['op'], 'add');
      expect(row['entity_id'], matches(_uuidRe));
      expect(row['status'], 'pending');
      expect(row['scope'], kScope);
      final p = await payload();
      expect(p, {
        'product_id': kP1,
        'shop_id': kShop,
        'delta': '3',
        'reason': 'Supplier drop',
        'occurred_at': '2026-11-16T09:30:00.000Z',
      });

      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
      expect(events.single, containsAll({'stock', 'products', 'outbox'}));
    });

    test('delta <= 0 is refused locally, nothing written', () async {
      for (final d in ['0', '-1', '0.000']) {
        await expectLater(
          service.add(productId: kP1, shopId: kShop, delta: d),
          throwsA(isA<StockValidationException>()),
        );
      }
      await expectNothingWritten();
    });

    test('bad numbers and more than 3 decimals are refused', () async {
      for (final d in ['abc', '', '1.2345']) {
        await expectLater(
          service.add(productId: kP1, shopId: kShop, delta: d),
          throwsA(isA<StockValidationException>()),
        );
      }
      await expectNothingWritten();
    });

    test('delta is sent normalised ("2.500" -> "2.5")', () async {
      await service.add(productId: kP1, shopId: kShop, delta: '2.500');
      expect((await payload())['delta'], '2.5');
      expect(await qty(kP1), 12.5);
    });

    test(
      'no local stock row: one is created (base 0, quantity = delta)',
      () async {
        await f.db.delete('stock', where: 'product_id = ?', whereArgs: [kP1]);
        await service.add(productId: kP1, shopId: kShop, delta: '4');
        final s = await f.stock(kP1);
        expect(s['base_quantity'], '0');
        expect((s['quantity'] as num).toDouble(), 4.0);
        expect(await f.level(kP1), 4.0);
      },
    );
  });

  group('stock.remove', () {
    test('sends the magnitude (positive) and lowers quantity', () async {
      await service.remove(productId: kP1, shopId: kShop, delta: '2');
      expect(await qty(kP1), 8.0);
      final row = await outboxRow();
      expect(row['op'], 'remove');
      expect((await payload())['delta'], '2');
    });

    test('a negative delta is sent as its magnitude', () async {
      await service.remove(productId: kP1, shopId: kShop, delta: '-1.5');
      expect((await payload())['delta'], '1.5');
      expect(await qty(kP1), 8.5);
    });

    test('negative stock is allowed', () async {
      await service.remove(productId: kP1, shopId: kShop, delta: '12');
      expect(await qty(kP1), -2.0);
    });

    test('zero delta is refused', () async {
      await expectLater(
        service.remove(productId: kP1, shopId: kShop, delta: '0'),
        throwsA(isA<StockValidationException>()),
      );
      await expectNothingWritten();
    });
  });

  group('stock.adjust', () {
    test('signed delta is sent as given', () async {
      await service.adjust(productId: kP1, shopId: kShop, delta: '-1.25');
      expect(await qty(kP1), 8.75);
      expect((await outboxRow())['op'], 'adjust');
      final p = await payload();
      expect(p['delta'], '-1.25');
      expect(p.keys.toSet(), {
        'product_id',
        'shop_id',
        'delta',
        'reason',
        'occurred_at',
      });
      expect(p['reason'], '');
    });

    test('zero delta is refused', () async {
      await expectLater(
        service.adjust(productId: kP1, shopId: kShop, delta: '0'),
        throwsA(isA<StockValidationException>()),
      );
      await expectNothingWritten();
    });

    test(
      'adjustTo: delta = new quantity - local quantity (base + pending)',
      () async {
        await service.add(productId: kP1, shopId: kShop, delta: '2'); // 12
        await service.adjustTo(
          productId: kP1,
          shopId: kShop,
          newQuantity: '7.5',
          reason: 'count',
        );
        expect(await qty(kP1), 7.5);
        final rows = await f.db.query('outbox', orderBy: 'seq');
        expect(rows, hasLength(2));
        final p =
            jsonDecode(rows.last['payload_json'] as String)
                as Map<String, dynamic>;
        expect(rows.last['op'], 'adjust');
        expect(p['delta'], '-4.5');
        expect(p['reason'], 'count');
      },
    );

    test('adjustTo the current quantity is refused (zero delta)', () async {
      await expectLater(
        service.adjustTo(productId: kP1, shopId: kShop, newQuantity: '10'),
        throwsA(isA<StockValidationException>()),
      );
      await expectNothingWritten();
    });

    test('reason is trimmed and capped at 200 chars (BE truncates)', () async {
      await service.adjust(
        productId: kP1,
        shopId: kShop,
        delta: '1',
        reason: '  ${'x' * 250}  ',
      );
      expect((await payload())['reason'], 'x' * 200);
    });
  });

  group('permissions', () {
    test(
      'restaurant business refuses every stock op with a clear error',
      () async {
        actor = const StockActor(
          businessType: AppBusinessType.restaurant,
          role: AppUserRole.owner,
          shopId: null,
        );
        final calls = <Future<Object?> Function()>[
          () => service.add(productId: kP1, shopId: kShop, delta: '1'),
          () => service.remove(productId: kP1, shopId: kShop, delta: '1'),
          () => service.adjust(productId: kP1, shopId: kShop, delta: '1'),
          () => service.receiveInbound(_inbound()),
        ];
        for (final c in calls) {
          await expectLater(
            c(),
            throwsA(
              isA<StockValidationException>().having(
                (e) => e.message,
                'message',
                contains('Restaurants do not track inventory'),
              ),
            ),
          );
        }
        await expectNothingWritten();
      },
    );

    test('cashier may act on their own shop', () async {
      actor = const StockActor(
        businessType: AppBusinessType.shop,
        role: AppUserRole.cashier,
        shopId: kShop,
      );
      await service.add(productId: kP1, shopId: kShop, delta: '1');
      await service.remove(productId: kP1, shopId: kShop, delta: '1');
      await service.adjust(productId: kP1, shopId: kShop, delta: '1');
      expect(await f.count('outbox'), 3);
    });

    test('cashier is refused for another shop or without a shop', () async {
      for (final a in const [
        StockActor(
          businessType: AppBusinessType.shop,
          role: AppUserRole.cashier,
          shopId: _otherShop,
        ),
        StockActor(
          businessType: AppBusinessType.shop,
          role: AppUserRole.cashier,
          shopId: null,
        ),
      ]) {
        actor = a;
        await expectLater(
          service.add(productId: kP1, shopId: kShop, delta: '1'),
          throwsA(isA<StockValidationException>()),
        );
      }
      await expectNothingWritten();
    });

    test('manager may act on any shop', () async {
      await service.add(productId: kP1, shopId: _otherShop, delta: '1');
      expect(await f.count('outbox'), 1);
    });

    test('no signed-in scope: throws, nothing written', () async {
      f.scope = null;
      await expectLater(
        service.add(productId: kP1, shopId: kShop, delta: '1'),
        throwsA(anything),
      );
      expect(await f.count('outbox'), 0);
      expect(await qty(kP1), 10.0);
    });
  });

  group('inbound.create', () {
    test('every line raises stock at once; ONE inbound.create row whose '
        'payload is the DTO json plus the client id (= entity id)', () async {
      final result = await service.receiveInbound(_inbound());
      expect(await qty(kP1), 13.0);
      expect(await qty(kP2), 5.5);
      expect((await f.stock(kP1))['base_quantity'], '10');
      expect(await f.level(kP2), 5.5);

      final row = await outboxRow();
      expect(row['entity'], 'inbound');
      expect(row['op'], 'create');
      expect(row['entity_id'], matches(_uuidRe));
      expect(result.id, row['entity_id']);
      final p = await payload();
      expect(p, {
        ..._inbound().toJson(),
        'client_inbound_id': row['entity_id'],
      });
      expect(p['shop_id'], kShop);
      expect(p['vendor_id'], _vendor);
      expect(p['reference'], 'INV-1');
      expect(p['items'], [
        {'product_id': kP1, 'quantity': '3', 'unit_cost': '1.25'},
        {'product_id': kP2, 'quantity': '0.5'},
      ]);

      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
      expect(
        events.single,
        containsAll({'stock', 'products', 'inbound_transactions', 'outbox'}),
      );
    });

    test(
      'a local inbound history row is written in the same transaction',
      () async {
        final result = await service.receiveInbound(_inbound());
        final row = (await f.db.query('inbound_transactions')).single;
        expect(row['id'], result.id);
        expect(row['shop_id'], kShop);
        expect(row['created_at'], '2026-11-16T09:30:00.000Z');
        final j = jsonDecode(row['json'] as String) as Map<String, dynamic>;
        expect(j['reference'], 'INV-1');
        expect(j['vendor_id'], _vendor);
        expect(j['total_quantity'], '3.5');
        expect(j['item_count'], 2);
        expect((j['items'] as List).first['product_name'], 'Tea');
      },
    );

    test('quantity is normalised to at most 3 decimals', () async {
      await service.receiveInbound(
        _inbound(
          items: const [
            CreateInboundItemRequestDto(productId: kP1, quantity: '2.5000'),
          ],
        ),
      );
      final p = await payload();
      expect((p['items'] as List).single['quantity'], '2.5');
    });

    test('cashier is refused (manager+ only)', () async {
      actor = const StockActor(
        businessType: AppBusinessType.shop,
        role: AppUserRole.cashier,
        shopId: kShop,
      );
      await expectLater(
        service.receiveInbound(_inbound()),
        throwsA(isA<StockValidationException>()),
      );
      await expectNothingWritten();
    });

    test('invalid input is refused before anything is written', () async {
      for (final bad in [
        _inbound(items: const []),
        _inbound(
          items: const [
            CreateInboundItemRequestDto(productId: kP1, quantity: '0'),
          ],
        ),
        _inbound(
          items: const [
            CreateInboundItemRequestDto(productId: kP1, quantity: '1.0001'),
          ],
        ),
        _inbound(reference: '  '),
        _inbound(vendorId: ''),
        _inbound(shopId: ''),
      ]) {
        await expectLater(
          service.receiveInbound(bad),
          throwsA(isA<StockValidationException>()),
        );
      }
      await expectNothingWritten();
      expect(await f.count('inbound_transactions'), 0);
    });

    test(
      'pending inbound counts in pendingDeltaUnits for its shop only',
      () async {
        await service.receiveInbound(_inbound());
        const s = StockLocalStore();
        expect(await s.pendingDeltaUnits(f.db, kP1, kShop), BigInt.from(3000));
        expect(await s.pendingDeltaUnits(f.db, kP2, kShop), BigInt.from(500));
        expect(await s.pendingDeltaUnits(f.db, kP1, _otherShop), BigInt.zero);
      },
    );
  });
}

CreateInboundRequestDto _inbound({
  String shopId = kShop,
  String vendorId = _vendor,
  String reference = 'INV-1',
  List<CreateInboundItemRequestDto>? items,
}) => CreateInboundRequestDto(
  shopId: shopId,
  reference: reference,
  vendorId: vendorId,
  items:
      items ??
      const [
        CreateInboundItemRequestDto(
          productId: kP1,
          quantity: '3',
          unitCost: '1.25',
        ),
        CreateInboundItemRequestDto(productId: kP2, quantity: '0.5'),
      ],
);
