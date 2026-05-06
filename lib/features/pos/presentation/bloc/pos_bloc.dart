import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/features/pos/domain/usecases/pos_usecase.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pos_event.dart';
part 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final PosUseCase useCase;

  PosBloc({
    required this.useCase,
  }) : super(PosState.initial()) {
    on<PosSearchChanged>(_onSearchChanged);
    on<PosCategoryChanged>(_onCategoryChanged);
    on<PosPaymentMethodChanged>(_onPaymentMethodChanged);
    on<PosAddProduct>(_onAddProduct);
    on<PosIncrementItem>(_onIncrementItem);
    on<PosDecrementItem>(_onDecrementItem);
    on<PosRemoveItem>(_onRemoveItem);
    on<PosClearCart>(_onClearCart);
    on<PosCheckoutSubmitted>(_onCheckoutSubmitted);
    on<PosAcknowledgeSubmit>(_onAcknowledgeSubmit);
    on<PosCartExpandedChanged>(_onCartExpandedChanged);
  }

  void _onSearchChanged(
      PosSearchChanged event,
      Emitter<PosState> emit,
      ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onCategoryChanged(
      PosCategoryChanged event,
      Emitter<PosState> emit,
      ) {
    emit(
      state.copyWith(
        selectedCategoryId: event.categoryId,
        clearSelectedCategory: event.categoryId == null,
      ),
    );
  }

  void _onPaymentMethodChanged(
      PosPaymentMethodChanged event,
      Emitter<PosState> emit,
      ) {
    emit(state.copyWith(paymentMethod: event.paymentMethod));
  }

  void _onAddProduct(
      PosAddProduct event,
      Emitter<PosState> emit,
      ) {
    final productId = event.product.id;
    if (productId == null) return;

    final existingIndex = state.items.indexWhere(
          (item) => item.product.id == productId,
    );

    final updated = [...state.items];

    if (existingIndex == -1) {
      updated.add(PosCartItem(product: event.product, quantity: 1));
    } else {
      final item = updated[existingIndex];
      updated[existingIndex] = item.copyWith(quantity: item.quantity + 1);
    }

    emit(state.copyWith(items: updated));
  }

  void _onIncrementItem(
      PosIncrementItem event,
      Emitter<PosState> emit,
      ) {
    final updated = state.items.map((item) {
      if (item.product.id != event.productId) return item;
      return item.copyWith(quantity: item.quantity + 1);
    }).toList();

    emit(state.copyWith(items: updated));
  }

  void _onDecrementItem(
      PosDecrementItem event,
      Emitter<PosState> emit,
      ) {
    final updated = <PosCartItem>[];

    for (final item in state.items) {
      if (item.product.id != event.productId) {
        updated.add(item);
        continue;
      }

      final nextQty = item.quantity - 1;
      if (nextQty > 0) {
        updated.add(item.copyWith(quantity: nextQty));
      }
    }

    emit(state.copyWith(items: updated));
  }

  void _onRemoveItem(
      PosRemoveItem event,
      Emitter<PosState> emit,
      ) {
    emit(
      state.copyWith(
        items: state.items
            .where((item) => item.product.id != event.productId)
            .toList(),
      ),
    );
  }

  void _onClearCart(
      PosClearCart event,
      Emitter<PosState> emit,
      ) {
    emit(state.copyWith(items: []));
  }


  Future<void> _onCheckoutSubmitted(
      PosCheckoutSubmitted event,
      Emitter<PosState> emit,
      ) async {
    if (state.items.isEmpty) return;

    emit(
      state.copyWith(
        submitStatus: PosSubmitStatus.loading,
        submitError: null,
      ),
    );

    try {
      final soldQuantities = state.currentSoldQuantities;

      final response = await useCase.submitSale(
        shopId: event.shopId,
        customerId: event.customerId,
        paymentMethod: state.paymentMethod,
        items: state.items,
        discountAmount: '0',
        taxAmount: '0',
      );

      response.fold(
            (error) {
          emit(
            state.copyWith(
              submitStatus: PosSubmitStatus.failure,
              submitError: error ?? 'Failed to submit sale',
            ),
          );
        },
            (result) {
              emit(
                state.copyWith(
                  items: [],
                  lastSoldQuantities: soldQuantities,
                  cartExpanded: false,
                  submitStatus: PosSubmitStatus.success,
                  submitError: result.queued
                      ? 'Sale saved offline. It will sync automatically when internet is back.'
                      : null,
                ),
              );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: PosSubmitStatus.failure,
          submitError: e.toString(),
        ),
      );
    }
  }

  void _onAcknowledgeSubmit(
      PosAcknowledgeSubmit event,
      Emitter<PosState> emit,
      ) {
    emit(
      state.copyWith(
        submitStatus: PosSubmitStatus.idle,
        submitError: null,
      ),
    );
  }

  void _onCartExpandedChanged(
      PosCartExpandedChanged event,
      Emitter<PosState> emit,
      ) {
    emit(state.copyWith(cartExpanded: event.expanded));
  }
}