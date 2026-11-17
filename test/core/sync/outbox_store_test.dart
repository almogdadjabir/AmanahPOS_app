import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/data.dart' show V4Options;
import 'package:uuid/uuid.dart';

import 'support/test_db.dart';

void main() {
  late OfflineDb odb;
  late Database db;
  late DateTime clock;
  late OutboxStore store;

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
    clock = DateTime.utc(2026, 1, 1, 12);
    store = OutboxStore(odb, now: () => clock);
  });
  tearDown(() async => db.close());

  Future<OutboxEntry> enq(
    String entityId, {
    String op = 'update',
    String? dep,
    Map<String, dynamic>? payload,
  }) {
    return store.enqueue(
      db,
      entity: 'product',
      op: op,
      entityId: entityId,
      payload: payload ?? {'a': 1},
      scope: 'u1|t1',
      dependsOn: [?dep],
    );
  }

  Future<String> statusOf(String mid) async =>
      (await db.query(
            'outbox',
            columns: ['status'],
            where: 'mutation_id = ?',
            whereArgs: [mid],
          )).first['status']
          as String;

  test('enqueue assigns increasing seq and unique mutation ids', () async {
    final a = await enq('e1');
    final b = await enq('e2');
    expect(b.seq! > a.seq!, isTrue);
    expect(a.mutationId, isNot(b.mutationId));
    expect(a.status, OutboxStatus.pending);
  });

  test('arabic and 1.2MB payloads round-trip', () async {
    final big = 'x' * 1200000;
    await enq('e1', payload: {'name': 'قهوة سودانية', 'big': big});
    final got = await store.claimBatch(scope: 'u1|t1');
    expect(got.single.payload['name'], 'قهوة سودانية');
    expect(got.single.payload['big'], big);
  });

  test(
    'blocked when dependency create is open; unblock flips to pending',
    () async {
      final parent = await enq('p1', op: 'create');
      final child = await enq('v1', op: 'create', dep: 'p1');
      expect(child.status, OutboxStatus.blocked);
      // Unblock re-checks the dependency: the create must be done first.
      await store.unblockDependents(db, 'p1', scope: 'u1|t1');
      expect(await statusOf(child.mutationId), 'blocked');
      await store.applyResult(db, parent.mutationId, status: OutboxStatus.done);
      await store.unblockDependents(db, 'p1', scope: 'u1|t1');
      expect(await statusOf(child.mutationId), 'pending');
    },
  );

  test('not blocked when dependency create is done', () async {
    final p = await enq('p1', op: 'create');
    await store.applyResult(db, p.mutationId, status: OutboxStatus.done);
    final child = await enq('v1', op: 'create', dep: 'p1');
    expect(child.status, OutboxStatus.pending);
  });

  test('failDependents rejects with dependency_failed (cascading)', () async {
    await enq('p1', op: 'create');
    final c = await enq('v1', op: 'create', dep: 'p1');
    final g = await enq('x1', op: 'create', dep: 'v1');
    await store.failDependents(db, 'p1', scope: 'u1|t1');
    final rej = await store.rejected();
    expect(
      rej.map((e) => e.mutationId),
      containsAll([c.mutationId, g.mutationId]),
    );
    expect(rej.every((e) => e.errorCode == 'dependency_failed'), isTrue);
  });

  test('claimBatch pages without repeats', () async {
    final es = [for (var i = 0; i < 5; i++) await enq('e$i')];
    final first = await store.claimBatch(scope: 'u1|t1', limit: 2);
    final second = await store.claimBatch(scope: 'u1|t1', limit: 2);
    final third = await store.claimBatch(scope: 'u1|t1', limit: 2);
    expect(first.map((e) => e.mutationId), [
      es[0].mutationId,
      es[1].mutationId,
    ]);
    expect(second.map((e) => e.mutationId), [
      es[2].mutationId,
      es[3].mutationId,
    ]);
    expect(third.map((e) => e.mutationId), [es[4].mutationId]);
    expect(first.every((e) => e.status == OutboxStatus.inflight), isTrue);
    expect(await store.claimBatch(scope: 'u1|t1'), isEmpty);
  });

  test(
    'same-entity mutations are never batched together or out of order',
    () async {
      final u1 = await enq('e1');
      final u2 = await enq('e1');
      final other = await enq('e2');
      final b1 = await store.claimBatch(scope: 'u1|t1');
      expect(b1.map((e) => e.mutationId), [u1.mutationId, other.mutationId]);
      expect(await store.claimBatch(scope: 'u1|t1'), isEmpty);
      await store.applyResult(db, u1.mutationId, status: OutboxStatus.done);
      final b2 = await store.claimBatch(scope: 'u1|t1');
      expect(b2.map((e) => e.mutationId), [u2.mutationId]);
    },
  );

  test('rejected earlier mutation holds later same-entity mutations '
      '(non-catalog entity, or a rejected create)', () async {
    Future<OutboxEntry> row(String entity, String op) => store.enqueue(
      db,
      entity: entity,
      op: op,
      entityId: 'e1',
      payload: const {'a': 1},
      scope: 'u1|t1',
    );
    for (final (entity, op) in [
      ('sale', 'refund'),
      ('customer', 'update'),
      ('product', 'create'),
    ]) {
      await db.delete('outbox');
      final first = await row(entity, op);
      await row(entity, op == 'create' ? 'update' : op);
      await store.claimBatch(scope: 'u1|t1');
      await store.applyResult(
        db,
        first.mutationId,
        status: OutboxStatus.rejected,
        code: 'validation_error',
      );
      expect(
        await store.claimBatch(scope: 'u1|t1'),
        isEmpty,
        reason: '$entity.$op',
      );
    }
  });

  test('a rejected catalog update/delete does not hold later rows of the '
      'same row (ruling I2)', () async {
    for (final entity in ['product', 'category', 'vendor']) {
      for (final op in ['update', 'delete']) {
        await db.delete('outbox');
        final first = await store.enqueue(
          db,
          entity: entity,
          op: op,
          entityId: 'e1',
          payload: const {},
          scope: 'u1|t1',
        );
        final later = await store.enqueue(
          db,
          entity: entity,
          op: 'update',
          entityId: 'e1',
          payload: const {'name': 'x'},
          scope: 'u1|t1',
        );
        await store.claimBatch(scope: 'u1|t1');
        await store.applyResult(
          db,
          first.mutationId,
          status: OutboxStatus.rejected,
          code: 'conflict_unique',
        );
        final got = await store.claimBatch(scope: 'u1|t1');
        expect(got.map((e) => e.mutationId), [
          later.mutationId,
        ], reason: '$entity.$op');
      }
    }
  });

  test('next_attempt_at in the future is not claimed until due', () async {
    final a = await enq('e1');
    await store.claimBatch(scope: 'u1|t1');
    await store.scheduleRetry(
      a.mutationId,
      clock.add(const Duration(minutes: 5)),
    );
    expect(await store.claimBatch(scope: 'u1|t1'), isEmpty);
    clock = clock.add(const Duration(minutes: 6));
    final got = await store.claimBatch(scope: 'u1|t1');
    expect(got.single.attempts, 1);
  });

  test(
    'releaseExpiredLeases returns expired inflight rows to pending',
    () async {
      final a = await enq('e1');
      await store.claimBatch(scope: 'u1|t1', lease: const Duration(minutes: 2));
      expect(await store.releaseExpiredLeases(), 0);
      clock = clock.add(const Duration(minutes: 3));
      expect(await store.releaseExpiredLeases(), 1);
      expect(await statusOf(a.mutationId), 'pending');
    },
  );

  test('retryRejected resets to pending with attempts 0', () async {
    final a = await enq('e1');
    await store.scheduleRetry(a.mutationId, clock);
    await store.applyResult(
      db,
      a.mutationId,
      status: OutboxStatus.rejected,
      code: 'validation_error',
    );
    await store.retryRejected(a.mutationId);
    final got = await store.claimBatch(scope: 'u1|t1');
    expect(got.single.attempts, 0);
    expect(got.single.errorCode, isNull);
  });

  test('discard deletes row and fails dependents', () async {
    final p = await enq('p1', op: 'create');
    final c = await enq('v1', op: 'create', dep: 'p1');
    await store.discard(p.mutationId);
    expect(
      await db.query(
        'outbox',
        where: 'mutation_id = ?',
        whereArgs: [p.mutationId],
      ),
      isEmpty,
    );
    expect(await statusOf(c.mutationId), 'rejected');
  });

  test('pruneDone removes only old done rows', () async {
    final old = await enq('e1');
    final fresh = await enq('e2');
    await store.applyResult(db, old.mutationId, status: OutboxStatus.done);
    await store.applyResult(db, fresh.mutationId, status: OutboxStatus.done);
    await db.update(
      'outbox',
      {'created_at': '2025-12-01T00:00:00.000Z'},
      where: 'mutation_id = ?',
      whereArgs: [old.mutationId],
    );
    final pending = await enq('e3');
    expect(await store.pruneDone(), 1);
    expect((await db.query('outbox')).length, 2);
    expect(await statusOf(pending.mutationId), 'pending');
  });

  test('watchPendingCount emits updates', () async {
    final n = DbChangeNotifier();
    final stream = store.watchPendingCount(n);
    final got = <int>[];
    final sub = stream.listen(got.add);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await enq('e1');
    n.notify({'outbox'});
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await sub.cancel();
    expect(got, [0, 1]);
  });

  test(
    'pendingCount counts pending only; unsyncedCount everything but done',
    () async {
      expect(await store.pendingCount(), 0);
      expect(await store.unsyncedCount(), 0);
      final a = await enq('e1');
      final b = await enq('e2');
      await enq('e3');
      await store.applyResult(db, a.mutationId, status: OutboxStatus.done);
      await store.applyResult(
        db,
        b.mutationId,
        status: OutboxStatus.rejected,
        code: 'validation_error',
      );
      expect(await store.pendingCount(), 1);
      expect(await store.unsyncedCount(), 2); // rejected is still unsent data
    },
  );

  test('scheduleRetry does not resurrect done or rejected rows', () async {
    final a = await enq('e1');
    final b = await enq('e2');
    await store.applyResult(db, a.mutationId, status: OutboxStatus.done);
    await store.applyResult(
      db,
      b.mutationId,
      status: OutboxStatus.rejected,
      code: 'validation_error',
    );
    await store.scheduleRetry(a.mutationId, clock);
    await store.scheduleRetry(b.mutationId, clock);
    expect(await statusOf(a.mutationId), 'done');
    expect(await statusOf(b.mutationId), 'rejected');
  });

  test('concurrent claimBatch calls never overlap', () async {
    final all = <int>{};
    for (var i = 0; i < 100; i++) {
      all.add((await enq('e$i')).seq!);
    }
    final res = await Future.wait([
      store.claimBatch(scope: 'u1|t1', limit: 50),
      store.claimBatch(scope: 'u1|t1', limit: 50),
    ]);
    final s1 = res[0].map((e) => e.seq!).toSet();
    final s2 = res[1].map((e) => e.seq!).toSet();
    expect(s1.intersection(s2), isEmpty);
    expect(res[0].length + res[1].length, 100);
    expect(s1.union(s2), all);
  });

  test('injected Uuid is used for mutationId', () async {
    final s = OutboxStore(odb, now: () => clock, uuid: const _FixedUuid());
    final e = await s.enqueue(
      db,
      entity: 'product',
      op: 'update',
      entityId: 'z',
      payload: {},
      scope: 'u1|t1',
    );
    expect(e.mutationId, 'fixed-id');
  });

  test('claim scans past a window full of blocked same-entity rows', () async {
    final first = await enq('hot');
    for (var i = 0; i < 600; i++) {
      await enq('hot');
    }
    final free = await enq('free');
    await store.applyResult(db, first.mutationId, status: OutboxStatus.pending);
    final got = await store.claimBatch(scope: 'u1|t1', limit: 5);
    expect(got.map((e) => e.seq), [first.seq, free.seq]);
  });

  test(
    'guarded writes ignore a stale lease after another runner reclaimed',
    () async {
      final a = await enq('e1');
      final first = (await store.claimBatch(
        scope: 'u1|t1',
        lease: const Duration(minutes: 2),
      )).single;
      clock = clock.add(const Duration(minutes: 3));
      expect(await store.releaseExpiredLeases(), 1);
      final second = (await store.claimBatch(
        scope: 'u1|t1',
        lease: const Duration(minutes: 2),
      )).single;
      expect(second.leaseUntil, isNot(first.leaseUntil));

      expect(
        await store.scheduleRetry(
          a.mutationId,
          clock,
          leaseUntil: first.leaseUntil,
        ),
        0,
      );
      expect(
        await store.applyResult(
          db,
          a.mutationId,
          status: OutboxStatus.done,
          leaseUntil: first.leaseUntil,
        ),
        0,
      );
      expect(
        await store.releaseClaim(a.mutationId, leaseUntil: first.leaseUntil),
        0,
      );
      final r = (await db.query(
        'outbox',
        where: 'mutation_id = ?',
        whereArgs: [a.mutationId],
      )).single;
      expect(r['status'], 'inflight');
      expect(r['attempts'], 0);
      expect(r['lease_until'], second.leaseUntil!.toIso8601String());

      // The current holder's lease works, also inside a transaction.
      await db.transaction((txn) async {
        expect(
          await store.scheduleRetry(
            a.mutationId,
            clock,
            executor: txn,
            leaseUntil: second.leaseUntil,
          ),
          1,
        );
      });
      expect(await statusOf(a.mutationId), 'pending');
    },
  );

  test(
    'small clock step back (within slack) keeps leases and retry times',
    () async {
      final a = await enq('e1');
      final realNow = clock;
      clock = realNow.add(const Duration(seconds: 30));
      await store.claimBatch(scope: 'u1|t1', lease: const Duration(minutes: 2));
      clock = realNow;
      expect(
        await store.releaseExpiredLeases(maxLease: const Duration(minutes: 2)),
        0,
      );
      clock = realNow.add(const Duration(seconds: 30));
      await store.scheduleRetry(
        a.mutationId,
        clock.add(const Duration(hours: 1)),
      );
      clock = realNow;
      expect(
        await store.claimBatch(
          scope: 'u1|t1',
          maxRetryDelay: const Duration(hours: 1),
        ),
        isEmpty,
      );
    },
  );

  test(
    'clock moved backwards: far-future leases and retry times not honoured',
    () async {
      final a = await enq('e1');
      final realNow = clock;
      clock = realNow.add(const Duration(days: 1));
      await store.claimBatch(scope: 'u1|t1', lease: const Duration(minutes: 2));
      clock = realNow;
      expect(await store.releaseExpiredLeases(), 0);
      expect(
        await store.releaseExpiredLeases(maxLease: const Duration(minutes: 2)),
        1,
      );
      expect(
        (await store.claimBatch(scope: 'u1|t1')).single.mutationId,
        a.mutationId,
      );

      clock = realNow.add(const Duration(days: 1));
      await store.scheduleRetry(
        a.mutationId,
        clock.add(const Duration(minutes: 5)),
      );
      clock = realNow;
      expect(await store.claimBatch(scope: 'u1|t1'), isEmpty);
      expect(
        (await store.claimBatch(
          scope: 'u1|t1',
          maxRetryDelay: const Duration(hours: 1),
        )).single.mutationId,
        a.mutationId,
      );
    },
  );
}

class _FixedUuid extends Uuid {
  const _FixedUuid();
  @override
  String v4({V4Options? config, Map<String, dynamic>? options}) => 'fixed-id';
}
