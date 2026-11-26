import 'package:amana_pos/common/app_progress/app_progress_cubit.dart';
import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/features/pos/data/model/pos_submit_result.dart';
import 'package:amana_pos/features/pos/domain/sale.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:amana_pos/features/pos/domain/usecases/pos_usecase.dart';
import 'package:amana_pos/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _UseCase extends Mock implements PosUseCase {}

class _FakeTax extends Fake implements TaxConfig {}

void main() {
  late _UseCase useCase;

  setUpAll(() {
    registerFallbackValue(_FakeTax());
    registerFallbackValue(<PosCartItem>[]);
    if (!getIt.isRegistered<AppProgressCubit>()) {
      getIt.registerLazySingleton<AppProgressCubit>(() => AppProgressCubit());
    }
  });

  setUp(() => useCase = _UseCase());

  final product = ProductData.fromJson(const {
    'id': 'p1',
    'name': 'Widget',
    'price': '100.00',
    'track_inventory': false,
  });

  void stub() => when(
    () => useCase.submitSale(
      shopId: any(named: 'shopId'),
      customerId: any(named: 'customerId'),
      paymentMethod: any(named: 'paymentMethod'),
      items: any(named: 'items'),
      discountAmount: any(named: 'discountAmount'),
      taxConfig: any(named: 'taxConfig'),
      payments: any(named: 'payments'),
    ),
  ).thenAnswer(
    (_) async => Right(PosSubmitResult.synced(clientSaleId: 'c1', saleId: 's1')),
  );

  Future<PosBloc> cartWith100() async {
    final bloc = PosBloc(useCase: useCase);
    addTearDown(bloc.close);
    bloc.add(PosAddProduct(product, ignoreStockLimit: true));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return bloc;
  }

  test('a confirmed split is sent as its parts and then cleared', () async {
    stub();
    final bloc = await cartWith100();
    bloc.add(const PosSplitConfirmed([
      SalePaymentPart(method: 'cash', amount: '60.00'),
      SalePaymentPart(method: 'bankak', amount: '40.00'),
    ]));
    bloc.add(const PosCheckoutSubmitted(shopId: 'shop1'));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final captured = verify(
      () => useCase.submitSale(
        shopId: any(named: 'shopId'),
        customerId: any(named: 'customerId'),
        paymentMethod: 'split',
        items: any(named: 'items'),
        discountAmount: any(named: 'discountAmount'),
        taxConfig: any(named: 'taxConfig'),
        payments: captureAny(named: 'payments'),
      ),
    ).captured.single as List<SalePaymentPart>;
    expect([for (final p in captured) '${p.method}:${p.amount}'], [
      'cash:60.00',
      'bankak:40.00',
    ]);
    expect(bloc.state.submitStatus, PosSubmitStatus.success);
    expect(bloc.state.paymentMethod, 'cash');
    expect(bloc.state.splitParts, isEmpty);
    expect(bloc.state.lastPaymentMethod, 'split');
    expect(bloc.state.lastSplitParts.length, 2);
  });

  test('a split that no longer matches the cart is refused, nothing saved', () async {
    stub();
    final bloc = await cartWith100();
    bloc.add(const PosSplitConfirmed([
      SalePaymentPart(method: 'cash', amount: '60.00'),
      SalePaymentPart(method: 'bankak', amount: '30.00'),
    ]));
    bloc.add(const PosCheckoutSubmitted(shopId: 'shop1'));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(bloc.state.submitStatus, PosSubmitStatus.failure);
    verifyNever(
      () => useCase.submitSale(
        shopId: any(named: 'shopId'),
        customerId: any(named: 'customerId'),
        paymentMethod: any(named: 'paymentMethod'),
        items: any(named: 'items'),
        discountAmount: any(named: 'discountAmount'),
        taxConfig: any(named: 'taxConfig'),
        payments: any(named: 'payments'),
      ),
    );
  });

  test('one filled row is saved as that single method', () async {
    stub();
    final bloc = await cartWith100();
    bloc.add(const PosSplitConfirmed([
      SalePaymentPart(method: 'bankak', amount: '100.00'),
    ]));
    bloc.add(const PosCheckoutSubmitted(shopId: 'shop1'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(bloc.state.lastPaymentMethod, 'bankak');
    verify(
      () => useCase.submitSale(
        shopId: any(named: 'shopId'),
        customerId: any(named: 'customerId'),
        paymentMethod: 'bankak',
        items: any(named: 'items'),
        discountAmount: any(named: 'discountAmount'),
        taxConfig: any(named: 'taxConfig'),
        payments: any(named: 'payments'),
      ),
    ).called(1);
  });

  test('picking cash or bankak drops the split parts', () async {
    final bloc = PosBloc(useCase: useCase);
    addTearDown(bloc.close);
    bloc.add(const PosSplitConfirmed([
      SalePaymentPart(method: 'cash', amount: '1.00'),
    ]));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    bloc.add(const PosPaymentMethodChanged('bankak'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.splitParts, isEmpty);
  });

  group('on account', () {
    test('credit without a customer is refused, nothing submitted', () async {
      stub();
      final bloc = await cartWith100();
      bloc.add(const PosPaymentMethodChanged('credit'));
      bloc.add(const PosCheckoutSubmitted(shopId: 'shop1'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(bloc.state.submitStatus, PosSubmitStatus.failure);
      verifyNever(
        () => useCase.submitSale(
          shopId: any(named: 'shopId'),
          customerId: any(named: 'customerId'),
          paymentMethod: any(named: 'paymentMethod'),
          items: any(named: 'items'),
          discountAmount: any(named: 'discountAmount'),
          taxConfig: any(named: 'taxConfig'),
          payments: any(named: 'payments'),
        ),
      );
    });

    test('credit with a customer sends the customer and clears the ticket', () async {
      stub();
      final bloc = await cartWith100();
      bloc.add(const PosCustomerSelected(id: 'c1', name: 'Sara'));
      bloc.add(const PosPaymentMethodChanged('credit'));
      bloc.add(const PosCheckoutSubmitted(shopId: 'shop1'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      verify(
        () => useCase.submitSale(
          shopId: any(named: 'shopId'),
          customerId: 'c1',
          paymentMethod: 'credit',
          items: any(named: 'items'),
          discountAmount: any(named: 'discountAmount'),
          taxConfig: any(named: 'taxConfig'),
          payments: any(named: 'payments'),
        ),
      ).called(1);
      expect(bloc.state.customerId, isNull);
      expect(bloc.state.paymentMethod, 'cash');
      expect(bloc.state.lastPaymentMethod, 'credit');
    });

    test('removing the customer drops On account back to cash', () async {
      final bloc = PosBloc(useCase: useCase);
      addTearDown(bloc.close);
      bloc.add(const PosCustomerSelected(id: 'c1', name: 'Sara'));
      bloc.add(const PosPaymentMethodChanged('credit'));
      bloc.add(const PosCustomerCleared());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.customerId, isNull);
      expect(bloc.state.paymentMethod, 'cash');
    });

    test('removing the customer drops a split that has an account part', () async {
      final bloc = PosBloc(useCase: useCase);
      addTearDown(bloc.close);
      bloc.add(const PosCustomerSelected(id: 'c1', name: 'Sara'));
      bloc.add(const PosSplitConfirmed([
        SalePaymentPart(method: 'cash', amount: '1.00'),
        SalePaymentPart(method: 'credit', amount: '1.00'),
      ]));
      bloc.add(const PosCustomerCleared());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.paymentMethod, 'cash');
      expect(bloc.state.splitParts, isEmpty);
    });

    test('a cash sale keeps an optional customer', () async {
      stub();
      final bloc = await cartWith100();
      bloc.add(const PosCustomerSelected(id: 'c1', name: 'Sara'));
      bloc.add(const PosCheckoutSubmitted(shopId: 'shop1'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      verify(
        () => useCase.submitSale(
          shopId: any(named: 'shopId'),
          customerId: 'c1',
          paymentMethod: 'cash',
          items: any(named: 'items'),
          discountAmount: any(named: 'discountAmount'),
          taxConfig: any(named: 'taxConfig'),
          payments: any(named: 'payments'),
        ),
      ).called(1);
    });
  });
}
