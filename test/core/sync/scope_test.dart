import 'dart:async';

import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/sync_coordinator.dart';
import 'package:amana_pos/core/sync/sync_device_registrar.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:amana_pos/core/sync/sync_triggers.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/core/sync/sync_session_guard.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/engine_harness.dart';
import 'support/test_db.dart';

const _a = 'A|t1';
const _b = 'B|t1';

void main() {
  _fixRound1();

  group('store level', () {
    test('(a) rows of scope A are not claimed under scope B', () async {
      final odb = await openTestDb();
      final db = await odb.database;
      final store = OutboxStore(odb);
      await store.enqueue(
        db,
        entity: 'product',
        op: 'create',
        entityId: 'p1',
        payload: {'n': 1},
        scope: _a,
      );
      expect(await store.claimBatch(scope: _b), isEmpty);
      expect(await store.unsyncedCount(scope: _b), 0);
      expect(await store.unsyncedCount(scope: _a), 1);
      final claimed = await store.claimBatch(scope: _a);
      expect(claimed, hasLength(1));
      expect(claimed.single.scope, _a);
      await db.close();
    });

    test('(b) cursor set under A is null under B', () async {
      final odb = await openTestDb();
      final db = await odb.database;
      final root = SyncStateStore(odb);
      await db.transaction((t) => root.forScope(_a).setCursor(t, 'c-a'));
      expect(await root.forScope(_a).cursor(), 'c-a');
      expect(await root.forScope(_b).cursor(), isNull);
      // device_id is global: same under every scope.
      expect(
        await root.forScope(_a).deviceId(),
        await root.forScope(_b).deviceId(),
      );
      await db.close();
    });

    test('v6 outbox upgrades additively: scope column and index', () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      await db.execute(
        'CREATE TABLE outbox (seq INTEGER PRIMARY KEY AUTOINCREMENT, '
        'mutation_id TEXT UNIQUE NOT NULL, status TEXT NOT NULL)',
      );
      await db.insert('outbox', {'mutation_id': 'm1', 'status': 'pending'});
      await SyncSchema.addOutboxScope(db);
      await SyncSchema.addOutboxScope(db); // idempotent
      final row = (await db.query('outbox')).single;
      expect(row['scope'], '', reason: 'legacy rows belong to no session');
      final idx = await db.rawQuery(
        'PRAGMA index_info(idx_outbox_scope_status_seq)',
      );
      expect(idx.map((r) => r['name']), ['scope', 'status', 'seq']);
      await db.close();
    });
  });

  group('engine', () {
    late EngineHarness h;
    setUp(() async => h = await EngineHarness.create());
    tearDown(() => h.dispose());

    test(
      '(c)(d) another scope pushes nothing; switching back pushes',
      () async {
        h.activeScope = _a;
        await h.createWidget('w1');
        await h.createWidget('w2');

        h.activeScope = _b;
        final e = h.build();
        expect(await e.syncNow(), isNot(SyncOutcome.alreadyRunning));
        expect(h.server.feed, isEmpty);
        expect(await h.countStatus('pending'), 2);
        expect(await h.countStatus('inflight'), 0);

        h.activeScope = _a;
        // A's cursor is not bootstrapped (seed cursor lives under u1|t1), so
        // seed it for A to let the pull phase finish.
        await h.db.transaction((t) async {
          await h.state.forScope(_a).setCursor(t, EngineHarness.seedCursor);
          await h.state.forScope(_a).setBootstrapped(t, true);
        });
        h.advance(const Duration(minutes: 10));
        expect(await e.syncNow(), SyncOutcome.completed);
        expect(h.server.feed, hasLength(2));
        expect(await h.countStatus('done'), 2);
      },
    );

    test('no session: blocked(noSession), nothing pushed', () async {
      await h.createWidget('w1');
      h.activeScope = null;
      final e = h.build();
      expect(await e.syncNow(), SyncOutcome.blocked);
      expect(e.current.block, SyncBlockReason.noSession);
      expect(h.server.feed, isEmpty);
      expect(await h.countStatus('pending'), 1);
    });

    test(
      'a scope without a cursor needs bootstrap even if another has one',
      () async {
        h.activeScope = _b; // cursor only exists under u1|t1
        final e = h.build();
        expect(await e.syncNow(), SyncOutcome.needsBootstrap);
      },
    );
  });

  group('coordinator', () {
    test(
      '(e) logout keeps A rows; clear only touches the empty scope',
      () async {
        final odb = await openTestDb();
        final db = await odb.database;
        final outbox = OutboxStore(odb);
        final state = SyncStateStore(odb);
        await outbox.enqueue(
          db,
          entity: 'sale',
          op: 'create',
          entityId: 's1',
          payload: {},
          scope: 'u1|t1',
        );
        await db.transaction((t) => state.forScope('u1|t1').setCursor(t, 'ca'));
        await db.transaction((t) => state.forScope('u2|t1').setCursor(t, 'cb'));

        final sessions = StreamController<SyncSession?>.broadcast();
        final status = StreamController<SyncStatus>.broadcast();
        final coord = SyncCoordinator(
          triggers: _NoTriggers(),
          guard: SyncSessionGuard(status.stream),
          registrar: _NoRegistrar(),
          outbox: outbox,
          state: state,
          sessions: sessions.stream,
          initialSession: const SyncSession(userId: 'u1', tenantId: 't1'),
          onSessionEnded: (_) async {},
        );
        await coord.attach(observeLifecycle: false);
        expect(SyncScope.current, 'u1|t1');

        // User 1 logs out with an unsynced sale: nothing is cleared or deleted.
        sessions.add(null);
        await untilAsync(() async => SyncScope.current == null);
        expect(await outbox.unsyncedCount(scope: 'u1|t1'), 1);
        expect(await state.forScope('u1|t1').cursor(), 'ca');

        // User 2 logs in then out: their scope has an empty outbox so only
        // their cursor is cleared; u1's survives.
        sessions.add(const SyncSession(userId: 'u2', tenantId: 't1'));
        await untilAsync(() async => SyncScope.current == 'u2|t1');
        sessions.add(null);
        await untilAsync(() async => SyncScope.current == null);
        await untilAsync(
          () async => await state.forScope('u2|t1').cursor() == null,
        );
        expect(await state.forScope('u2|t1').cursor(), isNull);
        expect(await state.forScope('u1|t1').cursor(), 'ca');
        expect(await outbox.unsyncedCount(scope: 'u1|t1'), 1);

        await coord.detach();
        await sessions.close();
        await status.close();
        await db.close();
      },
    );
  });
}

