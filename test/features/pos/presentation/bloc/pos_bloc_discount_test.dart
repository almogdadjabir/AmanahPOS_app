import 'package:amana_pos/common/app_progress/app_progress_cubit.dart';
import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/features/pos/data/model/pos_submit_result.dart';
import 'package:amana_pos/features/pos/domain/cart_discount.dart';
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


  test('line discount lowers the line, the sale and the tax base', () async {
    final bloc = await cartWith100();
    bloc.add(PosAddProduct(product, ignoreStockLimit: true)); // 2 x 100
    bloc.add(const PosLineDiscountSet('p1', CartDiscount.percent('10')));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final s = bloc.state;
    expect(s.grossSubtotal, 200.0);
    expect(s.lineDiscountTotal, 20.0);
    expect(s.subtotal, 180.0);
    expect(s.total, 180.0);
  });

  test('a percent line discount follows the quantity', () async {
    final bloc = await cartWith100();
    bloc.add(const PosLineDiscountSet('p1', CartDiscount.percent('10')));
    bloc.add(const PosIncrementItem('p1', ignoreStockLimit: true));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.subtotal, 180.0);
  });

  test('an amount line discount is cut when the quantity drops', () async {
    final bloc = await cartWith100();
    bloc.add(const PosIncrementItem('p1', ignoreStockLimit: true));
    bloc.add(const PosLineDiscountSet('p1', CartDiscount.amount('150')));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.subtotal, 50.0);
    bloc.add(const PosDecrementItem('p1'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.subtotal, 0.0); // 100 - min(150, 100)
  });

  test('sale discount comes after line discounts and before tax', () async {
    final bloc = await cartWith100();
    bloc.add(const PosLineDiscountSet('p1', CartDiscount.amount('20'))); // 80
    bloc.add(const PosSaleDiscountSet(CartDiscount.percent('50'))); // 40
    bloc.add(const PosTaxConfigChanged(
      TaxConfig(enabled: true, rate: 10, name: 'VAT', inclusive: false),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final s = bloc.state;
    expect(s.saleDiscountAmount, 40.0);
    expect(s.taxable, 40.0);
    expect(s.taxAmount, 4.0);
    expect(s.total, 44.0);
  });

  test('checkout sends the line and the sale discount, then forgets them',
      () async {
    stub();
    final bloc = await cartWith100();
    bloc.add(const PosLineDiscountSet('p1', CartDiscount.amount('10')));
    bloc.add(const PosSaleDiscountSet(CartDiscount.percent('10'))); // 9.00
    bloc.add(const PosCheckoutSubmitted(shopId: 'shop1'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final v = verify(
      () => useCase.submitSale(
        shopId: any(named: 'shopId'),
        customerId: any(named: 'customerId'),
        paymentMethod: any(named: 'paymentMethod'),
        items: captureAny(named: 'items'),
        discountAmount: captureAny(named: 'discountAmount'),
        taxConfig: any(named: 'taxConfig'),
        payments: any(named: 'payments'),
      ),
    ).captured;
    expect((v[0] as List<PosCartItem>).single.discountText, '10.00');
    expect(v[1], '9.00');
    expect(bloc.state.saleDiscount, isNull);
    expect(bloc.state.items, isEmpty);
  });

  test('an empty cart drops the sale discount; remove clears a line one',
      () async {
    final bloc = await cartWith100();
    bloc.add(const PosSaleDiscountSet(CartDiscount.percent('5')));
    bloc.add(const PosDecrementItem('p1'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.saleDiscount, isNull);

    bloc.add(PosAddProduct(product, ignoreStockLimit: true));
    bloc.add(const PosLineDiscountSet('p1', CartDiscount.percent('5')));
    bloc.add(const PosLineDiscountSet('p1', null));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.items.single.discount, isNull);
  });
}
