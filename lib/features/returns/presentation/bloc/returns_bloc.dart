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
    on<ReturnsSearchChanged>(_onSearchChanged);
    on<ReturnsSaleSelected>(_onSaleSelected);
    on<ReturnsItemToggled>(_onItemToggled);
    on<ReturnsQuantityChanged>(_onQuantityChanged);
    on<ReturnsAllToggled>(_onAllToggled);
    on<ReturnsSubmitted>(_onSubmitted);
    on<ReturnsReset>(_onReset);
    on<ReturnsPreloadSale>(_onPreloadSale);
  }

  Future<void> _onSearchChanged(
      ReturnsSearchChanged event, Emitter<ReturnsState> emit) async {
    emit(state.copyWith(
      searchQuery: event.query,
      searchStatus: event.query.trim().isEmpty
          ? ReturnsSearchStatus.idle
          : ReturnsSearchStatus.loading,
      searchResults: [],
    ));

    if (event.query.trim().isEmpty) return;

    final result =
        await _useCase.searchSales(query: event.query.trim());

    result.fold(
      (error) => emit(state.copyWith(
        searchStatus: ReturnsSearchStatus.failure,
        errorMessage: error ?? 'Search failed',
      )),
      (page) => emit(state.copyWith(
        searchResults: page.items,
        searchStatus: ReturnsSearchStatus.success,
      )),
    );
  }

  void _onSaleSelected(ReturnsSaleSelected event, Emitter<ReturnsState> emit) {
    // Default: all items selected at original quantity
    final selectedItems = {
      for (final item in event.sale.items)
        item.productId: item.quantity.toInt(),
    };
    emit(state.copyWith(
      selectedSale: event.sale,
      selectedItems: selectedItems,
    ));
  }

  void _onItemToggled(ReturnsItemToggled event, Emitter<ReturnsState> emit) {
    final updated = Map<String, int>.from(state.selectedItems);
    if (updated.containsKey(event.productId)) {
      updated.remove(event.productId);
    } else {
      // Find original quantity and default to it
      final original = state.selectedSale?.items
          .firstWhere((i) => i.productId == event.productId,
              orElse: () => SaleHistoryLineItem(
                  productId: '', productName: '', quantity: 1,
                  unitPrice: 0, subtotal: 0))
          .quantity
          .toInt() ?? 1;
      updated[event.productId] = original;
    }
    emit(state.copyWith(selectedItems: updated));
  }

  void _onQuantityChanged(
      ReturnsQuantityChanged event, Emitter<ReturnsState> emit) {
    final updated = Map<String, int>.from(state.selectedItems);
    if (event.quantity <= 0) {
      updated.remove(event.productId);
    } else {
      updated[event.productId] = event.quantity;
    }
    emit(state.copyWith(selectedItems: updated));
  }

  void _onAllToggled(ReturnsAllToggled event, Emitter<ReturnsState> emit) {
    final sale = state.selectedSale;
    if (sale == null) return;

    if (state.selectedItems.length == sale.items.length) {
      // Deselect all
      emit(state.copyWith(selectedItems: {}));
    } else {
      // Select all at original quantities
      final all = {
        for (final item in sale.items) item.productId: item.quantity.toInt(),
      };
      emit(state.copyWith(selectedItems: all));
    }
  }

  Future<void> _onSubmitted(
      ReturnsSubmitted event, Emitter<ReturnsState> emit) async {
    final sale = state.selectedSale;
    if (sale == null || sale.id == null) return;
    if (state.selectedItems.isEmpty) return;

    emit(state.copyWith(submitStatus: ReturnsSubmitStatus.loading));

    final items = state.selectedItems.entries
        .map((e) => RefundItemDto(productId: e.key, quantity: e.value))
        .toList();

    final result = await _useCase.processRefund(
      saleId: sale.id!,
      request: RefundRequestDto(items: items, notes: event.notes),
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

  void _onReset(ReturnsReset event, Emitter<ReturnsState> emit) {
    emit(ReturnsState.initial());
  }

  void _onPreloadSale(ReturnsPreloadSale event, Emitter<ReturnsState> emit) {
    final selectedItems = {
      for (final item in event.sale.items)
        item.productId: item.quantity.toInt(),
    };
    emit(state.copyWith(
      selectedSale: event.sale,
      selectedItems: selectedItems,
    ));
  }
}
