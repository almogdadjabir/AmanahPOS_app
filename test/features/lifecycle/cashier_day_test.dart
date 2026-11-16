// Full cashier day on the REAL stack (Task 12): SaleService / StockService /
// LocalWriter / SyncEngine + production appliers over a SQLite FILE, the
// FakeSyncServer mirroring the live BE (strict catalog), and simulated
// process kills that reopen the file.
//
//  bootstrap (catalog, stock base, cursor at head)
//  -> server DOWN for 2 h: 40 sales + 3 stock adds, kills at random points
//  -> server UP: everything drains in order, nothing lost, nothing doubled,
//     stock exact, dashboard == server, outbox empty, nothing rejected.
import 'dart:io';
import 'dart:math';

import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/decimal3.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/time/business_day.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;

import '../../core/sync/support/fake_sync_server.dart';
import 'support/drafts.dart';
import 'support/lifecycle_device.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cashier_day');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  for (final seed in [1, 2, 3]) {
    test('cashier day (seed $seed): 2 h offline, 40 sales + 3 stock adds '
        'with kills, then everything drains exactly once', () async {
      final r = Random(seed);
      final clock = Clock(DateTime.utc(2026, 11, 16, 7)); // 09:00 Khartoum
      final server = FakeSyncServer(deviceId: 'srv', now: clock.now)
        ..strictCatalog = true;
      for (final c in kCatalog) {
        server
          ..seedProduct(c.id, name: c.name, price: c.price)
          ..seedStock(c.id, kShop, c.base);
      }
      final view = server.forDevice('aaaa0000-0000-4000-8000-00000000000a');
      final dev = await LifecycleDevice.create(
        name: 'cashier',
        dir: dir,
        deviceId: view.deviceId,
        view: view,
        clock: clock,
      );
      addTearDown(dev.dispose);
      expect(await dev.sync(), SyncOutcome.completed);
      final today = BusinessDay.of(clock.now(), kTz);

      // ---- server DOWN for 2 h ----
      view.down = true;
      final downUntil = clock.now().add(const Duration(hours: 2));
      final confirmed = <String>{};
      final sold = <String, BigInt>{};
      final added = <String, BigInt>{};
      final kills = <String>[];
      final addAt = {7, 21, 36};
      var salesMade = 0;

      void addSold(SaleDraft d) {
        for (final e in soldBy(d).entries) {
          sold[e.key] = (sold[e.key] ?? BigInt.zero) + e.value;
        }
      }

      for (var i = 0; i < 43; i++) {
        clock.advance(Duration(seconds: 120 + r.nextInt(40)));
        // Killed while idle (app swiped away / OS reclaimed it).
        if (r.nextInt(10) == 0) {
          kills.add('idle@$i');
          await dev.reopen();
        }
        if (addAt.contains(i)) {
          final c = kCatalog[r.nextInt(kCatalog.length)];
          const delta = '5.5';
          await dev.stock.add(productId: c.id, shopId: kShop, delta: delta);
          added[c.id] = (added[c.id] ?? BigInt.zero) + Decimal3.parse(delta);
        } else {
          final draft = randomDraft(r, salesMade);
          final kill = switch (r.nextInt(8)) {
            0 => 'beforeCommit',
            1 => 'afterCommit',
            _ => null,
          };
          dev.saleCrashAt = kill;
          try {
            confirmed.add((await dev.sales.createSale(draft)).id);
          } on CrashSimulation {
            kills.add('sale-$kill@$i');
            await dev.reopen();
            final local = (await dev.localSales()).keys.toSet();
            final fresh = local.difference(confirmed);
            if (kill == 'beforeCommit') {
              // Nothing was written; the cashier rings the cart again.
              expect(fresh, isEmpty, reason: 'rolled back sale visible');
              confirmed.add((await dev.sales.createSale(draft)).id);
            } else {
              // Written before the kill: history shows it exactly once.
              expect(fresh, hasLength(1), reason: 'committed sale missing');
              confirmed.add(fresh.single);
            }
          }
          addSold(draft);
          salesMade++;
        }
        if (i % 6 == 5) await dev.sync(); // background attempts while down
      }
      expect(salesMade, 40);
      expect(clock.now().isBefore(downUntil), isTrue);
      expect(kills, isNotEmpty, reason: 'seed never killed the process');

      // A payment mismatch can never be enqueued from the UI path.
      final before = await _count(dev, 'outbox');
      await expectLater(
        dev.sales.createSale(
          SaleDraft(
            shopId: kShop,
            paymentMethod: 'split',
            lines: [
              SaleDraftLine.product(
                productId: kCatalog[0].id,
                productName: 'Tea',
                quantity: '1',
                unitPrice: '2.50',
              ),
            ],
            payments: const [SalePaymentPart(method: 'cash', amount: '2.48')],
          ),
        ),
        throwsA(isA<SaleValidationException>()),
      );
      expect(await _count(dev, 'outbox'), before);

      // Offline: nothing reached the server, everything is local + pending.
      expect(server.tables['sale'] ?? {}, isEmpty);
      expect((await dev.localSales()).keys.toSet(), confirmed);
      expect(await dev.notDone(), hasLength(43));
      final offlineDash = await dev.todayDashboard();
      expect(offlineDash.today.salesCount, 40);
      expect(offlineDash.includesLocalPendingSales, isTrue);
      for (final c in kCatalog) {
        expect(
          await dev.displayedUnits(c.id),
          Decimal3.parse(c.base) -
              (sold[c.id] ?? BigInt.zero) +
              (added[c.id] ?? BigInt.zero),
          reason: 'offline displayed stock ${c.name}',
        );
      }
      final order = [
        for (final row in await dev.notDone()) row['mutation_id'] as String,
      ];

      // ---- server UP: drain with faults and kills mid-sync ----
      clock.t = downUntil;
      view.down = false;
      const hooks = [
        'beforeResultWrite',
        'afterPushApplied',
        'beforePullPageCommit',
      ];
      for (var round = 0; round < 30; round++) {
        if (round < 4) {
          dev.crashAt = hooks[r.nextInt(hooks.length)];
          view.dropResponseAfterApply = r.nextInt(2);
        } else {
          dev.crashAt = null;
          view.dropResponseAfterApply = 0;
        }
        final o = await dev.sync();
        if (o == null) kills.add('sync-crash@$round');
        clock.advance(const Duration(hours: 1, minutes: 1)); // past backoff
        if (round >= 4 && (await dev.notDone()).isEmpty && await dev.atHead()) {
          break;
        }
      }

      // ---- invariants ----
      expect(await dev.notDone(), isEmpty, reason: 'outbox not drained');
      expect(await dev.rejectedCount(), 0);
      expect(await dev.atHead(), isTrue);

      // Applied in the order the cashier made them, each exactly once.
      final appliedOrder = server.applied.keys.where(order.contains).toList();
      expect(appliedOrder, order);
      expect(
        order.every((m) => server.applied[m]!.status == PushStatus.applied),
        isTrue,
      );
      final serverSales = server.tables['sale']!;
      expect(serverSales.keys.toSet(), confirmed, reason: 'lost/extra sale');
      final saleEmits = server.feed.where((c) => c.entity == 'sale').length;
      expect(saleEmits, 40, reason: 'a sale was applied twice');

      // Money: server == local == dashboard (Option A: Σ total_amount).
      final local = await dev.localSales();
      var serverSum = BigInt.zero;
      for (final s in serverSales.values) {
        final id = s['id'] as String;
        expect(
          cents(s['total_amount'] as String),
          cents(local[id]!),
          reason: 'sale $id total',
        );
        serverSum += cents(s['total_amount'] as String);
      }
      final localSum = local.values.fold(BigInt.zero, (a, v) => a + cents(v));
      expect(localSum, serverSum);
      expect(serverTotalFor(server, today), serverSum);
      final dash = await dev.todayDashboard();
      expect(dashCents(dash.today.grossSalesAmount), serverSum);
      expect(dash.today.salesCount, 40);
      expect(dash.includesLocalPendingSales, isFalse);
      // Local net/receipt adopted from the server.
      for (final row in await dev.db.query('sales')) {
        final s = serverSales[row['id']]!;
        expect(row['net_amount'], s['net_amount'], reason: 'net ${row['id']}');
        expect(row['receipt_number'], s['receipt_number']);
        expect(row['sync_state'], 'synced');
      }

      // Stock: server == local base == displayed == base - sold + added.
      for (final c in kCatalog) {
        final expected =
            Decimal3.parse(c.base) -
            (sold[c.id] ?? BigInt.zero) +
            (added[c.id] ?? BigInt.zero);
        expect(
          Decimal3.parse(server.stockQuantity(c.id, kShop)),
          expected,
          reason: 'server stock ${c.name}',
        );
        expect(await dev.baseUnits(c.id), expected, reason: 'base ${c.name}');
        expect(
          await dev.displayedUnits(c.id),
          expected,
          reason: 'displayed ${c.name}',
        );
      }
      expect(
        Decimal3.parse(server.stockQuantity(kCatalog[3].id, kShop)).isNegative,
        isTrue,
        reason: 'negative stock path not exercised',
      );
      // ignore: avoid_print
      print('seed $seed kills: ${kills.join(', ')}');
    });
  }
}

Future<int> _count(LifecycleDevice d, String table) async =>
    Sqflite.firstIntValue(await d.db.rawQuery('SELECT COUNT(*) FROM $table'))!;
