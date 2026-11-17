import 'dart:convert';

import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/appliers/vendor_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/features/inventory/data/models/responses/vendor_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../sync/support/test_db.dart';

PullChange _vendor(String id, int v, {bool active = true, String? name}) =>
    PullChange(
      seq: 0,
      entity: 'vendor',
      op: 'upsert',
      id: id,
      version: v,
      data: {
        'id': id,
        'name': name ?? 'Vendor $id',
        'is_active': active,
        'version': v,
      },
    );

/// REST `saveVendors` (active-only, paged list) must never erase vendors the
/// sync applier wrote, and must never lose a row's feed `version`.
void main() {
  late OfflineDb odb;
  late Database db;
  late OfflineLocalCache cache;

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
    cache = OfflineLocalCache(odb);
  });
  tearDown(() async => db.close());

  Future<void> apply(PullChange c) =>
      db.transaction((txn) => VendorApplier().apply(txn, c));

  Future<Map<String, Object?>?> row(String id) async {
    final r = await db.query('vendors', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : r.first;
  }

  String nameOf(Map<String, Object?>? r) =>
      (jsonDecode(r!['json'] as String) as Map<String, dynamic>)['name']
          as String;

  test(
    'REST list without a synced (inactive) vendor keeps that vendor',
    () async {
      await apply(_vendor('v1', 3));
      await apply(_vendor('v2', 5, active: false)); // not in the REST list

      await cache.saveVendors([
        const VendorData(id: 'v1', name: 'Renamed v1', isActive: true),
        const VendorData(id: 'v3', name: 'Only REST', isActive: true),
      ]);

      expect(await row('v2'), isNotNull);
      expect(nameOf(await row('v1')), 'Renamed v1');
      expect(nameOf(await row('v3')), 'Only REST');
      // The row stays in the table; the active-only read hides it (F1).
      final ids = (await cache.getVendors()).map((v) => v.id).toSet();
      expect(ids, {'v1', 'v3'});
    },
  );

  test('getVendors hides inactive vendors but keeps their rows (F1)', () async {
    await apply(_vendor('a', 1));
    await apply(_vendor('off', 2, active: false));
    // A REST deactivation (vendors screen update) is hidden too.
    await cache.saveVendors([
      const VendorData(id: 'rest-off', name: 'Rest off', isActive: false),
    ]);

    final vendors = await cache.getVendors();
    expect(vendors.map((v) => v.id).toSet(), {'a'});
    expect(vendors.single.isActive, isTrue);
    expect(await row('off'), isNotNull);
    expect(await row('rest-off'), isNotNull);

    // Reactivation through the feed shows it again.
    await apply(_vendor('off', 3));
    expect((await cache.getVendors()).map((v) => v.id).toSet(), {'a', 'off'});
  });

  test('REST overwrite keeps the feed version: an older feed row cannot roll '
      'it back, a newer one applies', () async {
    await apply(_vendor('v1', 3, name: 'Feed v3'));
    await cache.saveVendors([
      const VendorData(id: 'v1', name: 'REST', isActive: true),
    ]);
    expect((await row('v1'))!['version'], 3);

    await apply(_vendor('v1', 2, name: 'Stale v2'));
    expect(nameOf(await row('v1')), 'REST');

    await apply(_vendor('v1', 4, name: 'Feed v4'));
    expect(nameOf(await row('v1')), 'Feed v4');
  });

  test('removeVendorFromCache deletes only that vendor', () async {
    await apply(_vendor('v1', 1));
    await apply(_vendor('v2', 1));
    await cache.removeVendorFromCache('v1');
    expect(await row('v1'), isNull);
    expect(await row('v2'), isNotNull);
  });
}