Future<OutboxEntry> _enq(
  OutboxStore store,
  dynamic db, {
  required String scope,
  required String entityId,
  String op = 'update',
  String? dep,
}) => store.enqueue(
  db,
  entity: 'product',
  op: op,
  entityId: entityId,
  payload: {},
  scope: scope,
  dependsOn: [?dep],
);

void _fixRound1() {
  group('store ordering and dependencies are scoped (I1, I2, I3)', () {
    test('claim ordering ignores another scope\'s earlier row', () async {
      final odb = await openTestDb();
      final db = await odb.database;
      final store = OutboxStore(odb);
      await _enq(store, db, scope: _a, entityId: 'x'); // seq 1, stays pending
      await _enq(store, db, scope: _b, entityId: 'x'); // seq 2
      final got = await store.claimBatch(scope: _b);
      expect(got.map((e) => e.scope), [_b]);
      await db.close();
    });

    test('unblock/fail dependents only touch the given scope', () async {
      final odb = await openTestDb();
      final db = await odb.database;
      final store = OutboxStore(odb);
      // B has an open create for p1, so each scope's dependent is blocked.
      final pa = await _enq(store, db, scope: _a, entityId: 'p1', op: 'create');
      await _enq(store, db, scope: _b, entityId: 'p1', op: 'create');
      final da = await _enq(store, db, scope: _a, entityId: 'c1', dep: 'p1');
      final dbb = await _enq(store, db, scope: _b, entityId: 'c2', dep: 'p1');
      Future<String> st(String m) async =>
          (await db.query(
                'outbox',
                columns: ['status'],
                where: 'mutation_id = ?',
                whereArgs: [m],
              )).single['status']!
              as String;
      expect(await st(da.mutationId), 'blocked');
      expect(await st(dbb.mutationId), 'blocked');

      // A's create is done (B's is still open in B's scope).
      await store.applyResult(db, pa.mutationId, status: OutboxStatus.done);
      await store.unblockDependents(db, 'p1', scope: _a);
      expect(await st(da.mutationId), 'pending');
      expect(await st(dbb.mutationId), 'blocked');

      await store.failDependents(db, 'p1', scope: _b);
      expect(await st(dbb.mutationId), 'rejected');
      expect(await st(da.mutationId), 'pending');
      await db.close();
    });

    test(
      'enqueue dependency lookup ignores another scope\'s open create',
      () async {
        final odb = await openTestDb();
        final db = await odb.database;
        final store = OutboxStore(odb);
        await _enq(store, db, scope: _a, entityId: 'p1', op: 'create');
        final e = await _enq(store, db, scope: _b, entityId: 'c', dep: 'p1');
        expect(e.status, OutboxStatus.pending);
        await db.close();
      },
    );

    test('unscoped unsyncedCount includes legacy scope-empty rows', () async {
      final odb = await openTestDb();
      final db = await odb.database;
      final store = OutboxStore(odb);
      await _enq(store, db, scope: '', entityId: 'old');
      expect(await store.unsyncedCount(), 1);
      expect(await store.unsyncedCount(scope: _a), 0);
      await db.close();
    });

    test('claim scan uses the (scope,status,seq) index', () async {
      final odb = await openTestDb();
      final db = await odb.database;
      final plan = await db.rawQuery(
        "EXPLAIN QUERY PLAN SELECT seq, entity_id FROM outbox "
        "INDEXED BY idx_outbox_scope_status_seq "
        "WHERE status = 'pending' AND scope = ? AND seq > ? ORDER BY seq",
        [_a, 0],
      );
      expect(
        plan.map((r) => r['detail']).join(' '),
        contains('idx_outbox_scope_status_seq'),
      );
      await db.close();
    });

    test('watchPendingCount can be scoped', () async {
      final odb = await openTestDb();
      final db = await odb.database;
      final store = OutboxStore(odb);
      final n = DbChangeNotifier();
      await _enq(store, db, scope: _a, entityId: 'x');
      expect(await store.watchPendingCount(n, scope: _a).first, 1);
      expect(await store.watchPendingCount(n, scope: _b).first, 0);
      n.dispose();
      await db.close();
    });
  });

  group('M2: scoped state keys need a scope', () {
    test('unscoped store throws StateError', () async {
      final odb = await openTestDb();
      final db = await odb.database;
      final s = SyncStateStore(odb);
      expect(() => s.cursor(), throwsStateError);
      expect(
        () => db.transaction((t) => s.setCursor(t, 'c')),
        throwsStateError,
      );
      expect(() => s.repairNeeded(), throwsStateError);
      expect(() => s.setRepairNeeded(), throwsStateError);
      expect(() => s.clearRepairNeeded(), throwsStateError);
      expect(
        () => db.transaction((t) => s.deferredPullJson(t)),
        throwsStateError,
      );
      expect(() => s.clear(), throwsStateError);
      expect(await s.deviceId(), isNotEmpty); // global keys still work
      await db.close();
    });
  });

  group('C1: a session switch during a run never crosses scopes', () {
    late EngineHarness h;
    setUp(() async => h = await EngineHarness.create());
    tearDown(() => h.dispose());

    Future<void> expectUntouched() async {
      expect(h.server.feed, isEmpty, reason: 'nothing reached the server');
      expect(await h.countStatus('pending'), 2);
      expect(await h.countStatus('inflight'), 0);
      final rows = await h.db.query('outbox');
      expect(
        rows.every((r) => r['attempts'] == 0),
        isTrue,
        reason: 'no backoff penalty',
      );
      expect(rows.every((r) => r['scope'] == EngineHarness.scope), isTrue);
    }

    test('switch before the send: refused, claims released, quiet', () async {
      await h.createWidget('w1');
      await h.createWidget('w2');
      h.transport.onBeforeSend = (op) async {
        if (op == 'push') h.activeScope = _b;
      };
      final e = h.build();
      expect(await e.syncNow(), SyncOutcome.blocked);
      expect(e.current.block, SyncBlockReason.noSession);
      await expectUntouched();
    });

    test(
      'switch inside beforeResultWrite: nothing written, rows released',
      () async {
        await h.createWidget('w1');
        await h.createWidget('w2');
        final e = h.build(
          hooks: SyncHooks(
            beforeResultWrite: (b, r) async => h.activeScope = _b,
          ),
        );
        expect(await e.syncNow(), SyncOutcome.blocked);
        expect(await h.countStatus('done'), 0);
        expect(await h.countStatus('pending'), 2);
        expect(await h.countStatus('inflight'), 0);
        expect(h.applier.pushResults, isEmpty);
      },
    );

    test('token refresh must not resend under the new session', () async {
      await h.createWidget('w1');
      await h.createWidget('w2');
      h.transport.onBeforeSend = (op) async {
        if (op == 'push' && h.transport.pushCalls == 0) {
          throw SyncTransportException(kind: SyncTransportKind.tokenExpired);
        }
      };
      final e = h.build(
        refreshToken: () async {
          h.activeScope = _b; // refresh lands as another session
          return RefreshOutcome.refreshed;
        },
      );
      expect(await e.syncNow(), SyncOutcome.blocked);
      expect(h.transport.pushCalls, 0, reason: 'never resent');
      await expectUntouched();
    });

    test(
      'pull: switch before the send leaves the old cursor unchanged',
      () async {
        await h.otherDevice('x1');
        h.transport.onBeforeSend = (op) async {
          if (op == 'pull') h.activeScope = _b;
        };
        final e = h.build();
        expect(await e.syncNow(), SyncOutcome.blocked);
        expect(await h.state.cursor(), EngineHarness.seedCursor);
        expect(await h.widgets(), isEmpty);
      },
    );

    test(
      'stale SyncScope but live session switched: page must not commit',
      () async {
        await h.otherDevice('x1');
        final e = h.build(
          hooks: SyncHooks(
            // SyncScope.current (activeScope) still says A; the live auth
            // session already says B.
            beforePullPageCommit: (page) async => h.liveScope = _b,
          ),
        );
        expect(await e.syncNow(), SyncOutcome.blocked);
        expect(await h.state.cursor(), EngineHarness.seedCursor);
        expect(await h.widgets(), isEmpty);
      },
    );

    test('pull: switch before the page commit rolls the page back', () async {
      await h.otherDevice('x1');
      final e = h.build(
        hooks: SyncHooks(
          beforePullPageCommit: (page) async => h.activeScope = _b,
        ),
      );
      expect(await e.syncNow(), SyncOutcome.blocked);
      expect(await h.state.cursor(), EngineHarness.seedCursor);
      expect(await h.widgets(), isEmpty);
    });
  });
}

class _NoTriggers implements SyncTriggers {
  @override
  void start() {}

  @override
  Future<void> stop() async {}

  @override
  void onAppResumed() {}

  @override
  void onAppPaused() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoRegistrar implements SyncDeviceRegistrar {
  @override
  Future<bool> registerIfNeeded({String userKey = ''}) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Polls until [ok] holds (the coordinator runs real sqflite calls, so no
/// fixed number of microtask turns is enough under load).
Future<void> untilAsync(Future<bool> Function() ok) async {
  for (var i = 0; i < 600; i++) {
    if (await ok()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('condition not reached in time');
}
