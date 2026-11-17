import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/features/users/domain/user_conflict_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/user_device.dart';

void main() {
  late UserDevice d;
  late UserConflictService svc;
  setUp(() async {
    d = await UserDevice.create();
    svc = UserConflictService(writer: d.writer, outbox: d.outbox);
  });
  tearDown(() => d.dispose());

  /// A pending role change that the server refuses because another device
  /// changed the member first.
  Future<String> conflict({String role = 'manager'}) async {
    await d.seed('u2');
    await d.users.update('u2', role: role);
    d.server.tables['user']!['u2']!['version'] = 2;
    await d.sync();
    return (await d.rejected()).single.mutationId;
  }

  test('applyMineAgain re-queues with the fresh base and applies', () async {
    final m = await conflict();
    await svc.applyMineAgain(m);
    var u = (await d.store.readOne('u2'))!;
    expect(u.role, 'manager'); // shown again, pending
    expect(u.syncMark.name, 'pending');
    await d.sync();
    expect(await d.rejected(), isEmpty);
    expect(d.server.tables['user']!['u2']!['role'], 'manager');
    u = (await d.store.readOne('u2'))!;
    expect(u.version, 3);
    expect(u.syncMark.name, 'synced');
  });

  test(
    'applyMineAgain conflicts again when the server changed again',
    () async {
      final m = await conflict();
      await svc.applyMineAgain(m);
      d.server.tables['user']!['u2']!['version'] = 3; // changed once more
      await d.sync();
      final rej = await d.rejected();
      expect(rej.single.errorCode, 'conflict_version');
      expect(d.server.tables['user']!['u2']!['role'], 'cashier');
    },
  );

  test('dismiss shows the server role and clears the mark', () async {
    final m = await conflict();
    await svc.dismiss(m);
    final u = (await d.store.readOne('u2'))!;
    expect(u.role, 'cashier');
    expect(u.syncMark.name, 'synced');
    expect(u.conflict, isNull);
    expect(await d.db.query('outbox'), isEmpty);
  });

  test('dismiss keeps another queued edit', () async {
    final m = await conflict();
    await d.users.update('u2', fullName: 'Zed');
    await svc.dismiss(m);
    final u = (await d.store.readOne('u2'))!;
    expect(u.role, 'cashier');
    expect(u.fullName, 'Zed');
    expect(u.syncMark.name, 'pending');
  });

  test('dismiss of a rejected create removes the member', () async {
    await d.seed('u2', phone: '+249933');
    final id = await d.users.create(
      phone: '+249933',
      fullName: 'Dup',
      role: 'cashier',
    );
    await d.sync();
    final m = (await d.rejected()).single.mutationId;
    await svc.dismiss(m);
    expect(await d.store.readOne(id), isNull);
    expect(await d.db.query('outbox'), isEmpty);
  });

  test('applyMineAgain on a non-conflict row throws', () async {
    await d.seed('u2', phone: '+249933');
    d.server.ownerUserId = 'u2';
    await d.users.update('u2', fullName: 'Zed');
    await d.sync();
    final m = (await d.rejected()).single.mutationId;
    expect(
      () => svc.applyMineAgain(m),
      throwsA(isA<CatalogValidationException>()),
    );
  });

  test('applyMineAgain keeps the original edit time', () async {
    final m = await conflict();
    final at = (await d.db.query('outbox')).single['occurred_at'];
    await svc.applyMineAgain(m);
    expect((await d.db.query('outbox')).single['occurred_at'], at);
  });

  test('applyMineAgain keeps the queue position and mutation id', () async {
    final m = await conflict();
    await d.users.update('u2', fullName: 'Zed'); // a newer edit behind it
    final before = [
      for (final r in await d.db.query('outbox', orderBy: 'seq'))
        r['mutation_id'],
    ];
    await svc.applyMineAgain(m);
    final after = [
      for (final r in await d.db.query('outbox', orderBy: 'seq'))
        r['mutation_id'],
    ];
    expect(after, before);
    expect(after.first, m);
  });

  test(
    'dismiss of a create refuses while another row of it is inflight',
    () async {
      await d.seed('u2', phone: '+249933');
      final id = await d.users.create(
        phone: '+249933',
        fullName: 'Dup',
        role: 'cashier',
      );
      await d.sync();
      await d.users.update(id, fullName: 'Later');
      await d.db.update('outbox', {
        'status': 'inflight',
      }, where: "op = 'update'");
      final m = (await d.rejected()).single.mutationId;
      await expectLater(
        svc.dismiss(m),
        throwsA(isA<CatalogValidationException>()),
      );
      expect(await d.store.readOne(id), isNotNull);
      expect(await d.rejected(), hasLength(1));
    },
  );

  test('applyMineAgain throws when the row was already requeued', () async {
    final m = await conflict();
    await svc.applyMineAgain(m);
    await expectLater(
      svc.applyMineAgain(m),
      throwsA(isA<CatalogValidationException>()),
    );
  });
}
