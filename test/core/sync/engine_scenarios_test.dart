import 'dart:convert';

import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/engine_harness.dart';

/// Fault-injection scenarios for crash safety. Real LocalWriter + OfflineDb
/// (in-memory) + FakeSyncServer; "restart" = new SyncEngine / SyncStateStore /
/// OutboxStore on the same database. Each scenario asserts server rows,
/// outbox state and local rows.
void main() {
  late EngineHarness h;

  setUp(() async {
    h = await EngineHarness.create();
  });

  tearDown(() async {
    await h.dispose();
  });

  String cursorFor(int seq) => base64Url.encode(utf8.encode('seq:$seq'));

  group('1. lost response', () {
    test('dropResponseAfterApply: server applied once, retry replays as '
        'duplicate, outbox done', () async {
      final ids = <String>[];
      for (var i = 0; i < 5; i++) {
        ids.add((await h.createWidget('w$i')).mutationId);
      }
      h.server.dropResponseAfterApply = 1;
      final engine = h.build();

      expect(await engine.syncNow(), SyncOutcome.backoff);
      // The server applied the batch; the app never saw the answer.
      expect(h.serverProductCount, 5);
      expect(h.server.feed, hasLength(5));
      expect(await h.countStatus('pending'), 5);
      expect(await h.countStatus('done'), 0);
      expect(await h.countStatus('inflight'), 0);

      // Row backoff elapsed; retry.
      h.advance(const Duration(hours: 1));
      expect(await engine.syncNow(), SyncOutcome.completed);

      expect(h.serverProductCount, 5, reason: 'exactly one row each');
      expect(h.server.feed, hasLength(5), reason: 'no second apply');
      expect(h.server.applied.keys.toSet(), ids.toSet());
      expect(await h.countStatus('done'), 5);
      expect(await h.countStatus('pending'), 0);
      expect(h.applier.pushResults.map((r) => r.status).toSet(), {
        PushStatus.duplicate,
      });
      final w = await h.widgets();
      expect(w, hasLength(5));
      expect(w.every((r) => r['version'] == 1), isTrue);
    });

    test(
      'lostResponseRate 1.0 then healthy: still exactly one row each',
      () async {
        for (var i = 0; i < 4; i++) {
          await h.createWidget('w$i');
        }
        h.server.lostResponseRate = 1.0;
        final engine = h.build();
        for (var i = 0; i < 3; i++) {
          expect(await engine.syncNow(), SyncOutcome.backoff);
          h.advance(const Duration(hours: 1));
        }
        expect(h.serverProductCount, 4);
        expect(h.server.feed, hasLength(4));
        expect(await h.countStatus('done'), 0);

        h.server.lostResponseRate = 0;
        expect(await engine.syncNow(), SyncOutcome.completed);
        expect(h.serverProductCount, 4);
        expect(h.server.feed, hasLength(4));
        expect(await h.countStatus('done'), 4);
        expect((await h.widgets()), hasLength(4));
      },
    );
  });

  group('2. crash after server applied, before results written', () {
    test(
      'restart after lease expiry -> duplicates -> done, server unchanged',
      () async {
        final ids = <String>[];
        for (var i = 0; i < 5; i++) {
          ids.add((await h.createWidget('w$i')).mutationId);
        }
        final engine = h.build(
          hooks: SyncHooks(
            beforeResultWrite: (batch, response) async =>
                throw CrashSimulation('beforeResultWrite'),
          ),
        );

        await expectLater(engine.syncNow(), throwsA(isA<CrashSimulation>()));

        // Process died: server has it, device has no result, rows still leased.
        expect(h.serverProductCount, 5);
        expect(h.server.feed, hasLength(5));
        expect(await h.countStatus('inflight'), 5);
        expect(await h.countStatus('done'), 0);
        expect(h.applier.pushResults, isEmpty);

        // Restart once the lease and the sync lock have expired.
        h.advance(const Duration(minutes: 10));
        final engine2 = h.restart();
        expect(await h.outbox.releaseExpiredLeases(), 5);
        expect(await h.countStatus('pending'), 5);
        expect(await h.countStatus('inflight'), 0);

        expect(await engine2.syncNow(), SyncOutcome.completed);

        expect(h.serverProductCount, 5, reason: 'replay is a no-op');
        expect(h.server.feed, hasLength(5));
        expect(h.server.applied.keys.toSet(), ids.toSet());
        expect(await h.countStatus('done'), 5);
        expect(await h.countStatus('pending'), 0);
        expect(h.applier.pushResults.map((r) => r.status).toSet(), {
          PushStatus.duplicate,
        });
        final w = await h.widgets();
        expect(w, hasLength(5));
        expect(w.every((r) => r['version'] == 1), isTrue);
      },
    );

    test(
      'restart WITHOUT explicit release: the engine recovers the lease',
      () async {
        await h.createWidget('a');
        final engine = h.build(
          hooks: SyncHooks(
            beforeResultWrite: (b, r) async => throw CrashSimulation('x'),
          ),
        );
        await expectLater(engine.syncNow(), throwsA(isA<CrashSimulation>()));
        h.advance(const Duration(minutes: 10));
        expect(await h.restart().syncNow(), SyncOutcome.completed);
        expect(h.server.feed, hasLength(1));
        expect(await h.countStatus('done'), 1);
      },
    );
  });

  group('3. crash mid-pull page', () {
    test('cursor not advanced, no half page, re-apply is idempotent', () async {
      for (var i = 0; i < 5; i++) {
        await h.otherDevice('x$i');
      }
      expect(h.server.feed, hasLength(5));

      // Phase A: crash inside page 1's transaction (after apply, before cursor).
      var calls = 0;
      final e1 = h.build(
        pullPageSize: 2,
        hooks: SyncHooks(
          beforePullPageCommit: (page) async {
            calls++;
            throw CrashSimulation('page1');
          },
        ),
      );
      await expectLater(e1.syncNow(), throwsA(isA<CrashSimulation>()));
      expect(calls, 1);
      expect(await h.state.cursor(), EngineHarness.seedCursor);
      expect(await h.widgets(), isEmpty, reason: 'no half-applied page');

      // Phase B: page 1 commits, crash inside page 2.
      h.advance(const Duration(minutes: 10));
      calls = 0;
      final e2 = h.restart(
        pullPageSize: 2,
        hooks: SyncHooks(
          beforePullPageCommit: (page) async {
            calls++;
            if (calls == 2) throw CrashSimulation('page2');
          },
        ),
      );
      await expectLater(e2.syncNow(), throwsA(isA<CrashSimulation>()));
      expect(calls, 2);
      expect(
        (await h.widgets()).map((r) => r['id']).toList(),
        ['x0', 'x1'],
        reason: 'only the committed page is visible',
      );
      expect(await h.state.cursor(), cursorFor(2));

      // Phase C: clean restart resumes from the committed cursor.
      h.advance(const Duration(minutes: 10));
      final e3 = h.restart(pullPageSize: 2);
      expect(await e3.syncNow(), SyncOutcome.completed);
      final after = await h.widgets();
      expect(after.map((r) => r['id']).toList(), [
        'x0',
        'x1',
        'x2',
        'x3',
        'x4',
      ]);
      expect(await h.state.cursor(), cursorFor(5));

      // Phase D: re-applying the whole feed (cursor rewound) is idempotent.
      await h.db.transaction(
        (t) => h.state.setCursor(t, EngineHarness.seedCursor),
      );
      expect(await e3.syncNow(), SyncOutcome.completed);
      expect(await h.widgets(), after);
      expect(await h.state.cursor(), cursorFor(5));
      expect(h.server.feed, hasLength(5));
      expect(await h.outboxTotal(), 0);
    });
  });

  group('4. flaky link', () {
    test('flakyRate 0.5, 50 mutations: all applied, zero duplicates', () async {
      final ids = <String>[];
      for (var i = 0; i < 50; i++) {
        ids.add(
          (await h.createWidget('w${i.toString().padLeft(2, '0')}')).mutationId,
        );
      }
      final flaky = h.server.forDevice('device-1', seed: 1234)
        ..flakyRate = 0.5
        ..lostResponseRate = 0.2;
      h.transport = ScenarioTransport(flaky);
      final engine = h.build();

      var loops = 0;
      while (loops < 40) {
        loops++;
        await engine.syncNow();
        if (await h.countStatus('done') == 50) break;
        h.advance(const Duration(hours: 1));
      }

      expect(await h.countStatus('done'), 50, reason: 'after $loops loops');
      expect(await h.countStatus('pending'), 0);
      expect(await h.countStatus('inflight'), 0);
      expect(h.serverProductCount, 50);
      expect(h.server.feed, hasLength(50), reason: 'zero duplicate applies');
      expect(h.server.feed.map((c) => c.id).toSet(), hasLength(50));
      expect(h.server.applied.keys.toSet(), ids.toSet());
      expect(h.transport.pushCalls, greaterThanOrEqualTo(1));
    });
  });

  group('5. dependency chain', () {
    test(
      'rejected product create -> dependent sale.create dependency_failed',
      () async {
        final product = await h.createWidget('p1');
        final sale = await h.createWidget(
          's1',
          entity: 'sale',
          dependsOn: 'p1',
          payload: {
            'shop': 'sh1',
            'items': [
              {'product_id': 'p1', 'quantity': '1'},
            ],
          },
        );
        final ok = await h.createWidget('p2');
        expect(sale.status, OutboxStatus.blocked);

        h.transport.scripted[product.mutationId] = PushResult(
          mutationId: product.mutationId,
          status: PushStatus.rejected,
          entityId: 'p1',
          code: 'limit_exceeded',
          message: 'Product limit reached',
        );
        final engine = h.build();
        expect(await engine.syncNow(), SyncOutcome.completed);

        final p = await h.outboxRow(product.mutationId);
        expect(p['status'], 'rejected');
        expect(p['error_code'], 'limit_exceeded');
        final s = await h.outboxRow(sale.mutationId);
        expect(s['status'], 'rejected');
        expect(s['error_code'], 'dependency_failed');
        expect(
          await h.outbox.rejected().then(
            (l) => l.map((e) => e.mutationId).toSet(),
          ),
          {product.mutationId, sale.mutationId},
        );
        expect((await h.outboxRow(ok.mutationId))['status'], 'done');

        // The server never saw the sale nor the rejected product.
        expect(h.transport.pushedIds, isNot(contains(sale.mutationId)));
        expect(h.server.tables['sale'] ?? {}, isEmpty);
        expect(h.server.tables['product']!.keys.toSet(), {'p2'});
        expect(h.server.feed, hasLength(1));
        expect(engine.current.rejected, 2);

        // A rejected row stays rejected on later runs.
        h.advance(const Duration(hours: 1));
        expect(await engine.syncNow(), SyncOutcome.completed);
        expect(await h.countStatus('rejected'), 2);
        expect(
          h.transport.pushedIds.where((id) => id == product.mutationId),
          hasLength(1),
          reason: 'a rejected mutation is never re-sent',
        );
      },
    );
  });

  group('6. server down 2 hours then up', () {
    test(
      '500 queued mutations drain in batches of 100, in seq order',
      () async {
        final order = <String>[];
        for (var i = 0; i < 500; i++) {
          final id = 'w${i.toString().padLeft(3, '0')}';
          order.add(id);
          await h.createWidget(id);
        }
        h.server.down = true;
        final engine = h.build();

        // 2 hours of fake time, a sync attempt every 10 minutes.
        for (var i = 0; i < 12; i++) {
          expect(await engine.syncNow(), SyncOutcome.backoff);
          h.advance(const Duration(minutes: 10));
        }
        expect(h.clock, DateTime.utc(2026, 1, 1, 14));
        expect(await h.countStatus('pending'), 500);
        expect(h.serverProductCount, 0);
        expect(h.transport.pushCalls, 0, reason: 'ping gate stops the push');
        expect(engine.current.serverReachable, isFalse);

        h.server.down = false;
        expect(await engine.syncNow(), SyncOutcome.completed);

        expect(h.transport.batchSizes, [100, 100, 100, 100, 100]);
        final seqs = h.transport.pushed.map((e) => e.seq!).toList();
        expect([...seqs]..sort(), seqs, reason: 'sent in seq order');
        expect(h.transport.pushed.map((e) => e.entityId).toList(), order);
        expect(h.server.feed.map((c) => c.id).toList(), order);
        expect(h.serverProductCount, 500);
        expect(await h.countStatus('done'), 500);
        expect(await h.countStatus('pending'), 0);
        expect(await h.widgets(), hasLength(500));
      },
    );
  });

  group('7. device clock +5h skew', () {
    test('occurred_at untouched, skew recorded, ordered by seq', () async {
      // Device is 5 hours ahead of the server.
      h.server.clockSkew = const Duration(hours: -5);
      final occurred = <String, DateTime>{};
      final ids = <String>[];
      // Wall-clock stamps run BACKWARDS relative to seq (clock was fixed).
      for (var i = 0; i < 6; i++) {
        final at = h.clock.add(Duration(hours: 5, minutes: -i * 30));
        final m = await h.createWidget('w$i', occurredAt: at);
        occurred[m.mutationId] = at;
        ids.add(m.mutationId);
      }
      final engine = h.build();
      expect(await engine.syncNow(), SyncOutcome.completed);

      expect(await h.state.clockSkew(), const Duration(hours: -5));
      for (final id in ids) {
        final r = await h.outboxRow(id);
        expect(DateTime.parse(r['occurred_at'] as String), occurred[id]);
        expect(r['status'], 'done');
      }
      // What was sent carries the untouched stamp, ordered by seq not time.
      expect(h.transport.pushed.map((e) => e.mutationId).toList(), ids);
      for (final e in h.transport.pushed) {
        expect(e.occurredAt, occurred[e.mutationId]);
      }
      final seqs = h.transport.pushed.map((e) => e.seq!).toList();
      expect([...seqs]..sort(), seqs);
      expect(h.server.feed.map((c) => c.id).toList(), [
        'w0',
        'w1',
        'w2',
        'w3',
        'w4',
        'w5',
      ]);
      expect(h.serverProductCount, 6);
    });
  });

  group('8. version conflict results reach the UI', () {
    test('rejected conflict_version: code/message in outbox, server_state '
        'handed to the applier and stored locally', () async {
      final create = await h.createWidget('w1', name: 'Mine');
      final engine = h.build();
      expect(await engine.syncNow(), SyncOutcome.completed);
      expect((await h.outboxRow(create.mutationId))['status'], 'done');

      final upd = await h.createWidget(
        'w1',
        op: 'update',
        name: 'Mine v2',
        baseVersion: 1,
      );
      final later = await h.createWidget(
        'w1',
        op: 'update',
        name: 'Mine v3',
        baseVersion: 1,
      );
      final serverState = {'id': 'w1', 'name': 'Server name', 'version': 3};
      h.transport.scripted[upd.mutationId] = PushResult(
        mutationId: upd.mutationId,
        status: PushStatus.rejected,
        entityId: 'w1',
        code: 'conflict_version',
        message: 'Row changed on the server',
        serverState: serverState,
      );
      expect(await engine.syncNow(), SyncOutcome.completed);

      final r = await h.outboxRow(upd.mutationId);
      expect(r['status'], 'rejected');
      expect(r['error_code'], 'conflict_version');
      expect(r['error_message'], 'Row changed on the server');
      final rejected = await h.outbox.rejected();
      expect(rejected.map((e) => e.mutationId), [upd.mutationId]);

      // serverState reaches the applier, which stores it for the UI.
      final seen = h.applier.pushResults.firstWhere(
        (p) => p.mutationId == upd.mutationId,
      );
      expect(seen.serverState, serverState);
      final conflict =
          jsonDecode((await h.widget('w1'))['conflict'] as String) as Map;
      expect(conflict['code'], 'conflict_version');
      expect(conflict['server_state'], serverState);

      // Per-entity ordering: the later edit of the same row is held back.
      expect((await h.outboxRow(later.mutationId))['status'], 'pending');
      expect(h.transport.pushedIds, isNot(contains(later.mutationId)));
      expect(h.server.tables['product']!['w1']!['name'], 'Mine');
    });

    test(
      'merged (stale base_version) applies and hands serverState over',
      () async {
        await h.createWidget('w1', name: 'Mine');
        final engine = h.build();
        expect(await engine.syncNow(), SyncOutcome.completed);

        final upd = await h.createWidget(
          'w1',
          op: 'update',
          name: 'Mine v2',
          baseVersion: 99,
        );
        expect(await engine.syncNow(), SyncOutcome.completed);

        expect((await h.outboxRow(upd.mutationId))['status'], 'done');
        final seen = h.applier.pushResults.firstWhere(
          (p) => p.mutationId == upd.mutationId,
        );
        expect(seen.merged, isTrue);
        expect(seen.serverState!['name'], 'Mine v2');
        final w = await h.widget('w1');
        expect(w['version'], 2);
        expect(w['name'], 'Mine v2');
        expect(h.server.tables['product']!['w1']!['version'], 2);
        expect(h.server.feed, hasLength(2));
      },
    );
  });
}
