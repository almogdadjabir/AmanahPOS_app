import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_db.dart';

void main() {
  late OfflineDb odb;
  late DateTime clock;
  late SyncStateStore store;

  setUp(() async {
    clock = DateTime.utc(2026, 1, 1, 12);
    odb = await openTestDb();
    store = SyncStateStore(odb, now: () => clock, scope: 'u1|t1');
  });

  tearDown(() async => (await odb.database).close());

  test('deviceId generated once and stable across store instances', () async {
    final a = await store.deviceId();
    expect(a, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(await store.deviceId(), a);
    expect(await SyncStateStore(odb).deviceId(), a);
  });

  test('cursor roundtrip and rolls back with its transaction', () async {
    expect(await store.cursor(), isNull);
    final db = await odb.database;
    await db.transaction((txn) => store.setCursor(txn, 'c1'));
    expect(await store.cursor(), 'c1');
    try {
      await db.transaction((txn) async {
        await store.setCursor(txn, 'c2');
        throw StateError('boom');
      });
    } on StateError {
      // expected
    }
    expect(await store.cursor(), 'c1');
  });

  test('clock skew, lastSyncedAt, capabilities roundtrip and clear', () async {
    expect(await store.clockSkew(), isNull);
    await store.setClockSkew(const Duration(hours: -3));
    expect(await store.clockSkew(), const Duration(hours: -3));
    final t = DateTime.utc(2026, 2, 3, 4, 5, 6);
    await store.setLastSyncedAt(t);
    expect(await store.lastSyncedAt(), t);
    expect(await store.capabilities(), isEmpty);
    await store.setCapabilities({'sales', 'stock'});
    expect(await store.capabilities(), {'sales', 'stock'});
    final id = await store.deviceId();
    await store.clear();
    expect(await store.clockSkew(), isNull);
    expect(await store.lastSyncedAt(), isNull);
    expect(await store.capabilities(), isEmpty);
    expect(await store.deviceId(), id, reason: 'device id survives clear');
  });

  group('lock', () {
    const ttl = Duration(seconds: 30);

    test('racing holders: exactly one wins', () async {
      final r = await Future.wait([
        store.acquireLock('a', ttl),
        store.acquireLock('b', ttl),
        store.acquireLock('c', ttl),
      ]);
      expect(r.where((e) => e).length, 1);
    });

    test(
      'same holder reacquires, other blocked until expiry takeover',
      () async {
        expect(await store.acquireLock('a', ttl), isTrue);
        expect(await store.acquireLock('a', ttl), isTrue);
        expect(await store.acquireLock('b', ttl), isFalse);
        clock = clock.add(const Duration(seconds: 31));
        expect(await store.acquireLock('b', ttl), isTrue);
        expect(await store.renewLock('a', ttl), isFalse);
      },
    );

    test(
      'renew by non-holder or expired holder fails; holder extends',
      () async {
        await store.acquireLock('a', ttl);
        expect(await store.renewLock('b', ttl), isFalse);
        clock = clock.add(const Duration(seconds: 20));
        expect(await store.renewLock('a', ttl), isTrue);
        clock = clock.add(const Duration(seconds: 20));
        expect(await store.acquireLock('b', ttl), isFalse);
        clock = clock.add(const Duration(seconds: 11));
        expect(await store.renewLock('a', ttl), isFalse);
      },
    );

    test('release by non-holder is a no-op; by holder frees it', () async {
      await store.acquireLock('a', ttl);
      await store.releaseLock('b');
      expect(await store.acquireLock('b', ttl), isFalse);
      await store.releaseLock('a');
      expect(await store.acquireLock('b', ttl), isTrue);
    });

    test('lock persists across new store over the same db', () async {
      await store.acquireLock('a', ttl);
      final other = SyncStateStore(odb, now: () => clock);
      expect(await other.acquireLock('b', ttl), isFalse);
      expect(await other.renewLock('a', ttl), isTrue);
    });

    test('clear does not drop the lock', () async {
      await store.acquireLock('a', ttl);
      await store.clear();
      expect(await store.acquireLock('b', ttl), isFalse);
    });
  });

  test('lock written by a clock ahead is treated as expired', () async {
    const ttl = Duration(minutes: 2);
    final realNow = clock;
    clock = realNow.add(const Duration(days: 1));
    expect(await store.acquireLock('a', ttl), isTrue);
    clock = realNow;
    expect(await store.renewLock('a', ttl), isFalse);
    expect(await store.acquireLock('b', ttl), isTrue);
    expect(await store.renewLock('b', ttl), isTrue);
  });

  test('repair flag roundtrip', () async {
    expect(await store.repairNeeded(), isFalse);
    await store.setRepairNeeded();
    expect(await store.repairNeeded(), isTrue);
    await store.clear(); // sync progress reset keeps the repair flag
    expect(await store.repairNeeded(), isTrue);
    await store.clearRepairNeeded();
    expect(await store.repairNeeded(), isFalse);
  });

  test(
    'deferred pull json roundtrips in a transaction and clear() drops it',
    () async {
      final db = await odb.database;
      await db.transaction((t) => store.setDeferredPullJson(t, '{"a":1}'));
      expect(await store.deferredPullJson(db), '{"a":1}');
      await store.clear();
      expect(await store.deferredPullJson(db), isNull);
      await db.transaction((t) => store.setDeferredPullJson(t, '{}'));
      await db.transaction((t) => store.setDeferredPullJson(t, null));
      expect(await store.deferredPullJson(db), isNull);
    },
  );

  test('small clock step back (within slack) keeps a live lock', () async {
    const ttl = Duration(minutes: 2);
    final realNow = clock;
    clock = realNow.add(const Duration(seconds: 30));
    expect(await store.acquireLock('a', ttl), isTrue);
    clock = realNow;
    expect(await store.acquireLock('b', ttl), isFalse);
    expect(await store.renewLock('a', ttl), isTrue);
  });

  group('bootstrap state', () {
    BootstrapProgress sample() => BootstrapProgress(
      snapshotCursor: 'snap1',
      entities: const ['business', 'shop', 'product'],
      done: const ['business'],
      pageCursor: 'pc1',
      startedAt: DateTime.utc(2026, 11, 16, 9),
    );

    test('progress roundtrips per scope; other scope sees none', () async {
      final db = await odb.database;
      expect(await store.bootstrapProgress(db), isNull);
      await db.transaction((t) => store.setBootstrapProgress(t, sample()));
      final p = (await store.bootstrapProgress(db))!;
      expect(p.snapshotCursor, 'snap1');
      expect(p.entities, ['business', 'shop', 'product']);
      expect(p.done, ['business']);
      expect(p.pageCursor, 'pc1');
      expect(p.startedAt, DateTime.utc(2026, 11, 16, 9));
      final other = store.forScope('u2|t1');
      expect(await other.bootstrapProgress(db), isNull);
      await db.transaction((t) => store.setBootstrapProgress(t, null));
      expect(await store.bootstrapProgress(db), isNull);
    });

    test(
      'bootstrapped flag is scoped; clear() drops progress, keeps flag',
      () async {
        final db = await odb.database;
        expect(await store.isBootstrapped(), isFalse);
        await db.transaction((t) async {
          await store.setBootstrapProgress(t, sample());
          await store.setBootstrapped(t, true);
        });
        expect(await store.isBootstrapped(), isTrue);
        expect(await store.forScope('u2|t1').isBootstrapped(), isFalse);
        await store.clear();
        expect(await store.bootstrapProgress(db), isNull);
        expect(await store.isBootstrapped(), isTrue);
        await db.transaction((t) => store.setBootstrapped(t, false));
        expect(await store.isBootstrapped(), isFalse);
      },
    );

    test(
      'progress write rolls back with its transaction; corrupt value is null',
      () async {
        final db = await odb.database;
        try {
          await db.transaction((t) async {
            await store.setBootstrapProgress(t, sample());
            throw StateError('boom');
          });
        } on StateError {
          // expected
        }
        expect(await store.bootstrapProgress(db), isNull);
        await db.insert('sync_state', {
          'key': 'bootstrap_progress|u1|t1',
          'value': 'not json',
          'updated_at': 'x',
        });
        expect(await store.bootstrapProgress(db), isNull);
      },
    );

    // Ruling T11-a: the first-setup gate is per TENANT (catalog tables are
    // shared by the tenant's users on this device).
    test(
      'isTenantBootstrapped: any scope of the tenant, exact parsing',
      () async {
        final db = await odb.database;
        expect(await store.isTenantBootstrapped('t1'), isFalse);
        await db.transaction((t) => store.setBootstrapped(t, true));
        expect(await store.isTenantBootstrapped('t1'), isTrue);
        expect(
          await store.forScope('u9|t1').isTenantBootstrapped('t1'),
          isTrue,
          reason: 'any scope of the tenant',
        );
        expect(await store.isTenantBootstrapped('t2'), isFalse);
        expect(
          await store.isTenantBootstrapped('t'),
          isFalse,
          reason: 'prefix',
        );
        expect(
          await store.isTenantBootstrapped('t_'),
          isFalse,
          reason: 'no LIKE wildcard',
        );
        expect(await store.isTenantBootstrapped('%'), isFalse);
        expect(await store.isTenantBootstrapped(''), isFalse);
        // Look-alike / malformed keys never count.
        for (final k in [
          'bootstrapped|u1|t1x',
          'bootstrapped|t3',
          'bootstrapped||t3',
          'bootstrapped|a|b|t3',
          'bootstrappedX|u1|t3',
          'bootstrapped_|u1|t3',
        ]) {
          await db.insert('sync_state', {
            'key': k,
            'value': '1',
            'updated_at': 'x',
          });
        }
        expect(await store.isTenantBootstrapped('t1x'), isTrue);
        expect(await store.isTenantBootstrapped('t3'), isFalse);
        await db.insert('sync_state', {
          'key': 'bootstrapped|u5|t4',
          'value': '0',
          'updated_at': 'x',
        });
        expect(await store.isTenantBootstrapped('t4'), isFalse);
        // The logout / business-switch wipe resets the tenant gate too.
        await db.transaction(SyncStateStore.resetSetupOfAllScopes);
        expect(await store.isTenantBootstrapped('t1'), isFalse);
        expect(await store.isTenantBootstrapped('t1x'), isFalse);
      },
    );
  });

  group('audit state', () {
    test('round-trips and is scope isolated', () async {
      expect(await store.auditState(), isNull);
      expect(await store.lastAuditAt(), isNull);
      final st = AuditState(
        status: AuditState.drift,
        at: DateTime.utc(2026, 11, 17, 8),
        detail: {
          'sale': {'localCount': 3, 'serverCount': 4},
        },
      );
      await store.setAuditState(st);
      await store.setLastAuditAt(DateTime.utc(2026, 11, 17, 8));
      final back = (await store.auditState())!;
      expect(back.isDrift, isTrue);
      expect(back.detail['sale']['serverCount'], 4);
      expect(await store.lastAuditAt(), DateTime.utc(2026, 11, 17, 8));
      final other = store.forScope('u2|t1');
      expect(await other.auditState(), isNull);
      expect(await other.lastAuditAt(), isNull);
    });

    test('clear removes both; null removes the state', () async {
      await store.setAuditState(
        AuditState(status: AuditState.ok, at: DateTime.utc(2026)),
      );
      await store.setLastAuditAt(DateTime.utc(2026));
      await store.clear();
      expect(await store.auditState(), isNull);
      expect(await store.lastAuditAt(), isNull);
      await store.setAuditState(
        AuditState(status: AuditState.ok, at: DateTime.utc(2026)),
      );
      await store.setAuditState(null);
      expect(await store.auditState(), isNull);
    });

    test('corrupt JSON reads as null', () async {
      final db = await odb.database;
      await db.insert('sync_state', {
        'key': 'audit_state|u1|t1',
        'value': '{nope',
        'updated_at': 'x',
      });
      expect(await store.auditState(), isNull);
    });
  });
}
