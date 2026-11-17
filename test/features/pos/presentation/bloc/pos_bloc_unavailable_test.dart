// Fix-wave I2: a cart line whose product was merged away, discarded or
// deleted since it was added is dropped (with a notice) at checkout and
// whenever the products table changes; it never reaches SaleService.
import 'dart:async';

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

class _MockPosUseCase extends Mock implements PosUseCase {}

class _FakeTaxConfig extends Fake implements TaxConfig {}

ProductData _p(String id, String name) => ProductData.fromJson({
  'id': id,
  'name': name,
  'price': '5.00',
  'track_inventory': false,
});

void main() {
  late _MockPosUseCase useCase;
  late Set<String> gone;
  late StreamController<Set<String>> changes;
  late List<Set<String>> asked;

  setUpAll(() {
    registerFallbackValue(_FakeTaxConfig());
    registerFallbackValue(<PosCartItem>[]);
    if (!getIt.isRegistered<AppProgressCubit>()) {
      getIt.registerLazySingleton<AppProgressCubit>(() => AppProgressCubit());
    }
  });

  tearDownAll(() async => getIt.reset());

  setUp(() {
    useCase = _MockPosUseCase();
    gone = {};
    asked = [];
    changes = StreamController<Set<String>>.broadcast();
  });

  tearDown(() => changes.close());

  PosBloc build() => PosBloc(
    useCase: useCase,
    changes: changes.stream,
    unavailableProducts: (ids) async {
      asked.add(ids);
      return ids.intersection(gone);
    },
  );

  void stubSubmit({Object? error}) {
    when(
      () => useCase.submitSale(
        shopId: any(named: 'shopId'),
        customerId: any(named: 'customerId'),
        paymentMethod: any(named: 'paymentMethod'),
        items: any(named: 'items'),
        discountAmount: any(named: 'discountAmount'),
        taxConfig: any(named: 'taxConfig'),
      ),
    ).thenAnswer((_) async {
      if (error != null) throw error;
      return Right(
        PosSubmitResult.localSaved(
          saleId: 's1',
          receiptNumber: 'L-1',
          taxAmount: '0.00',
          taxRate: '0',
          taxInclusive: false,
          netAmount: '5.00',
        ),
      );
    });
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  test('checkout refuses a line whose product is gone: it is dropped with a '
      'notice and nothing is submitted', () async {
    stubSubmit();
    final bloc = build();
    bloc
      ..add(PosAddProduct(_p('a', 'Juice')))
      ..add(PosAddProduct(_p('b', 'Tea')))
      ..add(const PosAddCustomAmount(amount: 2, note: 'Tip'));
    await settle();
    gone = {'a'};
    bloc.add(const PosCheckoutSubmitted(shopId: 'shop'));
    await settle();

    expect(bloc.state.submitStatus, PosSubmitStatus.failure);
    expect(bloc.state.removedUnavailable, ['Juice']);
    expect(bloc.state.items.map((i) => i.product.name), ['Tea', 'Tip']);
    verifyNever(
      () => useCase.submitSale(
        shopId: any(named: 'shopId'),
        customerId: any(named: 'customerId'),
        paymentMethod: any(named: 'paymentMethod'),
        items: any(named: 'items'),
        discountAmount: any(named: 'discountAmount'),
        taxConfig: any(named: 'taxConfig'),
      ),
    );
    expect(asked.last, {'a', 'b'}, reason: 'custom lines are not checked');
    await bloc.close();
  });

  test('the SaleService backstop (product removed between the check and the '
      'write) is handled the same way', () async {
    stubSubmit(error: const SaleProductUnavailableException({'b'}));
    final bloc = build();
    bloc
      ..add(PosAddProduct(_p('a', 'Juice')))
      ..add(PosAddProduct(_p('b', 'Tea')));
    await settle();
    bloc.add(const PosCheckoutSubmitted(shopId: 'shop'));
    await settle();
    expect(bloc.state.submitStatus, PosSubmitStatus.failure);
    expect(bloc.state.removedUnavailable, ['Tea']);
    expect(bloc.state.items.map((i) => i.product.id), ['a']);
    await bloc.close();
  });

  test('a products change prunes the open cart and reports the names', () async {
    final bloc = build();
    bloc
      ..add(PosAddProduct(_p('a', 'Juice')))
      ..add(PosAddProduct(_p('b', 'Tea')));
    await settle();
    gone = {'a'};
    changes.add({'customers'});
    await settle();
    expect(bloc.state.items, hasLength(2), reason: 'unrelated table');
    changes.add({'products', 'outbox'});
    await settle();
    expect(bloc.state.items.map((i) => i.product.id), ['b']);
    expect(bloc.state.removedUnavailable, ['Juice']);
    expect(bloc.state.submitStatus, PosSubmitStatus.idle);
    bloc.add(const PosAcknowledgeSubmit());
    await settle();
    expect(bloc.state.removedUnavailable, isEmpty);
    await bloc.close();
  });

  test('an empty cart is never checked', () async {
    final bloc = build();
    changes.add({'products'});
    await settle();
    expect(asked, isEmpty);
    await bloc.close();
  });
}
