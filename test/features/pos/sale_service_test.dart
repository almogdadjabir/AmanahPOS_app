import 'dart:convert';

import 'package:amana_pos/features/inventory/data/local/stock_local_store.dart';
import 'package:amana_pos/features/pos/data/local/sale_local_store.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../core/sync/support/test_db.dart';
import 'support/sale_fixture.dart';

const _uuidRe =
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

void main() {
  late SaleFixture f;
  late SaleService service;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    service = f.service();
  });

  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  SaleDraft draft({
    List<SaleDraftLine>? lines,
    List<SalePaymentPart>? payments,
    TaxConfig tax = const TaxConfig.disabled(),
    String discount = '0',
    String? customerId,
  }) => SaleDraft(
    shopId: kShop,
    customerId: customerId,
    paymentMethod: 'cash',
    lines:
        lines ??
        [
          const SaleDraftLine.product(
            productId: kP1,
            productName: 'Tea',
            quantity: '3',
            unitPrice: '2.50',
            unitCost: '1.20',
            snapshot: {'id': kP1, 'name': 'Tea', 'price': '2.50'},
          ),
          const SaleDraftLine.product(
            productId: kP2,
            productName: 'Sugar',
            quantity: '1',
            unitPrice: '4.00',
          ),
        ],
    payments: payments,
    discountAmount: discount,
    taxConfig: tax,
  );

  Future<Map<String, Object?>> outboxRow() async =>
      (await f.db.query('outbox')).single;

  group('createSale', () {
    test('writes sale + items + payments + exactly ONE outbox row', () async {
      final sale = await service.createSale(draft());

      expect(sale.id, matches(_uuidRe));
      expect(await f.count('sales'), 1);
      expect(await f.count('sale_items'), 2);
      expect(await f.count('sale_payments'), 1);
      expect(await f.count('outbox'), 1);

      final row = (await f.db.query('sales')).single;
      expect(row['id'], sale.id);
      expect(row['shop_id'], kShop);
      expect(row['cashier_id'], kCashier);
      expect(row['status'], 'completed');
      expect(row['subtotal'], '11.50');
      expect(row['net_amount'], '11.50');
      expect(row['sync_state'], 'pending');
      expect(row['local_receipt_number'], 'L-abcd-000001');
      expect(row['occurred_at'], '2026-11-16T09:30:00.000Z');

      final items = await f.db.query('sale_items', orderBy: 'product_name');
      for (final it in items) {
        expect(it['id'], matches(_uuidRe));
        expect(it['sale_id'], sale.id);
      }
      expect(items.map((e) => e['line_total']), ['4.00', '7.50']);

      final pay = (await f.db.query('sale_payments')).single;
      expect(pay['method'], 'cash');
      expect(pay['amount'], '11.50');

      final ob = await outboxRow();
      expect(ob['entity'], 'sale');
      expect(ob['op'], 'create');
      expect(ob['entity_id'], sale.id);
      expect(ob['status'], 'pending');
      expect(ob['scope'], kScope);
    });

    test('outbox payload is the BE-exact sale.create shape', () async {
      final sale = await service.createSale(
        draft(
          customerId: '44444444-4444-4444-8444-444444444444',
          tax: const TaxConfig(
            enabled: true,
            name: 'VAT',
            rate: 15,
            inclusive: false,
          ),
        ),
      );
      final p =
          jsonDecode((await outboxRow())['payload_json'] as String)
              as Map<String, dynamic>;
      expect(p.keys.toSet(), {
        'client_sale_id',
        'shop',
        'customer',
        'payment_method',
        'discount_amount',
        'items',
        'occurred_at',
        'cashier',
        'device_id',
        'tax_rate',
        'tax_inclusive',
        'tax_name',
        'payments',
        'local_receipt_number',
      });
      expect(p['client_sale_id'], sale.id);
      expect(p['shop'], kShop);
      expect(p['customer'], '44444444-4444-4444-8444-444444444444');
      expect(p['payment_method'], 'cash');
      expect(p['discount_amount'], '0.00');
      expect(p['occurred_at'], '2026-11-16T09:30:00.000Z');
      expect(p['cashier'], kCashier);
      expect(p['device_id'], kDevice);
      expect(p['tax_rate'], '15');
      expect(p['tax_inclusive'], isA<bool>().having((b) => b, 'v', false));
      expect(p['tax_name'], 'VAT');
      // 11.50 + 15% = 13.225 -> 13.23 (ROUND_HALF_UP like the BE)
      expect(p['payments'], [
        {'method': 'cash', 'amount': '13.23'},
      ]);
      expect(sale.netAmount, '13.23');
      expect(sale.taxAmount, '1.73');
      expect(p['local_receipt_number'], 'L-abcd-000001');

      final items = (p['items'] as List).cast<Map<String, dynamic>>();
      final tea = items.firstWhere((e) => e['product_id'] == kP1);
      expect(tea.keys.toSet(), {
        'id',
        'product_id',
        'custom',
        'quantity',
        'unit_price',
        'unit_cost',
        'product_name',
      });
      expect(tea['custom'], false);
      expect(tea['quantity'], '3');
      expect(tea['unit_price'], '2.50');
      expect(tea['unit_cost'], '1.20');
      expect(tea['product_name'], 'Tea');
      final sugar = items.firstWhere((e) => e['product_id'] == kP2);
      expect(
        sugar.containsKey('unit_cost'),
        isFalse,
        reason: 'unknown cost is omitted (BE falls back to product cost)',
      );
      final ids = (await f.db.query('sale_items')).map((e) => e['id']).toSet();
      expect(items.map((e) => e['id']).toSet(), ids);
    });

    test('customer omitted when none', () async {
      await service.createSale(draft());
      final p =
          jsonDecode((await outboxRow())['payload_json'] as String) as Map;
      expect(p.containsKey('customer'), isFalse);
    });

    test('stock decremented once; base untouched; consistent with pending '
        'deltas', () async {
      await service.createSale(draft());
      final s1 = await f.stock(kP1);
      expect(s1['base_quantity'], '10');
      expect((s1['quantity'] as num).toDouble(), 7.0);
      expect(await f.level(kP1), 7.0);
      expect((((await f.stock(kP2))['quantity']) as num).toDouble(), 4.0);
      expect(
        await const StockLocalStore().pendingDeltaSum(f.db, kP1, kShop),
        '-3',
      );
      // Recompute is idempotent: the sale counts exactly once.
      await const StockLocalStore().recompute(f.db, kP1, kShop);
      expect(((await f.stock(kP1))['quantity'] as num).toDouble(), 7.0);
    });

    test('negative stock is allowed', () async {
      await service.createSale(
        draft(
          lines: [
            const SaleDraftLine.product(
              productId: kP2,
              productName: 'Sugar',
              quantity: '8',
              unitPrice: '1.00',
            ),
          ],
        ),
      );
      expect(((await f.stock(kP2))['quantity'] as num).toDouble(), -3.0);
    });

    test('notifier fires once, after commit, including sales', () async {
      final events = <Set<String>>[];
      var visibleAtNotify = -1;
      final sub = f.notifier.changes.listen((t) {
        events.add(t);
      });
      f.notifier.changes.listen((_) async {
        visibleAtNotify = await f.count('sales');
      });
      await service.createSale(draft());
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(events, hasLength(1));
      expect(
        events.single,
        containsAll({
          'sales',
          'sale_items',
          'sale_payments',
          'stock',
          'outbox',
        }),
      );
      expect(visibleAtNotify, 1);
    });

    test('payments mismatch throws and writes nothing', () async {
      final events = <Set<String>>[];
      f.notifier.changes.listen(events.add);
      await expectLater(
        service.createSale(
          draft(
            payments: const [SalePaymentPart(method: 'cash', amount: '11')],
          ),
        ),
        throwsA(isA<SaleValidationException>()),
      );
      expect(await f.count('sales'), 0);
      expect(await f.count('sale_items'), 0);
      expect(await f.count('sale_payments'), 0);
      expect(await f.count('outbox'), 0);
      expect(((await f.stock(kP1))['quantity'] as num).toDouble(), 10.0);
      expect(events, isEmpty);
      // The receipt counter did not advance.
      final s = await service.createSale(draft());
      expect(s.localReceiptNumber, 'L-abcd-000001');
    });

    test('payments within 0.01 of net are accepted', () async {
      final s = await service.createSale(
        draft(
          payments: const [SalePaymentPart(method: 'cash', amount: '11.49')],
        ),
      );
      expect(s.netAmount, '11.50');
    });

    test('empty cart and qty <= 0 are refused', () async {
      await expectLater(
        service.createSale(draft(lines: const [])),
        throwsA(isA<SaleValidationException>()),
      );
      for (final q in ['0', '-1']) {
        await expectLater(
          service.createSale(
            draft(
              lines: [
                SaleDraftLine.product(
                  productId: kP1,
                  productName: 'Tea',
                  quantity: q,
                  unitPrice: '1.00',
                ),
              ],
            ),
          ),
          throwsA(isA<SaleValidationException>()),
        );
      }
      expect(await f.count('outbox'), 0);
      expect(await f.count('sales'), 0);
    });

    test('no signed-in scope: throws, nothing written', () async {
      f.scope = null;
      await expectLater(service.createSale(draft()), throwsA(anything));
      expect(await f.count('sales'), 0);
      expect(await f.count('outbox'), 0);
      expect(((await f.stock(kP1))['quantity'] as num).toDouble(), 10.0);
    });

    test('custom line: null product, no stock effect', () async {
      final sale = await service.createSale(
        draft(
          lines: const [
            SaleDraftLine.custom(name: 'Delivery fee', unitPrice: '5.00'),
          ],
        ),
      );
      final it = (await f.db.query('sale_items')).single;
      expect(it['product_id'], isNull);
      expect(it['is_custom'], 1);
      expect(it['product_name'], 'Delivery fee');
      expect(it['line_total'], '5.00');
      expect(((await f.stock(kP1))['quantity'] as num).toDouble(), 10.0);
      final p =
          jsonDecode((await outboxRow())['payload_json'] as String) as Map;
      final line = (p['items'] as List).single as Map;
      expect(line.keys.toSet(), {
        'id',
        'custom',
        'quantity',
        'unit_price',
        'note',
      });
      expect(line['custom'], true);
      expect(line['note'], 'Delivery fee');
      expect(sale.netAmount, '5.00');
    });

    test('split payments: one row per part, payment_method split', () async {
      final sale = await service.createSale(
        draft(
          payments: const [
            SalePaymentPart(method: 'cash', amount: '10.00'),
            SalePaymentPart(method: 'bankak', amount: '1.50'),
          ],
        ),
      );
      final rows = await f.db.query('sale_payments', orderBy: 'rowid');
      expect(rows.map((r) => [r['method'], r['amount']]), [
        ['cash', '10.00'],
        ['bankak', '1.50'],
      ]);
      final p =
          jsonDecode((await outboxRow())['payload_json'] as String) as Map;
      expect(p['payment_method'], 'split');
      expect(p['payments'], [
        {'method': 'cash', 'amount': '10.00'},
        {'method': 'bankak', 'amount': '1.50'},
      ]);
      expect(sale.payments, hasLength(2));
    });

    test('cashier is sent only when it is a UUID (BE rejects the whole sale '
        'otherwise)', () async {
      f.cashier = 'u1';
      await service.createSale(draft());
      final p =
          jsonDecode((await outboxRow())['payload_json'] as String) as Map;
      expect(p.containsKey('cashier'), isFalse);
    });

    test('item quantity is sent with at most 3 decimals', () async {
      await service.createSale(
        draft(
          lines: const [
            SaleDraftLine.product(
              productId: kP1,
              productName: 'Tea',
              quantity: '1.5000',
              unitPrice: '2.00',
            ),
            SaleDraftLine.product(
              productId: kP2,
              productName: 'Sugar',
              quantity: '2.250',
              unitPrice: '4.00',
            ),
          ],
        ),
      );
      final p =
          jsonDecode((await outboxRow())['payload_json'] as String) as Map;
      final items = (p['items'] as List).cast<Map>();
      expect(items.map((e) => e['quantity']), ['1.5', '2.25']);
      expect(((await f.stock(kP1))['quantity'] as num).toDouble(), 8.5);
    });

    test("payment method 'split' without parts is refused", () async {
      await expectLater(
        service.createSale(
          SaleDraft(
            shopId: kShop,
            paymentMethod: 'split',
            lines: const [
              SaleDraftLine.product(
                productId: kP1,
                productName: 'Tea',
                quantity: '1',
                unitPrice: '2.00',
              ),
            ],
          ),
        ),
        throwsA(isA<SaleValidationException>()),
      );
      expect(await f.count('outbox'), 0);
      expect(await f.count('sales'), 0);
    });

    test('local receipt numbers count up per device', () async {
      final a = await service.createSale(draft());
      final b = await service.createSale(draft());
      expect(a.localReceiptNumber, 'L-abcd-000001');
      expect(b.localReceiptNumber, 'L-abcd-000002');
    });

    test('inclusive tax: local net equals BE net and payment', () async {
      final sale = await service.createSale(
        draft(
          tax: const TaxConfig(
            enabled: true,
            name: 'VAT',
            rate: 15,
            inclusive: true,
          ),
          discount: '1.50',
        ),
      );
      // taxable 10.00; tax = 10 - 10/1.15 = 1.304... -> 1.30
      expect(sale.subtotal, '11.50');
      expect(sale.discount, '1.50');
      expect(sale.taxAmount, '1.30');
      expect(sale.netAmount, '10.00');
      final row = (await f.db.query('sales')).single;
      expect(row['tax_inclusive'], 1);
      expect(row['tax_rate'], '15');
      expect(row['tax_name'], 'VAT');
      expect((await f.db.query('sale_payments')).single['amount'], '10.00');
    });

    test('a line whose product row is later deleted still renders from '
        'snapshot_json', () async {
      final sale = await service.createSale(draft());
      await f.db.delete('products', where: 'id = ?', whereArgs: [kP1]);
      final read = await const SaleLocalStore().read(f.db, sale.id);
      final tea = read!.items.firstWhere((e) => e.productId == kP1);
      expect(tea.productName, 'Tea');
      expect(tea.snapshot['price'], '2.50');
      expect(tea.lineTotal, '7.50');
      expect(read.localReceiptNumber, 'L-abcd-000001');
    });
  });

  group('product re-check at checkout (fix-wave I2)', () {
    test('a line whose product row is gone (merged / discarded) is refused; '
        'nothing is written', () async {
      await f.db.delete('products', where: 'id = ?', whereArgs: [kP2]);
      await expectLater(
        service.createSale(draft()),
        throwsA(
          isA<SaleProductUnavailableException>().having(
            (e) => e.productIds,
            'productIds',
            {kP2},
          ),
        ),
      );
      expect(await f.count('sales'), 0);
      expect(await f.count('sale_items'), 0);
      expect(await f.count('outbox'), 0);
    });

    test('an inactive (deleted) product is refused', () async {
      await f.db.update(
        'products',
        {'json': '{"id":"$kP1","name":"Tea","is_active":false}'},
        where: 'id = ?',
        whereArgs: [kP1],
      );
      await expectLater(
        service.createSale(draft()),
        throwsA(
          isA<SaleProductUnavailableException>().having(
            (e) => e.productIds,
            'productIds',
            {kP1},
          ),
        ),
      );
      expect(await f.count('outbox'), 0);
    });

    test('custom lines are never checked', () async {
      await f.db.delete('products');
      final sale = await service.createSale(
        draft(
          lines: [
            const SaleDraftLine.custom(
              name: 'Tip',
              unitPrice: '3',
              quantity: '1',
            ),
          ],
        ),
      );
      expect(sale.items.single.productId, isNull);
    });

    test('unavailableProductIds reports missing and inactive ids only', () async {
      await f.db.delete('products', where: 'id = ?', whereArgs: [kP2]);
      expect(await service.unavailableProductIds({kP1, kP2}), {kP2});
      expect(await service.unavailableProductIds(const []), isEmpty);
    });
  });

  group('schema v9', () {
    test('fresh onCreate has the sales tables', () async {
      expect(OfflineDb.schemaVersion, greaterThanOrEqualTo(9));
      for (final t in ['sales', 'sale_items', 'sale_payments']) {
        expect(await f.count(t), 0);
      }
    });

    test('v8 -> v9 upgrade adds the tables and indexes, idempotent; legacy '
        'pending tables untouched', () async {
      sqfliteFfiInit();
      final old = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      addTearDown(old.close);
      await old.execute('CREATE TABLE pending_sales (id TEXT PRIMARY KEY)');
      await old.insert('pending_sales', {'id': 'legacy'});
      await OfflineDb.onUpgrade(old, 8, 9);
      await OfflineDb.onUpgrade(old, 8, 9);
      final names = (await old.rawQuery(
        "SELECT name FROM sqlite_master WHERE type IN ('table','index')",
      )).map((r) => r['name']).toSet();
      expect(
        names,
        containsAll([
          'sales',
          'sale_items',
          'sale_payments',
          'idx_sales_shop_occurred',
          'idx_sales_status',
          'idx_sale_items_sale',
        ]),
      );
      expect(await old.query('pending_sales'), hasLength(1));
    });
  });
}
