import 'package:amana_pos/features/returns/data/models/requests/refund_request_dto.dart';
import 'package:amana_pos/features/returns/data/models/responses/refund_response_dto.dart';
import 'package:amana_pos/features/returns/domain/usecases/returns_usecase.dart';
import 'package:amana_pos/features/returns/presentation/bloc/returns_bloc.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockUseCase extends Mock implements ReturnsUseCase {}

class _FakeRequest extends Fake implements RefundRequestDto {}

SaleHistoryItem _sale() => SaleHistoryItem(
  id: 's1',
  clientSaleId: 'c1',
  receiptNumber: 'AM-1',
  shopId: null,
  shopName: null,
  customerId: null,
  customerName: null,
  paymentMethod: 'cash',
  total: 48000,
  itemCount: 3,
  status: SaleHistoryStatus.partialRefund,
  createdAt: DateTime(2026, 11, 15),
  isOfflinePending: false,
  offlineErrorMessage: null,
  items: const [
    SaleHistoryLineItem(
      lineId: 'oil',
      productId: 'p1',
      productName: 'Oil',
      quantity: 2,
      unitPrice: 19000,
      subtotal: 38000,
      returnedQuantity: 1,
    ),
    SaleHistoryLineItem(
      lineId: 'tomato',
      productId: 'p2',
      productName: 'Tomatoes',
      quantity: 2.5,
      unitPrice: 4000,
      subtotal: 10000,
    ),
    SaleHistoryLineItem(
      lineId: 'done',
      productId: 'p3',
      productName: 'Water',
      quantity: 1,
      unitPrice: 500,
      subtotal: 500,
      returnedQuantity: 1,
    ),
  ],
);

void main() {
  late _MockUseCase useCase;
  late ReturnsBloc bloc;

  setUpAll(() => registerFallbackValue(_FakeRequest()));

  setUp(() {
    useCase = _MockUseCase();
    bloc = ReturnsBloc(useCase: useCase)..add(ReturnsStarted(_sale()));
  });

  tearDown(() => bloc.close());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('starts with nothing selected', () async {
    await settle();
    expect(bloc.state.sale, isNotNull);
    expect(bloc.state.selected, isEmpty);
    expect(bloc.state.hasSelection, isFalse);
  });

  test(
    'toggling a line selects what is left to return, again clears it',
    () async {
      await settle();
      bloc.add(const ReturnsLineToggled('oil'));
      await settle();
      expect(bloc.state.selected, {'oil': 1.0});
      bloc.add(const ReturnsLineToggled('tomato'));
      await settle();
      expect(bloc.state.selected['tomato'], 2.5);
      bloc.add(const ReturnsLineToggled('oil'));
      await settle();
      expect(bloc.state.selected.keys, ['tomato']);
    },
  );

  test('a fully returned line cannot be selected', () async {
    await settle();
    bloc.add(const ReturnsLineToggled('done'));
    await settle();
    expect(bloc.state.selected, isEmpty);
  });

  test('quantity is clamped to what is left and 0 clears the line', () async {
    await settle();
    bloc.add(const ReturnsLineToggled('tomato'));
    bloc.add(const ReturnsQuantityChanged('tomato', 99));
    await settle();
    expect(bloc.state.selected['tomato'], 2.5);
    bloc.add(const ReturnsQuantityChanged('tomato', 1.5));
    await settle();
    expect(bloc.state.selected['tomato'], 1.5);
    bloc.add(const ReturnsQuantityChanged('tomato', 0));
    await settle();
    expect(bloc.state.selected, isEmpty);
  });

  test(
    'allSelected only counts lines that still have something left',
    () async {
      await settle();
      bloc.add(const ReturnsAllToggled());
      await settle();
      expect(bloc.state.selected.keys.toSet(), {'oil', 'tomato'});
      expect(bloc.state.allSelected, isTrue);
      bloc.add(const ReturnsAllToggled());
      await settle();
      expect(bloc.state.selected, isEmpty);
    },
  );

  test('refundTotal is unit price times the chosen quantity', () async {
    await settle();
    bloc.add(const ReturnsLineToggled('oil'));
    bloc.add(const ReturnsLineToggled('tomato'));
    bloc.add(const ReturnsQuantityChanged('tomato', 1.5));
    await settle();
    expect(bloc.state.refundTotal, 19000 + 6000);
  });

  test(
    'submit sends item_id lines with double quantities and the note',
    () async {
      when(
        () => useCase.processRefund(
          saleId: any(named: 'saleId'),
          request: any(named: 'request'),
        ),
      ).thenAnswer(
        (_) async => Right(
          RefundResponseDto.fromJson({
            'success': true,
            'refund_reference': 'AM-1-R2',
            'refund_total': '25000.00',
          }),
        ),
      );

      await settle();
      bloc.add(const ReturnsLineToggled('oil'));
      bloc.add(const ReturnsLineToggled('tomato'));
      bloc.add(const ReturnsQuantityChanged('tomato', 1.5));
      bloc.add(const ReturnsSubmitted(notes: 'damaged'));
      await settle();
      await settle();

      final req =
          verify(
                () => useCase.processRefund(
                  saleId: 's1',
                  request: captureAny(named: 'request'),
                ),
              ).captured.single
              as RefundRequestDto;
      expect(req.notes, 'damaged');
      expect(
        {for (final i in req.items) i.itemId: i.quantity},
        {'oil': 1.0, 'tomato': 1.5},
      );
      expect(bloc.state.submitStatus, ReturnsSubmitStatus.success);
      expect(bloc.state.refundResult?.safeRefundReference, 'AM-1-R2');
    },
  );

  test('a failed refund keeps the selection and reports the failure', () async {
    when(
      () => useCase.processRefund(
        saleId: any(named: 'saleId'),
        request: any(named: 'request'),
      ),
    ).thenAnswer((_) async => const Left('nope'));
    await settle();
    bloc.add(const ReturnsLineToggled('oil'));
    bloc.add(const ReturnsSubmitted());
    await settle();
    await settle();
    expect(bloc.state.submitStatus, ReturnsSubmitStatus.failure);
    expect(bloc.state.selected, {'oil': 1.0});
  });
}
