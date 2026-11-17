import 'dart:convert';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/appliers/bankak_account_applier.dart';
import 'package:amana_pos/core/sync/appliers/customer_applier.dart';
import 'package:amana_pos/core/sync/appliers/expiry_batch_applier.dart';
import 'package:amana_pos/core/sync/appliers/notification_applier.dart';
import 'package:amana_pos/core/sync/appliers/subscription_applier.dart';
import 'package:amana_pos/core/sync/appliers/synced_entities_store.dart';
import 'package:amana_pos/core/sync/appliers/user_applier.dart';
import 'package:amana_pos/core/sync/appliers/vendor_applier.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/sync_appliers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/test_db.dart';

PullChange _up(String entity, String id, int? v, Map<String, dynamic> d) =>
    PullChange(
      seq: 0,
      entity: entity,
      op: 'upsert',
      id: id,
      version: v,
      data: d,
    );

PullChange _del(String entity, String id) =>
    PullChange(seq: 0, entity: entity, op: 'delete', id: id);

void main() {
  late OfflineDb odb;
  late Database db;

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
  });
  tearDown(() async => db.close());

  Future<void> run(ChangeApplier a, PullChange c) =>
      db.transaction((txn) => a.apply(txn, c));

  Future<Map<String, Object?>?> row(String t, String id) async {
    final r = await db.query(t, where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : r.first;
  }

  Map<String, dynamic> js(Map<String, Object?>? r) =>
      jsonDecode(r!['json'] as String) as Map<String, dynamic>;

  Future<Map<String, dynamic>?> synced(String e, String id) async {
    final r = await db.query(
      'synced_entities',
      where: 'entity = ? AND id = ?',
      whereArgs: [e, id],
    );
    return r.isEmpty ? null : js(r.first);
  }

  Future<int?> syncedVersion(String e, String id) =>
      const SyncedEntitiesStore().localVersion(db, e, id);

  test('registration of all seven', () {
    final r = buildSyncAppliers();
    for (final e in [
      'customer',
      'vendor',
      'expiry_batch',
      'user',
      'subscription',
      'notification',
      'bankak_account',
    ]) {
      expect(r.of(e), isNotNull, reason: e);
    }
    final tables = syncedLocalTables(r);
    expect(tables, containsAll(['customers', 'vendors', 'synced_entities']));
  });

  test('vendors table has version column on a fresh DB', () async {
    final cols = await db.rawQuery('PRAGMA table_info(vendors)');
    expect(cols.any((c) => c['name'] == 'version'), isTrue);
  });

  group('customer', () {
    final a = CustomerApplier();
    Map<String, dynamic> c({int points = 40}) => {
      'id': 'c1',
      'version': 2,
      'name': 'Sara',
      'phone': '0911',
      'email': 's@x.com',
      'address': 'Khartoum',
      'notes': null,
      'loyalty_points': points,
      'is_active': true,
      'updated_at': '2026-01-01T00:00:00Z',
    };

    test('upsert writes legacy row, loyalty stored as sent', () async {
      await run(a, _up('customer', 'c1', 2, c(points: 40)));
      final r = await row('customers', 'c1');
      expect(r!['name'], 'Sara');
      expect(r['phone'], '0911');
      expect(r['email'], 's@x.com');
      expect(r['version'], 2);
      expect(js(r)['loyalty_points'], 40);
      expect(js(r)['is_active'], true);
    });

    test('newer wins, equal/older no-op', () async {
      await run(a, _up('customer', 'c1', 2, c()));
      await run(a, _up('customer', 'c1', 2, {...c(), 'name': 'Same'}));
      await run(a, _up('customer', 'c1', 1, {...c(), 'name': 'Old'}));
      expect((await row('customers', 'c1'))!['name'], 'Sara');
      await run(
        a,
        _up('customer', 'c1', 3, {...c(points: 99), 'version': 3, 'name': 'N'}),
      );
      final r = await row('customers', 'c1');
      expect(r!['name'], 'N');
      expect(js(r)['loyalty_points'], 99);
    });

    test('delete and malformed', () async {
      await run(a, _up('customer', 'c1', 2, c()));
      await run(a, _del('customer', 'c1'));
      expect(await row('customers', 'c1'), isNull);
      await run(a, _up('customer', 'bad', 1, {'id': 'bad'}));
      await run(a, _up('customer', 'bad2', null, c()..remove('version')));
      await run(a, _up('customer', 'bad3', 1, {...c(), 'name': 5}));
      await run(a, _up('customer', 'bad4', 1, {...c(), 'loyalty_points': 'x'}));
      expect(await odb.countRows('customers'), 0);
    });
  });

  group('vendor', () {
    final a = VendorApplier();
    Map<String, dynamic> v() => {
      'id': 'v1',
      'version': 1,
      'name': 'Acme',
      'phone': '1',
      'email': null,
      'address': null,
      'notes': null,
      'is_active': true,
      'updated_at': 't',
    };

    test('upsert, versions, delete, malformed', () async {
      await run(a, _up('vendor', 'v1', 1, v()));
      var r = await row('vendors', 'v1');
      expect(r!['version'], 1);
      expect(js(r)['name'], 'Acme');
      expect(js(r)['is_active'], true);
      await run(a, _up('vendor', 'v1', 1, {...v(), 'name': 'Eq'}));
      expect(js(await row('vendors', 'v1'))['name'], 'Acme');
      await run(a, _up('vendor', 'v1', 2, {...v(), 'version': 2, 'name': 'B'}));
      r = await row('vendors', 'v1');
      expect(js(r)['name'], 'B');
      expect(r!['version'], 2);
      await run(a, _del('vendor', 'v1'));
      expect(await row('vendors', 'v1'), isNull);
      await run(a, _up('vendor', 'v2', 1, {'id': 'v2'}));
      await run(a, _up('vendor', 'v3', 1, {...v(), 'is_active': 'yes'}));
      expect(await odb.countRows('vendors'), 0);
    });
  });

  group('expiry_batch', () {
    final a = ExpiryBatchApplier();
    Map<String, dynamic> e() => {
      'id': 'e1',
      'product': 'p1',
      'shop': 's1',
      'quantity': '5.000',
      'expiry_date': '2027-01-01',
      'batch_number': 'B1',
      'updated_at': 't1',
    };

    test('upsert, replace (unversioned), delete, malformed', () async {
      await run(a, _up('expiry_batch', 'e1', null, e()));
      expect((await synced('expiry_batch', 'e1'))!['quantity'], '5.000');
      await run(
        a,
        _up('expiry_batch', 'e1', null, {...e(), 'quantity': '2.000'}),
      );
      expect((await synced('expiry_batch', 'e1'))!['quantity'], '2.000');
      await run(a, _del('expiry_batch', 'e1'));
      expect(await synced('expiry_batch', 'e1'), isNull);
      await run(a, _up('expiry_batch', 'x', null, {...e(), 'quantity': 'abc'}));
      await run(a, _up('expiry_batch', 'y', null, {'id': 'y'}));
      expect(await odb.countRows('synced_entities'), 0);
    });
  });

  group('user', () {
    final a = UserApplier();
    Map<String, dynamic> u({int v = 1}) => {
      'id': 'u9',
      'version': v,
      'phone': '0900',
      'full_name': 'Ali',
      'role': 'cashier',
      'default_shop': 's1',
      'is_active': true,
      'status': 'active',
      'last_login_at': null,
      'created_at': 'c',
    };

    test('versioned, delete, malformed, no auth side effects', () async {
      await run(a, _up('user', 'u9', 1, u()));
      expect((await synced('user', 'u9'))!['role'], 'cashier');
      await run(a, _up('user', 'u9', 1, {...u(), 'role': 'owner'}));
      await run(a, _up('user', 'u9', 0, {...u(v: 0), 'role': 'owner'}));
      expect((await synced('user', 'u9'))!['role'], 'cashier');
      await run(a, _up('user', 'u9', 2, {...u(v: 2), 'role': 'manager'}));
      expect((await synced('user', 'u9'))!['role'], 'manager');
      expect(await syncedVersion('user', 'u9'), 2);
      await run(a, _del('user', 'u9'));
      expect(await synced('user', 'u9'), isNull);
      await run(a, _up('user', 'z', 1, {'id': 'z'}));
      expect(await odb.countRows('synced_entities'), 0);
    });
  });

  group('subscription', () {
    final a = SubscriptionApplier();
    Map<String, dynamic> s() => {
      'id': 'sub1',
      'start_date': '2026-01-01',
      'end_date': '2027-01-01',
      'is_active': true,
      'is_expired': false,
      'days_remaining': 100,
      'plan': {'id': 'pl', 'name': 'Pro', 'price': '10.00'},
    };

    test('upsert replaces, delete, malformed', () async {
      await run(a, _up('subscription', 'sub1', null, s()));
      expect((await synced('subscription', 'sub1'))!['plan']['name'], 'Pro');
      await run(
        a,
        _up('subscription', 'sub1', null, {...s(), 'days_remaining': 5}),
      );
      expect((await synced('subscription', 'sub1'))!['days_remaining'], 5);
      await run(a, _del('subscription', 'sub1'));
      expect(await synced('subscription', 'sub1'), isNull);
      await run(a, _up('subscription', 'b', null, {...s(), 'plan': 'x'}));
      await run(a, _up('subscription', 'c', null, {'id': 'c'}));
      expect(await odb.countRows('synced_entities'), 0);
    });
  });

  group('notification', () {
    final a = NotificationApplier();
    Map<String, dynamic> n() => {
      'id': 'n1',
      'title': 'T',
      'body': 'B',
      'notification_type': 'info',
      'is_read': false,
      'data': {'k': 1},
      'created_at': 'c',
    };

    test('upsert replaces, delete, malformed', () async {
      await run(a, _up('notification', 'n1', null, n()));
      await run(a, _up('notification', 'n1', null, {...n(), 'is_read': true}));
      expect((await synced('notification', 'n1'))!['is_read'], true);
      await run(a, _del('notification', 'n1'));
      expect(await synced('notification', 'n1'), isNull);
      await run(a, _up('notification', 'm', null, {'id': 'm'}));
      expect(await odb.countRows('synced_entities'), 0);
    });
  });

  group('bankak_account', () {
    final a = BankakAccountApplier();
    Map<String, dynamic> b() => {
      'id': 'b1',
      'account_number': '123',
      'account_name': 'Shop',
      'is_default': true,
      'is_active': true,
    };

    test('upsert replaces, delete, malformed', () async {
      await run(a, _up('bankak_account', 'b1', null, b()));
      await run(
        a,
        _up('bankak_account', 'b1', null, {...b(), 'account_name': 'New'}),
      );
      expect((await synced('bankak_account', 'b1'))!['account_name'], 'New');
      await run(a, _del('bankak_account', 'b1'));
      expect(await synced('bankak_account', 'b1'), isNull);
      await run(a, _up('bankak_account', 'q', null, {'id': 'q'}));
      expect(await odb.countRows('synced_entities'), 0);
    });
  });
}
