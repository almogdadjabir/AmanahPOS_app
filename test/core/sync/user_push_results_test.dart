// Task 4 (Phase 5): UserApplier push results through the real engine against
// the FakeSyncServer (BE semantics): adopt, re-base, revert.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'support/user_device.dart';

void main() {
  late UserDevice d;
  setUp(() async => d = await UserDevice.create());
  tearDown(() => d.dispose());

  test('two queued edits both apply (no self-conflict)', () async {
    await d.seed('u2');
    await d.users.update('u2', role: 'manager');
    await d.users.update('u2', shopId: 's2');
    await d.sync();
    expect(await d.rejected(), isEmpty);
    final s = d.server.tables['user']!['u2']!;
    expect(s['role'], 'manager');
    expect(s['default_shop'], 's2');
    expect(s['version'], 3);
    final u = (await d.store.readOne('u2'))!;
    expect(u.version, 3);
    expect(u.syncMark.name, 'synced');
  });

  test('a deactivate followed by a role edit does not self-conflict', () async {
    await d.seed('u2');
    await d.users.setActive('u2', false);
    await d.users.update('u2', role: 'manager');
    await d.sync();
    expect(await d.rejected(), isEmpty);
    expect(d.server.tables['user']!['u2']!['role'], 'manager');
    expect(d.server.tables['user']!['u2']!['is_active'], false);
  });

  test('an edit queued behind an unsent create applies', () async {
    final id = await d.users.create(
      phone: '+249922',
      fullName: 'Nour',
      role: 'cashier',
    );
    await d.users.update(id, role: 'manager');
    await d.sync();
    expect(await d.rejected(), isEmpty);
    final s = d.server.tables['user']![id]!;
    expect(s['role'], 'manager');
    expect(s['status'], 'invited');
    expect((await d.store.readOne(id))!.version, 2);
  });

  test('a foreign write in between: role change conflicts, row shows the '
      'server role, owner decides', () async {
    await d.seed('u2');
    await d.users.update('u2', role: 'manager');
    // Another device renames the member first (version 1 -> 2).
    d.server.tables['user']!['u2']!['full_name'] = 'Other';
    d.server.tables['user']!['u2']!['version'] = 2;
    await d.sync();
    final rej = await d.rejected();
    expect(rej.single.errorCode, 'conflict_version');
    final u = (await d.store.readOne('u2'))!;
    expect(u.role, 'cashier');
    expect(u.fullName, 'Other');
    expect(u.version, 2);
    expect(u.syncMark.name, 'failed');
    expect(u.conflict!.payload, {'role': 'manager'});
    expect(d.server.tables['user']!['u2']!['role'], 'cashier');
  });

  test('forbidden reverts the row from _server', () async {
    await d.seed('u2');
    d.server.ownerUserId = 'u2'; // the BE refuses edits of the owner
    await d.users.update('u2', fullName: 'Zed');
    await d.sync();
    expect((await d.rejected()).single.errorCode, 'forbidden');
    final u = (await d.store.readOne('u2'))!;
    expect(u.fullName, 'Sara');
    expect(u.version, 1);
  });

  test(
    'a create with an existing phone stays rejected with the clash id',
    () async {
      await d.seed('u2', phone: '+249933');
      final id = await d.users.create(
        phone: '+249933',
        fullName: 'Dup',
        role: 'cashier',
      );
      await d.sync();
      final r = (await d.rejected()).single;
      expect(r.errorCode, 'conflict_unique');
      expect(r.errorEntityId, 'u2');
      final u = (await d.store.readOne(id))!;
      expect(u.conflict!.code, 'conflict_unique');
      expect(json.encode(u.fullName), '"Dup"');
    },
  );

  test('an applied deactivate stays deactivated locally while a later edit '
      'is still queued', () async {
    await d.seed('u2');
    await d.users.setActive('u2', false);
    await d.sync();
    await d.users.update('u2', fullName: 'Zed');
    final u = (await d.store.readOne('u2'))!;
    expect(u.isActive, false);
    expect(u.fullName, 'Zed');
    await d.sync();
    expect((await d.store.readOne('u2'))!.isActive, false);
  });
}
