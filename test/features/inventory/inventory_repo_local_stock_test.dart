import 'dart:convert';

import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/inventory/data/models/requests/add_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/adjust_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/data/models/requests/transfer_stock_request_dto.dart';
import 'package:amana_pos/features/inventory/data/repository_impl/inventory_repo_impl.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/users/data/models/movement_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

class _Handler extends Mock implements RequestHandler {}

void main() {
  late SaleFixture f;
  late _Handler handler;
  var actor = const StockActor(
    businessType: AppBusinessType.shop,
    role: AppUserRole.owner,
    shopId: null,
  );

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    handler = _Handler();
    actor = const StockActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.owner,
      shopId: null,
    );
  });

  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
  });

  InventoryRepoImpl repo() => InventoryRepoImpl(
    handler,
    stockService: () =>
        StockService(writer: f.writer, actor: () => actor, now: () => f.clock),
  );

  Future<double> qty() async =>
      ((await f.stock(kP1))['quantity'] as num).toDouble();

  test('add is written locally + outbox, no network', () async {
    final r = await repo().addStock(
      const AddStockRequestDto(
        productId: kP1,
        shopId: kShop,
        quantity: '4',
        movementType: MovementType.in_,
        reference: 'restock',
      ),
    );
    expect(r.isRight(), isTrue);
    expect(r.getRight().toNullable()!.data!.quantity, '14');
    expect(await qty(), 14.0);
    final row = (await f.db.query('outbox')).single;
    expect(row['entity'], 'stock');
    expect(row['op'], 'add');
    expect(jsonDecode(row['payload_json'] as String)['reason'], 'restock');
    verifyZeroInteractions(handler);
  });

  test('adjust to an absolute quantity enqueues the signed '
      'delta', () async {
    final r = await repo().adjustStock(
      AdjustStockRequestDto(
        productId: kP1,
        shopId: kShop,
        newQuantity: '6',
        notes: 'broken',
      ),
    );
    expect(r.getRight().toNullable()!.data!.quantity, '6');
    final row = (await f.db.query('outbox')).single;
    expect(row['op'], 'adjust');
    expect(jsonDecode(row['payload_json'] as String)['delta'], '-4');
    verifyZeroInteractions(handler);
  });

  test('inbound is written locally + outbox', () async {
    final r = await repo().createInboundTransaction(
      const CreateInboundRequestDto(
        shopId: kShop,
        reference: 'INV-9',
        vendorId: '88888888-8888-4888-8888-888888888888',
        items: [CreateInboundItemRequestDto(productId: kP1, quantity: '2')],
      ),
    );
    expect(r.getRight().toNullable()!.success, isTrue);
    expect(await qty(), 12.0);
    expect((await f.db.query('outbox')).single['entity'], 'inbound');
    verifyZeroInteractions(handler);
  });

  test('local validation errors come back as Left with the message', () async {
    actor = const StockActor(
      businessType: AppBusinessType.restaurant,
      role: AppUserRole.owner,
      shopId: null,
    );
    final r = await repo().addStock(
      const AddStockRequestDto(
        productId: kP1,
        shopId: kShop,
        quantity: '1',
        movementType: MovementType.in_,
      ),
    );
    expect(r.getLeft().toNullable(), 'Restaurants do not track inventory');
    expect(await f.count('outbox'), 0);
  });

  group('transfer stays REST and mirrors on the local base', () {
    const other = '44444444-4444-4444-8444-444444444444';
    final req = TransferStockRequestDto(
      productId: kP1,
      fromShop: kShop,
      toShop: other,
      quantity: '4',
    );

    void answer(Either<String?, bool> r) => when(
      () => handler.handlePostRequest<bool>(
        any(),
        any(),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) async => r);

    Future<Map<String, Object?>?> row(String shop) async {
      final r = await f.db.query(
        'stock',
        where: 'product_id = ? AND shop_id = ?',
        whereArgs: [kP1, shop],
      );
      return r.isEmpty ? null : r.single;
    }

    test('success: base moves between shops, no outbox, level = sum', () async {
      answer(const Right(true));
      final r = await repo().transferStock(req);
      expect(r.isRight(), isTrue);
      verify(
        () => handler.handlePostRequest<bool>(
          'api/v1/inventory/stock/transfer/',
          any(),
          data: any(named: 'data'),
        ),
      ).called(1);
      expect((await row(kShop))!['base_quantity'], '6');
      expect((await row(kShop))!['quantity'], 6.0);
      expect((await row(other))!['base_quantity'], '4');
      expect(await f.level(kP1), 10.0);
      expect(await f.count('outbox'), 0);
    });

    test('REST failure: nothing local changes', () async {
      answer(const Left('offline'));
      final r = await repo().transferStock(req);
      expect(r.getLeft().toNullable(), 'offline');
      expect((await row(kShop))!['base_quantity'], '10');
      expect(await row(other), isNull);
      expect(await f.count('outbox'), 0);
    });
  });
}
