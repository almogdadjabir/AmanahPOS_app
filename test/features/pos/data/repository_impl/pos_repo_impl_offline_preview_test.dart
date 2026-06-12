import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/features/pos/data/datasources/pos_remote_data_source.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sale_dto.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sales_queue.dart';
import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/features/pos/data/repository_impl/pos_repo_impl.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNetworkMonitor extends Mock implements NetworkMonitor {}

class MockOfflineSalesQueue extends Mock implements OfflineSalesQueue {}

class MockPosRemoteDataSource extends Mock implements PosRemoteDataSource {}

class FakeOfflineSaleDto extends Fake implements OfflineSaleDto {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeOfflineSaleDto());
  });


  late MockNetworkMonitor networkMonitor;
  late MockOfflineSalesQueue offlineSalesQueue;
  late MockPosRemoteDataSource remoteDataSource;
  late PosRepoImpl repo;

  final cartItems = [
    PosCartItem(
      product: ProductData.fromJson(const {
        'id': 'p1',
        'name': 'Widget',
        'price': '90.00',
      }),
      quantity: 1,
    ),
  ];

  setUp(() {
    networkMonitor = MockNetworkMonitor();
    offlineSalesQueue = MockOfflineSalesQueue();
    remoteDataSource = MockPosRemoteDataSource();

    when(() => networkMonitor.isOnline).thenAnswer((_) async => false);
    when(() => offlineSalesQueue.enqueueSale(any())).thenAnswer((_) async {});

    repo = PosRepoImpl(
      networkMonitor: networkMonitor,
      offlineSalesQueue: offlineSalesQueue,
      remoteDataSource: remoteDataSource,
    );
  });

  group('offline tax preview wiring', () {
    test('exclusive tax: stores subtotal, tax, and net total', () async {
      final result = await repo.submitSale(
        shopId: 'shop1',
        customerId: null,
        paymentMethod: 'cash',
        items: cartItems,
        discountAmount: '0',
        taxConfig: const TaxConfig(
          enabled: true,
          name: 'VAT',
          rate: 15,
          inclusive: false,
        ),
      );

      expect(result.isRight(), true);
      final submitResult = result.getOrElse((_) => throw Exception());
      expect(submitResult.queued, true);

      final captured = verify(
        () => offlineSalesQueue.enqueueSale(captureAny()),
      ).captured;
      final dto = captured.single as OfflineSaleDto;

      expect(dto.subtotal, '90.00');
      expect(dto.taxAmount, '13.50');
      expect(dto.total, '103.50');
    });

    test('inclusive tax: total equals subtotal minus discount', () async {
      final result = await repo.submitSale(
        shopId: 'shop1',
        customerId: null,
        paymentMethod: 'cash',
        items: cartItems,
        discountAmount: '0',
        taxConfig: const TaxConfig(
          enabled: true,
          name: 'VAT',
          rate: 15,
          inclusive: true,
        ),
      );

      expect(result.isRight(), true);
      final submitResult = result.getOrElse((_) => throw Exception());
      expect(submitResult.queued, true);

      final captured = verify(
        () => offlineSalesQueue.enqueueSale(captureAny()),
      ).captured;
      final dto = captured.single as OfflineSaleDto;

      expect(dto.subtotal, '90.00');
      expect(dto.taxAmount, '11.74');
      expect(dto.total, '90.00');
    });
  });
}
