import 'dart:convert';
import 'dart:io';

import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Phase 7 perf budgets from the parent spec ("Test strategy" #6). Each
/// asserts the MEDIAN of [_runs] timed runs after a warm-up. Dashboard 50k
/// lives in local_dashboard_queries_test.dart, sale save in
/// features/pos/sale_crash_test.dart.
const _runs = 9;

Future<Duration> _median(Future<void> Function() body) async {
  await body();
  final t = <int>[];
  for (var i = 0; i < _runs; i++) {
    final sw = Stopwatch()..start();
    await body();
    sw.stop();
    t.add(sw.elapsedMicroseconds);
  }
  t.sort();
  return Duration(microseconds: t[t.length ~/ 2]);
}

Future<void> _seedProducts(OfflineDb odb, int n) async {
  final db = await odb.database;
  final batch = db.batch();
  for (var i = 0; i < n; i++) {
    final name = 'Product ${i.toString().padLeft(5, '0')} item';
    batch.insert('products', {
      'id': 'p$i',
      'category_id': 'c${i % 40}',
      'name': name,
      'sku': 'SKU$i',
      'barcode': '6${i.toString().padLeft(11, '0')}',
      'price': '12.500',
      'stock_level': 10.0,
      'json': jsonEncode({
        'id': 'p$i',
        'category': 'c${i % 40}',
        'category_name': 'Cat ${i % 40}',
        'name': name,
        'description': 'A reasonably typical product description text.',
        'sku': 'SKU$i',
        'barcode': '6${i.toString().padLeft(11, '0')}',
        'price': '12.500',
        'cost_price': '8.000',
        'unit': 'pcs',
        'is_active': true,
        'track_inventory': true,
        'min_stock_level': 2.0,
        'stock_level': 10.0,
        'created_at': '2026-01-01T00:00:00Z',
      }),
      'updated_at': '2026-01-01T00:00:00Z',
    });
  }
  await batch.commit(noResult: true);
}

void main() {
  late Directory dir;
  setUp(() async {
    sqfliteFfiInit();
    dir = await Directory.systemTemp.createTemp('perf_budgets');
  });
  tearDown(() async => dir.delete(recursive: true));

  Future<OfflineDb> openFile() async {
    final db = await databaseFactoryFfi.openDatabase(
      '${dir.path}/pos.db',
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

  test(
    'first page of the product list / search on 20k products < 16 ms',
    () async {
      final odb = await openFile();
      addTearDown(() async => (await odb.database).close());
      await _seedProducts(odb, 20000);
      final cache = OfflineLocalCache(odb);

      // A screen shows a page: the budget is the first page (limit 50).
      final list = await _median(() => cache.getProducts(limit: 50));
      final prefix = await _median(
        () => cache.getProducts(search: 'Product 123', limit: 50),
      );
      final mid = await _median(
        () => cache.getProducts(search: 'item', limit: 50),
      );
      // ignore: avoid_print
      print(
        'products 20k: list=${list.inMicroseconds / 1000} ms, '
        'prefix search=${prefix.inMicroseconds / 1000} ms, '
        'broad search=${mid.inMicroseconds / 1000} ms',
      );
      expect(list, lessThan(const Duration(milliseconds: 16)));
      expect(prefix, lessThan(const Duration(milliseconds: 16)));
      expect(mid, lessThan(const Duration(milliseconds: 16)));
    },
  );

  test('limit together with isActive is rejected at runtime', () async {
    final odb = await openFile();
    addTearDown(() async => (await odb.database).close());
    expect(
      () => OfflineLocalCache(odb).getProducts(limit: 10, isActive: true),
      throwsArgumentError,
    );
  });

  test('cold start to first POS query < 1 s with local data', () async {
    var odb = await openFile();
    await _seedProducts(odb, 20000);
    await (await odb.database).close();

    final sw = Stopwatch()..start();
    odb = await openFile();
    final first = await OfflineLocalCache(odb).getProducts(isActive: true);
    sw.stop();
    addTearDown(() async => (await odb.database).close());
    // ignore: avoid_print
    print(
      'cold start (open + first product list): ${sw.elapsedMilliseconds} ms',
    );
    expect(first, hasLength(20000));
    expect(sw.elapsed, lessThan(const Duration(seconds: 1)));
    expect(
      Sqflite.firstIntValue(
        await (await odb.database).rawQuery('SELECT COUNT(*) FROM products'),
      ),
      20000,
    );
  });
}
