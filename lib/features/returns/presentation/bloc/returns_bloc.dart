import 'package:amana_pos/features/returns/data/models/requests/refund_request_dto.dart';
import 'package:amana_pos/features/returns/data/models/responses/refund_response_dto.dart';
import 'package:amana_pos/features/returns/domain/usecases/returns_usecase.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'returns_event.dart';
part 'returns_state.dart';

class ReturnsBloc extends Bloc<ReturnsEvent, ReturnsState> {
  final ReturnsUseCase _useCase;

  ReturnsBloc({required ReturnsUseCase useCase})
      : _useCase = useCase,
        super(ReturnsState.initial()) {
    on<ReturnsStarted>(_onStarted);
    on<ReturnsLineToggled>(_onLineToggled);
    on<ReturnsQuantityChanged>(_onQuantityChanged);
    on<ReturnsAllToggled>(_onAllToggled);
    on<ReturnsSubmitted>(_onSubmitted);
    on<ReturnsReset>(_onReset);
  }

  void _onStarted(ReturnsStarted event, Emitter<ReturnsState> emit) {
    emit(ReturnsState.initial().copyWith(sale: event.sale));
  }

  void _onLineToggled(ReturnsLineToggled event, Emitter<ReturnsState> emit) {
    final line = state.lineById(event.lineId);
    if (line == null || line.returnableQuantity <= 0) return;
    final next = Map<String, double>.from(state.selected);
    if (next.containsKey(event.lineId)) {
      next.remove(event.lineId);
    } else {
      next[event.lineId] = line.returnableQuantity;
    }
    emit(state.copyWith(selected: next));
  }

  void _onQuantityChanged(
    ReturnsQuantityChanged event,
    Emitter<ReturnsState> emit,
  ) {
    final line = state.lineById(event.lineId);
    if (line == null) return;
    final next = Map<String, double>.from(state.selected);
    final q = double.parse(
      event.quantity.clamp(0, line.returnableQuantity).toStringAsFixed(3),
    );
    if (q <= 0) {
      next.remove(event.lineId);
    } else {
      next[event.lineId] = q;
    }
    emit(state.copyWith(selected: next));
  }

  void _onAllToggled(ReturnsAllToggled event, Emitter<ReturnsState> emit) {
    if (state.allSelected) {
      emit(state.copyWith(selected: {}));
      return;
    }
    emit(state.copyWith(selected: {
      for (final l in state.returnableLines) l.lineId: l.returnableQuantity,
    }));
  }

  Future<void> _onSubmitted(
    ReturnsSubmitted event,
    Emitter<ReturnsState> emit,
  ) async {
    final sale = state.sale;
    if (sale == null || sale.id == null || !state.hasSelection) return;
    if (state.submitStatus == ReturnsSubmitStatus.loading) return;

    emit(state.copyWith(submitStatus: ReturnsSubmitStatus.loading));

    final items = [
      for (final e in state.selected.entries)
        RefundItemDto(itemId: e.key, quantity: e.value),
    ];

    final result = await _useCase.processRefund(
      saleId: sale.id!,
      request: RefundRequestDto(
        items: items,
        notes: event.notes,
        method: _methodFor(sale.paymentMethod),
      ),
    );

    result.fold(
      (error) => emit(state.copyWith(
        submitStatus: ReturnsSubmitStatus.failure,
        errorMessage: error ?? 'Refund failed',
      )),
      (response) => emit(state.copyWith(
        submitStatus: ReturnsSubmitStatus.success,
        refundResult: response,
      )),
    );
  }

  /// The sale's own method when it was a single one, else cash.
  static String _methodFor(String paymentMethod) =>
      const {'cash', 'bankak', 'card', 'bank_transfer', 'mobile_wallet'}
              .contains(paymentMethod)
          ? paymentMethod
          : 'cash';

  void _onReset(ReturnsReset event, Emitter<ReturnsState> emit) {
    emit(ReturnsState.initial());
  }
}
