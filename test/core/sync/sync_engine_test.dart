import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'support/fake_sync_server.dart';
import 'support/test_db.dart';

/// Wraps a transport so tests can script failures, observe batches and
/// rewrite responses.
class _ScriptedTransport implements SyncTransport {
  _ScriptedTransport(this.inner);
  final SyncTransport inner;

  final pushErrors = <SyncTransportException>[];
  final pullErrors = <SyncTransportException>[];
  final batchSizes = <int>[];
  final pushedIds = <String>[];
  int pulls = 0;
  PingResponse Function(PingResponse)? onPing;
  Future<void> Function(int call, List<OutboxEntry> batch)? onPush;
  PushResponse Function(PushResponse)? rewritePush;
  Future<void> Function(int call)? onPull;
  Future<PullResponse> Function(String? cursor)? pullOverride;

  /// Collapses each pulled page to the latest change per (entity, id), like
  /// the live backend does.
  bool collapsePull = false;

  /// Drops pulled changes for which this returns false.
  bool Function(PullChange)? keepChange;

  @override
  Future<ChecksumResponse> checksum({
    required String entity,
    int sinceDays = 7,
    required String scope,
  }) => inner.checksum(entity: entity, sinceDays: sinceDays, scope: scope);

  @override
  Future<PingResponse> ping() async {
    final r = await inner.ping();
    return onPing == null ? r : onPing!(r);
  }

  @override
  Future<PushResponse> push({
    required String deviceId,
    required String appVersion,
    required List<OutboxEntry> mutations,
    required String scope,
  }) async {
    batchSizes.add(mutations.length);
    pushedIds.addAll(mutations.map((m) => m.mutationId));
    if (onPush != null) await onPush!(batchSizes.length, mutations);
    if (pushErrors.isNotEmpty) throw pushErrors.removeAt(0);
    final r = await inner.push(
      deviceId: deviceId,
      appVersion: appVersion,
      mutations: mutations,
      scope: scope,
    );
    return rewritePush == null ? r : rewritePush!(r);
  }

  @override
  Future<PullResponse> pull({
    String? cursor,
    int limit = 500,
    required String scope,
  }) async {
    pulls++;
    if (onPull != null) await onPull!(pulls);
    if (pullErrors.isNotEmpty) throw pullErrors.removeAt(0);
    if (pullOverride != null) return pullOverride!(cursor);
    var r = await inner.pull(cursor: cursor, limit: limit, scope: scope);
    final keep = keepChange;
    if (keep != null) {
      r = PullResponse(
        serverTime: r.serverTime,
        changes: r.changes.where(keep).toList(),
        nextCursor: r.nextCursor,
        hasMore: r.hasMore,
        fullResyncRequired: r.fullResyncRequired,
      );
    }
    if (!collapsePull) return r;
    final latest = <String, PullChange>{};
    for (final c in r.changes) {
      latest.remove('${c.entity}|${c.id}');
      latest['${c.entity}|${c.id}'] = c;
    }
    return PullResponse(
      serverTime: r.serverTime,
      changes: latest.values.toList(),
      nextCursor: r.nextCursor,
      hasMore: r.hasMore,
      fullResyncRequired: r.fullResyncRequired,
    );
  }

  @override
  Future<BootstrapManifest> bootstrapManifest({required String scope}) =>
      inner.bootstrapManifest(scope: scope);

  @override
  Future<BootstrapPage> bootstrapPage({
    required String entity,
    String? pageCursor,
    int limit = 500,
    String? snapshotCursor,
    int salesSinceDays = 90,
    required String scope,
  }) => inner.bootstrapPage(
    entity: entity,
    pageCursor: pageCursor,
    limit: limit,
    snapshotCursor: snapshotCursor,
    salesSinceDays: salesSinceDays,
    scope: scope,
  );
}

/// Writes pulled changes to `t_rows` inside the page transaction so tests can
/// observe atomicity.
class _TableApplier implements ChangeApplier {
  _TableApplier(this.entity, {this.skipWhenLocalPending = true});

  @override
  final String entity;

  @override
  final bool skipWhenLocalPending;

  final pushResults = <PushResult>[];
  Object? throwOnPushResult;
  final poisonIds = <String>{};

  /// Every pulled price applied, in order, as `id=price` (no DB access, so
  /// hooks running inside the page transaction can inspect it).
  final appliedPrices = <String>[];

