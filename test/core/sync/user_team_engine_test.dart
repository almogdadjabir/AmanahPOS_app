// Task 8 (Phase 5): team convergence across two devices, account_disabled
// never costs unsynced team rows, cashier scope.
import 'dart:math';

import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/user_device.dart';

void main() {
  test('owner offline: create + role + deactivate converges on a second '
      'device (50 seeds)', () async {
    for (var seed = 0; seed < 50; seed++) {
      final r = Random(seed);
      final a = await UserDevice.create();
      final b = await UserDevice.create(server: a.server.forDevice('dev-b'));
      try {
        await a.seed('m1');
        final id = await a.users.create(
          phone: '+2499${seed.toString().padLeft(8, '0')}',
          fullName: 'N$seed',
          role: 'cashier',
        );
        final steps = <Future<void> Function()>[
          () => a.users.update(id, role: 'manager'),
          () => a.users.update(id, fullName: 'Renamed$seed'),
          () => a.users.setActive(id, false),
          () => a.users.update('m1', role: 'manager'),
          () => a.users.setActive('m1', false),
        ]..shuffle(r);
        for (final s in steps.take(2 + r.nextInt(4))) {
          await s();
          if (r.nextBool()) await a.sync();
        }
        await a.sync();
        await a.sync();
        expect(await a.rejected(), isEmpty, reason: 'seed $seed');
        // The server row is what a fresh device sees.
        await b.sync();
        for (final uid in [id, 'm1']) {
          final server = a.server.tables['user']![uid]!;
          final local = (await a.store.readOne(uid))!;
          expect(local.role, server['role'], reason: 'seed $seed $uid');
          expect(local.isActive, server['is_active'], reason: 'seed $seed');
          expect(local.version, server['version'], reason: 'seed $seed');
          // A seeded member nobody touched has no feed row to pull.
          if (server['version'] == 1 && uid == 'm1') continue;
          final remote = await b.store.readOne(uid);
          expect(remote?.role, server['role'], reason: 'seed $seed $uid');
          expect(remote?.version, server['version'], reason: 'seed $seed');
        }
      } finally {
        await a.dispose();
        await b.dispose();
      }
    }
  });

  test(
    'account_disabled blocks the engine and keeps unsynced team rows',
    () async {
      final d = await UserDevice.create();
      addTearDown(d.dispose);
      await d.seed('m1');
      await d.users.update('m1', role: 'manager');
      await d.users.create(phone: '+249977', fullName: 'X', role: 'cashier');
      d.transport.onBeforeSend = (op) async {
        if (op == 'push') {
          throw SyncTransportException(kind: SyncTransportKind.accountDisabled);
        }
      };
      final out = await d.sync();
      expect(out, SyncOutcome.blocked);
      expect(d.engine.current.block, SyncBlockReason.accountDisabled);
      final rows = await d.db.query('outbox');
      expect(rows, hasLength(2));
      expect(rows.every((r) => r['status'] != 'done'), isTrue);
    },
  );

  test('a cashier device pulls only itself as user', () async {
    final owner = await UserDevice.create();
    addTearDown(owner.dispose);
    await owner.seed('m1');
    await owner.seed('cash-1', role: 'cashier');
    final c = await UserDevice.create(
      server: owner.server.forDevice('dev-c')
        ..role = 'cashier'
        ..callerUserId = 'cash-1',
    );
    addTearDown(c.dispose);
    // Make the server emit feed rows for both members.
    await owner.users.update('m1', role: 'manager');
    await owner.sync();
    owner.server.tables['user']!['cash-1']!['full_name'] = 'Cash';
    await c.sync();
    final all = await c.store.readAll();
    expect(all.map((u) => u.id).toSet().difference({'cash-1'}), isEmpty);
  });
}
