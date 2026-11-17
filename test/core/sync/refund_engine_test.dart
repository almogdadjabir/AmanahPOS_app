// Phase 4: refunds through the real SyncEngine, services and appliers
// against the FakeSyncServer (BE semantics), two devices.
import 'dart:io';
import 'dart:math';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/appliers/refund_applier.dart';
import 'package:amana_pos/core/sync/appliers/sale_applier.dart';
import 'package:amana_pos/core/sync/appliers/stock_applier.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/features/pos/data/local/sale_local_store.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/returns/domain/refund_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'support/engine_harness.dart';
import 'support/fake_sync_server.dart';
import 'support/test_db.dart';

const _scope = 'u1|t1';
const _shop = 'e0000000-0000-4000-8000-000000000001';

class _Dev {
  _Dev._(this.name);
  final String name;
  late OfflineDb odb;
  late Database db;
  late FakeSyncServer server;
  late OutboxStore outbox;
  late SyncStateStore state;
  late LocalWriter writer;
  late SyncEngine engine;
  late SaleService sales;
  late RefundService refunds;
  final notifier = DbChangeNotifier();
  final registry = ChangeApplierRegistry();
  DateTime clock = DateTime.utc(2026, 11, 17, 9);
  DateTime now() => clock;

  static Future<_Dev> create(FakeSyncServer shared, String name) async {
    final d = _Dev._(name);
    d.odb = await openTestDb();
    d.db = await d.odb.database;
    d.server = shared.forDevice(name);
    final transport = ScenarioTransport(d.server);
    d.outbox = OutboxStore(d.odb, now: d.now);
    d.state = SyncStateStore(d.odb, now: d.now, scope: _scope);
    d.writer = LocalWriter(
      d.odb,
      d.outbox,
      d.notifier,
      scopeProvider: () => _scope,
    );
    d.registry
      ..register(SaleApplier())
      ..register(RefundApplier())
      ..register(StockApplier());
    d.engine = SyncEngine(
      db: d.odb,
      transport: transport,
      outbox: d.outbox,
      state: d.state,
      scopeProvider: () => _scope,
      reachability: ServerReachability(transport, now: d.now),
      appliers: d.registry,
      notifier: d.notifier,
      appVersion: '1.0.0',
      backoff: Backoff(random: Random(1)),
      now: d.now,
    );
    d.sales = SaleService(
      writer: d.writer,
      state: d.state,
      cashierId: () => null,
      now: d.now,
    );
    d.refunds = RefundService(writer: d.writer, now: d.now);
    await d.db.insert('sync_state', {
      'key': 'device_id',
      'value': 'abcd1234-0000-4000-8000-0000000000${name.hashCode % 90 + 10}',
      'updated_at': '2026-01-01T00:00:00Z',
    });
    await d.db.transaction((t) async {
      await d.state.setCursor(t, EngineHarness.seedCursor);
      await d.state.setBootstrapped(t, true);
    });
    return d;
  }

  Future<void> sync() async {
    clock = clock.add(const Duration(hours: 2));
    await engine.syncNow();
  }

  Future<void> dispose() async {
    await engine.dispose();
    notifier.dispose();
    await db.close();
  }

  Future<Sale> sell(List<String> qtys) => sales.createSale(
    SaleDraft(
      shopId: _shop,
      paymentMethod: 'cash',
      lines: [
        for (var i = 0; i < qtys.length; i++)
          SaleDraftLine.custom(
            name: 'L$i',
            unitPrice: '${3 + i}.10',
            quantity: qtys[i],
          ),
      ],
    ),
  );

  Future<List<String>> lineIds(String saleId) async => [
    for (final r in await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'position',
    ))
      r['id'] as String,
  ];

  Future<Map<String, BigInt>> counted(String saleId) =>
      const SaleLocalStore().refundedQuantities(db, saleId);

  Future<int> states(String s) async => Sqflite.firstIntValue(
    await db.rawQuery(
      'SELECT COUNT(*) FROM sale_refunds WHERE sync_state = ?',
      [s],
    ),
  )!;
}

BigInt _units(String s) {
  final p = s.split('.');
  return BigInt.parse(p[0]) * BigInt.from(1000) +
      BigInt.parse(
        (p.length > 1 ? p[1] : '0').padRight(3, '0').substring(0, 3),
      );
}

