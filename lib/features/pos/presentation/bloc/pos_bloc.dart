import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/common/app_progress/app_progress_cubit.dart';
import 'package:amana_pos/core/errors/friendly_error.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:amana_pos/features/pos/domain/usecases/pos_usecase.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pos_event.dart';
part 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final PosUseCase useCase;

  PosBloc({required this.useCase}) : super(PosState.initial()) {
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
    on<PosShopSelected>(_onShopSelected);
    on<PosBarcodeScanned>(_onBarcodeScanned);
    on<PosSessionReset>(_onSessionReset);
    on<PosTaxConfigChanged>(_onTaxConfigChanged);
  }

  void _onShopSelected(PosShopSelected event, Emitter<PosState> emit) {
    emit(state.copyWith(
      selectedShopId: event.shopId,
      selectedShopName: event.shopName,
    ));
  }

  void _onTaxConfigChanged(PosTaxConfigChanged event, Emitter<PosState> emit) {
    emit(state.copyWith(taxConfig: event.taxConfig));
  }

  void _onBarcodeScanned(PosBarcodeScanned event, Emitter<PosState> emit) {}

  void _onSearchChanged(PosSearchChanged event, Emitter<PosState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onCategoryChanged(PosCategoryChanged event, Emitter<PosState> emit) {
    emit(state.copyWith(
      selectedCategoryId: event.categoryId,
      clearSelectedCategory: event.categoryId == null,
    ));
  }

  void _onPaymentMethodChanged(
      PosPaymentMethodChanged event, Emitter<PosState> emit) {
    emit(state.copyWith(paymentMethod: event.paymentMethod));
  }

  void _onAddProduct(PosAddProduct event, Emitter<PosState> emit) {
    final productId = event.product.id;
    if (productId == null) return;

    final existingIndex =
    state.items.indexWhere((item) => item.product.id == productId);
    final currentQty = existingIndex == -1 ? 0 : state.items[existingIndex].quantity;
    final nextQty = currentQty + 1;

    if (!_canUseQuantity(
      product: event.product,
      quantity: nextQty,
      ignoreStockLimit: event.ignoreStockLimit,
    )) {
      emit(state.copyWith(submitError: _stockLimitMessage(event.product)));
      return;
    }

    final updated = [...state.items];
    if (existingIndex == -1) {
      updated.add(PosCartItem(product: event.product, quantity: 1));
    } else {
      final item = updated[existingIndex];
      updated[existingIndex] = item.copyWith(quantity: nextQty);
    }

    emit(state.copyWith(items: updated, submitError: null));
  }

  void _onIncrementItem(PosIncrementItem event, Emitter<PosState> emit) {
    final updated = <PosCartItem>[];
    for (final item in state.items) {
      if (item.product.id != event.productId) {
        updated.add(item);
        continue;
      }
      final nextQty = item.quantity + 1;
      if (!_canUseQuantity(
        product: item.product,
        quantity: nextQty,
        ignoreStockLimit: event.ignoreStockLimit,
      )) {
        emit(state.copyWith(submitError: _stockLimitMessage(item.product)));
        return;
      }
      updated.add(item.copyWith(quantity: nextQty));
    }
    emit(state.copyWith(items: updated, submitError: null));
  }

  void _onDecrementItem(PosDecrementItem event, Emitter<PosState> emit) {
    final updated = <PosCartItem>[];
    for (final item in state.items) {
      if (item.product.id != event.productId) {
        updated.add(item);
        continue;
      }
      final nextQty = item.quantity - 1;
      if (nextQty > 0) updated.add(item.copyWith(quantity: nextQty));
    }
    emit(state.copyWith(items: updated));
  }

  void _onRemoveItem(PosRemoveItem event, Emitter<PosState> emit) {
    emit(state.copyWith(
      items: state.items.where((i) => i.product.id != event.productId).toList(),
    ));
  }

  void _onClearCart(PosClearCart event, Emitter<PosState> emit) {
    emit(state.copyWith(items: [], clearShop: true));
  }

  Future<void> _onCheckoutSubmitted(
      PosCheckoutSubmitted event,
      Emitter<PosState> emit,
      ) async {
    if (state.items.isEmpty) return;

    // Snapshot BEFORE clearing
    final cartSnapshot = [...state.items];
    final saleSubtotal = state.subtotal;
    final salePreviewTax = state.taxAmount;
    final saleTotal = state.total;
    final saleTaxConfig = state.taxConfig;
    final salePaymentMethod = state.paymentMethod;
    final soldQuantities = state.currentSoldQuantities;

    emit(state.copyWith(
      submitStatus: PosSubmitStatus.loading,
      submitError: null,
    ));

    try {
      final response = await getIt<AppProgressCubit>().run(
            () => useCase.submitSale(
          shopId: event.shopId,
          customerId: event.customerId,
          paymentMethod: state.paymentMethod,
          items: state.items,
          discountAmount: '0',
          taxConfig: saleTaxConfig,
        ),
      );

      response.fold(
            (error) {
          emit(state.copyWith(
            submitStatus: PosSubmitStatus.failure,
            submitError: error ?? 'Failed to submit sale',
          ));
        },
            (result) {
          final serverTax = double.tryParse(result.taxAmount ?? '');
          final serverNet = double.tryParse(result.netAmount ?? '');
          final resolvedTaxAmount = serverTax ?? salePreviewTax;
          final resolvedTotal = serverNet ?? saleTotal;
          final resolvedInclusive =
              result.taxInclusive ?? saleTaxConfig.inclusive;
          // Keep receipt rows arithmetically consistent: with server values in
          // exclusive mode, displayed subtotal must equal net − tax (the local
          // subtotal can drift ±0.01 from the server's Decimal math).
          final resolvedSubtotal =
              (serverNet != null && serverTax != null && !resolvedInclusive)
                  ? serverNet - serverTax
                  : saleSubtotal;

          emit(state.copyWith(
            items: [],
            lastSoldQuantities: soldQuantities,
            cartExpanded: false,
            submitStatus: PosSubmitStatus.success,
            clearShop: true,
            // Receipt snapshot
            lastReceiptNumber: result.receiptNumber,
            lastSaleId: result.saleId,
            lastClientSaleId: result.clientSaleId,
            lastCartSnapshot: cartSnapshot,
            lastSubtotal: resolvedSubtotal,
            // Online sales: server values are authoritative; offline-queued
            // sales fall back to the local preview.
            lastTaxAmount: resolvedTaxAmount,
            lastTotal: resolvedTotal,
            lastTaxName: saleTaxConfig.name,
            lastTaxRate:
                double.tryParse(result.taxRate ?? '') ?? saleTaxConfig.rate,
            lastTaxInclusive: resolvedInclusive,
            lastPaymentMethod: salePaymentMethod,
            lastSaleWasOffline: result.queued,
            submitError: result.queued
                ? 'Sale saved offline. Will sync when internet is restored.'
                : null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        submitStatus: PosSubmitStatus.failure,
        submitError: friendlyError(e),
      ));
    }
  }

  void _onAcknowledgeSubmit(
      PosAcknowledgeSubmit event, Emitter<PosState> emit) {
    emit(state.copyWith(
      submitStatus: PosSubmitStatus.idle,
      submitError: null,
    ));
  }

  void _onCartExpandedChanged(
      PosCartExpandedChanged event, Emitter<PosState> emit) {
    emit(state.copyWith(cartExpanded: event.expanded));
  }

  void _onSessionReset(PosSessionReset event, Emitter<PosState> emit) {
    // Keep shop selection, wipe everything else
    emit(PosState(
      selectedShopId: state.selectedShopId,
      selectedShopName: state.selectedShopName,
      taxConfig: state.taxConfig,
    ));
  }

  bool _canUseQuantity({
    required ProductData product,
    required int quantity,
    required bool ignoreStockLimit,
  }) {
    if (ignoreStockLimit) return true;
    final trackInventory = product.trackInventory ?? true;
    if (!trackInventory) return true;
    final stock = product.stockLevel ?? 0;
    return quantity <= stock;
  }

  String _stockLimitMessage(ProductData product) {
    final stock = product.stockLevel ?? 0;
    final name = product.name ?? 'Product';
    final formattedStock =
    stock % 1 == 0 ? stock.toInt().toString() : stock.toStringAsFixed(1);
    return 'Only $formattedStock item(s) available for $name.';
  }
}