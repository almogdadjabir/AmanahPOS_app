// A device (real DB + engine + user applier) against FakeSyncServer.
import 'dart:math';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/appliers/user_applier.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/features/users/data/local/user_local_store.dart';
import 'package:amana_pos/features/users/domain/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'engine_harness.dart';
import 'fake_sync_server.dart';
import 'test_db.dart';

const kUserScope = 'u1|t1';

class UserDevice {
  late OfflineDb odb;
  late Database db;
  late FakeSyncServer server;
  late ScenarioTransport transport;
  late OutboxStore outbox;
  late SyncEngine engine;
  late LocalWriter writer;
  late UserService users;
  late UserLocalStore store;
  final notifier = DbChangeNotifier();
  DateTime clock = DateTime.utc(2026, 11, 17, 9);
  DateTime now() => clock;

  static Future<UserDevice> create({FakeSyncServer? server}) async {
    SyncScope.current = kUserScope;
    final d = UserDevice();
    d.odb = await openTestDb();
    d.db = await d.odb.database;
    d.server = server ?? (FakeSyncServer(now: d.now)..callerUserId = 'u1');
    final transport = d.transport = ScenarioTransport(d.server);
    d.outbox = OutboxStore(d.odb, now: d.now);
    final state = SyncStateStore(d.odb, now: d.now, scope: kUserScope);
    final writer = d.writer = LocalWriter(
      d.odb,
      d.outbox,
      d.notifier,
      scopeProvider: () => kUserScope,
    );
    final registry = ChangeApplierRegistry()..register(UserApplier());
    d.engine = SyncEngine(
      db: d.odb,
      transport: transport,
      outbox: d.outbox,
      state: state,
      scopeProvider: () => kUserScope,
      reachability: ServerReachability(transport, now: d.now),
      appliers: registry,
      notifier: d.notifier,
      appVersion: '1.0.0',
      backoff: Backoff(random: Random(1)),
      now: d.now,
    );
    d.users = UserService(writer: writer, now: d.now);
    d.store = UserLocalStore(writer);
    await d.db.insert('sync_state', {
      'key': 'device_id',
      'value': 'abcd1234-0000-4000-8000-000000000000',
      'updated_at': '2026-01-01T00:00:00Z',
    });
    await d.db.transaction((t) async {
      await state.setCursor(t, EngineHarness.seedCursor);
      await state.setBootstrapped(t, true);
    });
    return d;
  }

  Future<void> dispose() async {
    await engine.dispose();
    notifier.dispose();
    await db.close();
    SyncScope.current = null;
  }

  Future<SyncOutcome> sync() {
    clock = clock.add(const Duration(hours: 2));
    return engine.syncNow();
  }

  /// A member known to the server AND to this device (version 1).
  Future<void> seed(
    String id, {
    String phone = '+249911',
    String role = 'cashier',
  }) async {
    final row = {
      'id': id,
      'version': 1,
      'phone': phone,
      'full_name': 'Sara',
      'role': role,
      'default_shop': null,
      'is_active': true,
      'status': 'active',
    };
    server.tables.putIfAbsent('user', () => {})[id] = {...row};
    await db.transaction(
      (t) => UserApplier().apply(
        t,
        PullChange(
          seq: 1,
          entity: 'user',
          op: 'upsert',
          id: id,
          version: 1,
          data: row,
        ),
      ),
    );
  }

  Future<List<OutboxEntry>> rejected() async => [
    for (final r in await db.query('outbox', where: "status = 'rejected'"))
      OutboxEntry.fromRow(r),
  ];
}
