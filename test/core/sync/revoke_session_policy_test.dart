import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/revoke_session_policy.dart';
import 'package:amana_pos/core/sync/sync_session_guard.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'support/test_db.dart';

void main() {
  late OfflineDb odb;
  late Database db;
  late OutboxStore outbox;
  late SyncStateStore state;
  late List<String> calls;
  bool wipeThrows = false;
  late RevokeSessionPolicy policy;
  final t0 = DateTime.utc(2026, 3, 1, 12);

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
    outbox = OutboxStore(odb, now: () => t0);
    state = SyncStateStore(odb, now: () => t0);
    calls = [];
    wipeThrows = false;
    policy = RevokeSessionPolicy(
      outbox: outbox,
      state: state,
      wipe: () async {
        calls.add('wipe');
        if (wipeThrows) throw StateError('boom');
      },
      logout: () async => calls.add('logout'),
      now: () => t0,
    );
  });
  tearDown(() async => db.close());

  Future<String> enq(String id) async => (await outbox.enqueue(
    db,
    entity: 'product',
    op: 'update',
    entityId: id,
    payload: {'a': 1},
    scope: 'u1|t1',
  )).mutationId;

  test('deviceRevoked with empty outbox wipes then logs out', () async {
    await policy.handle(SyncSessionEvent.deviceRevoked);
    expect(calls, ['wipe', 'logout']);
    expect(await state.revokeMarker(), isNull);
  });

  test('accountDisabled with an open row keeps data, marker, logout', () async {
    await enq('a');
    await policy.handle(SyncSessionEvent.accountDisabled);
    expect(calls, ['logout']);
    final m = (await state.revokeMarker())!;
    expect(m.pendingCount, 1);
    expect(m.reason, 'accountDisabled');
  });

  test('only a rejected row counts as unsynced: no wipe', () async {
    final id = await enq('a');
    await db.update(
      'outbox',
      {'status': 'rejected'},
      where: 'mutation_id = ?',
      whereArgs: [id],
    );
    await policy.handle(SyncSessionEvent.deviceRevoked);
    expect(calls, ['logout']);
    expect((await state.revokeMarker())!.pendingCount, 1);
  });

  test('count in the marker is the real total', () async {
    await enq('a');
    await policy.handle(SyncSessionEvent.deviceRevoked);
    expect(calls, ['logout']);
    expect((await state.revokeMarker())!.pendingCount, 1);
  });

  test('another scope with pending rows blocks the wipe', () async {
    await outbox.enqueue(
      db,
      entity: 'product',
      op: 'update',
      entityId: 'x',
      payload: {'a': 1},
      scope: 'u2|t2',
    );
    await policy.handle(SyncSessionEvent.deviceRevoked); // current u1|t1: empty
    expect(calls, ['logout']);
    expect((await state.revokeMarker())!.pendingCount, 1);
  });

  test('a wipe clears a stale marker', () async {
    await state.setRevokeMarker(
      RevokeMarker(reason: 'deviceRevoked', pendingCount: 9, at: t0),
    );
    await policy.handle(SyncSessionEvent.deviceRevoked);
    expect(calls, ['wipe', 'logout']);
    expect(await state.revokeMarker(), isNull);
  });

  test('wipe throws -> logout still called, no marker', () async {
    wipeThrows = true;
    await policy.handle(SyncSessionEvent.deviceRevoked);
    expect(calls, ['wipe', 'logout']);
    expect(await state.revokeMarker(), isNull);
  });

  test('second event replaces the marker', () async {
    await enq('a');
    await policy.handle(SyncSessionEvent.deviceRevoked);
    await enq('b');
    await policy.handle(SyncSessionEvent.accountDisabled);
    final m = (await state.revokeMarker())!;
    expect(m.reason, 'accountDisabled');
    expect(m.pendingCount, 2);
    final rows = await db.query('sync_state', where: "key = 'revoke_marker'");
    expect(rows, hasLength(1));
  });

  test('needsLogin never wipes and never writes a marker', () async {
    await policy.handle(SyncSessionEvent.needsLogin);
    expect(calls, ['logout']);
    expect(await state.revokeMarker(), isNull);
  });

  test('marker survives wipe and clear()', () async {
    await state.setRevokeMarker(
      RevokeMarker(reason: 'deviceRevoked', pendingCount: 2, at: t0),
    );
    await odb.clearAllLocalOfflineData();
    await state.forScope('u1|t1').clear();
    expect((await state.revokeMarker())!.pendingCount, 2);
    await state.setRevokeMarker(null);
    expect(await state.revokeMarker(), isNull);
  });

  test('marker json: garbage reads as null', () {
    expect(RevokeMarker.tryFromJson('nope'), isNull);
    expect(RevokeMarker.tryFromJson('{"reason":1}'), isNull);
    final m = RevokeMarker(reason: 'x', pendingCount: 3, at: t0);
    final back = RevokeMarker.tryFromJson((markerJson(m)));
    expect(back!.pendingCount, 3);
  });
}

String markerJson(RevokeMarker m) =>
    '{"reason":"${m.reason}","pending":${m.pendingCount},"at":"${m.at.toIso8601String()}"}';
