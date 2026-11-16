// Two devices of the same tenant on the REAL stack (Task 12): separate
// SQLite files, separate device ids, one FakeSyncServer (strict catalog,
// BE semantics). Both sell the same products offline, one adds stock, the
// other receives an inbound; then they sync through flaky / lost-response /
// dropped-after-apply faults and kills. Both must converge to the same
// stock, the same set of sales and the same dashboard as the server.
import 'dart:io';
import 'dart:math';

import 'package:amana_pos/core/sync/decimal3.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/time/business_day.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/fake_sync_server.dart';
import 'support/drafts.dart';
import 'support/lifecycle_device.dart';

const _vendor = 'cccccccc-0000-4000-8000-000000000001';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('two_devices');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  for (final seed in [11, 12, 13, 14]) {
    test('two devices (seed $seed) sell the same products offline under '
        'faults and converge exactly', () async {
      final r = Random(seed);
      final clock = Clock(DateTime.utc(2026, 11, 16, 8));
      final server = FakeSyncServer(deviceId: 'srv', now: clock.now)
        ..strictCatalog = true
        ..seedVendor(_vendor);
      for (final c in kCatalog) {
        server
          ..seedProduct(c.id, name: c.name, price: c.price)
          ..seedStock(c.id, kShop, c.base);
      }
      Future<LifecycleDevice> device(String name, String id) async {
        final d = await LifecycleDevice.create(
          name: name,
          dir: dir,
          deviceId: id,
          view: server.forDevice(id, seed: r.nextInt(1 << 30)),
          clock: clock,
        );
        addTearDown(d.dispose);
        return d;
      }

      final a = await device('a', 'aaaa0000-0000-4000-8000-00000000000a');
      final b = await device('b', 'bbbb0000-0000-4000-8000-00000000000b');
      final today = BusinessDay.of(clock.now(), kTz);
      final sold = <String, BigInt>{};
      final added = <String, BigInt>{};
      void count(Map<String, BigInt> into, Map<String, BigInt> d) {
        for (final e in d.entries) {
          into[e.key] = (into[e.key] ?? BigInt.zero) + e.value;
        }
      }

      // ---- both offline: same products, interleaved ----
      a.view.down = true;
      b.view.down = true;
      for (var i = 0; i < 24; i++) {
        clock.advance(const Duration(minutes: 3));
        final dev = i.isEven ? a : b;
        final draft = randomDraft(r, i);
        await dev.sales.createSale(draft);
        count(sold, soldBy(draft));
        if (i == 5) {
          await a.stock.add(
            productId: kCatalog[0].id,
            shopId: kShop,
            delta: '7.25',
          );
          count(added, {kCatalog[0].id: Decimal3.parse('7.25')});
        }
        if (i == 9) {
          await b.stock.receiveInbound(
            CreateInboundRequestDto(
              shopId: kShop,
              reference: 'PO-$seed',
              vendorId: _vendor,
              items: [
                CreateInboundItemRequestDto(
                  productId: kCatalog[2].id,
                  quantity: '10.5',
                  unitCost: '2.00',
                ),
              ],
            ),
          );
          count(added, {kCatalog[2].id: Decimal3.parse('10.5')});
        }
      }

      // ---- faulty sync rounds ----
      for (final d in [a, b]) {
        d.view.down = false;
      }
      const hooks = [
        'beforeResultWrite',
        'afterPushApplied',
        'beforePullPageCommit',
      ];
      for (var round = 0; round < 6; round++) {
        for (final d in [a, b]..shuffle(r)) {
          d.view
            ..flakyRate = r.nextDouble() * 0.4
            ..lostResponseRate = r.nextDouble() * 0.5
            ..dropResponseAfterApply = r.nextInt(2);
          d.crashAt = r.nextInt(3) == 0 ? hooks[r.nextInt(3)] : null;
          await d.sync();
        }
        clock.advance(Duration(minutes: 5 + r.nextInt(20)));
      }

      // ---- fault-free until both are at a fixed point ----
      Future<void> settle() async {
        for (final d in [a, b]) {
          d.crashAt = null;
          d.view
            ..flakyRate = 0
            ..lostResponseRate = 0
            ..dropResponseAfterApply = 0;
        }
        for (var round = 0; round < 25; round++) {
          clock.advance(const Duration(hours: 1, minutes: 1));
          for (final d in [a, b]) {
            await d.sync();
          }
          var fixed = true;
          for (final d in [a, b]) {
            if ((await d.notDone()).isNotEmpty || !await d.atHead()) {
              fixed = false;
            }
          }
          if (fixed) return;
        }
        fail('no fixed point');
      }

      await settle();

      Future<void> expectConverged(String when, {String? cancelled}) async {
        final serverSales = server.tables['sale']!;
        expect(serverSales, hasLength(24), reason: '$when: lost/extra sale');
        expect(
          server.feed.where((c) => c.entity == 'sale').map((c) => c.id).toSet(),
          hasLength(24),
        );
        for (final d in [a, b]) {
          expect(await d.rejectedCount(), 0, reason: '$when ${d.name}');
          final local = await d.localSales();
          expect(
            local.keys.toSet(),
            serverSales.keys.toSet(),
            reason: '$when ${d.name} sale ids',
          );
          for (final s in serverSales.values) {
            expect(
              cents(local[s['id']]!),
              cents(s['total_amount'] as String),
              reason: '$when ${d.name} sale ${s['id']}',
            );
          }
          for (final c in kCatalog) {
            var expected =
                Decimal3.parse(c.base) -
                (sold[c.id] ?? BigInt.zero) +
                (added[c.id] ?? BigInt.zero);
            if (cancelled != null) {
              for (final it in serverSales[cancelled]!['items'] as List) {
                if ((it as Map)['product'] == c.id) {
                  expected += Decimal3.parse(it['quantity'] as String);
                }
              }
            }
            expect(
              Decimal3.parse(server.stockQuantity(c.id, kShop)),
              expected,
              reason: '$when server ${c.name}',
            );
            expect(
              await d.displayedUnits(c.id),
              expected,
              reason: '$when ${d.name} displayed ${c.name}',
            );
            expect(
              await d.baseUnits(c.id),
              expected,
              reason: '$when ${d.name} base ${c.name}',
            );
          }
        }
        final da = await a.dayDashboard(today);
        final db = await b.dayDashboard(today);
        final total = serverTotalFor(server, today);
        for (final x in [da, db]) {
          expect(dashCents(x.today.grossSalesAmount), total, reason: when);
          expect(x.today.salesCount, cancelled == null ? 24 : 23, reason: when);
        }
        expect(da.today.cashAmount, db.today.cashAmount);
        expect(
          da.today.paymentBreakdown.map((p) => '${p.method}=${p.amount}'),
          db.today.paymentBreakdown.map((p) => '${p.method}=${p.amount}'),
        );
      }

      await expectConverged('after sync');

      // ---- the web cancels one of A's sales: both devices must follow ----
      final victim = (await a.localSales()).keys.first;
      final web = server.forDevice('web');
      final res = await web.push(
        deviceId: 'web',
        appVersion: 'web',
        mutations: [
          OutboxEntry(
            seq: 1,
            mutationId: 'web-cancel',
            entity: 'sale',
            op: 'cancel',
            entityId: victim,
            occurredAt: clock.now(),
            payload: const {},
          ),
        ],
        scope: kScope,
      );
      expect(res.results.single.status.name, 'applied');
      await settle();
      for (final d in [a, b]) {
        final row = (await d.db.query(
          'sales',
          where: 'id = ?',
          whereArgs: [victim],
        )).single;
        expect(row['status'], 'cancelled', reason: '${d.name} missed cancel');
      }
      await expectConverged('after cancel', cancelled: victim);
    });
  }
}
