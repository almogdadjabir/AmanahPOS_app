import 'dart:convert';

import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/features/inventory/data/models/responses/add_stock_response_dto.dart';
import 'package:amana_pos/features/inventory/data/repository_impl/inventory_repo_impl.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:amana_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:amana_pos/features/inventory/presentation/update_stock_screen.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

class _Handler extends Mock implements RequestHandler {}

void main() {
  late SaleFixture f;
  late _Handler handler;
  late InventoryBloc bloc;
  late bool online;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    handler = _Handler();
    online = true;
    final repo = InventoryRepoImpl(
      handler,
      stockService: () => StockService(
        writer: f.writer,
        actor: () => const StockActor(
          businessType: AppBusinessType.shop,
          role: AppUserRole.manager,
          shopId: kShop,
        ),
        now: () => f.clock,
      ),
    );
    bloc = InventoryBloc(
      useCase: InventoryUseCase(repository: repo),
      offlineLocalCache: OfflineLocalCache(f.odb),
      isOnline: () async => online,
    );
  });

  tearDown(() async {
    await bloc.close();
    f.notifier.dispose();
    await f.db.close();
  });

  Future<InventoryState> settle() => bloc.stream.firstWhere(
    (s) =>
        s.submitStatus == InventorySubmitStatus.success ||
        s.submitStatus == InventorySubmitStatus.failure,
  );

  Future<double> qty() async =>
      ((await f.stock(kP1))['quantity'] as num).toDouble();

  Future<List<Map<String, dynamic>>> stockRows() async => [
    for (final r in await f.db.query(
      'outbox',
      where: "entity = 'stock'",
      orderBy: 'seq',
    ))
      {
        'op': r['op'],
        ...jsonDecode(r['payload_json'] as String) as Map<String, dynamic>,
      },
  ];

  group('remove (I1)', () {
    test('remove after a local sale lowers stock by exactly q and sends '
        'stock.remove with the positive magnitude', () async {
      // The inventory list was loaded with 10; the POS then sells 3.
      await f.service().createSale(
        const SaleDraft(
          shopId: kShop,
          paymentMethod: 'cash',
          lines: [
            SaleDraftLine.product(
              productId: kP1,
              productName: 'Tea',
              quantity: '3',
              unitPrice: '2.50',
            ),
          ],
        ),
      );
      expect(await qty(), 7.0);

      bloc.add(
        const OnRemoveStock(
          productId: kP1,
          shopId: kShop,
          quantity: '1',
          reason: 'broken',
        ),
      );
      final s = await settle();
      expect(s.submitStatus, InventorySubmitStatus.success);
      expect(await qty(), 6.0);
      final rows = await stockRows();
      expect(rows, hasLength(1));
      expect(rows.single['op'], 'remove');
      expect(rows.single['delta'], '1');
      expect(rows.single['reason'], 'broken');
    });

    test('raw entered text keeps 3 decimals (0.125 stays 0.125)', () async {
      bloc.add(
        OnRemoveStock(
          productId: kP1,
          shopId: kShop,
          quantity: enteredQtyText(' 0,125 '),
        ),
      );
      await settle();
      expect((await stockRows()).single['delta'], '0.125');
      expect(await qty(), 9.875);
    });
  });

  test('add: raw 0.125 is sent as 0.125 (never rounded)', () async {
    bloc.add(
      OnAddStock(
        productId: kP1,
        shopId: kShop,
        quantity: enteredQtyText('0.125'),
      ),
    );
    await settle();
    final row = (await stockRows()).single;
    expect(row['op'], 'add');
    expect(row['delta'], '0.125');
    expect(await qty(), 10.125);
  });

  test('enteredQtyText trims and accepts a comma decimal separator', () {
    expect(enteredQtyText(' 1,5 '), '1.5');
    expect(enteredQtyText('0.125'), '0.125');
  });

  group('add with expiry (I2)', () {
    test('offline: refused with expiryNeedsConnection, nothing written, no '
        'network', () async {
      online = false;
      bloc.add(
        const OnAddStock(
          productId: kP1,
          shopId: kShop,
          quantity: '2',
          expiryDate: '2027-01-01',
        ),
      );
      final s = await settle();
      expect(s.submitStatus, InventorySubmitStatus.failure);
      expect(s.expiryNeedsConnection, isTrue);
      expect(await f.count('outbox'), 0);
      expect(await qty(), 10.0);
      verifyZeroInteractions(handler);
    });

    test('online: the legacy REST add (creates the batch) is used; no outbox '
        'row; local base raised by exactly q', () async {
      when(
        () => handler.handlePostRequest<AddStockResponseDto>(
          any(),
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => Right(AddStockResponseDto(success: true)));
      bloc.add(
        const OnAddStock(
          productId: kP1,
          shopId: kShop,
          quantity: '2.5',
          expiryDate: '2027-01-01',
        ),
      );
      final s = await settle();
      expect(s.submitStatus, InventorySubmitStatus.success);
      final captured = verify(
        () => handler.handlePostRequest<AddStockResponseDto>(
          'api/v1/inventory/stock/add/',
          any(),
          data: captureAny(named: 'data'),
        ),
      ).captured;
      expect((captured.single as Map)['expiry_date'], '2027-01-01');
      expect(await f.count('outbox'), 0);
      expect(await qty(), 12.5);
      expect((await f.stock(kP1))['base_quantity'], '12.5');
    });

    test('online REST failure: nothing changes locally', () async {
      when(
        () => handler.handlePostRequest<AddStockResponseDto>(
          any(),
          any(),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => const Left('server says no'));
      bloc.add(
        const OnAddStock(
          productId: kP1,
          shopId: kShop,
          quantity: '2',
          expiryDate: '2027-01-01',
        ),
      );
      final s = await settle();
      expect(s.submitStatus, InventorySubmitStatus.failure);
      expect(s.submitError, 'server says no');
      expect(s.expiryNeedsConnection, isFalse);
      expect(await qty(), 10.0);
      expect((await f.stock(kP1))['base_quantity'], '10');
    });
  });
}
