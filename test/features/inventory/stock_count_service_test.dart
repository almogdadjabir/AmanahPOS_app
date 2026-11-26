import 'dart:convert';

import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/decimal3.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

BigInt u(String s) => Decimal3.parse(s);

void main() {
  late SaleFixture f;
  late StockService service;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    service = StockService(
      writer: f.writer,
      actor: () => const StockActor(
        businessType: AppBusinessType.shop,
        role: AppUserRole.cashier,
        shopId: kShop,
      ),
      now: () => f.clock,
    );
  });

  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  Future<double> qty(String p) async =>
      ((await f.stock(p))['quantity'] as num).toDouble();

  test('a difference becomes one signed stock.adjust; matching lines write '
      'nothing', () async {
    final out = await service.applyCount(
      shopId: kShop,
      lines: [CountLine(productId: kP1, counted: u('8'), expected: u('10'))],
    );
    expect(out.changed, 1);
    expect(out.matched, 0);
    expect(out.taken, u('2'));
    expect(out.added, BigInt.zero);
    final row = (await f.db.query('outbox')).single;
    expect(row['entity'], 'stock');
    expect(row['op'], 'adjust');
    final p = jsonDecode(row['payload_json'] as String) as Map;
    expect(p['delta'], '-2');
    expect(p['reason'], 'Stock count');
    expect(await qty(kP1), 8.0);
  });

  test('uses the stock shown when counted, so a sale made meanwhile stands',
      () async {
    // The shelf showed 10 when counted; 7 are really there. One was sold
    // while counting (stock now 9). The delta is -3, so stock ends at 6.
    await service.remove(productId: kP1, shopId: kShop, delta: '1');
    final out = await service.applyCount(
      shopId: kShop,
      lines: [CountLine(productId: kP1, counted: u('7'), expected: u('10'))],
    );
    expect(out.taken, u('3'));
    expect(await qty(kP1), 6.0);
  });

  test('a count that matches everywhere has nothing to apply', () async {
    await expectLater(
      service.applyCount(
        shopId: kShop,
        lines: [CountLine(productId: kP1, counted: u('10'), expected: u('10'))],
      ),
      throwsA(isA<StockValidationException>()),
    );
    expect(await f.count('outbox'), 0);
  });

  test('negative or repeated lines are refused, nothing written', () async {
    await expectLater(
      service.applyCount(
        shopId: kShop,
        lines: [CountLine(productId: kP1, counted: u('-1'), expected: u('10'))],
      ),
      throwsA(isA<StockValidationException>()),
    );
    await expectLater(
      service.applyCount(shopId: kShop, lines: [
        CountLine(productId: kP1, counted: u('1'), expected: u('10')),
        CountLine(productId: kP1, counted: u('2'), expected: u('10')),
      ]),
      throwsA(isA<StockValidationException>()),
    );
    expect(await f.count('outbox'), 0);
  });

  test('all or none: an unknown product undoes the lines before it', () async {
    await expectLater(
      service.applyCount(shopId: kShop, lines: [
        CountLine(productId: kP1, counted: u('12'), expected: u('10')),
        CountLine(
          productId: '99999999-9999-4999-8999-999999999999',
          counted: u('1'),
          expected: u('0'),
        ),
      ]),
      throwsA(isA<StockValidationException>()),
    );
    expect(await f.count('outbox'), 0);
    expect(await qty(kP1), 10.0);
  });
}
