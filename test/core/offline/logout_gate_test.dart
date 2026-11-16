import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/core/network/app_interceptors.dart';
import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:dio/dio.dart';
import 'package:amana_pos/core/offline/offline_first_manager.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/offline/presentation/bloc/offline_status_bloc.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';

import '../sync/support/test_db.dart';

class _NoopStorage implements CacheStorage {
  @override
  Future<bool> resetTokens() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockNet extends Mock implements NetworkMonitor {}

class _MockCache extends Mock implements OfflineLocalCache {}

class _MockFirst extends Mock implements OfflineFirstManager {}

void main() {
  late OfflineDb odb;
  late Database db;
  late OutboxStore store;

  OfflineStatusBloc bloc() => OfflineStatusBloc(
    networkMonitor: _MockNet(),
    localCache: _MockCache(),
    offlineFirstManager: _MockFirst(),
    outboxUnsyncedCount: () => store.unsyncedCount(),
  );

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
    store = OutboxStore(odb);
  });
  tearDown(() async => db.close());

  Future<void> enq(String scope, OutboxStatus status) async {
    final e = await store.enqueue(
      db,
      entity: 'sale',
      op: 'create',
      entityId: 'e-${DateTime.now().microsecondsSinceEpoch}-$status',
      payload: {'a': 1},
      scope: scope,
    );
    await db.update(
      'outbox',
      {'status': status.name},
      where: 'seq = ?',
      whereArgs: [e.seq],
    );
  }

  test('empty outbox: gate is 0', () async {
    expect(await bloc().blockingPendingOfflineSalesCount, 0);
  });

  for (final s in [
    OutboxStatus.pending,
    OutboxStatus.inflight,
    OutboxStatus.blocked,
    OutboxStatus.rejected,
  ]) {
    test('outbox row in state ${s.name} (foreign scope) blocks', () async {
      await enq('other|t9', s);
      expect(await bloc().blockingPendingOfflineSalesCount, 1);
    });
  }

  test('scope-less legacy row (scope empty) blocks', () async {
    await enq('', OutboxStatus.pending);
    expect(await bloc().blockingPendingOfflineSalesCount, 1);
  });

  test('done row does not block', () async {
    await enq('u1|t1', OutboxStatus.done);
    expect(await bloc().blockingPendingOfflineSalesCount, 0);
  });

  test('gate = unsynced outbox rows of every scope, done excluded', () async {
    await enq('u1|t1', OutboxStatus.pending);
    await enq('u1|t1', OutboxStatus.done);
    await enq('u2|t2', OutboxStatus.rejected);
    await enq('u3|t3', OutboxStatus.blocked);
    expect(await bloc().blockingPendingOfflineSalesCount, 3);
    expect(await bloc().pendingOfflineSalesCount, 3);
  });

  group('wipes never destroy unsynced data', () {
    Future<int> count(String t) async =>
        (await db.rawQuery('SELECT COUNT(*) c FROM $t')).first['c'] as int;

    Future<void> seed() async {
      await enq('u1|t1', OutboxStatus.pending);
      await enq('u2|t2', OutboxStatus.rejected);
      await db.insert('products', {
        'id': 'p1',
        'json': '{}',
        'updated_at': 'x',
      });
      await db.insert('sync_state', {
        'key': 'cursor|u1|t1',
        'value': 'c1',
        'updated_at': 'x',
      });
    }

    Future<void> expectOutboxIntact() async {
      expect(await count('outbox'), 2);
      expect(await count('sync_state'), 1);
      expect(await count('products'), 0, reason: 'reference data wiped');
    }

    test('clearAllLocalOfflineData keeps outbox and sync_state', () async {
      await seed();
      await odb.clearAllLocalOfflineData();
      await expectOutboxIntact();
    });

    test('clearAllOnLogout keeps outbox and sync_state', () async {
      await seed();
      await OfflineLocalCache(odb).clearAllOnLogout();
      await expectOutboxIntact();
    });

    test('forceLogout keeps outbox rows and sync_state', () async {
      await seed();
      await db.insert('sync_state', {
        'key': 'device_id',
        'value': 'd1',
        'updated_at': 'x',
      });
      getIt.registerSingleton<CacheStorage>(_NoopStorage());
      getIt.registerSingleton<Dio>(Dio());
      AppInterceptors.isLoggingOut = false;
      await AppInterceptors.forceLogout();
      AppInterceptors.isLoggingOut = false;
      await getIt.reset();
      expect(await count('outbox'), 2);
      expect(await count('sync_state'), 2);
    });
  });

  group('OutboxStore.discardAll', () {
    test('deletes only the scope non-done rows', () async {
      await enq('a|t', OutboxStatus.pending);
      await enq('a|t', OutboxStatus.rejected);
      await enq('a|t', OutboxStatus.done);
      await enq('b|t', OutboxStatus.pending);
      final n = await store.discardAll(scope: 'a|t');
      expect(n, 2);
      final rows = await db.query('outbox', columns: ['scope', 'status']);
      expect(rows.length, 2);
      expect(
        rows.any((r) => r['scope'] == 'a|t' && r['status'] == 'done'),
        isTrue,
      );
      expect(await store.unsyncedCount(scope: 'b|t'), 1);
    });
  });
}
