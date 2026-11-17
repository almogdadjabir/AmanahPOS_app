import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrap_controller.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_db.dart';

class _Boot implements Bootstrapper {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late OfflineDb odb;
  late SyncStateStore state;
  String? scope;

  setUp(() async {
    odb = await openTestDb();
    state = SyncStateStore(odb);
    final db = await odb.database;
    await db.transaction(
      (t) => state.forScope('u1|t1').setBootstrapped(t, true),
    );
  });
  tearDown(() async => (await odb.database).close());

  BootstrapController make() => BootstrapController(
    bootstrapper: _Boot(),
    state: state,
    scopeProvider: () => scope,
  );

  // Ruling T11-a.
  test('isTenantBootstrapped: any user of the live scope tenant', () async {
    scope = 'u2|t1';
    expect(
      await state.forScope('u2|t1').isBootstrapped(),
      isFalse,
      reason: 'own flag',
    );
    expect(await make().isTenantBootstrapped(), isTrue);
    scope = 'u3|t2';
    expect(await make().isTenantBootstrapped(), isFalse);
    scope = null;
    expect(await make().isTenantBootstrapped(), isFalse);
    scope = 'malformed';
    expect(await make().isTenantBootstrapped(), isFalse);
  });

  test('the wipe resets the tenant gate', () async {
    scope = 'u2|t1';
    final db = await odb.database;
    await db.transaction(SyncStateStore.resetSetupOfAllScopes);
    expect(await make().isTenantBootstrapped(), isFalse);
  });
}
