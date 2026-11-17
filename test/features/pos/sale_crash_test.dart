import 'dart:io';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/features/pos/domain/sale.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/sale_fixture.dart';

/// Crash injection for the money path (plan Review Focus #1): the process
/// dies between "sale rows written" and "UI confirms". The DB is a real file
/// that is closed and reopened, like a relaunch.
void main() {
  late Directory dir;
  late String path;

  setUp(() async {
    sqfliteFfiInit();
    dir = await Directory.systemTemp.createTemp('sale_crash');
    path = '${dir.path}/pos.db';
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  Future<OfflineDb> open() async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        singleInstance: false,
        version: OfflineDb.schemaVersion,
        onConfigure: OfflineDb.onConfigure,
        onCreate: OfflineDb.onCreate,
        onUpgrade: OfflineDb.onUpgrade,
      ),
    );
    return OfflineDb.forTesting(db);
  }

  const draft = SaleDraft(
    shopId: kShop,
    paymentMethod: 'cash',
    lines: [
      SaleDraftLine.product(
        productId: kP1,
        productName: 'Tea',
        quantity: '3',
        unitPrice: '2.50',
      ),
    ],
  );

  Future<void> expectAfterRelaunch({
    required int sales,
    required int outbox,
    required double quantity,
  }) async {
    final odb = await open();
    final db = await odb.database;
    addTearDown(db.close);
    Future<int> count(String t) async =>
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $t'))!;
    expect(await count('sales'), sales);
    expect(await count('sale_items'), sales);
    expect(await count('sale_payments'), sales);
    expect(await count('outbox'), outbox);
    final s = (await db.query(
      'stock',
      where: 'product_id = ?',
      whereArgs: [kP1],
    )).single;
    expect((s['quantity'] as num).toDouble(), quantity);
    expect(s['base_quantity'], '10');
  }

  test('killed after the sale rows, before commit: relaunch shows no sale, '
      'no outbox row, stock untouched', () async {
    final f = await SaleFixture.on(await open());
    final service = f.service(
      debugHook: (stage) async {
        if (stage == 'beforeCommit') {
          // The rows exist inside the open transaction at this point.
          throw CrashSimulation('sale beforeCommit');
        }
      },
    );
    await expectLater(
      service.createSale(draft),
      throwsA(isA<CrashSimulation>()),
    );
    await f.db.close();
    await expectAfterRelaunch(sales: 0, outbox: 0, quantity: 10);

    // The local receipt counter rolled back with the sale: the next sale
    // after relaunch takes number 1 again (no gap, no reuse of a committed one).
    final odb = await open();
    final db = await odb.database;
    addTearDown(db.close);
    final counter = await db.query(
      'sync_state',
      where: 'key = ?',
      whereArgs: ['local_receipt_counter'],
    );
    expect(counter, isEmpty);
    final next = await db.transaction(
      (txn) => SyncStateStore(odb).nextLocalReceiptCounter(txn),
    );
    expect(next, 1);
  });

  test('killed right after commit (before the UI confirms): relaunch shows '
      'exactly one sale, one outbox row, stock decremented once', () async {
    final f = await SaleFixture.on(await open());
    final service = f.service(
      debugHook: (stage) async {
        if (stage == 'afterCommit') throw CrashSimulation('sale afterCommit');
      },
    );
    await expectLater(
      service.createSale(draft),
      throwsA(isA<CrashSimulation>()),
    );
    await f.db.close();
    await expectAfterRelaunch(sales: 1, outbox: 1, quantity: 7);
  });

  test('beforeCommit hook really runs inside the transaction with the rows '
      'written', () async {
    final f = await SaleFixture.on(await open());
    addTearDown(f.db.close);
    var seen = false;
    final service = f.service(
      debugHook: (stage) async {
        if (stage == 'beforeCommit') seen = true;
      },
    );
    await service.createSale(draft);
    expect(seen, isTrue);
  });

  // Review I5: synchronous=FULL fsyncs every commit. A sale is ONE commit;
  // on a real file DB the save must stay well inside the checkout budget.
  test('sale save on a file DB with synchronous=FULL stays under 100 ms '
      'per sale on average', () async {
    final f = await SaleFixture.on(await open());
    addTearDown(f.db.close);
    final mode = await f.db.rawQuery('PRAGMA synchronous');
    expect(mode.single.values.single, 2);
    final service = f.service();
    await service.createSale(draft); // warm-up
    const n = 50;
    final sw = Stopwatch()..start();
    for (var i = 0; i < n; i++) {
      await service.createSale(draft);
    }
    sw.stop();
    final avgMs = sw.elapsedMicroseconds / n / 1000;
    // ignore: avoid_print
    print(
      'sale save (file db, synchronous=FULL): ${avgMs.toStringAsFixed(2)} ms avg',
    );
    expect(avgMs, lessThan(100));
  });
}
