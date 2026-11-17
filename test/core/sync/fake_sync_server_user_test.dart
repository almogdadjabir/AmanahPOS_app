// Task 1 (Phase 5): FakeSyncServer user semantics mirror amanaPOS-be
// apps/sync/handlers.py user_create / user_update.
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_server.dart';

void main() {
  late FakeSyncServer s;
  var n = 0;

  setUp(() {
    s = FakeSyncServer(now: () => DateTime.utc(2026, 11, 17));
    n = 0;
  });

  OutboxEntry m(
    String op,
    String id,
    Map<String, dynamic> payload, {
    int? baseVersion,
  }) => OutboxEntry(
    seq: ++n,
    mutationId: 'm$n',
    entity: 'user',
    op: op,
    entityId: id,
    baseVersion: baseVersion,
    occurredAt: DateTime.utc(2026, 11, 17),
    payload: payload,
  );

  Future<PushResult> push(OutboxEntry e, {FakeSyncServer? on}) async =>
      (await (on ?? s).push(
        deviceId: 'd',
        appVersion: '1',
        mutations: [e],
        scope: 'u1|t1',
      )).results.single;

  Future<void> create(String id, String phone) async {
    final r = await push(
      m('create', id, {
        'id': id,
        'phone': phone,
        'full_name': 'Sara',
        'role': 'cashier',
      }),
    );
    expect(r.status, PushStatus.applied);
  }

  test('create then set_role with base == version applies and bumps', () async {
    await create('u2', '+249900000001');
    expect(s.tables['user']!['u2']!['status'], 'invited');
    final r = await push(
      m('set_role', 'u2', {'role': 'manager'}, baseVersion: 1),
    );
    expect(r.status, PushStatus.applied);
    expect(r.version, 2);
    expect(s.tables['user']!['u2']!['role'], 'manager');
  });

  test('create answers inviteSent', () async {
    final r = await push(
      m('create', 'u2', {
        'id': 'u2',
        'phone': '+249900000001',
        'full_name': 'S',
        'role': 'cashier',
      }),
    );
    expect(r.inviteSent, isTrue);
  });

  test(
    'set_role with a stale base is conflict_version with server state',
    () async {
      await create('u2', '+249900000001');
      await push(m('set_role', 'u2', {'role': 'manager'}, baseVersion: 1));
      final r = await push(
        m('set_role', 'u2', {'role': 'cashier'}, baseVersion: 1),
      );
      expect(r.status, PushStatus.rejected);
      expect(r.code, 'conflict_version');
      expect(r.serverState!['role'], 'manager');
      expect(r.serverState!['version'], 2);
    },
  );

  test('set_role without a base is validation_error', () async {
    await create('u2', '+249900000001');
    final r = await push(m('set_role', 'u2', {'role': 'manager'}));
    expect(r.code, 'validation_error');
  });

  test('cashier push is forbidden', () async {
    final c = s.forDevice('d2')..role = 'cashier';
    final r = await push(
      m('create', 'u9', {
        'id': 'u9',
        'phone': '+249900000009',
        'full_name': 'X',
        'role': 'cashier',
      }),
      on: c,
    );
    expect(r.code, 'forbidden');
  });

  test(
    'create with an existing phone is conflict_unique with the id',
    () async {
      await create('u2', '+249900000001');
      final r = await push(
        m('create', 'u3', {
          'id': 'u3',
          'phone': '+249900000001',
          'full_name': 'T',
          'role': 'cashier',
        }),
      );
      expect(r.code, 'conflict_unique');
      expect(r.conflictEntityId, 'u2');
    },
  );

  test('update of only full_name applies with a stale base', () async {
    await create('u2', '+249900000001');
    await push(m('set_role', 'u2', {'role': 'manager'}, baseVersion: 1));
    final r = await push(
      m('update', 'u2', {'full_name': 'Sara B'}, baseVersion: 1),
    );
    expect(r.status, PushStatus.applied);
  });

  test('update carrying role with a stale base is conflict_version', () async {
    await create('u2', '+249900000001');
    await push(m('set_role', 'u2', {'role': 'manager'}, baseVersion: 1));
    final r = await push(
      m('update', 'u2', {'role': 'cashier'}, baseVersion: 1),
    );
    expect(r.code, 'conflict_version');
  });

  test('the owner and the caller cannot be edited', () async {
    s.tables['user'] = {
      'owner-1': {'id': 'owner-1', 'version': 1, 'role': 'owner'},
    };
    final r = await push(m('update', 'owner-1', {'full_name': 'X'}));
    expect(r.code, 'forbidden');
  });
}
