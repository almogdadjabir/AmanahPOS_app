import 'package:amana_pos/core/sync/appliers/sale_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/features/returns/data/models/requests/refund_request_dto.dart';
import 'package:amana_pos/features/returns/data/repository_impl/returns_repo_impl.dart';
import 'package:amana_pos/features/returns/domain/refund_service.dart';
import 'package:amana_pos/features/sales_history/data/local/local_sales_history.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/sync/sale_applier_test.dart' show feedSale;
import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

const _sale = '55555555-5555-4555-8555-555555555555';
const _item = '66666666-6666-4666-8666-666666666666';

void main() {
  late SaleFixture f;
  late ReturnsRepoImpl repo;
  late LocalSalesHistory history;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    await f.seedShop(kShop, businessId: 'b');
    repo = ReturnsRepoImpl(
      refunds: RefundService(writer: f.writer, now: () => f.clock),
    );
    history = LocalSalesHistory(db: f.odb, tenantId: () => 'b');
    await f.db.transaction(
      (t) => SaleApplier().apply(
        t,
        PullChange(
          seq: 1,
          entity: 'sale',
          op: 'upsert',
          id: _sale,
          version: 1,
          data: feedSale(),
          shopId: kShop,
        ),
      ),
    );
  });
  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  test(
    'submit offline succeeds without network and shows a pending refund',
    () async {
      final r = await repo.processRefund(
        saleId: _sale,
        request: const RefundRequestDto(
          items: [RefundItemDto(itemId: _item, quantity: 1)],
          notes: 'broken',
        ),
      );
      final dto = r.getOrElse((_) => throw StateError('failed'));
      expect(dto.refundTotal, '2.50');
      expect(dto.returnedItems!.single.productName, 'Tea');
      expect(dto.isFullRefund, isFalse);
      final sale = (await history.byId(_sale))!;
      expect(sale.refunds.single.isPending, isTrue);
      expect(sale.refundedTotal, 2.5);
      expect(sale.items.single.returnableQuantity, 2);
    },
  );

  test(
    'returnable quantity excludes pending refunds; a voided one is flagged, not counted',
    () async {
      await repo.processRefund(
        saleId: _sale,
        request: const RefundRequestDto(
          items: [RefundItemDto(itemId: _item, quantity: 3)],
        ),
      );
      expect((await history.byId(_sale))!.items.single.returnableQuantity, 0);
      await f.db.update('sale_refunds', {
        'sync_state': 'rejected',
        'error_code': 'refund_exceeds_sold',
      });
      final sale = (await history.byId(_sale))!;
      expect(sale.hasRejectedRefund, isTrue);
      expect(sale.refundedTotal, 0);
      expect(sale.items.single.returnableQuantity, 3);
    },
  );

  test('RefundValidationException surfaces as a failure message', () async {
    final r = await repo.processRefund(
      saleId: _sale,
      request: const RefundRequestDto(
        items: [RefundItemDto(itemId: _item, quantity: 9)],
      ),
    );
    expect(r.isLeft(), isTrue);
  });
}
