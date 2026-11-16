import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/pos/support/sale_fixture.dart';
import '../sync/support/test_db.dart';

/// Wipes never delete local sales: the pull cursor is per scope and
/// resumes, so a wiped synced sale would never come back. Isolation between
/// businesses is the read filter (SaleLocalStore.visibleShopSql).
void main() {
  late SaleFixture f;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
  });

  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  Future<Sale> sell() => f.service().createSale(
    const SaleDraft(
      shopId: kShop,
      paymentMethod: 'cash',
      lines: [
        SaleDraftLine.product(
          productId: kP1,
          productName: 'Tea',
          quantity: '1',
          unitPrice: '2.50',
        ),
      ],
      payments: [
        SalePaymentPart(method: 'cash', amount: '1.00'),
        SalePaymentPart(method: 'bankak', amount: '1.50'),
      ],
    ),
  );

  for (final wipe in <String, Future<void> Function()>{
    'clearAllLocalOfflineData': () => f.odb.clearAllLocalOfflineData(),
    'clearAllOnLogout': () => OfflineLocalCache(f.odb).clearAllOnLogout(),
  }.entries) {
    test('${wipe.key} keeps every local sale (synced, pending, rejected), '
        'its lines and payments, and the outbox', () async {
      final synced = await sell();
      final pending = await sell();
      final rejected = await sell();
      await f.db.update(
        'sales',
        {'sync_state': 'synced'},
        where: 'id = ?',
        whereArgs: [synced.id],
      );
      await f.db.update(
        'sales',
        {'sync_state': 'rejected'},
        where: 'id = ?',
        whereArgs: [rejected.id],
      );
      final outboxBefore = await f.db.query('outbox', orderBy: 'seq');

      await wipe.value();

      final left = await f.db.query('sales', columns: ['id']);
      expect(left.map((r) => r['id']).toSet(), {
        synced.id,
        pending.id,
        rejected.id,
      });
      expect(await f.count('sale_items'), 3);
      expect(await f.count('sale_payments'), 6);
      expect(await f.db.query('outbox', orderBy: 'seq'), outboxBefore);
      // The shops table is wiped: nothing is visible until a business loads.
      expect(await f.count('shops'), 0);
    });
  }
}
