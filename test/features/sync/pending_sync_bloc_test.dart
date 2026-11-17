import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/features/sync/presentation/bloc/pending_sync_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/sync/support/test_db.dart';

void main() {
  const mine = 'u1|t1';
  const other = 'u2|t2';
  late OfflineDb odb;
  late Database db;
  late OutboxStore outbox;
  late PendingSyncBloc bloc;
  late DbChangeNotifier notifier;
  late List<Set<String>> notified;
  var syncNowCalls = 0;

  Future<OutboxEntry> enq(
    String entity,
    String entityId, {
    String op = 'create',
    String scope = mine,
    String? dep,
    Map<String, dynamic>? payload,
  }) => outbox.enqueue(
    db,
    entity: entity,
    op: op,
    entityId: entityId,
    payload: payload ?? {},
    scope: scope,
    dependsOn: [?dep],
  );

  Future<void> reject(OutboxEntry e) => outbox.applyResult(
    db,
    e.mutationId,
    status: OutboxStatus.rejected,
    code: 'bad',
    message: 'nope',
  );

  Future<void> insertSale(String id, {String state = 'pending'}) =>
      db.insert('sales', {
        'id': id,
        'shop_id': 's1',
        'status': 'completed',
        'subtotal': '10.00',
        'discount': '0.00',
        'tax_amount': '0.00',
        'net_amount': '10.00',
        'local_receipt_number': 'L-7',
        'occurred_at': '2026-01-01T00:00:00Z',
        'sync_state': state,
      });

  Future<PendingSyncState> load() async {
    bloc.add(const OnPendingSyncLoad());
    return bloc.stream.firstWhere((s) => s.status == PendingSyncStatus.loaded);
  }

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
    outbox = OutboxStore(odb);
    await db.insert('products', {'id': 'p1', 'name': 'Tea', 'json': '{}'});
    syncNowCalls = 0;
    notifier = DbChangeNotifier();
    notified = [];
    notifier.changes.listen(notified.add);
    bloc = PendingSyncBloc(
      outbox: outbox,
      db: odb,
      scope: () => mine,
      notifier: notifier,
      syncNow: () async => syncNowCalls++,
    );
  });
  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  test(
    'lists rows with labels, errors, blocked waits-behind, scopes',
    () async {
      await insertSale('sale1');
      final sale = await enq('sale', 'sale1');
      await reject(sale);
      final dep = await enq('stock', 'st1', dep: 'sale1');
      final stock = await enq(
        'stock',
        'st2',
        payload: {'product_id': 'p1', 'delta': '1.000'},
      );
      final foreign = await enq('inbound', 'in1', scope: other);

      final s = await load();
      final byId = {for (final r in s.rows) r.entry.mutationId: r};
      expect(s.rows.length, 4);
      expect(byId[sale.mutationId]!.entry.status, OutboxStatus.rejected);
      expect(byId[sale.mutationId]!.entry.errorCode, 'bad');
      expect(byId[sale.mutationId]!.label, contains('L-7'));
      expect(byId[sale.mutationId]!.total, '10.00');
      expect(byId[stock.mutationId]!.label, 'Tea');
      expect(byId[stock.mutationId]!.otherScope, isFalse);
      expect(byId[foreign.mutationId]!.otherScope, isTrue);
      expect(byId[dep.mutationId]!.entry.status, OutboxStatus.blocked);
      expect(
        byId[dep.mutationId]!.waitsBehind?.entry.mutationId,
        sale.mutationId,
      );
    },
  );

  test('blocked row waits behind the rejected row', () async {
    final parent = await enq('sale', 'sale1');
    final child = await enq('stock', 'st1', dep: 'sale1');
    expect(child.status, OutboxStatus.blocked);
    await db.update(
      'outbox',
      {'status': 'rejected'},
      where: 'mutation_id = ?',
      whereArgs: [parent.mutationId],
    );
    final s = await load();
    final r = s.rows.firstWhere((r) => r.entry.mutationId == child.mutationId);
    expect(r.waitsBehind?.entry.mutationId, parent.mutationId);
  });

  test('retry makes a rejected row pending', () async {
    final e = await enq('stock', 'st1');
    await reject(e);
    await load();
    bloc.add(OnPendingSyncRetryRow(e.mutationId));
    final s = await bloc.stream.firstWhere(
      (s) =>
          s.status == PendingSyncStatus.loaded &&
          s.rows.any((r) => r.entry.status == OutboxStatus.pending),
    );
    expect(s.rows.single.entry.errorCode, isNull);
  });

  test('discard sale removes the outbox row, keeps sale as rejected', () async {
    await insertSale('sale1');
    final e = await enq('sale', 'sale1');
    await reject(e);
    await load();
    bloc.add(OnPendingSyncDiscardRow(e.mutationId));
    final s = await bloc.stream.firstWhere(
      (s) => s.status == PendingSyncStatus.loaded && s.rows.isEmpty,
    );
    expect(s.rows, isEmpty);
    final sale = await db.query('sales', where: "id = 'sale1'");
    expect(sale, hasLength(1));
    expect(sale.single['sync_state'], 'rejected');
  });

  test('discard of other scope removes only that scope', () async {
    await enq('stock', 'st1');
    await enq('inbound', 'in1', scope: other);
    await load();
    bloc.add(const OnPendingSyncDiscardScope(other));
    final s = await bloc.stream.firstWhere(
      (s) => s.status == PendingSyncStatus.loaded && s.rows.length == 1,
    );
    expect(s.rows.single.otherScope, isFalse);
  });

  group('review fixes', () {
    Future<PendingSyncState> next(bool Function(PendingSyncState) p) =>
        bloc.stream.firstWhere(p);

    test('I1: a row claimed by the engine between list load and confirm is '
        'NOT discarded; the bloc reports it and shows it as sending', () async {
      await insertSale('sale1');
      final e = await enq('sale', 'sale1');
      final s0 = await load();
      expect(s0.rows.single.entry.status, OutboxStatus.pending);

      // The engine claims (and sends) the row while the sheet is open.
      final claimed = await outbox.claimBatch(scope: mine);
      expect(claimed.single.mutationId, e.mutationId);

      bloc.add(OnPendingSyncDiscardRow(e.mutationId));
      final s = await next((s) => s.failure != null);
      expect(s.failure, PendingSyncFailure.discardSending);
      expect(s.rows.single.entry.mutationId, e.mutationId);
      expect(s.rows.single.entry.status, OutboxStatus.inflight);
      final sale = await db.query('sales', where: "id = 'sale1'");
      expect(sale.single['sync_state'], 'pending');
    });

    test('M4: if removing the outbox row fails, the sale is NOT marked '
        'rejected (one transaction) and the failure is reported', () async {
      await insertSale('sale1');
      final e = await enq('sale', 'sale1');
      await load();
      await db.execute(
        'CREATE TRIGGER t_fail BEFORE DELETE ON outbox '
        "BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );
      bloc.add(OnPendingSyncDiscardRow(e.mutationId));
      final s = await next((s) => s.failure != null);
      expect(s.failure, PendingSyncFailure.actionFailed);
      expect(s.errorMessage, contains('boom'));
      final sale = await db.query('sales', where: "id = 'sale1'");
      expect(sale.single['sync_state'], 'pending');
      expect(s.rows.single.entry.mutationId, e.mutationId);
    });

    test('M3: discard, retry and retry-all notify outbox + sales + stock '
        'listeners', () async {
      final a = await enq('stock', 'st1');
      final b = await enq('stock', 'st2');
      final c = await enq('stock', 'st3');
      await reject(a);
      await reject(b);
      await load();

      bloc.add(OnPendingSyncRetryRow(a.mutationId));
      await next((s) => s.status == PendingSyncStatus.loaded);
      bloc.add(const OnPendingSyncRetryAll());
      await next((s) => s.status == PendingSyncStatus.loaded);
      bloc.add(OnPendingSyncDiscardRow(c.mutationId));
      await next((s) => s.rows.length == 2);

      expect(notified, hasLength(3));
      for (final t in notified) {
        expect(t, containsAll(<String>['outbox', 'sales', 'stock']));
      }
    });

    test('retry-all retries only the signed-in scope rejected rows', () async {
      final a = await enq('stock', 'st1');
      final f = await enq('stock', 'st2', scope: other);
      await reject(a);
      await reject(f);
      await load();
      bloc.add(const OnPendingSyncRetryAll());
      final s = await next(
        (s) => s.rows.any(
          (r) =>
              r.entry.mutationId == a.mutationId &&
              r.entry.status == OutboxStatus.pending,
        ),
      );
      expect(
        s.rows
            .firstWhere((r) => r.entry.mutationId == f.mutationId)
            .entry
            .status,
        OutboxStatus.rejected,
      );
    });
  });

  test(
    'fix round 1: Send now runs the existing sync-now and reloads',
    () async {
      await enq('stock', 'st1');
      await load();
      bloc.add(const OnPendingSyncSendNow());
      // Same rows => no new state; wait for the handler instead.
      for (var i = 0; i < 50 && syncNowCalls == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(syncNowCalls, 1);
    },
  );

  test(
    'fix round 1: discarding another scope row one by one is refused',
    () async {
      final f = await enq('stock', 'st9', scope: other);
      await load();
      bloc.add(OnPendingSyncDiscardRow(f.mutationId));
      final s = await bloc.stream.firstWhere((s) => s.failure != null);
      expect(s.failure, PendingSyncFailure.discardOtherScope);
      expect(s.rows.single.entry.mutationId, f.mutationId);
    },
  );
}