void main() {
  late FakeSyncServer server;
  final devs = <_Dev>[];

  setUp(() {
    server = FakeSyncServer(now: () => DateTime.utc(2026, 11, 17, 9));
  });
  tearDown(() async {
    for (final d in devs) {
      await d.dispose();
    }
    devs.clear();
  });

  Future<_Dev> dev(String n) async {
    final d = await _Dev.create(server, n);
    devs.add(d);
    return d;
  }

  test(
    'offline sale then offline refund: both reach the server, refund counted once',
    () async {
      final a = await dev('dev-a');
      final sale = await a.sell(['3']);
      final line = (await a.lineIds(sale.id)).single;
      await a.refunds.refund(
        saleId: sale.id,
        quantitiesByLineId: {line: '2'},
        method: 'cash',
      );
      await a.sync();
      await a.sync();
      expect(await a.states('pending'), 0);
      expect(await a.db.query('sale_refunds'), hasLength(1));
      expect((await a.counted(sale.id))[line], _units('2'));
      expect(await a.db.query('outbox', where: "status != 'done'"), isEmpty);
      expect(server.tables['sale']![sale.id]!['status'], 'partial_refund');
    },
  );

  test(
    'two devices refund the same line: one applied, the other voided and flagged',
    () async {
      final a = await dev('dev-a');
      final b = await dev('dev-b');
      final sale = await a.sell(['3']);
      await a.sync();
      await b.sync();
      final line = (await a.lineIds(sale.id)).single;
      await a.refunds.refund(
        saleId: sale.id,
        quantitiesByLineId: {line: '3'},
        method: 'cash',
      );
      await b.refunds.refund(
        saleId: sale.id,
        quantitiesByLineId: {line: '3'},
        method: 'cash',
      );
      await a.sync();
      await b.sync();
      await a.sync();
      await b.sync();
      expect(await a.states('synced'), 1);
      expect(await b.states('rejected'), 1);
      expect(await b.states('synced'), 1, reason: "A's refund pulled onto B");
      expect((await b.counted(sale.id))[line], _units('3'));
      expect((await a.counted(sale.id))[line], _units('3'));
      final sb = (await b.db.query(
        'sales',
        where: 'id = ?',
        whereArgs: [sale.id],
      )).single;
      expect(sb['status'], 'refunded');
    },
  );

  test(
    'randomized refunds from two devices never exceed sold, never double count',
    () async {
      final seeds =
          int.tryParse(Platform.environment['CONV_SEEDS'] ?? '') ?? 15;
      for (var seed = 0; seed < seeds; seed++) {
        final r = Random(seed);
        for (final d in devs) {
          await d.dispose();
        }
        devs.clear();
        server = FakeSyncServer(now: () => DateTime.utc(2026, 11, 17, 9));
        final a = await dev('dev-a');
        final b = await dev('dev-b');
        final qtys = [for (var i = 0; i < 3; i++) '${r.nextInt(5) + 1}'];
        final sale = await a.sell(qtys);
        await a.sync();
        await b.sync();
        final lines = await a.lineIds(sale.id);
        for (var step = 0; step < 6; step++) {
          final d = r.nextBool() ? a : b;
          final i = r.nextInt(lines.length);
          final q = '${r.nextInt(3) + 1}';
          try {
            await d.refunds.refund(
              saleId: sale.id,
              quantitiesByLineId: {lines[i]: q},
              method: r.nextBool() ? 'cash' : 'bankak',
            );
          } on RefundValidationException {
            // refused locally: the guard held.
          }
          if (r.nextInt(3) == 0) await (r.nextBool() ? a : b).sync();
        }
        for (var k = 0; k < 3; k++) {
          await a.sync();
          await b.sync();
        }
        for (final d in [a, b]) {
          expect(await d.states('pending'), 0, reason: 'seed $seed ${d.name}');
          final counted = await d.counted(sale.id);
          for (var i = 0; i < lines.length; i++) {
            final onServer = server.refundedQuantity(sale.id, lines[i]);
            expect(
              counted[lines[i]] ?? BigInt.zero,
              onServer,
              reason: 'seed $seed ${d.name} line $i',
            );
            expect(onServer <= _units(qtys[i]), isTrue, reason: 'seed $seed');
          }
          // One counted row per refund the server holds.
          final counts = Sqflite.firstIntValue(
            await d.db.rawQuery(
              "SELECT COUNT(*) FROM sale_refunds WHERE sync_state != 'rejected'",
            ),
          )!;
          final serverRefunds = server.feed
              .where((c) => c.entity == 'refund')
              .length;
          expect(counts, serverRefunds, reason: 'seed $seed ${d.name} rows');
        }
      }
    },
  );
}
