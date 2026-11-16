import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/sales_history/data/local/local_sales_history.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/data/repository_impl/sales_history_repo_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../core/sync/support/test_db.dart';
import '../../../pos/support/sale_fixture.dart';

class _MockRequestHandler extends Mock implements RequestHandler {}

class _MockNetworkMonitor extends Mock implements NetworkMonitor {}

void main() {
  test(
    'with local history: lists local sales, never calls the network',
    () async {
      final f = await SaleFixture.on(await openTestDb());
      await f.seedShop(kShop);
      addTearDown(() async {
        f.notifier.dispose();
        await f.db.close();
      });
      final http = _MockRequestHandler();
      final net = _MockNetworkMonitor();
      final repo = SalesHistoryRepoImpl(
        requestHandler: http,
        networkMonitor: net,
        localHistory: LocalSalesHistory(db: f.odb, tenantId: () => 'biz-1'),
        businessTimezone: () async => 'Africa/Khartoum',
      );

      // 23:30 Khartoum on 2026-11-16 (21:30Z): a business-day "today" sale.
      f.clock = DateTime.utc(2026, 11, 16, 21, 30);
      final sale = await f.service().createSale(
        const SaleDraft(
          shopId: kShop,
          paymentMethod: 'cash',
          lines: [
            SaleDraftLine.product(
              productId: kP1,
              productName: 'Tea',
              quantity: '2',
              unitPrice: '2.50',
            ),
          ],
        ),
      );

      final res = await repo.getSalesPage(
        page: 1,
        dateFrom: DateTime(2026, 11, 16),
        dateTo: DateTime(2026, 11, 16),
      );
      final page = res.getOrElse((_) => throw StateError('failed'));
      expect(page.items.single.id, sale.id);
      expect(page.items.single.total, 5.0);
      expect(page.items.single.status, SaleHistoryStatus.completed);
      expect(page.items.single.isOfflinePending, isTrue);
      expect(page.hasMore, isFalse);

      final next = (await repo.getSalesPage(
        page: 1,
        dateFrom: DateTime(2026, 11, 17),
        dateTo: DateTime(2026, 11, 17),
      )).getOrElse((_) => throw StateError('failed'));
      expect(next.items, isEmpty);

      verifyZeroInteractions(http);
      verifyZeroInteractions(net);
    },
  );
}
