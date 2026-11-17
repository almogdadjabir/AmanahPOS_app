// Task 5: a failed create also fails the LATER rows of the same entity
// (Review Focus 2), and retrying it revives the rows it failed (M1).
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'support/test_db.dart';

const _scope = 'u1|t1';

void main() {
  late Database db;
  late OutboxStore store;

  setUp(() async {
    final odb = await openTestDb();
    db = await odb.database;
    store = OutboxStore(odb);
  });
  tearDown(() async => db.close());

  Future<OutboxEntry> enq(
    String entityId, {
    String entity = 'product',
    String op = 'create',
    List<String> deps = const [],
    String scope = _scope,
  }) => store.enqueue(
    db,
    entity: entity,
    op: op,
    entityId: entityId,
    payload: const {},
    scope: scope,
    dependsOn: deps,
  );

  Future<OutboxEntry> get(OutboxEntry e) async => OutboxEntry.fromRow(
    (await db.query(
      'outbox',
      where: 'mutation_id = ?',
      whereArgs: [e.mutationId],
    )).single,
  );

  Future<void> reject(OutboxEntry e, {String code = 'conflict_unique'}) async {
    await store.applyResult(
      db,
      e.mutationId,
      status: OutboxStatus.rejected,
      code: code,
      message: 'x',
      errorEntityId: 'winner',
    );
    if (OutboxStore.failsDependents(e)) {
      await store.failDependents(db, e.entityId, scope: e.scope);
    }
  }

  test('failDependents also fails later update/delete of the same entity, '
      'not other scopes, not done rows', () async {
    final c = await enq('p1');
    final u = await enq('p1', op: 'update');
    final d = await enq('p1', op: 'delete');
    final otherScope = await enq('p1', op: 'update', scope: 'u2|t2');
    final otherEntity = await enq('p2', op: 'update');
    await reject(c);
    for (final e in [u, d]) {
      final r = await get(e);
      expect(r.status, OutboxStatus.rejected);
      expect(r.errorCode, 'dependency_failed');
      expect(r.errorMessage, 'Dependency p1 failed');
    }
    expect((await get(otherScope)).status, OutboxStatus.pending);
    expect((await get(otherEntity)).status, OutboxStatus.pending);
    final cr = await get(c);
    expect([cr.errorCode, cr.errorEntityId], ['conflict_unique', 'winner']);
  });

  test('a rejected update fails nothing (C1 unchanged)', () async {
    final u = await enq('p1', op: 'update');
    final later = await enq('p1', op: 'update');
    final sale = await enq('s1', entity: 'sale', deps: ['p1']);
    await reject(u);
    expect((await get(later)).status, OutboxStatus.pending);
    expect((await get(sale)).status, OutboxStatus.pending);
  });

  test(
    'cascade continues through a dependent create and its own later rows',
    () async {
      final cat = await enq('c1', entity: 'category');
      final p = await enq('p1', deps: ['c1']);
      final pEdit = await enq('p1', op: 'update');
      final stock = await enq('s1', entity: 'stock', op: 'add', deps: ['p1']);
      await reject(cat);
      for (final e in [p, pEdit, stock]) {
        expect((await get(e)).errorCode, 'dependency_failed', reason: e.op);
      }
    },
  );

  test('discarding a create fails its later same-entity rows', () async {
    final c = await enq('p1');
    final u = await enq('p1', op: 'update');
    expect(await store.discard(c.mutationId), DiscardOutcome.discarded);
    expect((await get(u)).errorCode, 'dependency_failed');
  });

  test('retryRejected revives the rows failed only because of that create '
      '(recursively); rows failed by another create stay rejected', () async {
    final cat = await enq('c1', entity: 'category');
    final other = await enq('c2', entity: 'category');
    final p = await enq('p1', deps: ['c1']);
    final pEdit = await enq('p1', op: 'update');
    final stock = await enq('s1', entity: 'stock', op: 'add', deps: ['p1']);
    final q = await enq('p2', deps: ['c2']);
    final unrelated = await enq('v1', entity: 'vendor');
    await reject(cat);
    await reject(other);
    await reject(unrelated, code: 'validation_error');

    expect(await store.retryRejected(cat.mutationId), isTrue);
    final cr = await get(cat);
    expect(
      [cr.status, cr.errorCode, cr.errorEntityId],
      [OutboxStatus.pending, null, null],
    );
    expect((await get(p)).status, OutboxStatus.blocked, reason: 'c1 open');
    expect((await get(pEdit)).status, OutboxStatus.pending);
    expect((await get(stock)).status, OutboxStatus.blocked, reason: 'p1 open');
    for (final e in [p, pEdit, stock]) {
      final r = await get(e);
      expect([r.errorCode, r.errorMessage], [null, null]);
    }
    expect((await get(q)).status, OutboxStatus.rejected);
    expect((await get(other)).status, OutboxStatus.rejected);
    expect((await get(unrelated)).status, OutboxStatus.rejected);
  });

  test('retrying a non-create row revives nothing', () async {
    final c = await enq('p1');
    final u = await enq('p1', op: 'update');
    await reject(c);
    expect(await store.retryRejected(u.mutationId), isTrue);
    expect((await get(c)).status, OutboxStatus.rejected);
  });

  test('M9: revival matches the failed_by column even when the message was '
      'changed (e.g. by a merge) or written by the BE', () async {
    final c = await enq('p1');
    final sale = await enq('s1', entity: 'sale', deps: ['p1']);
    await reject(c);
    expect((await get(sale)).status, OutboxStatus.rejected);
    await db.update(
      'outbox',
      {'error_message': 'A mutation this one depends on was rejected.'},
      where: 'mutation_id = ?',
      whereArgs: [sale.mutationId],
    );
    expect(await store.retryRejected(c.mutationId), isTrue);
    expect((await get(sale)).status, OutboxStatus.blocked);
  });
}
