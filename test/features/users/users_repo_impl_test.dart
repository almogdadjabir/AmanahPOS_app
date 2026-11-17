import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/features/users/data/repository_impl/users_repo_impl.dart';
import 'package:amana_pos/features/users/domain/user_conflict_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/user_device.dart';

void main() {
  late UserDevice d;
  late UsersRepoImpl repo;
  setUp(() async {
    d = await UserDevice.create();
    repo = UsersRepoImpl(
      store: d.store,
      service: () => d.users,
      conflicts: () => UserConflictService(writer: d.writer, outbox: d.outbox),
    );
  });
  tearDown(() => d.dispose());

  test(
    'addUser saves locally with no network and returns the member',
    () async {
      final r = await repo.addUser(
        phone: '+249900',
        fullName: 'Nour',
        role: 'cashier',
      );
      final u = r.getOrElse((_) => throw StateError('left'));
      expect(u.fullName, 'Nour');
      expect(u.isLocalOnly, isTrue);
      expect(u.syncMark.name, 'pending');
      expect(
        (await repo.getUsers()).getOrElse((_) => throw 1).data,
        hasLength(1),
      );
    },
  );

  test('a local refusal is the Left message', () async {
    final r = await repo.addUser(phone: '', fullName: 'X', role: 'cashier');
    expect(r.getLeft().toNullable(), 'Phone is required');
  });

  test('updateUser with role + isActive writes both', () async {
    await d.seed('u2');
    final r = await repo.updateUser(
      userId: 'u2',
      role: 'manager',
      isActive: false,
    );
    expect(r.isRight(), isTrue);
    final ops = [
      for (final o in await d.db.query('outbox', orderBy: 'seq')) o['op'],
    ];
    expect(ops, ['set_role', 'deactivate']);
  });

  test('a cashier device lists only the rows it holds', () async {
    SyncScope.current = kUserScope;
    await d.seed('u1');
    expect(
      (await repo.getUsers()).getOrElse((_) => throw 1).data,
      hasLength(1),
    );
  });
}
