import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/features/pos/data/repository_impl/pos_repo_impl.dart';
import 'package:amana_pos/features/pos/domain/sale.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../core/sync/support/test_db.dart';
import '../../support/sale_fixture.dart';

void main() {
  late SaleFixture f;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
  });

  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  final cart = [
    PosCartItem(
      product: ProductData.fromJson(const {
        'id': kP1,
        'name': 'Tea',
        'price': '2.50',
        'cost_price': '1.20',
      }),
      quantity: 3,
    ),
    PosCartItem.custom(id: 'k1', name: 'Fee', price: 1),
  ];

  PosRepoImpl repo() => PosRepoImpl(saleService: () => f.service());

  test('saved locally + outbox (the only sale write path)', () async {
    final r = await repo().submitSale(
      shopId: kShop,
      customerId: null,
      paymentMethod: 'cash',
      items: cart,
      taxConfig: const TaxConfig(
        enabled: true,
        name: 'VAT',
        rate: 15,
        inclusive: false,
      ),
    );
    final res = r.getOrElse((e) => throw Exception(e));
    expect(res.local, isTrue);
    expect(res.queued, isFalse, reason: 'UI treats it as a finished sale');
    expect(res.synced, isFalse);
    expect(res.receiptNumber, 'L-abcd-000001');
    expect(res.saleId, res.clientSaleId);
    // 7.50 + 1.00 = 8.50; 15% = 1.275 -> 1.28; net 9.775 -> 9.78
    expect(res.taxAmount, '1.28');
    expect(res.netAmount, '9.78');
    expect(res.taxRate, '15');
    expect(res.taxInclusive, isFalse);
    expect(await f.count('sales'), 1);
    expect(await f.count('outbox'), 1);
    final items = await f.db.query('sale_items', orderBy: 'position');
    expect(items.first['product_id'], kP1);
    expect(items.first['unit_cost'], '1.20');
    expect(items.last['is_custom'], 1);
    expect(items.last['product_id'], isNull);
  });

  test('a gone product is rethrown (not a Left) so PosBloc can drop the '
      'line and say why (fix-wave I2)', () async {
    await f.db.delete('products', where: 'id = ?', whereArgs: [kP1]);
    await expectLater(
      repo().submitSale(
        shopId: kShop,
        customerId: null,
        paymentMethod: 'cash',
        items: cart,
      ),
      throwsA(isA<SaleProductUnavailableException>()),
    );
    expect(await f.count('sales'), 0);
  });

  test('validation error surfaces as Left, nothing saved', () async {
    final r = await repo().submitSale(
      shopId: kShop,
      customerId: null,
      paymentMethod: 'not_a_method',
      items: cart,
    );
    expect(r.isLeft(), isTrue);
    expect(await f.count('sales'), 0);
    expect(await f.count('outbox'), 0);
  });
}
