import 'package:amana_pos/common/app_progress/app_progress_cubit.dart';
import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/features/pos/data/model/pos_submit_result.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:amana_pos/features/pos/domain/usecases/pos_usecase.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPosUseCase extends Mock implements PosUseCase {}

class _FakeTaxConfig extends Fake implements TaxConfig {}

void main() {
  late MockPosUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(_FakeTaxConfig());
    // Fallback for List<PosCartItem> used in submitSale's `items` param.
    registerFallbackValue(<PosCartItem>[]);
    // Register a real AppProgressCubit in getIt so that the bloc's
    // `getIt<AppProgressCubit>().run(...)` call resolves correctly.
    if (!getIt.isRegistered<AppProgressCubit>()) {
      getIt.registerLazySingleton<AppProgressCubit>(() => AppProgressCubit());
    }
  });

  tearDownAll(() async {
    await getIt.reset();
  });

  setUp(() {
    mockUseCase = MockPosUseCase();
  });

  final product = ProductData.fromJson(const {
    'id': 'p1',
    'name': 'Widget',
    'price': '90.00',
    'track_inventory': false,
  });

  const taxConfig = TaxConfig(
    enabled: true,
    name: 'VAT',
    rate: 15,
    inclusive: false,
  );

  PosBloc buildBloc() => PosBloc(useCase: mockUseCase);

  group('receipt snapshot — server/preview fallback', () {
    test('online sale prefers server values', () async {
      when(() => mockUseCase.submitSale(
            shopId: any(named: 'shopId'),
            customerId: any(named: 'customerId'),
            paymentMethod: any(named: 'paymentMethod'),
            items: any(named: 'items'),
            discountAmount: any(named: 'discountAmount'),
            taxConfig: any(named: 'taxConfig'),
          )).thenAnswer(
        (_) async => Right(
          PosSubmitResult.synced(
            clientSaleId: 'c1',
            saleId: 's1',
            receiptNumber: 'REC1',
            taxAmount: '13.49',
            taxRate: '15.00',
            taxInclusive: false,
            netAmount: '103.49',
          ),
        ),
      );

      final bloc = buildBloc();
      addTearDown(bloc.close);

      // Seed tax config
      bloc.add(const PosTaxConfigChanged(taxConfig));
      await Future.microtask(() {});

      // Add product
      bloc.add(PosAddProduct(product, ignoreStockLimit: true));
      await Future.microtask(() {});

      // Submit checkout
      bloc.add(const PosCheckoutSubmitted(shopId: 'shop1'));
      // Wait for async work to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = bloc.state;
      expect(state.submitStatus, PosSubmitStatus.success,
          reason: 'submit should succeed');
      expect(state.lastTaxAmount, closeTo(13.49, 0.001),
          reason: 'server tax amount used');
      expect(state.lastTotal, closeTo(103.49, 0.001),
          reason: 'server net amount used');
      expect(state.lastSubtotal, closeTo(90.00, 0.001),
          reason: 'subtotal = net - tax (exclusive mode)');
      expect(state.lastTaxRate, closeTo(15.0, 0.001),
          reason: 'server tax rate used');
      expect(state.lastTaxInclusive, isFalse,
          reason: 'server tax inclusive flag used');
      expect(state.lastSaleWasOffline, isFalse,
          reason: 'online sale flag correct');
    });

    test('offline-queued sale falls back to local preview', () async {
      when(() => mockUseCase.submitSale(
            shopId: any(named: 'shopId'),
            customerId: any(named: 'customerId'),
            paymentMethod: any(named: 'paymentMethod'),
            items: any(named: 'items'),
            discountAmount: any(named: 'discountAmount'),
            taxConfig: any(named: 'taxConfig'),
          )).thenAnswer(
        (_) async => Right(PosSubmitResult.offlineQueued('c1')),
      );

      final bloc = buildBloc();
      addTearDown(bloc.close);

      // Seed tax config
      bloc.add(const PosTaxConfigChanged(taxConfig));
      await Future.microtask(() {});

      // Add product
      bloc.add(PosAddProduct(product, ignoreStockLimit: true));
      await Future.microtask(() {});

      // Submit checkout
      bloc.add(const PosCheckoutSubmitted(shopId: 'shop1'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = bloc.state;
      expect(state.submitStatus, PosSubmitStatus.success,
          reason: 'submit should succeed (queued)');
      // Local preview: 90.00 * 15% = 13.50 (exclusive)
      expect(state.lastTaxAmount, closeTo(13.50, 0.001),
          reason: 'local preview tax amount used');
      expect(state.lastTotal, closeTo(103.50, 0.001),
          reason: 'local preview total used');
      expect(state.lastSubtotal, closeTo(90.00, 0.001),
          reason: 'local subtotal preserved');
      expect(state.lastTaxRate, closeTo(15.0, 0.001),
          reason: 'local tax rate from config used');
      expect(state.lastSaleWasOffline, isTrue,
          reason: 'offline flag set');
    });
  });
}
