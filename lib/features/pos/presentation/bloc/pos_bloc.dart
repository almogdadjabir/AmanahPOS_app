import 'dart:async';

import 'package:amana_pos/features/pos/data/model/pos_cart_item.dart';
import 'package:amana_pos/common/app_progress/app_progress_cubit.dart';
import 'package:amana_pos/core/errors/friendly_error.dart';
import 'package:amana_pos/features/pos/domain/cart_discount.dart';
import 'package:amana_pos/features/pos/domain/sale.dart';
import 'package:amana_pos/features/pos/domain/split_payment.dart';
import 'package:amana_pos/features/shifts/domain/cash_expectation.dart';
import 'package:amana_pos/features/pos/domain/tax_config.dart';
import 'package:amana_pos/features/pos/domain/usecases/pos_usecase.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

part 'pos_event.dart';
part 'pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final PosUseCase useCase;

  /// The subset of the given product ids that can no longer be sold (no
  /// local row, or inactive): `SaleService.unavailableProductIds`. Null =
  /// no pre-check (SaleService still refuses them).
  final Future<Set<String>> Function(Set<String> productIds)?
  unavailableProducts;

  StreamSubscription<Set<String>>? _changesSub;

  /// [changes]: `DbChangeNotifier.changes`. A merge / discard / delete that
  /// touches `products` re-checks the open cart (fix-wave I2).
  PosBloc({
    required this.useCase,
    this.unavailableProducts,
    Stream<Set<String>>? changes,
  }) : super(PosState.initial()) {
    on<_PosCatalogChanged>(_onCatalogChanged);
    on<PosSearchChanged>(_onSearchChanged);
    on<PosCategoryChanged>(_onCategoryChanged);
    on<PosPaymentMethodChanged>(_onPaymentMethodChanged);
    on<PosSplitConfirmed>(_onSplitConfirmed);
    on<PosCustomerSelected>(
      (e, emit) => emit(state.copyWith(customerId: e.id, customerName: e.name)),
    );
    on<PosCustomerCleared>(_onCustomerCleared);
    on<PosAddProduct>(_onAddProduct);
    on<PosAddCustomAmount>(_onAddCustomAmount);
    on<PosIncrementItem>(_onIncrementItem);
    on<PosDecrementItem>(_onDecrementItem);
    on<PosRemoveItem>(_onRemoveItem);
    on<PosLineDiscountSet>(_onLineDiscountSet);
    on<PosSaleDiscountSet>(_onSaleDiscountSet);
    on<PosClearCart>(_onClearCart);
    on<PosCheckoutSubmitted>(_onCheckoutSubmitted);
    on<PosAcknowledgeSubmit>(_onAcknowledgeSubmit);
    on<PosCartExpandedChanged>(_onCartExpandedChanged);
    on<PosShopSelected>(_onShopSelected);
    on<PosBarcodeScanned>(_onBarcodeScanned);
    on<PosSessionReset>(_onSessionReset);
    on<PosTaxConfigChanged>(_onTaxConfigChanged);
    _changesSub = changes?.listen((tables) {
      if (tables.contains('products') && !isClosed) {
        add(const _PosCatalogChanged());
      }
    });
  }

  @override
  Future<void> close() async {
    await _changesSub?.cancel();
    return super.close();
  }

  /// Product ids of the cart's non-custom lines.
  Set<String> get _cartProductIds => {
    for (final i in state.items)
      if (!i.isCustom && i.product.id != null) i.product.id!,
  };

  /// Cart lines whose product is gone, or empty.
  Future<Set<String>> _goneFromCart() async {
    final check = unavailableProducts;
    final ids = _cartProductIds;
    if (check == null || ids.isEmpty) return const {};
    return check(ids);
  }

  /// The cart without [gone] lines, and the dropped lines' names.
  (List<PosCartItem>, List<String>) _without(Set<String> gone) {
    final kept = <PosCartItem>[];
    final names = <String>[];
    for (final i in state.items) {
      if (!i.isCustom && gone.contains(i.product.id)) {
        names.add(i.product.name ?? '');
      } else {
        kept.add(i);
      }
    }
    return (kept, names);
  }

  Future<void> _onCatalogChanged(
    _PosCatalogChanged event,
    Emitter<PosState> emit,
  ) async {
    if (state.submitStatus == PosSubmitStatus.loading) return;
    final Set<String> gone;
    try {
      gone = await _goneFromCart();
    } catch (_) {
      return; // checkout re-checks anyway
    }
    if (gone.isEmpty) return;
    final (kept, names) = _without(gone);
    if (names.isEmpty) return;
    emit(state.copyWith(items: kept, removedUnavailable: names));
  }

  void _refuseGone(Set<String> gone, Emitter<PosState> emit) {
    final (kept, names) = _without(gone);
    emit(
      state.copyWith(
        items: kept,
        submitStatus: PosSubmitStatus.failure,
        removedUnavailable: names,
      ),
    );
  }

  void _onShopSelected(PosShopSelected event, Emitter<PosState> emit) {
    emit(
      state.copyWith(
        selectedShopId: event.shopId,
        selectedShopName: event.shopName,
      ),
    );
  }

  void _onTaxConfigChanged(PosTaxConfigChanged event, Emitter<PosState> emit) {
    emit(state.copyWith(taxConfig: event.taxConfig));
  }

  void _onBarcodeScanned(PosBarcodeScanned event, Emitter<PosState> emit) {}

  void _onSearchChanged(PosSearchChanged event, Emitter<PosState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onCategoryChanged(PosCategoryChanged event, Emitter<PosState> emit) {
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
    emit(
      state.copyWith(
        paymentMethod: event.paymentMethod,
        splitParts: event.paymentMethod == 'split' ? null : const [],
      ),
    );
  }

  void _onCustomerCleared(PosCustomerCleared event, Emitter<PosState> emit) {
    // On account (whole or as a split part) never outlives its customer.
    final dropsAccount =
        state.paymentMethod == 'credit' ||
        (state.paymentMethod == 'split' &&
            state.splitParts.any((p) => p.method == 'credit'));
    emit(
      state.copyWith(
        clearCustomer: true,
        paymentMethod: dropsAccount ? 'cash' : null,
        splitParts: dropsAccount ? const [] : null,
      ),
    );
  }

  void _onSplitConfirmed(PosSplitConfirmed event, Emitter<PosState> emit) {
    emit(state.copyWith(paymentMethod: 'split', splitParts: event.parts));
  }

  void _onAddProduct(PosAddProduct event, Emitter<PosState> emit) {
    final productId = event.product.id;
    if (productId == null) return;

    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == productId,
    );
    final currentQty = existingIndex == -1
        ? 0
        : state.items[existingIndex].quantity;
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

  void _onAddCustomAmount(PosAddCustomAmount event, Emitter<PosState> emit) {
    if (event.amount <= 0) return;
    final item = PosCartItem.custom(
      id: const Uuid().v4(),
      name: event.note.trim(),
      price: event.amount,
    );
    emit(state.copyWith(items: [...state.items, item], submitError: null));
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
    emit(state.copyWith(items: updated, clearSaleDiscount: updated.isEmpty));
  }

  void _onRemoveItem(PosRemoveItem event, Emitter<PosState> emit) {
    final left = state.items
        .where((i) => i.product.id != event.productId)
        .toList();
    emit(state.copyWith(items: left, clearSaleDiscount: left.isEmpty));
  }

  void _onLineDiscountSet(PosLineDiscountSet event, Emitter<PosState> emit) {
    emit(
      state.copyWith(
        items: [
          for (final i in state.items)
            if (i.product.id == event.productId)
              event.discount == null
                  ? i.copyWith(clearDiscount: true)
                  : i.copyWith(discount: event.discount)
            else
              i,
        ],
      ),
    );
  }

  void _onSaleDiscountSet(PosSaleDiscountSet event, Emitter<PosState> emit) {
    emit(
      state.copyWith(
        saleDiscount: event.discount,
        clearSaleDiscount: event.discount == null,
      ),
    );
  }

  void _onClearCart(PosClearCart event, Emitter<PosState> emit) {
    emit(state.copyWith(items: [], clearShop: true, clearSaleDiscount: true));
  }

  Future<void> _onCheckoutSubmitted(
    PosCheckoutSubmitted event,
    Emitter<PosState> emit,
  ) async {
    if (state.items.isEmpty) return;

    // Fix-wave I2: a line whose product was merged away, discarded or
    // deleted since it was added must not be sold (its sale would reach
    // the server with product = NULL).
    final gone = await _goneFromCart();
    if (gone.isNotEmpty) {
      _refuseGone(gone, emit);
      return;
    }

    // Snapshot BEFORE clearing
    final cartSnapshot = [...state.items];
    final saleSubtotal = state.subtotal;
    final salePreviewTax = state.taxAmount;
    final saleTotal = state.total;
    final saleDiscountText = Cents.format(state.saleDiscountCents);
    final saleTaxConfig = state.taxConfig;
    final saleCustomerId = event.customerId ?? state.customerId;
    var salePaymentMethod = state.paymentMethod;
    List<SalePaymentPart>? salePayments;
    final needsCustomer =
        salePaymentMethod == 'credit' ||
        (salePaymentMethod == 'split' &&
            state.splitParts.any((p) => p.method == 'credit'));
    if (needsCustomer && (saleCustomerId == null || saleCustomerId.isEmpty)) {
      emit(
        state.copyWith(
          submitStatus: PosSubmitStatus.failure,
          submitError: 'A sale on account needs a customer.',
        ),
      );
      return;
    }
    if (salePaymentMethod == 'split') {
      final parts = state.splitParts;
      final cents = Cents.parse(state.total.toStringAsFixed(2));
      if (parts.isEmpty || cents == null || !SplitPayment.matches(parts, cents)) {
        // The cart changed after the split was confirmed.
        emit(
          state.copyWith(
            submitStatus: PosSubmitStatus.failure,
            submitError: 'The split no longer matches the total. Edit it.',
          ),
        );
        return;
      }
      salePayments = parts;
      if (parts.length == 1) salePaymentMethod = parts.single.method;
    }
    final soldQuantities = state.currentSoldQuantities;

    emit(
      state.copyWith(submitStatus: PosSubmitStatus.loading, submitError: null),
    );

    try {
      final response = await getIt<AppProgressCubit>().run(
        () => useCase.submitSale(
          shopId: event.shopId,
          customerId: saleCustomerId,
          paymentMethod: salePaymentMethod,
          payments: salePayments,
          items: state.items,
          discountAmount: saleDiscountText,
          taxConfig: saleTaxConfig,
        ),
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

          emit(
            state.copyWith(
              items: [],
              clearSaleDiscount: true,
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
              lastSplitParts: salePayments ?? const [],
              paymentMethod:
                  state.paymentMethod == 'split' ||
                      state.paymentMethod == 'credit'
                  ? 'cash'
                  : state.paymentMethod,
              splitParts: const [],
              clearCustomer: true,
              lastSaleWasOffline: result.queued,
              submitError: result.queued
                  ? 'Sale saved offline. Will sync when internet is restored.'
                  : null,
            ),
          );
        },
      );
    } on SaleProductUnavailableException catch (e) {
      _refuseGone(e.productIds, emit);
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: PosSubmitStatus.failure,
          submitError: friendlyError(e),
        ),
      );
    }
  }

  void _onAcknowledgeSubmit(
    PosAcknowledgeSubmit event,
    Emitter<PosState> emit,
  ) {
    emit(state.copyWith(submitStatus: PosSubmitStatus.idle, submitError: null));
  }

  void _onCartExpandedChanged(
    PosCartExpandedChanged event,
    Emitter<PosState> emit,
  ) {
    emit(state.copyWith(cartExpanded: event.expanded));
  }

  void _onSessionReset(PosSessionReset event, Emitter<PosState> emit) {
    // Keep shop selection, wipe everything else
    emit(
      PosState(
        selectedShopId: state.selectedShopId,
        selectedShopName: state.selectedShopName,
        taxConfig: state.taxConfig,
      ),
    );
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
    final formattedStock = stock % 1 == 0
        ? stock.toInt().toString()
        : stock.toStringAsFixed(1);
    return 'Only $formattedStock item(s) available for $name.';
  }
}
