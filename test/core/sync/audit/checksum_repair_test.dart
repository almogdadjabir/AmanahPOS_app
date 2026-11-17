import 'package:amana_pos/core/sync/audit/checksum_repair.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sale_applier_test.dart' show feedSale;
import '../support/bootstrap_harness.dart';

String _id(int i) => '55555555-5555-4555-8555-${i.toString().padLeft(12, '0')}';

void main() {
  late BootHarness h;
  setUp(() async {
    h = await BootHarness.create();
    h.server.bootstrapEntities = ['sale', 'refund', 'stock'];
  });
  tearDown(() async => h.dispose());

  ChecksumRepair build({int pageSize = 200, int? throwAssertAt}) {
    var calls = 0;
    return ChecksumRepair(
      db: h.odb,
      transport: h.transport,
      appliers: h.registry,
      notifier: h.notifier,
      authedFor: h.buildEngine().authedFor,
      assertScope: () async {
        calls++;
        if (throwAssertAt != null && calls >= throwAssertAt) {
          throw SyncTransportException(kind: SyncTransportKind.scopeChanged);
        }
      },
      pageSize: pageSize,
    );
  }

  void seedSales(int n, {int version = 1}) {
    for (var i = 1; i <= n; i++) {
      final row = feedSale(id: _id(i))..['version'] = version;
      h.server.seedRow('sale', row);
    }
  }

  test('a sale missing locally is inserted; pages through cursors', () async {
    seedSales(5);
    final n = await build(pageSize: 2).repair(scope: BootHarness.scope);
    expect(n, 5);
    expect(await h.ids('sales'), [for (var i = 1; i <= 5; i++) _id(i)]);
  });

  test('cursor, bootstrapped flag and progress stay untouched (4d)', () async {
    seedSales(2);
    await h.db.transaction((t) async {
      await h.scoped.setCursor(t, 'cur-1');
      await h.scoped.setBootstrapped(t, true);
    });
    await build().repair(scope: BootHarness.scope);
    expect(await h.scoped.cursor(), 'cur-1');
    expect(await h.scoped.isBootstrapped(), isTrue);
    expect(await h.progress(), isNull);
    expect(await h.deferredJson(), isNull);
  });

  test('a row at the same version is left alone (4b)', () async {
    seedSales(1);
    final repair = build();
    expect(await repair.repair(scope: BootHarness.scope), 1);
    expect(await repair.repair(scope: BootHarness.scope), 0);
  });

  test('a row with a pending local edit is skipped (4c)', () async {
    seedSales(2);
    await h.pendingOutbox('sale', _id(1));
    final n = await build().repair(scope: BootHarness.scope);
    expect(n, 1);
    expect(await h.ids('sales'), [_id(2)]);
  });

  test('scope change rolls the page back, nothing partial (4e)', () async {
    seedSales(3);
    // 1st assert before the page fetch passes, the in-txn one throws.
    await expectLater(
      build(throwAssertAt: 2).repair(scope: BootHarness.scope),
      throwsA(isA<SyncTransportException>()),
    );
    expect(await h.ids('sales'), isEmpty);
  });
}
