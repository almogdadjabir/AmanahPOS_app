part of 'pos_bloc.dart';

enum PosSubmitStatus { idle, loading, success, failure }

class PosState extends Equatable {
  final List<PosCartItem> items;
  final String searchQuery;
  final String? selectedCategoryId;
  final String paymentMethod;
  final PosSubmitStatus submitStatus;
  final String? submitError;
  final bool cartExpanded;
  final Map<String, int> lastSoldQuantities;

  final String? selectedShopId;
  final String? selectedShopName;

  const PosState({
    this.items = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.paymentMethod = 'cash',
    this.submitStatus = PosSubmitStatus.idle,
    this.submitError,
    this.cartExpanded = false,
    this.lastSoldQuantities = const {},
    this.selectedShopId,
    this.selectedShopName,
  });

  factory PosState.initial() => const PosState();

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int  get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal =>
      items.fold(0, (sum, i) => sum + i.lineTotal);

  double get total => subtotal;

  int quantityOf(String? productId) {
    if (productId == null) return 0;
    final match = items.where((i) => i.product.id == productId);
    return match.isEmpty ? 0 : match.first.quantity;
  }

  Map<String, int> get currentSoldQuantities => {
    for (final item in items)
      if (item.product.id != null) item.product.id!: item.quantity,
  };

  PosState copyWith({
    List<PosCartItem>? items,
    String? searchQuery,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
    String? paymentMethod,
    PosSubmitStatus?   submitStatus,
    String? submitError,
    bool? cartExpanded,
    Map<String, int>?  lastSoldQuantities,
    String? selectedShopId,
    String? selectedShopName,
    bool clearShop = false,
  }) {
    return PosState(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId  ?? this.selectedCategoryId),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: submitError,
      cartExpanded: cartExpanded ?? this.cartExpanded,
      lastSoldQuantities: lastSoldQuantities ?? this.lastSoldQuantities,
      selectedShopId: clearShop ? null : (selectedShopId  ?? this.selectedShopId),
      selectedShopName: clearShop ? null : (selectedShopName ?? this.selectedShopName),
    );
  }

  @override
  List<Object?> get props => [
    items, searchQuery, selectedCategoryId, paymentMethod,
    submitStatus, submitError, cartExpanded, lastSoldQuantities,
    selectedShopId, selectedShopName,
  ];
}
