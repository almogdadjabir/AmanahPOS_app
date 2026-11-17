import 'dart:convert';

import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/sync_appliers.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/bootstrap_harness.dart';

void main() {
  late BootHarness h;

  setUp(() async => h = await BootHarness.create());
  tearDown(() async => h.dispose());

  group('(a) happy path', () {
    test('3 entities across pages: completed, cursor == snapshot, '
        'bootstrapped, progress cleared, all rows present', () async {
      h.seedStandard();
      final snapshot = (await h.server.bootstrapManifest(
        scope: 'x',
      )).snapshotCursor;
      final statuses = <BootstrapStatus>[];
      final b = h.build();
      final sub = b.status.listen(statuses.add);

      expect(await b.run(), BootstrapOutcome.completed);
      await sub.cancel();

      expect(await h.scoped.cursor(), snapshot);
      expect(await h.scoped.isBootstrapped(), isTrue);
      expect(await h.progress(), isNull);
      expect(await h.ids('categories'), ['c1', 'c2', 'c3']);
      expect(await h.ids('products'), ['p1', 'p2', 'p3', 'p4', 'p5']);
      expect(await h.ids('customers'), ['k1', 'k2']);
      // 2 + 3 + 1 pages, one manifest.
      expect(h.transport.manifestCalls, 1);
      expect(h.transport.pageRequests, hasLength(6));
      expect(h.transport.requestedEntities, [
        'category',
        'product',
        'customer',
      ]);
      // Lock released.
      expect(
        (await h.db.query('sync_state', where: "key = 'sync_lock'")),
        isEmpty,
      );
      expect(h.notified, containsAll(['categories', 'products', 'customers']));
      expect(statuses.last.outcome, BootstrapOutcome.completed);
      expect(statuses.last.rowsApplied, 10);
      expect(statuses.last.entityCount, 3);
      expect(statuses.map((s) => s.currentEntity).whereType<String>().toSet(), {
        'category',
        'product',
        'customer',
      });
    });

    test('page size: 500 by default, 200 for sale', () async {
      h.server.bootstrapEntities = ['category', 'sale'];
      final b = h.build(pageSize: 500);
      expect(await b.run(), BootstrapOutcome.completed);
      expect(h.transport.pageRequests.map((r) => (r.$1, r.$3)), [
        ('category', 500),
        ('sale', 200),
      ]);
    });

    test('notNeeded when the scope has a cursor and is bootstrapped', () async {
      await h.db.transaction((t) async {
        await h.scoped.setCursor(t, 'c');
        await h.scoped.setBootstrapped(t, true);
      });
      expect(await h.build().run(), BootstrapOutcome.notNeeded);
      expect(h.transport.manifestCalls, 0);
    });

    // Ruling T6-b: needed = no cursor OR not bootstrapped (a cursor left
    // by an older build without the flag must still bootstrap).
    test('a cursor without the bootstrapped flag still bootstraps', () async {
      h.seedStandard();
      await h.db.transaction((t) => h.scoped.setCursor(t, 'old'));
      expect(await h.build().run(), BootstrapOutcome.completed);
      expect(h.transport.manifestCalls, 1);
      expect(await h.scoped.isBootstrapped(), isTrue);
      expect(await h.scoped.cursor(), isNot('old'));
    });

    test('the final transaction records the completion time', () async {
      h.seedStandard();
      expect(await h.build().run(), BootstrapOutcome.completed);
      expect(await h.scoped.bootstrapCompletedAt(), h.clock);
    });

    test('alreadyRunning when another holder owns sync_lock', () async {
      h.seedStandard();
      expect(
        await h.state.acquireLock('other', const Duration(minutes: 2)),
        isTrue,
      );
      expect(await h.build().run(), BootstrapOutcome.alreadyRunning);
      expect(h.transport.manifestCalls, 0);
    });

    test('a second run() while one is in flight is alreadyRunning', () async {
      h.seedStandard();
      final b = h.build();
      final first = b.run();
      expect(await b.run(), BootstrapOutcome.alreadyRunning);
      expect(await first, BootstrapOutcome.completed);
    });

    test('cancel() stops between pages; a rerun resumes', () async {
      h.seedStandard();
      final b = h.build();
      h.transport.afterPage = (n, page) {
        if (n == 2) b.cancel();
        return null;
      };
      expect(await b.run(), BootstrapOutcome.interrupted);
      final p = (await h.progress())!;
      expect(p.done, ['category']);
      expect(h.transport.pageRequests, hasLength(2));
      h.transport.afterPage = null;
      expect(await b.run(), BootstrapOutcome.completed);
      expect(await h.ids('products'), hasLength(5));
      expect(h.transport.manifestCalls, 1);
    });

    test('item without a usable id and a malformed row are skipped; the '
        'page still commits', () async {
      h.server.bootstrapEntities = ['product'];
      h.seedProduct('p1');
      h.seedProduct('p2');
      h.transport.afterPage = (n, page) => BootstrapPage(
        entity: page.entity,
        snapshotCursor: page.snapshotCursor,
        hasMore: page.hasMore,
        nextPageCursor: page.nextPageCursor,
        items: [
          {'name': 'no id', 'version': 1, 'price': '1'},
          {'id': '', 'version': 1, 'name': 'empty', 'price': '1'},
          {'id': 'bad', 'version': 1, 'name': 'Bad', 'price': 'abc'},
          ...page.items,
        ],
      );
      expect(await h.build(pageSize: 10).run(), BootstrapOutcome.completed);
      expect(await h.ids('products'), ['p1', 'p2']);
    });
  });

  group('(b) rows written between pages', () {
    test('pull from the snapshot delivers them; DB == server', () async {
      h.seedStandard();
      h.server.onBootstrapPage = (entity, index) {
        if (entity == 'category' && index == 0) {
          h.seedProduct('p9');
          h.seedCategory('c1', version: 2, name: 'Renamed');
        }
      };
      final b = h.build();
      expect(await b.run(), BootstrapOutcome.completed);
      expect(await h.ids('products'), isNot(contains('p9')));

      final e = h.engine!;
      expect(await e.syncNow(), SyncOutcome.completed);
      expect(
        await h.ids('products'),
        (h.server.tables['product']!.keys.toList()..sort()),
      );
      expect(
        await h.ids('categories'),
        (h.server.tables['category']!.keys.toList()..sort()),
      );
      final c1 = (await h.row('categories', 'c1'))!;
      expect(c1['name'], 'Renamed');
      expect(c1['version'], 2);
    });
  });

  group('(d) atomic page', () {
    test('an applier throwing inside the page txn leaves progress at the '
        'previous page and writes nothing of that page', () async {
      final h2 = await BootHarness.create(
        registry: (hh) {
          final r = ChangeApplierRegistry();
          for (final a in buildSyncAppliers(
            scopeProvider: () => hh.activeScope,
          ).all) {
            r.register(a.entity == 'product' ? ThrowingApplier(a) : a);
          }
          return r;
        },
      );
      addTearDown(h2.dispose);
      h2.seedStandard();
      final thrower = h2.registry.of('product')! as ThrowingApplier;
      thrower.throwOn.add('p4'); // product page 2 = p3, p4

      final b = h2.build();
      expect(await b.run(), BootstrapOutcome.interrupted);
      final p = (await h2.progress())!;
      expect(p.done, ['category']);
      expect(p.pageCursor, base64Url.encode(utf8.encode('p2')));
      expect(await h2.ids('products'), ['p1', 'p2']);
      expect(await h2.scoped.cursor(), isNull);
      expect(await h2.scoped.isBootstrapped(), isFalse);

      thrower.throwOn.clear();
      expect(await b.run(), BootstrapOutcome.completed);
      expect(await h2.ids('products'), ['p1', 'p2', 'p3', 'p4', 'p5']);
      expect(h2.transport.manifestCalls, 1);
    });

    test('hasMore without a next cursor is a protocol error: nothing of the '
        'page commits', () async {
      h.seedStandard();
      h.transport.afterPage = (n, page) => n == 1
          ? BootstrapPage(
              entity: page.entity,
              snapshotCursor: page.snapshotCursor,
              items: page.items,
              hasMore: true,
            )
          : null;
      expect(await h.build().run(), BootstrapOutcome.interrupted);
      expect(await h.ids('categories'), isEmpty);
      expect((await h.progress())!.done, isEmpty);
    });
  });

  group('(e) scope switch mid-run', () {
    Future<void> otherScopeProgress() => h.db.transaction(
      (t) => h.state
          .forScope('u2|t2')
          .setBootstrapProgress(
            t,
            BootstrapProgress(
              snapshotCursor: 'other-snap',
              entities: const ['product'],
              done: const [],
              pageCursor: 'other-page',
              startedAt: DateTime.utc(2026),
            ),
          ),
    );

    test('switch before page 2 is sent: interrupted, nothing of page 2, '
        'other scope untouched', () async {
      h.seedStandard();
      await otherScopeProgress();
      final b = h.build();
      h.transport.beforePage = (n, _) {
        if (n == 2) h.activeScope = 'u2|t2';
      };
      expect(await b.run(), BootstrapOutcome.interrupted);
      expect(await h.ids('categories'), ['c1', 'c2']);
      final mine = (await h.progress())!;
      expect(mine.done, isEmpty);
      expect(mine.pageCursor, base64Url.encode(utf8.encode('c2')));
      final other = (await h.progress('u2|t2'))!;
      expect(other.snapshotCursor, 'other-snap');
      expect(other.pageCursor, 'other-page');
      expect(await h.state.forScope('u2|t2').cursor(), isNull);
      expect(await h.state.forScope('u2|t2').isBootstrapped(), isFalse);
    });

    test('switch while page 2 is in flight: the page txn rolls back', () async {
      h.seedStandard();
      await otherScopeProgress();
      final b = h.build();
      h.transport.afterPage = (n, page) {
        if (n == 2) {
          h.activeScope = 'u2|t2';
          h.liveScope = 'u2|t2';
        }
        return null;
      };
      expect(await b.run(), BootstrapOutcome.interrupted);
      expect(await h.ids('categories'), ['c1', 'c2']);
      expect(
        (await h.progress())!.pageCursor,
        base64Url.encode(utf8.encode('c2')),
      );
      expect((await h.progress('u2|t2'))!.pageCursor, 'other-page');
    });
  });

  group('(f) local pending edit', () {
    test('row with a pending outbox row is deferred, not overwritten; the '
        'final txn keeps the deferral; pull applies it later', () async {
      await h.localProduct('p2', version: 1, name: 'Local');
      await h.pendingOutbox('product', 'p2');
      h.seedStandard();
      h.server.tables['product']!['p2']!['version'] = 2;
      h.server.tables['product']!['p2']!['name'] = 'Server';

      expect(await h.build().run(), BootstrapOutcome.completed);
      expect((await h.row('products', 'p2'))!['name'], 'Local');
      final deferred =
          jsonDecode((await h.deferredJson())!) as Map<String, dynamic>;
      expect(deferred.keys, ['product|p2']);
      final change = PullChange.fromJson(
        Map<String, dynamic>.from(deferred['product|p2'] as Map),
      );
      expect(change.version, 2);
      expect(change.data!['name'], 'Server');
      expect(await h.scoped.isBootstrapped(), isTrue);

      // The local edit resolves; the next pull's last page applies it.
      await h.db.update('outbox', {'status': 'done'});
      expect(await h.engine!.syncNow(), SyncOutcome.completed);
      expect((await h.row('products', 'p2'))!['name'], 'Server');
      expect(await h.deferredJson(), isNull);
    });
  });

  group('(g) versions', () {
    test('an older version never overwrites a newer local row', () async {
      await h.localProduct('p1', version: 5, name: 'Newer');
      h.seedStandard();
      expect(await h.build().run(), BootstrapOutcome.completed);
      final p1 = (await h.row('products', 'p1'))!;
      expect(p1['name'], 'Newer');
      expect(p1['version'], 5);
    });
  });

  group('(h) entity list', () {
    test('unknown entity skipped, absent entities not requested, client '
        'order wins', () async {
      h.server.bootstrapEntities = [
        'notification',
        'mystery',
        'customer',
        'stock',
        'product',
        'category',
      ];
      h.seedStandard();
      expect(await h.build().run(), BootstrapOutcome.completed);
      expect(h.transport.requestedEntities, [
        'category',
        'product',
        'customer',
        'stock',
        'notification',
      ]);
      final asked = h.transport.pageRequests.map((r) => r.$1).toSet();
      expect(asked, isNot(contains('mystery')));
      expect(asked, isNot(contains('vendor')));
      expect(asked, isNot(contains('inbound')));
    });
  });

  group('(i) capability gate', () {
    test('missing bootstrap_paged -> blocked, nothing requested', () async {
      h.server.capabilities = {'push', 'pull'};
      final b = h.build();
      final statuses = <BootstrapStatus>[];
      final sub = b.status.listen(statuses.add);
      expect(await b.run(), BootstrapOutcome.blocked);
      await sub.cancel();
      expect(h.transport.manifestCalls, 0);
      expect(h.transport.pageRequests, isEmpty);
      expect(statuses.last.outcome, BootstrapOutcome.blocked);
      expect(statuses.last.serverNotReady, isTrue);
      expect(await h.progress(), isNull);
    });

    test('no signed-in scope -> blocked(noSession)', () async {
      h.activeScope = null;
      final b = h.build();
      expect(await b.run(), BootstrapOutcome.blocked);
      expect(h.transport.manifestCalls, 0);
    });
  });

  group('(j) auth and network', () {
    Future<void> engineRanOnce() async {
      // The engine run that answers needsBootstrap (sets its scope).
      expect(await h.buildEngine().syncNow(), SyncOutcome.needsBootstrap);
    }

    test('token_expired once -> one refresh, then continues', () async {
      h.seedStandard();
      await engineRanOnce();
      h.server.failNextWith = 'tokenExpired';
      expect(await h.build().run(), BootstrapOutcome.completed);
      expect(h.refreshCalls, 1);
      expect(await h.ids('products'), hasLength(5));
    });

    test(
      'token_expired mid-run (page 3) -> refresh, resumes same page',
      () async {
        h.seedStandard();
        await engineRanOnce();
        h.transport.beforePage = (n, _) {
          if (n == 3) {
            h.transport.beforePage = null;
            throw SyncTransportException(kind: SyncTransportKind.tokenExpired);
          }
        };
        expect(await h.build().run(), BootstrapOutcome.completed);
        expect(h.refreshCalls, 1);
        expect(await h.ids('products'), hasLength(5));
      },
    );

    test('refresh rejected -> blocked(tokenExpired), never logs out', () async {
      h.seedStandard();
      await engineRanOnce();
      h.refreshOutcome = RefreshOutcome.rejected;
      h.server.failNextWith = 'tokenExpired';
      final b = h.build();
      final statuses = <BootstrapStatus>[];
      final sub = b.status.listen(statuses.add);
      expect(await b.run(), BootstrapOutcome.blocked);
      await sub.cancel();
      expect(statuses.last.block, SyncBlockReason.tokenExpired);
    });

    test('account_disabled -> blocked(accountDisabled)', () async {
      h.seedStandard();
      h.server.failNextWith = 'accountDisabled';
      final b = h.build();
      final statuses = <BootstrapStatus>[];
      final sub = b.status.listen(statuses.add);
      expect(await b.run(), BootstrapOutcome.blocked);
      await sub.cancel();
      expect(statuses.last.block, SyncBlockReason.accountDisabled);
    });

    test(
      'device_revoked mid-run -> blocked(deviceRevoked), progress kept',
      () async {
        h.seedStandard();
        h.transport.beforePage = (n, _) {
          if (n == 2) {
            throw SyncTransportException(kind: SyncTransportKind.deviceRevoked);
          }
        };
        final b = h.build();
        final statuses = <BootstrapStatus>[];
        final sub = b.status.listen(statuses.add);
        expect(await b.run(), BootstrapOutcome.blocked);
        await sub.cancel();
        expect(statuses.last.block, SyncBlockReason.deviceRevoked);
        expect((await h.progress())!.pageCursor, isNotNull);
      },
    );

    test('offline / timeout -> interrupted(offline), progress kept', () async {
      h.seedStandard();
      final b = h.build();
      final statuses = <BootstrapStatus>[];
      final sub = b.status.listen(statuses.add);
      h.transport.beforePage = (n, _) {
        if (n == 3) h.server.down = true;
      };
      expect(await b.run(), BootstrapOutcome.interrupted);
      expect(statuses.last.offline, isTrue);
      expect((await h.progress())!.done, ['category']);

      h.transport.beforePage = (n, _) {
        if (n == 4) {
          throw SyncTransportException(kind: SyncTransportKind.timeout);
        }
      };
      h.server.down = false;
      expect(await b.run(), BootstrapOutcome.interrupted);
      expect(statuses.last.offline, isTrue);

      h.transport.beforePage = null;
      expect(await b.run(), BootstrapOutcome.completed);
      await sub.cancel();
      expect(statuses.last.offline, isFalse);
      expect(await h.ids('products'), hasLength(5));
      expect(h.transport.manifestCalls, 1);
    });

    test('5xx -> interrupted (not offline)', () async {
      h.seedStandard();
      h.server.failNextWith = 'server';
      final b = h.build();
      final statuses = <BootstrapStatus>[];
      final sub = b.status.listen(statuses.add);
      expect(await b.run(), BootstrapOutcome.interrupted);
      await sub.cancel();
      expect(statuses.last.offline, isFalse);
    });
  });

  group('fix round 1: scope-bound refresh budget (I-1)', () {
    test('FRESH engine that never ran + one token_expired -> exactly one '
        'refresh, then completed', () async {
      h.seedStandard();
      h.server.failNextWith = 'tokenExpired';
      expect(await h.build().run(), BootstrapOutcome.completed);
      expect(h.refreshCalls, 1);
      expect(await h.ids('products'), hasLength(5));
    });

    test('a second 401 later in the same run (after a successful call) gets '
        'another refresh', () async {
      h.seedStandard();
      h.transport.beforePage = (n, _) {
        if (n == 2 || n == 5) {
          throw SyncTransportException(kind: SyncTransportKind.tokenExpired);
        }
      };
      expect(await h.build().run(), BootstrapOutcome.completed);
      expect(h.refreshCalls, 2);
      expect(await h.ids('products'), hasLength(5));
    });

    test('two 401s in a row (no success between) -> one refresh, then '
        'interrupted (never blocked, never logout)', () async {
      h.seedStandard();
      h.transport.beforePage = (n, _) {
        if (n == 2 || n == 3) {
          throw SyncTransportException(kind: SyncTransportKind.tokenExpired);
        }
      };
      final b = h.build();
      expect(await b.run(), BootstrapOutcome.interrupted);
      expect(h.refreshCalls, 1);
      // A new run gets a fresh budget.
      h.transport.beforePage = (n, _) {
        if (n == 4) {
          throw SyncTransportException(kind: SyncTransportKind.tokenExpired);
        }
      };
      expect(await b.run(), BootstrapOutcome.completed);
      expect(h.refreshCalls, 2);
    });

    test('refresh landing on another live session -> quiet interrupted, '
        'nothing retried', () async {
      h.seedStandard();
      h.onRefresh = () => h.liveScope = 'u2|t2';
      h.server.failNextWith = 'tokenExpired';
      final b = h.build();
      expect(await b.run(), BootstrapOutcome.interrupted);
      expect(b.current.block, isNull);
      expect(h.refreshCalls, 1);
      expect(h.transport.manifestCalls, 0);
    });

    test('account_disabled on a fresh engine still blocked', () async {
      h.seedStandard();
      h.server.failNextWith = 'accountDisabled';
      final b = h.build();
      expect(await b.run(), BootstrapOutcome.blocked);
      expect(b.current.block, SyncBlockReason.accountDisabled);
      expect(h.refreshCalls, 0);
    });
  });

  group('fix round 1: M-1 / M-2', () {
    test('resume: a stored entity with no applier is dropped (pages never '
        'requested), its page cursor discarded', () async {
      h.seedStandard();
      h.transport.beforePage = (n, _) {
        if (n == 4) {
          throw SyncTransportException(kind: SyncTransportKind.network);
        }
      };
      expect(await h.build().run(), BootstrapOutcome.interrupted);
      final before = (await h.progress())!;
      expect(before.done, ['category']);
      expect(before.pageCursor, isNotNull); // inside product

      final r = ChangeApplierRegistry();
      for (final a in h.registry.all) {
        if (a.entity != 'product') r.register(a);
      }
      h.registry = r;
      h.transport.beforePage = null;
      final from = h.transport.pageRequests.length;
      expect(await h.build().run(), BootstrapOutcome.completed);
      final rerun = h.transport.pageRequests.sublist(from);
      expect(rerun.map((e) => e.$1), ['customer']);
      expect(rerun.single.$2, isNull);
      expect(await h.ids('customers'), ['k1', 'k2']);
      expect(await h.progress(), isNull);
      expect(await h.scoped.isBootstrapped(), isTrue);
    });

    test('a cycling page cursor hits the per-entity page cap -> interrupted, '
        'not bootstrapped', () async {
      h.seedStandard();
      final a = base64Url.encode(utf8.encode('c1'));
      final bb = base64Url.encode(utf8.encode('c2'));
      h.transport.afterPage = (n, page) => BootstrapPage(
        entity: page.entity,
        snapshotCursor: page.snapshotCursor,
        items: page.items,
        hasMore: true,
        nextPageCursor: n.isOdd ? a : bb,
      );
      final b = h.build(maxPagesPerEntity: 5);
      expect(await b.run(), BootstrapOutcome.interrupted);
      expect(h.transport.pageRequests, hasLength(5));
      expect(await h.scoped.isBootstrapped(), isFalse);
      expect(await h.scoped.cursor(), isNull);
      expect((await h.progress())!.done, isEmpty);
      expect(Bootstrapper.defaultMaxPagesPerEntity, 20000);
    });
  });

  group('lock lease', () {
    Future<String?> lockValue() async {
      final r = await h.db.query('sync_state', where: "key = 'sync_lock'");
      return r.isEmpty ? null : r.single['value'] as String;
    }

    test('lease is renewed between pages', () async {
      h.seedStandard();
      final b = h.build();
      final values = <String?>[];
      h.transport.beforePage = (n, _) async {
        values.add(await lockValue());
        h.advance(const Duration(seconds: 50));
      };
      // 6 pages x 50 s = 5 min > the 2 min ttl.
      expect(await b.run(), BootstrapOutcome.completed);
      expect(values, hasLength(6));
      expect(values.toSet(), hasLength(6)); // a fresh expiry every page
      expect(await lockValue(), isNull);
    });

    test('a lease taken over by another holder: the in-flight page is not '
        'committed, the other lock is kept', () async {
      h.seedStandard();
      final b = h.build();
      h.transport.beforePage = (n, _) async {
        if (n == 3) {
          h.advance(const Duration(minutes: 5));
          expect(
            await h.state.acquireLock('other', const Duration(minutes: 2)),
            isTrue,
          );
        }
      };
      expect(await b.run(), BootstrapOutcome.alreadyRunning);
      expect(await h.ids('products'), isEmpty); // page 3 = p1, p2
      expect((await h.progress())!.done, ['category']);
      expect(await h.scoped.isBootstrapped(), isFalse);
      expect((await lockValue())!.startsWith('other|'), isTrue);
    });
  });

  group('(F3) ghost sweep after a full snapshot', () {
    test('a synced local product absent from the snapshot is removed; '
        'served, pending-edit and never-synced rows stay', () async {
      h.seedStandard();
      await h.localProduct('ghost', version: 3);
      await h.localProduct('p1', version: 1);
      await h.localProduct('edited', version: 2);
      await h.pendingOutbox('product', 'edited');
      await h.db.insert('products', {
        'id': 'local-new',
        'name': 'New',
        'json': '{}',
      });
      expect(await h.build().run(), BootstrapOutcome.completed);
      final ids = await h.ids('products');
      expect(ids, isNot(contains('ghost')));
      expect(ids, containsAll(['p1', 'p2', 'edited', 'local-new']));
    });

    test(
      'a resumed bootstrap never sweeps (it did not see every page)',
      () async {
        h.seedStandard();
        await h.localProduct('ghost', version: 3);
        final b = h.build();
        h.transport.beforePage = (call, entity) {
          if (call == 3) b.cancel();
        };
        expect(await b.run(), BootstrapOutcome.interrupted);
        h.transport.beforePage = null;
        expect(await h.build().run(), BootstrapOutcome.completed);
        expect(await h.ids('products'), contains('ghost'));
      },
    );
  });
}
