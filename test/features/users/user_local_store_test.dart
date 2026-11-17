import 'dart:convert';

import 'package:amana_pos/core/sync/appliers/user_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/features/users/data/local/user_local_store.dart';
import 'package:amana_pos/features/users/data/models/responses/user_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

void main() {
  late SaleFixture f;
  late UserLocalStore store;
  final applier = UserApplier();

  setUp(() async {
    SyncScope.current = kScope;
    f = await SaleFixture.on(await openTestDb());
    store = UserLocalStore(f.writer);
  });
  tearDown(() async {
    SyncScope.current = null;
    f.notifier.dispose();
    await f.db.close();
  });

  Future<void> serverRow(String id, {String name = 'Sara'}) => f.db.transaction(
    (t) => applier.apply(
      t,
      PullChange(
        seq: 1,
        entity: 'user',
        op: 'upsert',
        id: id,
        version: 2,
        data: {
          'id': id,
          'phone': '+249911',
          'full_name': name,
          'role': 'cashier',
          'default_shop': 's1',
          'is_active': true,
          'status': 'invited',
        },
      ),
    ),
  );

  Future<void> outbox(String id, String status, {String scope = kScope}) =>
      f.db.insert('outbox', {
        'mutation_id': 'm-$id-$status-$scope',
        'entity': 'user',
        'op': 'set_role',
        'entity_id': id,
        'payload_json': jsonEncode({'role': 'manager'}),
        'status': status,
        'attempts': 0,
        'scope': scope,
        'created_at': DateTime.utc(2026).toIso8601String(),
        'occurred_at': DateTime.utc(2026).toIso8601String(),
        'error_code': status == 'rejected' ? 'conflict_version' : null,
      });

  test('fromJson reads the feed shape', () {
    final u = UserData.fromJson({
      'id': 'u',
      'default_shop': 's1',
      'status': 'invited',
      'version': 4,
    });
    expect(u.defaultShopId, 's1');
    expect(u.isVerified, isFalse);
    expect(u.version, 4);
  });

  test('fromJson reads the legacy shape', () {
    final u = UserData.fromJson({
      'id': 'u',
      'default_shop_id': 's2',
      'is_verified': true,
    });
    expect(u.defaultShopId, 's2');
    expect(u.isVerified, isTrue);
  });

  test('readAll marks pending when an open outbox row exists', () async {
    await serverRow('u1');
    await outbox('u1', 'pending');
    final u = (await store.readAll()).single;
    expect(u.syncMark, UserSyncMark.pending);
    expect(u.conflict, isNull);
    expect(u.defaultShopId, 's1');
  });

  test('readAll marks failed and exposes the conflict', () async {
    await serverRow('u1');
    await outbox('u1', 'rejected');
    final u = (await store.readOne('u1'))!;
    expect(u.syncMark, UserSyncMark.failed);
    expect(u.conflict!.isVersionConflict, isTrue);
    expect(u.conflict!.payload, {'role': 'manager'});
  });

  test('readAll ignores another scope', () async {
    await serverRow('u1');
    await outbox('u1', 'rejected', scope: 'x|y');
    final u = (await store.readAll()).single;
    expect(u.syncMark, UserSyncMark.synced);
    expect(u.conflict, isNull);
  });
}