  /// When set, a push result writes the sent payload + server version into
  /// t_rows (like a real applier adopting the server version).
  bool adoptPushVersion = false;

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) async {
    final r = await txn.query(
      't_rows',
      where: 'entity = ? AND id = ?',
      whereArgs: [entity, change.id],
    );
    if (r.isEmpty || r.single['data'] == null) return null;
    final d = jsonDecode(r.single['data'] as String) as Map;
    return d['version'] as int?;
  }

  @override
  Set<String> get tables => {'t_rows'};

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    appliedPrices.add('${change.id}=${change.data?['price']}');
    await txn.insert('t_rows', {
      'entity': entity,
      'id': change.id,
      'op': change.op,
      'origin': change.originDeviceId,
      'data': change.data == null ? null : jsonEncode(change.data),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {
    final t = throwOnPushResult;
    if (t != null) throw t;
    if (poisonIds.contains(sent.mutationId)) throw StateError('poison');
    pushResults.add(result);
    if (adoptPushVersion) {
      final r = await txn.query(
        't_rows',
        where: 'entity = ? AND id = ?',
        whereArgs: [entity, sent.entityId],
      );
      final data = r.isEmpty || r.single['data'] == null
          ? <String, dynamic>{}
          : jsonDecode(r.single['data'] as String) as Map<String, dynamic>;
      await txn.insert('t_rows', {
        'entity': entity,
        'id': sent.entityId,
        'op': 'upsert',
        'data': jsonEncode({
          ...data,
          ...sent.payload,
          'version': result.version,
        }),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}

void main() {
  late OfflineDb odb;
  late Database db;
  late DateTime clock;
  late FakeSyncServer server;
  late _ScriptedTransport transport;
  late OutboxStore outbox;
  late SyncStateStore state;
  late DbChangeNotifier notifier;
  late ChangeApplierRegistry registry;
  late _TableApplier productApplier;
  final engines = <SyncEngine>[];

  DateTime now() => clock;
  const scope = 'u1|t1';
  final seedCursor = base64Url.encode(utf8.encode('seq:0'));

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
    await db.execute(
      'CREATE TABLE t_rows (entity TEXT, id TEXT, op TEXT, origin TEXT, '
      'data TEXT, PRIMARY KEY (entity, id))',
    );
    clock = DateTime.utc(2026, 1, 1, 12);
    server = FakeSyncServer(now: now);
    transport = _ScriptedTransport(server);
    outbox = OutboxStore(odb, now: now);
    state = SyncStateStore(odb, now: now, scope: scope);
    notifier = DbChangeNotifier();
    // Bootstrapped device: a cursor at the start of the feed (and the
    // scope's `bootstrapped` flag the final bootstrap transaction sets).
    await db.transaction((t) async {
      await state.setCursor(t, seedCursor);
      await state.setBootstrapped(t, true);
    });
    productApplier = _TableApplier('product');
    registry = ChangeApplierRegistry()
      ..register(productApplier)
      ..register(_TableApplier('stock', skipWhenLocalPending: false))
      ..register(_TableApplier('sale'));
  });

  tearDown(() async {
    for (final e in engines) {
      await e.dispose();
    }
    engines.clear();
    notifier.dispose();
    await db.close();
  });

  SyncEngine build({
    SyncTransport? t,
    SyncHooks? hooks,
    Future<RefreshOutcome> Function()? refreshToken,
    String appVersion = '1.0.0',
    bool requireBootstrapWhenNoCursor = true,
    int pullPageSize = SyncEngine.defaultPullPageSize,
  }) {
    final tr = t ?? transport;
    final e = SyncEngine(
      db: odb,
      transport: tr,
      outbox: outbox,
      state: state,
      scopeProvider: () => scope,
      reachability: ServerReachability(tr, now: now),
      appliers: registry,
      notifier: notifier,
      appVersion: appVersion,
      backoff: Backoff(random: Random(1)),
      now: now,
      hooks: hooks,
      refreshToken: refreshToken,
      requireBootstrapWhenNoCursor: requireBootstrapWhenNoCursor,
      pullPageSize: pullPageSize,
    );
    engines.add(e);
    return e;
  }

  Future<OutboxEntry> enq(
    String entityId, {
    String entity = 'product',
    String op = 'create',
    Map<String, dynamic>? payload,
    String? dep,
  }) => outbox.enqueue(
    db,
    entity: entity,
    op: op,
    entityId: entityId,
    payload: payload ?? {'name': 'P $entityId'},
    scope: scope,
    dependsOn: [?dep],
  );

  Future<Map<String, Object?>> row(String mid) async => (await db.query(
    'outbox',
    where: 'mutation_id = ?',
    whereArgs: [mid],
  )).single;

  Future<String> statusOf(String mid) async =>
      (await row(mid))['status'] as String;

  Future<int> countStatus(String s) async => Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM outbox WHERE status = ?', [s]),
  )!;

  Future<List<Map<String, Object?>>> tRows() =>
      db.query('t_rows', orderBy: 'id');

  /// Pushes a mutation as another device straight to the server.
  Future<PushResult> otherDevice(
    String entityId, {
    String op = 'create',
    String entity = 'product',
    Map<String, dynamic>? payload,
  }) async {
    final view = server.forDevice('dev-2');
    final r = await view.push(
      deviceId: 'dev-2',
      appVersion: '1.0.0',
      mutations: [
        OutboxEntry(
          seq: server.headSeq + 1,
          mutationId: 'other-${server.headSeq}-$entityId-$op',
          entity: entity,
          op: op,
          entityId: entityId,
          occurredAt: clock,
          payload: payload ?? {'name': 'Other $entityId'},
        ),
      ],
      scope: 'u1|t1',
    );
    return r.results.single;
  }

  group('Backoff', () {
    test('exponential 2s base x2, capped at 5 min, +-20% jitter', () {
      final b = Backoff(random: Random(3));
      for (var attempt = 1; attempt <= 12; attempt++) {
        final nominal = min(2000 * pow(2, attempt - 1), 300000).toDouble();
        for (var i = 0; i < 50; i++) {
          final d = b.delay(attempt).inMilliseconds;
          expect(d, greaterThanOrEqualTo((nominal * 0.8).floor()));
          expect(d, lessThanOrEqualTo(min(nominal * 1.2, 300000).ceil()));
        }
      }
    });
  });

  group('ChangeApplierRegistry', () {
    test('of returns registered applier, null for unknown', () {
      expect(registry.of('product'), same(productApplier));
      expect(registry.of('nope'), isNull);
    });

    test('duplicate entity registration throws', () {
      expect(
        () => registry.register(_TableApplier('product')),
        throwsStateError,
      );
    });
  });

  group('happy path', () {
    test(
      '3 mutations -> done, appliers called, idle with lastSyncedAt',
      () async {
        final engine = build();
        final statuses = <SyncStatus>[];
        final sub = engine.status.listen(statuses.add);
        final a = await enq('p1');
        final b = await enq('p2');
        final c = await enq('p3');

        final out = await engine.syncNow(reason: SyncReason.manual);

        expect(out, SyncOutcome.completed);
        for (final m in [a, b, c]) {
          expect(await statusOf(m.mutationId), 'done');
        }
        expect(productApplier.pushResults.map((r) => r.mutationId).toSet(), {
          a.mutationId,
          b.mutationId,
          c.mutationId,
        });
        expect(server.tables['product']!.keys.toSet(), {'p1', 'p2', 'p3'});
        expect(await state.lastSyncedAt(), clock);
        await pumpEventQueue();
        final last = statuses.last;
        expect(last.phase, SyncPhase.idle);
        expect(last.block, SyncBlockReason.none);
        expect(last.pending, 0);
        expect(last.rejected, 0);
        expect(last.lastSyncedAt, clock);
        expect(last.serverReachable, isTrue);
        expect(
          statuses.map((s) => s.phase),
          containsAllInOrder([
            SyncPhase.pinging,
            SyncPhase.pushing,
            SyncPhase.pulling,
            SyncPhase.idle,
          ]),
        );
        await sub.cancel();
      },
    );

    test('empty outbox still pulls (device has a cursor)', () async {
      await otherDevice('x1');
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(transport.batchSizes, isEmpty);
      expect(transport.pulls, greaterThan(0));
      expect((await tRows()).single['id'], 'x1');
      expect(await state.cursor(), isNotNull);
    });

    test('push batch size is 100 for 250 queued mutations', () async {
      final ids = <String>[];
      for (var i = 0; i < 250; i++) {
        ids.add((await enq('p$i')).mutationId);
      }
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(transport.batchSizes, [100, 100, 50]);
      expect(await countStatus('done'), 250);
      expect(transport.pushedIds.toSet().length, 250);
    });

    test('clock skew is stored, occurred_at is not rewritten', () async {
      server.clockSkew = const Duration(hours: 5);
      final m = await enq('p1');
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(await state.clockSkew(), const Duration(hours: 5));
      expect(
        DateTime.parse((await row(m.mutationId))['occurred_at'] as String),
        m.occurredAt,
      );
    });

    test('never adopts PushResponse.nextCursor as pull cursor', () async {
      // Another device writes first, then we push: the push response's
      // next_cursor is the head, which would skip x1.
      await otherDevice('x1');
      await enq('p1');
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.completed);
      final ids = (await tRows()).map((r) => r['id']).toList();
      expect(ids, contains('x1'));
    });
  });

  group('push results', () {
    test('server down -> pending, unreachable, no exception', () async {
      server.down = true;
      final m = await enq('p1');
      final engine = build();
      final out = await engine.syncNow();
      expect(out, SyncOutcome.backoff);
      expect(await statusOf(m.mutationId), 'pending');
      expect(engine.current.serverReachable, isFalse);
      expect(engine.current.phase, SyncPhase.backoff);
      expect(engine.current.nextRetryAt!.isAfter(clock), isTrue);
    });

    test(
      'network failure mid-push -> rows back to pending with backoff',
      () async {
        transport.pushErrors.add(
          SyncTransportException(kind: SyncTransportKind.network),
        );
        final m = await enq('p1');
        final engine = build();
        expect(await engine.syncNow(), SyncOutcome.backoff);
        final r = await row(m.mutationId);
        expect(r['status'], 'pending');
        expect(r['lease_until'], isNull);
        expect(r['attempts'], 1);
        expect(
          DateTime.parse(r['next_attempt_at'] as String).isAfter(clock),
          isTrue,
        );
        expect(engine.current.serverReachable, isFalse);
        expect(await countStatus('inflight'), 0);
      },
    );

    test(
      'retry result schedules next_attempt_at and is not re-claimed early',
      () async {
        final m = await enq(
          'r1',
          entity: 'sale',
          op: 'refund',
          payload: {
            'sale_id': 'unknown-sale',
            'items': [
              {'product_id': 'p', 'quantity': '1'},
            ],
          },
        );
        final engine = build();
        expect(await engine.syncNow(), SyncOutcome.completed);
        final r = await row(m.mutationId);
        expect(r['status'], 'pending');
        expect(r['attempts'], 1);
        final due = DateTime.parse(r['next_attempt_at'] as String);
        expect(due.isAfter(clock), isTrue);
        expect(transport.batchSizes, [1]);

        await engine.syncNow();
        expect(transport.batchSizes, [1], reason: 'not due yet');

        clock = due.add(const Duration(seconds: 1));
        await engine.syncNow();
        expect(transport.batchSizes, [1, 1]);
      },
    );

    test(
      'rejected parks the item and fails dependents; stays rejected',
      () async {
        await otherDevice('x1', payload: {'barcode': 'B1'});
        final p = await enq('p2', payload: {'barcode': 'B1'});
        final child = await enq(
          's1',
          entity: 'stock',
          op: 'adjust',
          dep: 'p2',
          payload: {'product_id': 'p2', 'shop_id': 'sh', 'delta': '1'},
        );
        expect(child.status, OutboxStatus.blocked);
        final engine = build();
        expect(await engine.syncNow(), SyncOutcome.completed);

        final pr = await row(p.mutationId);
        expect(pr['status'], 'rejected');
        expect(pr['error_code'], 'conflict_unique');
        final cr = await row(child.mutationId);
        expect(cr['status'], 'rejected');
        expect(cr['error_code'], 'dependency_failed');
        expect(engine.current.rejected, 2);
        expect(engine.current.pending, 0);

        await engine.syncNow();
        expect(await statusOf(p.mutationId), 'rejected');
        expect(transport.batchSizes, [1], reason: 'rejected never re-pushed');
      },
    );

    test('rejected replay from server stays rejected', () async {
      await otherDevice('x1', payload: {'barcode': 'B1'});
      final p = await enq('p2', payload: {'barcode': 'B1'});
      // First attempt: server applies (rejects) but the response is lost.
      server.dropResponseAfterApply = 1;
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.backoff);
      expect(await statusOf(p.mutationId), 'pending');
      clock = clock.add(const Duration(minutes: 10));
      expect(await engine.syncNow(), SyncOutcome.completed);
      final r = await row(p.mutationId);
      expect(r['status'], 'rejected');
      expect(r['error_code'], 'conflict_unique');
    });

    test('applied dependency unblocks dependents in the same run', () async {
      final p = await enq('p1');
      final child = await enq(
        's1',
        entity: 'stock',
        op: 'adjust',
        dep: 'p1',
        payload: {'product_id': 'p1', 'shop_id': 'sh', 'delta': '2'},
      );
      expect(child.status, OutboxStatus.blocked);
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(await statusOf(p.mutationId), 'done');
      expect(await statusOf(child.mutationId), 'done');
      expect(server.stockQuantity('p1', 'sh'), '2');
    });

    test('entity_deleted on a delete mutation is converged (done)', () async {
      await otherDevice('x1');
      await otherDevice('x1', op: 'delete', payload: {});
      final d = await enq('x1', op: 'delete', payload: {});
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(await statusOf(d.mutationId), 'done');
      expect(engine.current.rejected, 0);
    });

    test('entity_deleted on an update is still rejected', () async {
      await otherDevice('x1');
      await otherDevice('x1', op: 'delete', payload: {});
      final u = await enq('x1', op: 'update', payload: {'name': 'n'});
      final engine = build();
      await engine.syncNow();
      final r = await row(u.mutationId);
      expect(r['status'], 'rejected');
      expect(r['error_code'], 'entity_deleted');
    });

    test(
      'missing result for a claimed mutation -> retry, never done',
      () async {
        final a = await enq('p1');
        final b = await enq('p2');
        transport.rewritePush = (r) => PushResponse(
          serverTime: r.serverTime,
          nextCursor: r.nextCursor,
          results: r.results
              .where((x) => x.mutationId != b.mutationId)
              .toList(),
        );
        final engine = build();
        await engine.syncNow();
        expect(await statusOf(a.mutationId), 'done');
        final rb = await row(b.mutationId);
        expect(rb['status'], 'pending');
        expect(rb['attempts'], 1);
        expect(rb['lease_until'], isNull);
        expect(
          DateTime.parse(rb['next_attempt_at'] as String).isAfter(clock),
          isTrue,
        );

        // Server already applied it: the replay is a duplicate -> done.
        transport.rewritePush = null;
        clock = clock.add(const Duration(minutes: 10));
        await engine.syncNow();
        expect(await statusOf(b.mutationId), 'done');
        expect(server.tables['product']!.length, 2);
      },
    );

    test(
      'results are matched by mutation_id; unknown ids are ignored',
      () async {
        final a = await enq('p1');
        final b = await enq('p2');
        transport.rewritePush = (r) => PushResponse(
          serverTime: r.serverTime,
          nextCursor: r.nextCursor,
          results: [
            const PushResult(
              mutationId: 'not-ours',
              status: PushStatus.rejected,
              code: 'validation_error',
            ),
            ...r.results.reversed,
          ],
        );
        final engine = build();
        expect(await engine.syncNow(), SyncOutcome.completed);
        expect(await statusOf(a.mutationId), 'done');
        expect(await statusOf(b.mutationId), 'done');
        expect(await countStatus('rejected'), 0);
      },
    );

    test('applier always throwing -> server outcome kept, repair flagged, '
        'no row left inflight, lock freed', () async {
      final reported = <FlutterErrorDetails>[];
      final prev = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = prev);
      final a = await enq('p1');
      productApplier.throwOnPushResult = StateError('boom');
      final engine = build();
      final out = await engine.syncNow();
      expect(out, SyncOutcome.completed);
      expect(reported.single.exception.toString(), contains('boom'));
      expect(await state.repairNeeded(), isTrue);
      final r = await row(a.mutationId);
      expect(r['status'], 'done');
      expect(await countStatus('inflight'), 0);
      // Lock released: another holder can take it immediately.
      expect(
        await state.acquireLock('other', const Duration(minutes: 1)),
        isTrue,
      );
    });
  });

  group('pull', () {
    test('page applied atomically with cursor (crash before commit)', () async {
      await otherDevice('x1');
      await otherDevice('x2');
      final crashing = build(
        hooks: SyncHooks(
          beforePullPageCommit: (_) async => throw CrashSimulation('pull'),
        ),
      );
      await expectLater(crashing.syncNow(), throwsA(isA<CrashSimulation>()));
      expect(await tRows(), isEmpty);
      expect(await state.cursor(), seedCursor);

      // Restart after the dead runner's lock expired.
      clock = clock.add(const Duration(minutes: 5));
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect((await tRows()).map((r) => r['id']), ['x1', 'x2']);
      expect(await state.cursor(), isNotNull);
    });

    test(
      'own-device changes are applied once confirmed (no origin skip)',
      () async {
        await enq('p1');
        final engine = build();
        expect(await engine.syncNow(), SyncOutcome.completed);
        expect((await tRows()).single['id'], 'p1');
        final cursor = await state.cursor();
        expect(cursor, isNotNull);
        final page = await server.pull(cursor: cursor, scope: 'u1|t1');
        expect(page.changes, isEmpty);
      },
    );

    test('unknown entity is ignored but cursor advances', () async {
      await otherDevice('n1', entity: 'notification');
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(await tRows(), isEmpty);
      final page = await server.pull(
        cursor: await state.cursor(),
        scope: 'u1|t1',
      );
      expect(page.changes, isEmpty);
    });

    test(
      'fullResyncRequired stops with needsBootstrap and clears cursor',
      () async {
        await otherDevice('x1');
        final engine = build();
        await engine.syncNow();
        expect(await state.cursor(), isNotNull);
        server.fullResyncRequired = true;
        expect(await engine.syncNow(), SyncOutcome.needsBootstrap);
        expect(await state.cursor(), isNull);
      },
    );

    test('pull network failure -> backoff, cursor unchanged', () async {
      await otherDevice('x1');
      transport.pullErrors.add(
        SyncTransportException(kind: SyncTransportKind.timeout),
      );
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.backoff);
      expect(await state.cursor(), seedCursor);
      expect(await tRows(), isEmpty);
    });
  });

  group('crash safety', () {
    test('killed between push and result write: replay is a no-op', () async {
      final a = await enq('p1');
      final crashing = build(
        hooks: SyncHooks(
          beforeResultWrite: (_, _) async => throw CrashSimulation('push'),
        ),
      );
      await expectLater(crashing.syncNow(), throwsA(isA<CrashSimulation>()));
      expect(await statusOf(a.mutationId), 'inflight');
      expect(server.applied.length, 1);

      clock = clock.add(const Duration(minutes: 5));
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(await statusOf(a.mutationId), 'done');
      expect(server.tables['product']!.length, 1);
      expect(server.feed.length, 1);
    });
  });

  group('afterSyncCompleted hook (checksum audit)', () {
    test('fires once after a completed, drained sync; idle by then', () async {
      final engine = build();
      var calls = 0;
      SyncOutcome? nested;
      engine.afterSyncCompleted = () async {
        calls++;
        nested = await engine.syncNow();
      };
      expect(await engine.syncNow(), SyncOutcome.completed);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      expect(nested, isNot(SyncOutcome.alreadyRunning));
    });

    test('not fired on blocked / backoff', () async {
      server.minAppVersion = '9.0.0';
      final engine = build();
      var calls = 0;
      engine.afterSyncCompleted = () async => calls++;
      expect(await engine.syncNow(), SyncOutcome.blocked);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 0);
    });

    test('a throwing hook does not change the outcome', () async {
      final engine = build();
      engine.afterSyncCompleted = () async => throw StateError('boom');
      expect(await engine.syncNow(), SyncOutcome.completed);
      await Future<void>.delayed(Duration.zero);
    });
  });

  group('gates and blocks', () {
    test('appTooOld leaves the outbox untouched', () async {
      server.minAppVersion = '2.1.0';
      final m = await enq('p1');
      final engine = build(appVersion: '2.0.9+77');
      expect(await engine.syncNow(), SyncOutcome.blocked);
      expect(engine.current.block, SyncBlockReason.appTooOld);
      expect(engine.current.phase, SyncPhase.blocked);
      final r = await row(m.mutationId);
      expect(r['status'], 'pending');
      expect(r['attempts'], 0);
      expect(transport.batchSizes, isEmpty);
    });

    test('equal minAppVersion is allowed', () async {
      server.minAppVersion = '2.1.0';
      final engine = build(appVersion: '2.1.0+5');
      expect(await engine.syncNow(), SyncOutcome.completed);
    });

    test('maintenance -> backoff honoring retry_after', () async {
      transport.onPing = (p) => PingResponse(
        ok: true,
        serverTime: p.serverTime,
        maintenance: true,
        retryAfterSeconds: 600,
      );
      final m = await enq('p1');
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.backoff);
      expect(engine.current.block, SyncBlockReason.maintenance);
      expect(
        engine.current.nextRetryAt,
        clock.add(const Duration(minutes: 10)),
      );
      expect(await statusOf(m.mutationId), 'pending');
      expect(transport.batchSizes, isEmpty);
    });

    test('accountDisabled -> blocked, outbox untouched', () async {
      transport.pushErrors.add(
        SyncTransportException(kind: SyncTransportKind.accountDisabled),
      );
      final m = await enq('p1');
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.blocked);
      expect(engine.current.block, SyncBlockReason.accountDisabled);
      final r = await row(m.mutationId);
      expect(r['status'], 'pending');
      expect(r['attempts'], 0);
      expect(r['next_attempt_at'], isNull);
    });

    test('deviceRevoked -> blocked', () async {
      transport.pullErrors.add(
        SyncTransportException(kind: SyncTransportKind.deviceRevoked),
      );
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.blocked);
      expect(engine.current.block, SyncBlockReason.deviceRevoked);
    });

    test(
      'tokenExpired without refresh callback -> backoff, not blocked',
      () async {
        transport.pushErrors.add(
          SyncTransportException(kind: SyncTransportKind.tokenExpired),
        );
        final m = await enq('p1');
        final engine = build();
        expect(await engine.syncNow(), SyncOutcome.backoff);
        expect(engine.current.block, SyncBlockReason.none);
        expect(engine.current.needsLogin, isFalse);
        expect(await statusOf(m.mutationId), 'pending');
      },
    );

    test('tokenExpired + refreshed -> retried once and completes', () async {
      transport.pushErrors.add(
        SyncTransportException(kind: SyncTransportKind.tokenExpired),
      );
      var calls = 0;
      final m = await enq('p1');
      final engine = build(
        refreshToken: () async {
          calls++;
          return RefreshOutcome.refreshed;
        },
      );
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(calls, 1);
      expect(transport.batchSizes, [1, 1]);
      expect(await statusOf(m.mutationId), 'done');
    });

    test('refresh is attempted only once per syncNow', () async {
      transport.pushErrors.addAll([
        SyncTransportException(kind: SyncTransportKind.unauthorized),
        SyncTransportException(kind: SyncTransportKind.tokenExpired),
      ]);
      var calls = 0;
      await enq('p1');
      final engine = build(
        refreshToken: () async {
          calls++;
          return RefreshOutcome.refreshed;
        },
      );
      expect(await engine.syncNow(), SyncOutcome.backoff);
      expect(calls, 1);
      expect(engine.current.needsLogin, isFalse);
    });

    test(
      'tokenExpired + refresh rejected -> blocked tokenExpired, needsLogin',
      () async {
        transport.pushErrors.add(
          SyncTransportException(kind: SyncTransportKind.tokenExpired),
        );
        final m = await enq('p1');
        final engine = build(refreshToken: () async => RefreshOutcome.rejected);
        expect(await engine.syncNow(), SyncOutcome.blocked);
        expect(engine.current.block, SyncBlockReason.tokenExpired);
        expect(engine.current.needsLogin, isTrue);
        final r = await row(m.mutationId);
        expect(r['status'], 'pending');
        expect(r['attempts'], 0);
      },
    );

    test('tokenExpired + refresh transient or throwing -> backoff', () async {
      transport.pullErrors.add(
        SyncTransportException(kind: SyncTransportKind.tokenExpired),
      );
      final engine = build(refreshToken: () async => RefreshOutcome.transient);
      expect(await engine.syncNow(), SyncOutcome.backoff);
      expect(engine.current.phase, SyncPhase.backoff);
      expect(engine.current.needsLogin, isFalse);

      transport.pullErrors.add(
        SyncTransportException(kind: SyncTransportKind.tokenExpired),
      );
      final engine2 = build(refreshToken: () async => throw Exception('x'));
      expect(await engine2.syncNow(), SyncOutcome.backoff);
      expect(engine2.current.needsLogin, isFalse);
    });
  });

  group('single flight', () {
    test('second concurrent syncNow returns alreadyRunning', () async {
      await enq('p1');
      final engine = build();
      final a = engine.syncNow();
      final b = engine.syncNow();
      expect(await b, SyncOutcome.alreadyRunning);
      expect(await a, SyncOutcome.completed);
      expect(transport.batchSizes, [1]);
      // Mutex is released afterwards.
      expect(await engine.syncNow(), SyncOutcome.completed);
    });

    test('lease held by another unexpired holder -> alreadyRunning', () async {
      await state.acquireLock('other', const Duration(minutes: 2));
      final m = await enq('p1');
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.alreadyRunning);
      expect(await statusOf(m.mutationId), 'pending');
      expect(transport.batchSizes, isEmpty);
    });

    test('expired lease is taken over', () async {
      await state.acquireLock('other', const Duration(minutes: 2));
      clock = clock.add(const Duration(minutes: 3));
      await enq('p1');
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.completed);
    });

    test('lease renewed per batch so a second runner cannot start', () async {
      for (var i = 0; i < 250; i++) {
        await enq('p$i');
      }
      final engine = build();
      final second = build();
      final secondOutcomes = <SyncOutcome>[];
      transport.onPush = (call, _) async {
        // Each batch takes 90 s; after batch 2 we are past the initial
        // 2-minute lease.
        clock = clock.add(const Duration(seconds: 90));
        if (call >= 2) secondOutcomes.add(await second.syncNow());
      };
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(secondOutcomes, [
        SyncOutcome.alreadyRunning,
        SyncOutcome.alreadyRunning,
      ]);
      expect(transport.batchSizes, [100, 100, 50]);
      expect(await countStatus('done'), 250);
    });

    test(
      'lock taken by another holder mid-run -> aborts without pushing',
      () async {
        for (var i = 0; i < 150; i++) {
          await enq('p$i');
        }
        final engine = build();
        transport.onPush = (call, _) async {
          if (call == 1) {
            // Lock expires during a stalled batch and another runner takes it.
            clock = clock.add(const Duration(minutes: 3));
            await state.acquireLock('intruder', const Duration(minutes: 2));
          }
        };
        expect(await engine.syncNow(), SyncOutcome.alreadyRunning);
        expect(transport.batchSizes, [100]);
        // The lock was lost before the results write: nothing is written,
        // the rows stay claimed for lease recovery by the new holder.
        expect(await countStatus('done'), 0);
        expect(await countStatus('inflight'), 100);
        expect(productApplier.pushResults, isEmpty);
      },
    );
  });

  group('status stream', () {
    test('reflects outbox counts after local writes', () async {
      final engine = build();
      final seen = <SyncStatus>[];
      final sub = engine.status.listen(seen.add);
      await enq('p1');
      notifier.notify({'outbox'});
      await pumpEventQueue();
      expect(seen.last.pending, 1);
      await engine.syncNow();
      await pumpEventQueue();
      expect(seen.last.pending, 0);
      await sub.cancel();
    });
  });

  group('review fixes', () {
    Future<Map<String, dynamic>> dataOf(
      String id, [
      String e = 'product',
    ]) async {
      final r = await db.query(
        't_rows',
        where: 'entity = ? AND id = ?',
        whereArgs: [e, id],
      );
      return jsonDecode(r.single['data'] as String) as Map<String, dynamic>;
    }

    PushResponse allRetry(PushResponse r) => PushResponse(
      serverTime: r.serverTime,
      nextCursor: r.nextCursor,
      results: [
        for (final x in r.results)
          PushResult(
            mutationId: x.mutationId,
            status: PushStatus.retry,
            code: 'server_busy',
          ),
      ],
    );

    SyncHooks freezeBeforeWrite(
      Completer<void> reached,
      Completer<void> gate,
    ) => SyncHooks(
      beforeResultWrite: (_, _) async {
        reached.complete();
        await gate.future;
      },
    );

    // ---------------------------------------------------------------- C-1
    test('C-1 own-origin latest row of a collapsed page converges', () async {
      transport.collapsePull = true;
      await otherDevice('x1', payload: {'name': 'A', 'price': '5'});
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect((await dataOf('x1'))['price'], '5');

      // Tablet changes the price, then the phone pushes a name edit: the
      // collapsed page only carries the phone's (own-origin) row.
      await otherDevice('x1', op: 'update', payload: {'price': '9'});
      await enq('x1', op: 'update', payload: {'name': 'phone'});
      expect(await engine.syncNow(), SyncOutcome.completed);
      final d = await dataOf('x1');
      expect(d['price'], '9');
      expect(d['name'], 'phone');
    });

    test('C-1 change for an entity with a pending local edit is deferred, then '
        'applied after the push completes', () async {
      await otherDevice('x1', payload: {'name': 'A', 'price': '5'});
      final engine = build();
      await engine.syncNow();
      await otherDevice('x1', op: 'update', payload: {'price': '9'});
      final m = await enq('x1', op: 'update', payload: {'name': 'phone'});

      transport.rewritePush = allRetry; // server applied, we saw "retry"
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(await statusOf(m.mutationId), 'pending');
      expect(
        (await dataOf('x1'))['price'],
        '5',
        reason: 'local edit pending: server row not applied yet',
      );

      transport.rewritePush = null;
      clock = clock.add(const Duration(minutes: 10));
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(await statusOf(m.mutationId), 'done');
      final d = await dataOf('x1');
      expect(d['price'], '9');
      expect(d['name'], 'phone');
    });

    test(
      'C-1 skipWhenLocalPending=false applier receives the change',
      () async {
        final local = await enq(
          'p1:sh',
          entity: 'stock',
          op: 'adjust',
          payload: {'product_id': 'p1', 'shop_id': 'sh', 'delta': '1'},
        );
        await otherDevice(
          'adj-2',
          entity: 'stock',
          op: 'adjust',
          payload: {'product_id': 'p1', 'shop_id': 'sh', 'delta': '4'},
        );
        transport.rewritePush = allRetry;
        final engine = build();
        expect(await engine.syncNow(), SyncOutcome.completed);
        expect(await statusOf(local.mutationId), 'pending');
        // Stock change ids are server UUIDs, not '<product>:<shop>'; the BE
        // serialises StockLevel.quantity with its 3 decimal places.
        final rows = await db.query('t_rows', where: "entity = 'stock'");
        expect(jsonDecode(rows.single['data'] as String)['quantity'], '5.000');
      },
    );

    // ---------------------------------------------------------------- I-1
    test('I-1 frozen runner resumes after another runner finished: writes '
        'nothing', () async {
      final m = await enq('p1');
      final reached = Completer<void>();
      final gate = Completer<void>();
      final a = build(hooks: freezeBeforeWrite(reached, gate));
      final aFut = a.syncNow();
      await reached.future;

      clock = clock.add(const Duration(minutes: 5));
      expect(await build().syncNow(), SyncOutcome.completed);
      final afterB = await row(m.mutationId);
      expect(afterB['status'], 'done');
      expect(productApplier.pushResults, hasLength(1));

      gate.complete();
      await aFut;
      expect(await row(m.mutationId), afterB);
      expect(productApplier.pushResults, hasLength(1));
    });

    test('I-1 frozen runner cannot touch rows another runner holds', () async {
      final m = await enq('p1');
      final aReached = Completer<void>();
      final aGate = Completer<void>();
      final a = build(hooks: freezeBeforeWrite(aReached, aGate));
      final aFut = a.syncNow();
      await aReached.future;

      clock = clock.add(const Duration(minutes: 5));
      final bReached = Completer<void>();
      final bGate = Completer<void>();
      final b = build(hooks: freezeBeforeWrite(bReached, bGate));
      final bFut = b.syncNow();
      await bReached.future;
      final heldByB = await row(m.mutationId);
      expect(heldByB['status'], 'inflight');

      aGate.complete();
      expect(await aFut, SyncOutcome.alreadyRunning);
      expect(await row(m.mutationId), heldByB);
      expect(productApplier.pushResults, isEmpty);

      bGate.complete();
      expect(await bFut, SyncOutcome.completed);
      expect(await statusOf(m.mutationId), 'done');
      expect(productApplier.pushResults, hasLength(1));
    });

    // ---------------------------------------------------------------- I-2
    test('I-2 lock and leases written by a clock 1 day ahead do not wedge '
        'sync after the clock is corrected', () async {
      final m = await enq('p1');
      final realNow = clock;
      clock = clock.add(const Duration(days: 1));
      final crashing = build(
        hooks: SyncHooks(
          beforeResultWrite: (_, _) async => throw CrashSimulation('ahead'),
        ),
      );
      await expectLater(crashing.syncNow(), throwsA(isA<CrashSimulation>()));
      expect(await statusOf(m.mutationId), 'inflight');

      clock = realNow;
      expect(await build().syncNow(), SyncOutcome.completed);
      expect(await statusOf(m.mutationId), 'done');
    });

    // ---------------------------------------------------------------- I-3
    test('I-3 poison applier in a batch of 5', () async {
      final reported = <FlutterErrorDetails>[];
      final prev = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = prev);
      final ids = [for (var i = 0; i < 5; i++) (await enq('p$i')).mutationId];
      productApplier.poisonIds.add(ids[2]);
      final engine = build();

      expect(await engine.syncNow(), SyncOutcome.completed);
      for (final id in ids) {
        expect(await statusOf(id), 'done');
      }
      expect(
        productApplier.pushResults.map((r) => r.mutationId).toSet(),
        {...ids}..remove(ids[2]),
      );
      expect(await state.repairNeeded(), isTrue);
      expect(await countStatus('inflight'), 0);
      expect(engine.current.phase, SyncPhase.idle);
      expect(reported, hasLength(1));
      expect(server.tables['product']!.length, 5);
    });

    // ---------------------------------------------------------------- I-4
    test(
      'I-4 syncNow during the pull phase is coalesced into the run',
      () async {
        final engine = build();
        String? saleId;
        SyncOutcome? second;
        transport.onPull = (call) async {
          if (call != 1) return;
          saleId = (await enq(
            's1',
            entity: 'sale',
            payload: {
              'shop': 'sh',
              'items': [
                {'product_id': 'p1', 'quantity': '1'},
              ],
            },
          )).mutationId;
          second = await engine.syncNow(reason: SyncReason.afterWrite);
        };
        expect(await engine.syncNow(), SyncOutcome.completed);
        expect(second, SyncOutcome.alreadyRunning);
        expect(await statusOf(saleId!), 'done');
        expect(transport.batchSizes, [1]);
      },
    );

    test('I-4 at most 2 extra cycles', () async {
      final engine = build();
      transport.onPull = (_) async {
        await engine.syncNow(); // always asks for another run
      };
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(transport.pulls, 3);
    });

    // ---------------------------------------------------------------- I-5
    test(
      'I-5 no stored cursor -> needsBootstrap, no pull, outbox pushed',
      () async {
        await state.clear();
        final m = await enq('p1');
        final engine = build();
        expect(await engine.syncNow(), SyncOutcome.needsBootstrap);
        expect(transport.pulls, 0);
        expect(await statusOf(m.mutationId), 'done');
        expect(await state.lastSyncedAt(), isNull);
      },
    );

    test(
      'I-5 requireBootstrapWhenNoCursor=false pulls from the start',
      () async {
        await state.clear();
        await otherDevice('x1');
        final engine = build(requireBootstrapWhenNoCursor: false);
        expect(await engine.syncNow(), SyncOutcome.completed);
        expect((await tRows()).single['id'], 'x1');
      },
    );

    // ---------------------------------------------------------------- M-1
    test('M-1 pull stops when next_cursor does not advance', () async {
      transport.pullOverride = (c) async => PullResponse(
        serverTime: clock,
        changes: const [],
        nextCursor: c!,
        hasMore: true,
      );
      expect(await build().syncNow(), SyncOutcome.completed);
      expect(transport.pulls, 1);
    });

    test(
      'M-1 pull capped at 200 pages per cycle, continued by re-run',
      () async {
        var n = 0;
        transport.pullOverride = (_) async => PullResponse(
          serverTime: clock,
          changes: const [],
          nextCursor: 'c${++n}',
          hasMore: true,
        );
        final engine = build();
        expect(await engine.syncNow(), SyncOutcome.completed);
        expect(transport.pulls, 600); // 200 x (1 + 2 extra cycles)
        expect(engine.current.moreToPull, isTrue);
        expect(await state.cursor(), 'c600');
      },
    );

    // ---------------------------------------------------------------- M-2
    test('M-2 payload_too_large splits the batch and parks a single '
        'oversize mutation', () async {
      final huge = await enq('h1', payload: {'huge': true});
      final a = await enq('p1');
      final b = await enq('p2');
      final child = await enq(
        's1',
        entity: 'stock',
        op: 'adjust',
        dep: 'h1',
        payload: {'product_id': 'h1', 'shop_id': 'sh', 'delta': '1'},
      );
      transport.onPush = (_, batch) async {
        if (batch.any((m) => m.payload['huge'] == true)) {
          throw SyncTransportException(kind: SyncTransportKind.tooLarge);
        }
      };
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(transport.batchSizes, [3, 1, 1, 1]);
      final hr = await row(huge.mutationId);
      expect(hr['status'], 'rejected');
      expect(hr['error_code'], 'payload_too_large');
      final cr = await row(child.mutationId);
      expect(cr['status'], 'rejected');
      expect(cr['error_code'], 'dependency_failed');
      expect(await statusOf(a.mutationId), 'done');
      expect((await row(b.mutationId))['attempts'], 0);

      // The batch limit is reset at the next syncNow.
      await enq('p3');
      await enq('p4');
      await engine.syncNow();
      expect(transport.batchSizes.last, 2);
    });
  });

  group('review round 2', () {
    Future<String?> priceOf(String id) async {
      final r = await db.query(
        't_rows',
        where: "entity = 'product' AND id = ?",
        whereArgs: [id],
      );
      if (r.isEmpty) return null;
      return (jsonDecode(r.single['data'] as String) as Map)['price']
          as String?;
    }

    /// Simulates LocalWriter's optimistic local write.
    Future<void> setLocal(String id, Map<String, dynamic> data) => db.insert(
      't_rows',
      {'entity': 'product', 'id': id, 'op': 'upsert', 'data': jsonEncode(data)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    test(
      'N-1 deferred change is applied only on the last page; an older '
      'deferred row never overwrites a newer one, even across a failure',
      () async {
        // Bootstrapped row x1 at price 5.
        await otherDevice('x1', payload: {'name': 'A', 'price': '5'});
        expect(await build(pullPageSize: 3).syncNow(), SyncOutcome.completed);
        expect(await priceOf('x1'), '5');

        // Local edit to 7 (optimistic), push fails -> pending in backoff.
        final m = await enq('x1', op: 'update', payload: {'price': '7'});
        await setLocal('x1', {'name': 'A', 'price': '7', 'version': 1});
        transport.pushErrors.add(
          SyncTransportException(kind: SyncTransportKind.network),
        );
        expect(await build(pullPageSize: 3).syncNow(), SyncOutcome.backoff);

        // Tablet sets 9; a pull while our edit is pending defers it.
        await otherDevice('x1', op: 'update', payload: {'price': '9'});
        expect(await build(pullPageSize: 3).syncNow(), SyncOutcome.completed);
        expect(await statusOf(m.mutationId), 'pending');
        expect(await priceOf('x1'), '7');

        // Filler rows so our pushed edit (price 7) lands on page 2.
        for (var i = 0; i < 5; i++) {
          await otherDevice('f$i');
        }
        clock = clock.add(const Duration(minutes: 10));
        productApplier.appliedPrices.clear();
        var pageNo = 0;
        final crashing = build(
          pullPageSize: 3,
          hooks: SyncHooks(
            beforePullPageCommit: (_) async {
              pageNo++;
              if (pageNo == 2) throw CrashSimulation('page 2');
            },
          ),
        );
        await expectLater(crashing.syncNow(), throwsA(isA<CrashSimulation>()));
        expect(await statusOf(m.mutationId), 'done');
        expect(pageNo, 2);
        expect(await priceOf('x1'), '7', reason: 'page 1 committed alone');

        clock = clock.add(const Duration(minutes: 5));
        final engine = build(pullPageSize: 3);
        expect(await engine.syncNow(), SyncOutcome.completed);
        expect(await priceOf('x1'), '7');
        // Across both runs the stale price 9 was never applied to x1.
        expect(productApplier.appliedPrices, isNot(contains('x1=9')));
        expect(productApplier.appliedPrices, contains('x1=7'));
        expect(server.tables['product']!['x1']!['price'], '7');
        expect(await state.deferredPullJson(db), isNull);
      },
    );

    test(
      'N-1 deferred change not newer than the local version is dropped',
      () async {
        productApplier.adoptPushVersion = true;
        await otherDevice('x1', payload: {'name': 'A', 'price': '5'});
        final engine = build();
        await engine.syncNow();

        final m = await enq('x1', op: 'update', payload: {'price': '7'});
        transport.pushErrors.add(
          SyncTransportException(kind: SyncTransportKind.network),
        );
        expect(await engine.syncNow(), SyncOutcome.backoff);
        await otherDevice('x1', op: 'update', payload: {'price': '9'}); // v2
        expect(await engine.syncNow(), SyncOutcome.completed); // deferred v2
        expect(await state.deferredPullJson(db), isNotNull);

        // Our edit is applied (v3, adopted locally); hide our own feed row so
        // only the deferred v2 entry is in play on the last page.
        clock = clock.add(const Duration(minutes: 10));
        transport.keepChange = (c) => c.id != 'x1';
        expect(await engine.syncNow(), SyncOutcome.completed);
        expect(await statusOf(m.mutationId), 'done');
        expect(await priceOf('x1'), '7');
        expect(await state.deferredPullJson(db), isNull);
      },
    );

    test('N-4 corrupt deferred blob is dropped and reported once', () async {
      final reported = <FlutterErrorDetails>[];
      final prev = FlutterError.onError;
      FlutterError.onError = reported.add;
      addTearDown(() => FlutterError.onError = prev);
      await db.transaction((t) => state.setDeferredPullJson(t, 'not json'));
      for (var i = 0; i < 4; i++) {
        await otherDevice('x$i');
      }
      final engine = build(pullPageSize: 1);
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect(transport.pulls, greaterThan(2));
      expect(reported, hasLength(1));
      expect(await state.deferredPullJson(db), isNull);
      expect(await state.repairNeeded(), isTrue);
      expect(await tRows(), hasLength(4));
    });
  });

  // ------------------------------------------------- phase 2 (Task 7)
  group('bootstrap state and resync semantics', () {
    Future<void> completedBootstrapAt(DateTime at) =>
        db.transaction((t) => state.setBootstrapCompletedAt(t, at));

    Future<String> rejectedRow() async {
      final m = await enq('r1');
      await db.update(
        'outbox',
        {'status': 'rejected'},
        where: 'mutation_id = ?',
        whereArgs: [m.mutationId],
      );
      return m.mutationId;
    }

    test('cursor without the bootstrapped flag -> needsBootstrap, no pull, '
        'outbox still pushed', () async {
      await db.transaction((t) => state.setBootstrapped(t, false));
      final m = await enq('p1');
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.needsBootstrap);
      expect(transport.pulls, 0);
      expect(await statusOf(m.mutationId), 'done');
      expect(await state.cursor(), seedCursor, reason: 'nothing reset');
    });

    test('requireBootstrapWhenNoCursor=false ignores the flag too', () async {
      await db.transaction((t) => state.setBootstrapped(t, false));
      await otherDevice('x1');
      final engine = build(requireBootstrapWhenNoCursor: false);
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect((await tRows()).single['id'], 'x1');
    });

    test('full_resync_required: cursor, old progress and old deferred pulls '
        'cleared; bootstrapped, local rows and outbox kept', () async {
      await otherDevice('x1');
      final engine = build();
      expect(await engine.syncNow(), SyncOutcome.completed);
      final rejected = await rejectedRow();
      final before = await row(rejected);
      await db.transaction((t) async {
        await state.setDeferredPullJson(t, '{}');
        await state.setBootstrapProgress(
          t,
          BootstrapProgress(
            snapshotCursor: 's',
            entities: const ['product'],
            done: const [],
            startedAt: clock,
          ),
        );
      });
      server.fullResyncRequired = true;
      expect(await engine.syncNow(), SyncOutcome.needsBootstrap);
      expect(await state.cursor(), isNull);
      expect(await state.isBootstrapped(), isTrue);
      expect(await state.deferredPullJson(db), isNull);
      expect(await state.bootstrapProgress(db), isNull);
      expect((await tRows()).single['id'], 'x1', reason: 'rows stay visible');
      expect(await row(rejected), before, reason: 'outbox untouched');
    });

    test(
      'a second full_resync_required within 10 min of a completed '
      'bootstrap backs off (loud), no restart; after 10 min it resets',
      () async {
        final reported = <FlutterErrorDetails>[];
        final prev = FlutterError.onError;
        FlutterError.onError = reported.add;
        addTearDown(() => FlutterError.onError = prev);
        await completedBootstrapAt(clock.subtract(const Duration(minutes: 3)));
        server.fullResyncRequired = true;
        final engine = build();
        expect(await engine.syncNow(), SyncOutcome.backoff);
        expect(engine.current.phase, SyncPhase.backoff);
        expect(engine.current.nextRetryAt, isNotNull);
        expect(engine.current.lastError, 'full_resync_loop');
        expect(await state.cursor(), seedCursor, reason: 'no reset');
        expect(await state.isBootstrapped(), isTrue);
        expect(reported, hasLength(1));

        clock = clock.add(const Duration(minutes: 8)); // 11 min after
        expect(await engine.syncNow(), SyncOutcome.needsBootstrap);
        expect(await state.cursor(), isNull);
        expect(await state.isBootstrapped(), isTrue);
      },
    );

    test('a completed-at far in the future (clock moved back) does not wedge '
        'the resync', () async {
      await completedBootstrapAt(clock.add(const Duration(days: 30)));
      server.fullResyncRequired = true;
      expect(await build().syncNow(), SyncOutcome.needsBootstrap);
      expect(await state.cursor(), isNull);
    });

    test('the completed-at timestamp survives the reset (clear)', () async {
      final at = clock.subtract(const Duration(hours: 1));
      await completedBootstrapAt(at);
      server.fullResyncRequired = true;
      expect(await build().syncNow(), SyncOutcome.needsBootstrap);
      expect(await state.bootstrapCompletedAt(), at);
    });

    test('a cursor wiped under the run (logout table wipe) is never '
        're-set by the page in flight', () async {
      await otherDevice('x1');
      final engine = build();
      transport.onPull = (_) async {
        await db.transaction(SyncStateStore.resetSetupOfAllScopes);
      };
      expect(await engine.syncNow(), SyncOutcome.cancelled);
      expect(await state.cursor(), isNull);
      expect(await state.isBootstrapped(), isFalse);
      expect(await tRows(), isEmpty, reason: 'page rolled back');
    });
  });
}
