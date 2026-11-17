import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/sync/appliers/refund_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/time/business_day.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/dashboard/data/local/local_dashboard_queries.dart';
import 'package:amana_pos/features/dashboard/data/models/dashboard_summary_dto.dart';
import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:amana_pos/features/pos/data/local/sale_local_store.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:amana_pos/features/sales_history/data/local/local_sales_history.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

const _kShop2 = '44444444-4444-4444-8444-444444444444';
const _kBiz = '99999999-9999-4999-8999-999999999999';
const _tz = 'Africa/Khartoum';

SaleDraftLine _tea(String qty, {String discount = '0'}) =>
    SaleDraftLine.product(
      productId: kP1,
      productName: 'Tea',
      quantity: qty,
      unitPrice: '500',
      unitCost: '300',
      discount: discount,
    );

SaleDraft _cash(List<SaleDraftLine> lines, {String shop = kShop}) =>
    SaleDraft(shopId: shop, paymentMethod: 'cash', lines: lines);

void main() {
  late SaleFixture f;
  late SaleService service;
  late LocalDashboardQueries q;
  late LocalSalesHistory history;
  String? tenant;
  late StreamController<String?> tenantChanges;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    await f.seedShop(kShop, businessId: _kBiz);
    await f.seedShop(_kShop2, businessId: _kBiz);
    tenant = _kBiz;
    tenantChanges = StreamController<String?>.broadcast();
    service = f.service();
    q = LocalDashboardQueries(
      db: f.odb,
      notifier: f.notifier,
      now: () => f.clock,
      tenantId: () => tenant,
      tenantChanges: tenantChanges.stream,
    );
    history = LocalSalesHistory(db: f.odb, tenantId: () => tenant);
  });

  tearDown(() async {
    await tenantChanges.close();
    f.notifier.dispose();
    await f.db.close();
  });

  Future<Sale> saleAt(DateTime utc, SaleDraft d) async {
    f.clock = utc;
    return service.createSale(d);
  }

  Future<DashboardSummary> day(
    String iso, {
    String? shop = kShop,
    String? cashier,
  }) => q.summaryFor(
    day: BusinessDay.parse(iso),
    shopId: shop,
    timezone: _tz,
    businessId: _kBiz,
    shiftCashierId: cashier,
  );

  group('BusinessDay', () {
    test('Africa/Khartoum is a fixed UTC+2 zone', () {
      expect(BusinessDay.isSupported(_tz), isTrue);
      expect(BusinessDay.offsetOf(_tz), const Duration(hours: 2));
      // Unknown zones fall back to the default zone's offset.
      expect(BusinessDay.offsetOf('Mars/Olympus'), const Duration(hours: 2));
      final d = BusinessDay.parse('2026-11-16');
      expect(d.startUtc(_tz), DateTime.utc(2026, 11, 15, 22));
      expect(d.endUtc(_tz), DateTime.utc(2026, 11, 16, 22));
      expect(d.utcTextRange(_tz).start, '2026-11-15T22:00:00');
      expect(
        BusinessDay.of(DateTime.utc(2026, 11, 16, 21, 59, 59), _tz).iso,
        '2026-11-16',
      );
      expect(
        BusinessDay.of(DateTime.utc(2026, 11, 16, 22), _tz).iso,
        '2026-11-17',
      );
      expect(BusinessDay.parse('2026-12-31').addDays(1).iso, '2027-01-01');
    });
  });

  group('summaryFor', () {
    test('empty day emits zeros without error', () async {
      final s = await day('2026-11-16');
      expect(s.today.date, '2026-11-16');
      expect(s.today.salesCount, 0);
      expect(s.today.grossSalesAmount, 0);
      expect(s.today.netSalesAmount, 0);
      expect(s.today.averageSaleAmount, 0);
      expect(s.today.paymentBreakdown, isEmpty);
      expect(s.topSellers, isEmpty);
      expect(s.today.comparison, isNull);
      expect(s.sparkline.firstSaleHour, isNull);
      expect(s.includesLocalPendingSales, isFalse);
    });

    test('a pulled refund (RefundApplier) is subtracted on its refund date '
        'by the sale payment method', () async {
      final sale = await saleAt(
        DateTime.utc(2026, 11, 15, 9),
        _cash([_tea('3')]),
      );
      await f.db.transaction(
        (txn) => RefundApplier().apply(
          txn,
          PullChange(
            seq: 0,
            entity: 'refund',
            op: 'upsert',
            id: 'rf-1',
            data: {
              'id': 'rf-1',
              'sale': sale.id,
              'shop': kShop,
              'reference': 'RF-1',
              'total': '500.00',
              'method': 'cash',
              'notes': '',
              'refunded_by': null,
              'occurred_at': '2026-11-15T09:30:00Z',
              // Refund recorded on the 16th (Khartoum day), BE created_at.
              'created_at': '2026-11-16T08:00:00.000000+00:00',
              'items': const [],
            },
          ),
        ),
      );
      final s = await day('2026-11-16');
      expect(s.today.refundCount, 1);
      expect(s.today.refundAmount, 500);
      expect(s.today.refundCashAmount, 500);
      expect(s.today.netSalesAmount, -500);
      // The sale's own day carries no refund.
      final before = await day('2026-11-15');
      expect(before.today.refundAmount, 0);
      expect(before.today.grossSalesAmount, 1500);
    });

    test(
      'midnight boundary in Africa/Khartoum with a UTC test clock',
      () async {
        await saleAt(
          DateTime.utc(2026, 11, 16, 21, 59, 59),
          _cash([_tea('1')]),
        );
        await saleAt(DateTime.utc(2026, 11, 16, 22), _cash([_tea('2')]));
        // A microsecond after midnight is still tomorrow (text bounds).
        await saleAt(
          DateTime.utc(2026, 11, 16, 22, 0, 0, 0, 1),
          _cash([_tea('4')]),
        );

        final today = await day('2026-11-16');
        expect(today.today.salesCount, 1);
        expect(today.today.grossSalesAmount, 500);
        expect(today.sparkline.points.last.label, '23:00');
        expect(today.sparkline.points.last.amount, 500);

        final tomorrow = await day('2026-11-17');
        expect(tomorrow.today.salesCount, 2);
        expect(tomorrow.today.grossSalesAmount, 3000);
        expect(tomorrow.sparkline.firstSaleHour, '00:00');
      },
    );

    test('revenue statuses only: cancelled and pending are excluded', () async {
      final a = await saleAt(DateTime.utc(2026, 11, 16, 8), _cash([_tea('1')]));
      final b = await saleAt(DateTime.utc(2026, 11, 16, 9), _cash([_tea('2')]));
      final c = await saleAt(DateTime.utc(2026, 11, 16, 9), _cash([_tea('3')]));
      final d = await saleAt(DateTime.utc(2026, 11, 16, 9), _cash([_tea('5')]));
      await f.db.update(
        'sales',
        {'status': 'cancelled'},
        where: 'id = ?',
        whereArgs: [b.id],
      );
      await f.db.update(
        'sales',
        {'status': 'pending'},
        where: 'id = ?',
        whereArgs: [c.id],
      );
      await f.db.update(
        'sales',
        {'status': 'refunded'},
        where: 'id = ?',
        whereArgs: [d.id],
      );
      final s = await day('2026-11-16');
      expect(s.today.salesCount, 2, reason: '${a.id} + refunded ${d.id}');
      expect(s.today.grossSalesAmount, 3000);
      expect(s.topSellers.single.quantitySold, 6);
    });

    test('a rejected sale still counts and is flagged', () async {
      final s1 = await saleAt(
        DateTime.utc(2026, 11, 16, 8),
        _cash([_tea('1')]),
      );
      final s2 = await saleAt(
        DateTime.utc(2026, 11, 16, 9),
        _cash([_tea('2')]),
      );
      await f.db.update(
        'sales',
        {'sync_state': 'synced'},
        where: 'id = ?',
        whereArgs: [s1.id],
      );
      await f.db.update(
        'sales',
        {
          'sync_state': 'rejected',
          'error_code': 'validation_error',
          'error_message': 'Shop closed',
        },
        where: 'id = ?',
        whereArgs: [s2.id],
      );

      final s = await day('2026-11-16');
      expect(s.today.salesCount, 2);
      expect(s.today.grossSalesAmount, 1500);
      expect(s.includesLocalPendingSales, isTrue);
      expect(s.sync.includesPendingOfflineSales, isTrue);

      final page = await history.page(page: 1, timezone: _tz);
      final rejected = page.items.firstWhere((i) => i.id == s2.id);
      expect(rejected.status, SaleHistoryStatus.failed);
      expect(rejected.isOfflinePending, isTrue);
      expect(rejected.offlineErrorMessage, 'Shop closed');
      final synced = page.items.firstWhere((i) => i.id == s1.id);
      expect(synced.isOfflinePending, isFalse);
      expect(synced.status, SaleHistoryStatus.completed);
    });

    test('all synced: not flagged as offline', () async {
      final s1 = await saleAt(
        DateTime.utc(2026, 11, 16, 8),
        _cash([_tea('1')]),
      );
      await f.db.update(
        'sales',
        {'sync_state': 'synced'},
        where: 'id = ?',
        whereArgs: [s1.id],
      );
      final s = await day('2026-11-16');
      expect(s.includesLocalPendingSales, isFalse);
      expect(s.source, DashboardSummarySource.remote);
    });

    test(
      'payment breakdown, custom lines, discount and tax are exact',
      () async {
        // 0.10 + 0.20 style values summed many times stay exact.
        for (var i = 0; i < 30; i++) {
          await saleAt(
            DateTime.utc(2026, 11, 16, 8, i),
            SaleDraft(
              shopId: kShop,
              paymentMethod: i.isEven ? 'cash' : 'bankak',
              lines: [
                const SaleDraftLine.product(
                  productId: kP2,
                  productName: 'Sugar',
                  quantity: '0.333',
                  unitPrice: '0.30',
                ),
                const SaleDraftLine.custom(name: 'Bag', unitPrice: '0.10'),
              ],
              discountAmount: '0.05',
              taxConfig: const TaxConfig(
                enabled: true,
                name: 'VAT',
                rate: 17,
                inclusive: false,
              ),
            ),
          );
        }
        final s = await day('2026-11-16');
        // Line: 0.333 * 0.30 = 0.0999 -> line_total 0.10; subtotal 0.20.
        final rows = await f.db.query('sales', columns: ['subtotal']);
        expect(rows.first['subtotal'], '0.20');
        expect(s.today.salesCount, 30);
        expect(s.today.grossSalesAmount, 6.0); // 30 * 0.20 exactly
        expect(s.today.cashAmount, 3.0);
        expect(s.today.bankakAmount, 3.0);
        expect(s.today.otherAmount, 0);
        expect(s.today.averageSaleAmount, 0.2);
        expect(s.today.customAmount, 3.0);
        expect(s.today.customCount, 30);
        expect(s.topSellers.single.quantitySold, 9.99); // 30 * 0.333
        expect(s.topSellers.single.grossAmount, 3.0);
        expect(s.today.paymentBreakdown, const [
          PaymentBreakdownItem(method: 'bankak', amount: 3.0, count: 15),
          PaymentBreakdownItem(method: 'cash', amount: 3.0, count: 15),
        ]);
      },
    );

    test('large amounts sum exactly (no double accumulation)', () async {
      for (var i = 0; i < 3; i++) {
        await saleAt(
          DateTime.utc(2026, 11, 16, 8, i),
          _cash([
            const SaleDraftLine.product(
              productId: kP1,
              productName: 'Tea',
              quantity: '1',
              unitPrice: '3333333333.33',
            ),
          ]),
        );
      }
      final s = await day('2026-11-16');
      expect(s.today.grossSalesAmount, 9999999999.99);
      expect(s.today.averageSaleAmount, 3333333333.33);
    });

    test(
      'top sellers rank by quantity then product id, limit applies',
      () async {
        await f.seedProduct('00000000-0000-4000-8000-000000000001', 'Rice');
        await saleAt(
          DateTime.utc(2026, 11, 16, 8),
          _cash([
            _tea('2'),
            const SaleDraftLine.product(
              productId: kP2,
              productName: 'Sugar',
              quantity: '2',
              unitPrice: '1',
            ),
            const SaleDraftLine.product(
              productId: '00000000-0000-4000-8000-000000000001',
              productName: 'Rice',
              quantity: '3',
              unitPrice: '1',
            ),
          ]),
        );
        final s = await q.summaryFor(
          day: BusinessDay.parse('2026-11-16'),
          shopId: kShop,
          timezone: _tz,
          topSellersLimit: 2,
        );
        expect(s.topSellers.map((t) => t.name), ['Rice', 'Tea']);
        final all = await day('2026-11-16');
        // Tie on quantity 2: product id string order (kP1 < kP2).
        expect(all.topSellers.map((t) => t.name), ['Rice', 'Tea', 'Sugar']);
      },
    );

    test(
      'top seller name comes from products, falls back to the line',
      () async {
        await saleAt(DateTime.utc(2026, 11, 16, 8), _cash([_tea('1')]));
        await f.db.update(
          'products',
          {'name': 'Green Tea'},
          where: 'id = ?',
          whereArgs: [kP1],
        );
        expect((await day('2026-11-16')).topSellers.single.name, 'Green Tea');
        await f.db.delete('products', where: 'id = ?', whereArgs: [kP1]);
        expect((await day('2026-11-16')).topSellers.single.name, 'Tea');
      },
    );

    test('shift: only for a cashier id, over that cashier\'s sales', () async {
      await saleAt(DateTime.utc(2026, 11, 16, 8), _cash([_tea('1')]));
      f.cashier = null;
      await saleAt(DateTime.utc(2026, 11, 16, 9), _cash([_tea('2')]));
      final owner = await day('2026-11-16');
      expect(owner.shift!.salesCount, 0);
      expect(owner.shift!.cashierId, isNull);
      final cashier = await day('2026-11-16', cashier: kCashier);
      expect(cashier.shift!.cashierId, kCashier);
      expect(cashier.shift!.salesCount, 1);
      expect(cashier.shift!.grossSalesAmount, 500);
      expect(cashier.shift!.shiftStartedAt, startsWith('2026-11-16T08:00:00'));
    });

    test('sparkline: sales stamped after the current hour land in the '
        'last bucket (points sum to gross)', () async {
      // Another device's clock was ahead: 14:00 local, "now" is 10:30.
      await saleAt(DateTime.utc(2026, 11, 16, 7), _cash([_tea('1')]));
      await saleAt(DateTime.utc(2026, 11, 16, 12), _cash([_tea('2')]));
      f.clock = DateTime.utc(2026, 11, 16, 8, 30);
      final s = await day('2026-11-16');
      expect(s.sparkline.points.last.label, '10:00');
      expect(s.sparkline.points.last.amount, 1000);
      expect(s.sparkline.points.last.salesCount, 1);
      final sum = s.sparkline.points.fold<double>(0, (a, p) => a + p.amount);
      expect(sum, s.today.grossSalesAmount);
      expect(s.sparkline.firstSaleHour, '09:00');
    });

    test('no shop filter aggregates every shop', () async {
      await saleAt(DateTime.utc(2026, 11, 16, 8), _cash([_tea('1')]));
      await saleAt(
        DateTime.utc(2026, 11, 16, 8),
        _cash([_tea('2')], shop: _kShop2),
      );
      expect((await day('2026-11-16')).today.salesCount, 1);
      expect((await day('2026-11-16', shop: null)).today.salesCount, 2);
    });

    test('equals the BE dashboard-summary fixture for the same sales', () async {
      // Business day 2026-11-16 (Khartoum, UTC+2); "now" 15:20 local.
      await saleAt(
        DateTime.utc(2026, 11, 16, 7, 30),
        SaleDraft(
          shopId: kShop,
          paymentMethod: 'cash',
          lines: [
            _tea('2'),
            const SaleDraftLine.custom(name: 'Delivery', unitPrice: '250'),
          ],
          discountAmount: '50',
        ),
      );
      await saleAt(
        DateTime.utc(2026, 11, 16, 8, 15),
        SaleDraft(
          shopId: kShop,
          paymentMethod: 'bankak',
          lines: [
            const SaleDraftLine.product(
              productId: kP2,
              productName: 'Sugar',
              quantity: '1.5',
              unitPrice: '300',
            ),
            _tea('1', discount: '20'),
          ],
          taxConfig: const TaxConfig(
            enabled: true,
            name: 'VAT',
            rate: 10,
            inclusive: false,
          ),
        ),
      );
      await saleAt(
        DateTime.utc(2026, 11, 16, 11, 5),
        SaleDraft(
          shopId: kShop,
          paymentMethod: 'split',
          lines: [_tea('1')],
          payments: const [
            SalePaymentPart(method: 'cash', amount: '300'),
            SalePaymentPart(method: 'bankak', amount: '200'),
          ],
        ),
      );
      final cancelled = await saleAt(
        DateTime.utc(2026, 11, 16, 12),
        _cash([_tea('5')]),
      );
      await f.db.update(
        'sales',
        {'status': 'cancelled'},
        where: 'id = ?',
        whereArgs: [cancelled.id],
      );
      await saleAt(DateTime.utc(2026, 11, 15, 18), _cash([_tea('1')]));
      await saleAt(DateTime.utc(2026, 11, 16, 22), _cash([_tea('1')]));
      await saleAt(
        DateTime.utc(2026, 11, 16, 9),
        _cash([_tea('7')], shop: _kShop2),
      );
      await f.db.update('sales', {'sync_state': 'synced'});
      f.clock = DateTime.utc(2026, 11, 16, 13, 20);

      final json =
          jsonDecode(
                File(
                  'test/features/dashboard/fixtures/dashboard_summary_2026-11-16.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final be = DashboardSummaryDto.fromJson(json).toEntity();

      final local = await q.summaryFor(
        day: BusinessDay.parse('2026-11-16'),
        shopId: kShop,
        timezone: _tz,
        businessId: _kBiz,
      );

      expect(local.today, be.today);
      expect(local.shift, be.shift);
      expect(local.sparkline, be.sparkline);
      expect(local.topSellers, be.topSellers);
      expect(local.timezone, be.timezone);
      expect(local.currency, be.currency);
      expect(local.scope.shopId, be.scope.shopId);
      expect(local.scope.businessId, be.scope.businessId);
      expect(
        local.sync.includesPendingOfflineSales,
        be.sync.includesPendingOfflineSales,
      );
    });
  });

  group('business isolation', () {
    const bizB = '88888888-8888-4888-8888-888888888888';
    const shopB = '77777777-7777-4777-8777-777777777777';

    Future<void> sellInA() async {
      await saleAt(DateTime.utc(2026, 11, 16, 8), _cash([_tea('1')]));
      await saleAt(
        DateTime.utc(2026, 11, 16, 9),
        _cash([_tea('2')], shop: _kShop2),
      );
    }

    Future<void> expectAInvisible() async {
      for (final shop in [null, kShop, shopB]) {
        final s = await day('2026-11-16', shop: shop);
        expect(s.today.salesCount, 0, reason: 'shop=$shop');
        expect(s.today.grossSalesAmount, 0);
        expect(s.topSellers, isEmpty);
        expect(s.today.paymentBreakdown, isEmpty);
        expect(s.sparkline.points.every((p) => p.salesCount == 0), isTrue);
      }
      final page = await history.page(page: 1, timezone: _tz);
      expect(page.items, isEmpty);
      expect(page.totalCount, 0);
      final byShop = await history.page(page: 1, shopId: kShop, timezone: _tz);
      expect(byShop.items, isEmpty);
      final search = await history.page(page: 1, search: 'L-', timezone: _tz);
      expect(search.items, isEmpty);
    }

    test('switching to business B (shops replaced) hides A\'s sales', () async {
      await sellInA();
      expect((await day('2026-11-16', shop: null)).today.salesCount, 2);
      await f.db.delete('shops');
      await f.seedShop(shopB, businessId: bizB);
      tenant = bizB;
      await expectAInvisible();

      // Back to A: its synced sales were never wiped and show again.
      await f.db.delete('shops');
      await f.seedShop(kShop, businessId: _kBiz);
      await f.seedShop(_kShop2, businessId: _kBiz);
      tenant = _kBiz;
      expect((await day('2026-11-16', shop: null)).today.salesCount, 2);
      expect((await history.page(page: 1, timezone: _tz)).items, hasLength(2));
    });

    test(
      'owner with both businesses cached: only the active one shows',
      () async {
        await sellInA();
        await f.seedShop(shopB, businessId: bizB); // shops of A and B cached
        tenant = bizB;
        await expectAInvisible();
        tenant = _kBiz;
        expect((await day('2026-11-16', shop: null)).today.salesCount, 2);
      },
    );

    test('before the active business is known nothing is visible', () async {
      await sellInA();
      tenant = null;
      expect((await day('2026-11-16', shop: null)).today.salesCount, 0);
      expect((await day('2026-11-16')).today.salesCount, 0);
      expect((await history.page(page: 1, timezone: _tz)).items, isEmpty);
    });

    test('watchToday re-evaluates when the business becomes known', () async {
      await sellInA();
      tenant = null;
      final values = StreamIterator(q.watchToday(shopId: null, timezone: _tz));
      expect(await values.moveNext(), isTrue);
      expect(values.current.today.salesCount, 0);

      tenant = _kBiz;
      tenantChanges.add(_kBiz);
      expect(
        await values.moveNext().timeout(const Duration(seconds: 1)),
        isTrue,
      );
      expect(values.current.today.salesCount, 2);
      await values.cancel();
    });
  });

  group('shops arriving after the first value', () {
    test('the dashboard re-emits when the real cache writer fills shops '
        '(re-login: business known, bootstrap still running)', () async {
      f.odb.onTablesChanged = f.notifier.notify;
      await saleAt(DateTime.utc(2026, 11, 16, 8), _cash([_tea('3')]));
      await f.db.delete('shops');
      final values = StreamIterator(q.watchToday(shopId: kShop, timezone: _tz));
      expect(await values.moveNext(), isTrue);
      expect(values.current.today.salesCount, 0);

      await OfflineLocalCache(f.odb).saveBusinessesToCache([
        BusinessData(
          id: _kBiz,
          shops: [ShopData(id: kShop, business: _kBiz)],
        ),
      ]);
      expect(
        await values.moveNext().timeout(const Duration(seconds: 1)),
        isTrue,
      );
      expect(values.current.today.salesCount, 1);
      expect(values.current.today.grossSalesAmount, 1500);
      await values.cancel();
    });

    test('every shops writer notifies after commit', () async {
      final seen = <Set<String>>[];
      f.odb.onTablesChanged = seen.add;
      final cache = OfflineLocalCache(f.odb);
      await cache.saveBusinessesToCache([
        BusinessData(
          id: _kBiz,
          shops: [ShopData(id: kShop)],
        ),
      ]);
      await cache.clearAllOnLogout();
      await f.odb.clearAllLocalOfflineData();
      expect(seen.where((t) => t.contains('shops')), hasLength(3));
    });

    test('no notifier hook: writers still work (flag off)', () async {
      f.odb.onTablesChanged = null;
      await OfflineLocalCache(f.odb).saveBusinessesToCache([
        BusinessData(
          id: _kBiz,
          shops: [ShopData(id: kShop)],
        ),
      ]);
      expect(await f.count('shops'), 2);
    });
  });

  group('watch', () {
    test('a sale through SaleService re-emits within one debounce', () async {
      f.clock = DateTime.utc(2026, 11, 16, 8);
      final values = StreamIterator(q.watchToday(shopId: kShop, timezone: _tz));
      expect(await values.moveNext(), isTrue);
      expect(values.current.today.salesCount, 0);

      await service.createSale(_cash([_tea('3')]));
      final sw = Stopwatch()..start();
      expect(
        await values.moveNext().timeout(const Duration(milliseconds: 500)),
        isTrue,
      );
      sw.stop();
      expect(values.current.today.salesCount, 1);
      expect(values.current.today.grossSalesAmount, 1500);
      expect(sw.elapsedMilliseconds, lessThan(100));
      // ignore: avoid_print
      print('re-emit after commit: ${sw.elapsedMilliseconds} ms');
      await values.cancel();
    });

    test('a pulled sale (SaleApplier path) also re-emits', () async {
      f.clock = DateTime.utc(2026, 11, 16, 8);
      final values = StreamIterator(q.watchToday(shopId: kShop, timezone: _tz));
      await values.moveNext();
      // Same store + notification the applier/engine use.
      final other = await saleAt(
        DateTime.utc(2026, 11, 16, 8),
        _cash([_tea('1')]),
      );
      await values.moveNext();
      expect(values.current.today.salesCount, 1);
      await f.db.transaction(
        (txn) => const SaleLocalStore().delete(txn, other.id),
      );
      f.notifier.notify(SaleLocalStore.tables);
      await values.moveNext();
      expect(values.current.today.salesCount, 0);
      await values.cancel();
    });

    test(
      'wrong device clock (3 days ahead): dashboard and list agree',
      () async {
        final wrong = DateTime.now().toUtc().add(const Duration(days: 3));
        f.clock = wrong;
        await service.createSale(_cash([_tea('1')]));

        final values = StreamIterator(
          q.watchToday(shopId: kShop, timezone: _tz),
        );
        await values.moveNext();
        final dash = values.current;
        await values.cancel();
        expect(dash.today.date, BusinessDay.of(wrong, _tz).iso);
        expect(dash.today.salesCount, 1);

        final d = BusinessDay.parse(dash.today.date);
        final page = await history.page(
          page: 1,
          timezone: _tz,
          dateFrom: DateTime(d.year, d.month, d.day),
          dateTo: DateTime(d.year, d.month, d.day),
        );
        expect(page.items, hasLength(1));
        expect(page.items.single.total, 500);
      },
    );
  });

  group('history', () {
    test('keyset pages newest first, receipt fallback and search', () async {
      final ids = <String>[];
      for (var i = 0; i < 45; i++) {
        final s = await saleAt(
          DateTime.utc(2026, 11, 16, 8, i ~/ 2), // pairs share a timestamp
          _cash([_tea('1')]),
        );
        ids.add(s.id);
      }
      await f.db.update(
        'sales',
        {'receipt_number': 'R-000777'},
        where: 'id = ?',
        whereArgs: [ids[10]],
      );

      final seen = <String>[];
      var page = 1;
      while (true) {
        final p = await history.page(page: page, pageSize: 20, timezone: _tz);
        seen.addAll(p.items.map((e) => e.id!));
        expect(p.totalCount, 45);
        if (!p.hasMore) break;
        page++;
      }
      expect(seen, hasLength(45));
      expect(seen.toSet(), hasLength(45));
      expect(page, 3);

      final first = await history.page(page: 1, timezone: _tz);
      expect(
        first.items.first.createdAt.isAfter(first.items.last.createdAt),
        isTrue,
      );
      final local = first.items.first;
      expect(local.receiptNumber, startsWith('L-'));
      expect(local.items.single.productName, 'Tea');
      expect(local.itemCount, 1);

      final found = await history.page(page: 1, search: '777', timezone: _tz);
      expect(found.items.single.id, ids[10]);
      expect(found.items.single.receiptNumber, 'R-000777');
      final byLocal = await history.page(
        page: 1,
        search: local.receiptNumber!.toLowerCase(),
        timezone: _tz,
      );
      expect(byLocal.items.single.id, local.id);
    });

    test('status filter: only synced sales; pending and rejected show '
        'under All (and Unsynced) only', () async {
      final ok = await saleAt(
        DateTime.utc(2026, 11, 16, 8),
        _cash([_tea('1')]),
      );
      final pending = await saleAt(
        DateTime.utc(2026, 11, 16, 9),
        _cash([_tea('1')]),
      );
      final rejected = await saleAt(
        DateTime.utc(2026, 11, 16, 10),
        _cash([_tea('1')]),
      );
      await f.db.update(
        'sales',
        {'sync_state': 'synced'},
        where: 'id = ?',
        whereArgs: [ok.id],
      );
      await f.db.update(
        'sales',
        {'sync_state': 'rejected'},
        where: 'id = ?',
        whereArgs: [rejected.id],
      );

      final completed = await history.page(
        page: 1,
        status: 'completed',
        timezone: _tz,
      );
      expect(completed.items.map((e) => e.id), [ok.id]);
      expect(completed.totalCount, 1);
      final all = await history.page(page: 1, timezone: _tz);
      expect(all.items.map((e) => e.id).toSet(), {
        ok.id,
        pending.id,
        rejected.id,
      });
      final unsynced = await history.page(
        page: 1,
        onlyUnsynced: true,
        timezone: _tz,
      );
      expect(unsynced.items.map((e) => e.id).toSet(), {
        pending.id,
        rejected.id,
      });
    });

    test('returns are offered for synced and pending local sales, not rejected', () async {
      final ok = await saleAt(
        DateTime.utc(2026, 11, 16, 8),
        _cash([_tea('1')]),
      );
      final pending = await saleAt(
        DateTime.utc(2026, 11, 16, 9),
        _cash([_tea('1')]),
      );
      final rejected = await saleAt(
        DateTime.utc(2026, 11, 16, 10),
        _cash([_tea('1')]),
      );
      await f.db.update(
        'sales',
        {'sync_state': 'synced'},
        where: 'id = ?',
        whereArgs: [ok.id],
      );
      await f.db.update(
        'sales',
        {'sync_state': 'rejected'},
        where: 'id = ?',
        whereArgs: [rejected.id],
      );
      final items = {
        for (final i in (await history.page(page: 1, timezone: _tz)).items)
          i.id: i,
      };
      expect(items[ok.id]!.canBeReturned, isTrue);
      expect(items[pending.id]!.canBeReturned, isTrue);
      expect(items[rejected.id]!.canBeReturned, isFalse);
    });

    test('filters: unsynced, payment, status', () async {
      final a = await saleAt(DateTime.utc(2026, 11, 16, 8), _cash([_tea('1')]));
      await saleAt(
        DateTime.utc(2026, 11, 16, 9),
        SaleDraft(shopId: kShop, paymentMethod: 'bankak', lines: [_tea('1')]),
      );
      await f.db.update(
        'sales',
        {'sync_state': 'synced'},
        where: 'id = ?',
        whereArgs: [a.id],
      );
      expect(
        (await history.page(
          page: 1,
          onlyUnsynced: true,
          timezone: _tz,
        )).items.single.paymentMethod,
        'bankak',
      );
      expect(
        (await history.page(
          page: 1,
          paymentMethod: 'cash',
          timezone: _tz,
        )).items.single.id,
        a.id,
      );
      expect(
        (await history.page(page: 1, status: 'cancelled', timezone: _tz)).items,
        isEmpty,
      );
    });
  });

  group('performance', () {
    test('dashboard on 20k sales stays well under 100 ms', () async {
      const store = SaleLocalStore();
      final base = DateTime.utc(2026, 10, 1);
      await f.db.transaction((txn) async {
        for (var i = 0; i < 20000; i++) {
          // ~45 days of history, the last day busy.
          final at = i < 18000
              ? base.add(Duration(minutes: i * 3))
              : DateTime.utc(2026, 11, 16, 6).add(Duration(seconds: i - 18000));
          await store.insert(
            txn,
            Sale(
              id: 'sale-$i',
              shopId: i % 5 == 0 ? _kShop2 : kShop,
              customerId: null,
              cashierId: kCashier,
              status: 'completed',
              paymentMethod: i.isEven ? 'cash' : 'bankak',
              subtotal: '12.50',
              discount: '0.00',
              taxAmount: '0.00',
              netAmount: '12.50',
              taxRate: '0',
              taxInclusive: false,
              taxName: '',
              receiptNumber: null,
              localReceiptNumber: 'L-x-$i',
              occurredAt: at,
              version: null,
              syncState: 'synced',
              warnings: const [],
              deviceId: kDevice,
              items: [
                SaleLine(
                  id: 'line-$i-a',
                  productId: kP1,
                  productName: 'Tea',
                  isCustom: false,
                  quantity: '2',
                  unitPrice: '5.00',
                  unitCost: '3.00',
                  discount: '0',
                  lineTotal: '10.00',
                  note: null,
                  snapshot: const {},
                ),
                SaleLine(
                  id: 'line-$i-b',
                  productId: null,
                  productName: 'Bag',
                  isCustom: true,
                  quantity: '1',
                  unitPrice: '2.50',
                  unitCost: null,
                  discount: '0',
                  lineTotal: '2.50',
                  note: 'Bag',
                  snapshot: const {},
                ),
              ],
              payments: [
                SalePaymentPart(
                  method: i.isEven ? 'cash' : 'bankak',
                  amount: '12.50',
                ),
              ],
            ),
          );
        }
      });
      f.clock = DateTime.utc(2026, 11, 16, 13);

      Future<int> timed(String? shop) async {
        // Warm-up, then best of 3.
        await q.summaryFor(
          day: BusinessDay.parse('2026-11-16'),
          shopId: shop,
          timezone: _tz,
        );
        var best = 1 << 30;
        for (var r = 0; r < 3; r++) {
          final sw = Stopwatch()..start();
          await q.summaryFor(
            day: BusinessDay.parse('2026-11-16'),
            shopId: shop,
            timezone: _tz,
          );
          sw.stop();
          if (sw.elapsedMicroseconds < best) best = sw.elapsedMicroseconds;
        }
        return best;
      }

      final shopUs = await timed(kShop);
      final allUs = await timed(null);
      final s = await q.summaryFor(
        day: BusinessDay.parse('2026-11-16'),
        shopId: kShop,
        timezone: _tz,
      );
      expect(s.today.salesCount, 1600); // 2000 busy-day sales, 4/5 in kShop
      expect(s.today.grossSalesAmount, 20000);
      // ignore: avoid_print
      print(
        'dashboard 20k sales: shop=${shopUs / 1000} ms, '
        'all shops=${allUs / 1000} ms',
      );
      expect(shopUs, lessThan(100000));
      expect(allUs, lessThan(100000));

      final sw = Stopwatch()..start();
      final p = await history.page(page: 1, timezone: _tz);
      sw.stop();
      // ignore: avoid_print
      print('history first page 20k sales: ${sw.elapsedMilliseconds} ms');
      expect(p.items, hasLength(20));
      expect(sw.elapsedMilliseconds, lessThan(100));
    });
  });
}
