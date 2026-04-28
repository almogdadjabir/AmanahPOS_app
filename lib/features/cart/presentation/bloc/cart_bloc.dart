import 'package:amana_pos/features/dashboard/data/models/cart_item.dart';
import 'package:amana_pos/features/dashboard/data/models/discount.dart';
import 'package:amana_pos/features/dashboard/data/models/product.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(CartState.initial()) {
    _initializeEvents();
  }

  void _initializeEvents() {
    on<AddProductEvent>(_onAddProduct);
    on<IncrementProductEvent>(_onIncrementProduct);
    on<DecrementProductEvent>(_onDecrementProduct);
    on<RemoveProductEvent>(_onRemoveProduct);
    on<SetDiscountEvent>(_onSetDiscount);
    on<SeedDemoEvent>(_onSeedDemo);
    on<ChargeCartEvent>(_onChargeCart);
    on<AcknowledgeChargeEvent>(_onAcknowledgeCharge);
    on<ClearCartEvent>(_onClearCart);
  }

  // ── Handlers ───────────────────────────────────────────────────────

  void _onAddProduct(AddProductEvent event, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere((i) => i.product.id == event.product.id);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(qty: items[idx].qty + 1);
    } else {
      items.add(CartItem(product: event.product, qty: 1));
    }
    emit(state.copyWith(items: items));
  }

  void _onIncrementProduct(IncrementProductEvent event, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere((i) => i.product.id == event.productId);
    if (idx < 0) return;
    items[idx] = items[idx].copyWith(qty: items[idx].qty + 1);
    emit(state.copyWith(items: items));
  }

  void _onDecrementProduct(DecrementProductEvent event, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere((i) => i.product.id == event.productId);
    if (idx < 0) return;
    final cur = items[idx];
    if (cur.qty <= 1) {
      items.removeAt(idx);
    } else {
      items[idx] = cur.copyWith(qty: cur.qty - 1);
    }
    emit(state.copyWith(items: items));
  }

  void _onRemoveProduct(RemoveProductEvent event, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items)
      ..removeWhere((i) => i.product.id == event.productId);
    emit(state.copyWith(items: items));
  }

  void _onSetDiscount(SetDiscountEvent event, Emitter<CartState> emit) {
    emit(state.copyWith(discount: event.discount));
  }

  void _onSeedDemo(SeedDemoEvent event, Emitter<CartState> emit) {
    emit(state.copyWith(items: List<CartItem>.from(event.items)));
  }

  void _onChargeCart(ChargeCartEvent event, Emitter<CartState> emit) {
    // Capture total before clearing, then emit charged status
    final charged = state.total;
    emit(state.copyWith(
      items: const [],
      discount: const Discount.none(),
      status: CartStatus.charged,
      lastChargedTotal: charged,
    ));
  }

  void _onAcknowledgeCharge(AcknowledgeChargeEvent event, Emitter<CartState> emit) {
    // Reset status back to idle once the UI has reacted (snackbar shown, etc.)
    emit(state.copyWith(status: CartStatus.idle));
  }

  void _onClearCart(ClearCartEvent event, Emitter<CartState> emit) {
    emit(CartState.initial());
  }
}