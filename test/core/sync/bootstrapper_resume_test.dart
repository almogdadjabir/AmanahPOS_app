import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/sync_appliers.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/bootstrap_harness.dart';

/// (c) Kill at every page boundary and mid-page, then rerun on the same DB
/// with a NEW bootstrapper (process restart): the final DB is identical to
/// an uninterrupted run, the snapshot is taken once, no duplicates.
void main() {
  const pages = 6; // 2 category + 3 product + 1 customer pages

  late String reference;
  late int referenceAssertCalls;

  setUpAll(() async {
    final h = await BootHarness.create();
    h.seedStandard();
    expect(await h.build().run(), BootstrapOutcome.completed);
    expect(h.transport.pageRequests, hasLength(pages));
    reference = await h.dump();
    referenceAssertCalls = h.assertCalls;
    await h.dispose();
  });

  /// Reruns (new bootstrapper each time, lease expired) until completed.
  Future<void> finish(BootHarness h) async {
    for (var i = 0; i < 5; i++) {
      h.advance(const Duration(minutes: 3)); // dead runner's lease expires
      final outcome = await h.build().run();
      if (outcome == BootstrapOutcome.completed) return;
      expect(outcome, BootstrapOutcome.interrupted);
    }
    fail('bootstrap never completed');
  }

  Future<void> expectConverged(
    BootHarness h, {
    required bool oneSnapshot,
  }) async {
    expect(await h.dump(), reference);
    if (oneSnapshot) expect(h.transport.manifestCalls, 1);
    expect(await h.progress(), isNull);
    expect(await h.scoped.isBootstrapped(), isTrue);
  }

  for (var k = 1; k <= pages; k++) {
    test('kill before page $k is sent (after boundary ${k - 1})', () async {
      final h = await BootHarness.create();
      addTearDown(h.dispose);
      h.seedStandard();
      h.transport.beforePage = (n, _) {
        if (n == k) throw CrashSimulation('before page $k');
      };
      await expectLater(h.build().run(), throwsA(isA<CrashSimulation>()));
      h.transport.beforePage = null;
      await finish(h);
      await expectConverged(h, oneSnapshot: true);
    });

    test(
      'response of page $k lost (kill mid-page, nothing committed)',
      () async {
        final h = await BootHarness.create();
        addTearDown(h.dispose);
        h.seedStandard();
        h.transport.afterPage = (n, _) {
          if (n == k) throw CrashSimulation('after page $k');
          return null;
        };
        await expectLater(h.build().run(), throwsA(isA<CrashSimulation>()));
        h.transport.afterPage = null;
        await finish(h);
        await expectConverged(h, oneSnapshot: true);
      },
    );

    test('offline at page $k, then resumed', () async {
      final h = await BootHarness.create();
      addTearDown(h.dispose);
      h.seedStandard();
      h.transport.beforePage = (n, _) {
        if (n == k) {
          throw SyncTransportException(kind: SyncTransportKind.network);
        }
      };
      expect(await h.build().run(), BootstrapOutcome.interrupted);
      h.transport.beforePage = null;
      await finish(h);
      await expectConverged(h, oneSnapshot: true);
    });
  }

  test('kill at EVERY scope check (before requests, inside each page txn, '
      'inside the final txn)', () async {
    expect(referenceAssertCalls, greaterThan(pages * 2));
    for (var kill = 1; kill <= referenceAssertCalls; kill++) {
      final h = await BootHarness.create();
      h.seedStandard();
      h.assertKillAt = kill;
      await expectLater(
        h.build().run(),
        throwsA(isA<CrashSimulation>()),
        reason: 'kill $kill',
      );
      final hadProgress = await h.progress() != null;
      final manifestsAtKill = h.transport.manifestCalls;
      h.assertKillAt = null;
      await finish(h);
      expect(await h.dump(), reference, reason: 'kill $kill');
      // Once progress is stored, no second snapshot is ever taken.
      expect(
        h.transport.manifestCalls,
        hadProgress ? 1 : manifestsAtKill + 1,
        reason: 'kill $kill',
      );
      await h.dispose();
    }
  });

  for (final id in ['p1', 'p2', 'p3', 'p4', 'p5']) {
    test('kill inside the applier at $id (page txn rolled back)', () async {
      final h = await BootHarness.create(
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
      addTearDown(h.dispose);
      h.seedStandard();
      final t = h.registry.of('product')! as ThrowingApplier
        ..throwOn.add(id)
        ..error = () => CrashSimulation('applier $id');
      await expectLater(h.build().run(), throwsA(isA<CrashSimulation>()));
      t.throwOn.clear();
      await finish(h);
      await expectConverged(h, oneSnapshot: true);
    });
  }

  test(
    'a resume after the manifest changed finishes the ORIGINAL list',
    () async {
      final h = await BootHarness.create();
      addTearDown(h.dispose);
      h.seedStandard();
      h.transport.beforePage = (n, _) {
        if (n == 3) {
          throw SyncTransportException(kind: SyncTransportKind.network);
        }
      };
      expect(await h.build().run(), BootstrapOutcome.interrupted);
      final p = (await h.progress())!;
      expect(p.entities, ['category', 'product', 'customer']);

      h.server.bootstrapEntities = ['category', 'vendor'];
      h.transport.beforePage = null;
      await finish(h);
      expect(h.transport.manifestCalls, 1);
      expect(h.transport.requestedEntities, [
        'category',
        'product',
        'customer',
      ]);
      expect(await h.dump(), reference);
    },
  );

  for (var k = 1; k <= pages; k++) {
    test('rows written between pages + kill before page $k: pull from the '
        'snapshot converges to the server', () async {
      final h = await BootHarness.create();
      addTearDown(h.dispose);
      h.seedStandard();
      h.server.onBootstrapPage = (entity, index) {
        h.seedProduct('n-$entity-$index');
        h.seedCustomer('nc-$entity-$index', version: 1);
      };
      h.transport.beforePage = (n, _) {
        if (n == k) throw CrashSimulation('before page $k');
      };
      await expectLater(h.build().run(), throwsA(isA<CrashSimulation>()));
      h.transport.beforePage = null;
      await finish(h);
      expect(h.transport.manifestCalls, 1);

      h.advance(const Duration(minutes: 3));
      expect(await h.buildEngine().syncNow(), SyncOutcome.completed);
      expect(
        await h.ids('products'),
        h.server.tables['product']!.keys.toList()..sort(),
      );
      expect(
        await h.ids('customers'),
        h.server.tables['customer']!.keys.toList()..sort(),
      );
      expect(
        await h.ids('categories'),
        h.server.tables['category']!.keys.toList()..sort(),
      );
    });
  }
}
