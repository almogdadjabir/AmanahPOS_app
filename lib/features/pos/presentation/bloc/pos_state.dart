part of 'pos_bloc.dart';

enum PosSubmitStatus { idle, loading, success, failure }

class PosState extends Equatable {
  final List<PosCartItem> items;
  final String searchQuery;
  final String? selectedCategoryId;
  final String paymentMethod;

  /// The customer on this ticket (optional; required to sell on account).
  final String? customerId;
  final String? customerName;

  /// Discount on the whole sale (owner/manager). Null = none.
  final CartDiscount? saleDiscount;

  /// Confirmed split parts (only meaningful while [paymentMethod] is 'split').
  final List<SalePaymentPart> splitParts;

  /// Parts of the sale just finished, for its receipt.
  final List<SalePaymentPart> lastSplitParts;
  final PosSubmitStatus submitStatus;
  final String? submitError;

  /// Fix-wave I2, transient like [submitError]: names of cart lines just
  /// dropped because their product no longer exists locally (merged,
  /// discarded) or was deleted. The screen shows a localized notice.
  final List<String> removedUnavailable;
  final bool cartExpanded;
  final Map<String, int> lastSoldQuantities;
  final String? selectedShopId;
  final String? selectedShopName;
  final TaxConfig taxConfig;

  // Receipt snapshot — set on success, consumed by SaleReceiptSheet
  final String? lastReceiptNumber;
  final String? lastSaleId;
  final String? lastClientSaleId;
  final List<PosCartItem> lastCartSnapshot;
  final double lastTotal;
  final String lastPaymentMethod;
  final bool lastSaleWasOffline;
  final double lastSubtotal;
  final double lastTaxAmount;
  final String lastTaxName;
  final double lastTaxRate;
  final bool lastTaxInclusive;

  const PosState({
    this.items = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.paymentMethod = 'cash',
    this.customerId,
    this.customerName,
    this.saleDiscount,
    this.splitParts = const [],
    this.lastSplitParts = const [],
    this.submitStatus = PosSubmitStatus.idle,
    this.submitError,
    this.removedUnavailable = const [],
    this.cartExpanded = false,
    this.lastSoldQuantities = const {},
    this.selectedShopId,
    this.selectedShopName,
    this.taxConfig = const TaxConfig.disabled(),
    this.lastReceiptNumber,
    this.lastSaleId,
    this.lastClientSaleId,
    this.lastCartSnapshot = const [],
    this.lastTotal = 0,
    this.lastPaymentMethod = 'cash',
    this.lastSaleWasOffline = false,
    this.lastSubtotal = 0,
    this.lastTaxAmount = 0,
    this.lastTaxName = 'VAT',
    this.lastTaxRate = 0,
    this.lastTaxInclusive = false,
  });

  factory PosState.initial() => const PosState();

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  /// Sum of the lines after their own discounts.
  double get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);

  /// Sum of the lines before any discount.
  double get grossSubtotal => items.fold(0, (sum, i) => sum + i.lineGross);

  double get lineDiscountTotal =>
      items.fold(0, (sum, i) => sum + i.lineDiscount);

  BigInt get saleDiscountCents => saleDiscount == null
      ? BigInt.zero
      : saleDiscount!.cutOf(BigInt.from((subtotal * 100).round()));

  /// The whole-sale discount, taken off after the line discounts.
  double get saleDiscountAmount => saleDiscountCents.toDouble() / 100;

  /// What tax is worked out on.
  double get taxable => saleDiscount == null
      ? subtotal
      : ((BigInt.from((subtotal * 100).round()) - saleDiscountCents)
                .toDouble() /
            100);

  /// Local tax preview (docs/TAX_SUPPORT.md §2) — server stays authoritative.
  double get taxAmount => TaxCalculator.compute(
    taxableAmount: taxable,
    config: taxConfig,
  ).taxAmount;

  /// Net payable total: subtotal + tax when exclusive, subtotal when
  /// inclusive or tax disabled.
  double get total => TaxCalculator.compute(
    taxableAmount: taxable,
    config: taxConfig,
  ).netAmount;

  int quantityOf(String? productId) {
    if (productId == null) return 0;
    final match = items.where((i) => i.product.id == productId);
    return match.isEmpty ? 0 : match.first.quantity;
  }

  Map<String, int> get currentSoldQuantities => {
    for (final item in items)
      if (item.product.id != null && !item.isCustom)
        item.product.id!: item.quantity,
  };

  PosState copyWith({
    List<PosCartItem>? items,
    String? searchQuery,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
    String? paymentMethod,
    String? customerId,
    String? customerName,
    bool clearCustomer = false,
    CartDiscount? saleDiscount,
    bool clearSaleDiscount = false,
    List<SalePaymentPart>? splitParts,
    List<SalePaymentPart>? lastSplitParts,
    PosSubmitStatus? submitStatus,
    String? submitError,
    List<String>? removedUnavailable,
    bool? cartExpanded,
    Map<String, int>? lastSoldQuantities,
    String? selectedShopId,
    String? selectedShopName,
    bool clearShop = false,
    TaxConfig? taxConfig,
    String? lastReceiptNumber,
    String? lastSaleId,
    String? lastClientSaleId,
    List<PosCartItem>? lastCartSnapshot,
    double? lastTotal,
    String? lastPaymentMethod,
    bool? lastSaleWasOffline,
    double? lastSubtotal,
    double? lastTaxAmount,
    String? lastTaxName,
    double? lastTaxRate,
    bool? lastTaxInclusive,
  }) {
    return PosState(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearSelectedCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerId: clearCustomer ? null : (customerId ?? this.customerId),
      customerName: clearCustomer ? null : (customerName ?? this.customerName),
      saleDiscount: clearSaleDiscount
          ? null
          : (saleDiscount ?? this.saleDiscount),
      splitParts: splitParts ?? this.splitParts,
      lastSplitParts: lastSplitParts ?? this.lastSplitParts,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: submitError,
      removedUnavailable: removedUnavailable ?? const [],
      cartExpanded: cartExpanded ?? this.cartExpanded,
      lastSoldQuantities: lastSoldQuantities ?? this.lastSoldQuantities,
      selectedShopId: clearShop
          ? null
          : (selectedShopId ?? this.selectedShopId),
      selectedShopName: clearShop
          ? null
          : (selectedShopName ?? this.selectedShopName),
      taxConfig: taxConfig ?? this.taxConfig,
      lastReceiptNumber: lastReceiptNumber ?? this.lastReceiptNumber,
      lastSaleId: lastSaleId ?? this.lastSaleId,
      lastClientSaleId: lastClientSaleId ?? this.lastClientSaleId,
      lastCartSnapshot: lastCartSnapshot ?? this.lastCartSnapshot,
      lastTotal: lastTotal ?? this.lastTotal,
      lastPaymentMethod: lastPaymentMethod ?? this.lastPaymentMethod,
      lastSaleWasOffline: lastSaleWasOffline ?? this.lastSaleWasOffline,
      lastSubtotal: lastSubtotal ?? this.lastSubtotal,
      lastTaxAmount: lastTaxAmount ?? this.lastTaxAmount,
      lastTaxName: lastTaxName ?? this.lastTaxName,
      lastTaxRate: lastTaxRate ?? this.lastTaxRate,
      lastTaxInclusive: lastTaxInclusive ?? this.lastTaxInclusive,
    );
  }

  @override
  List<Object?> get props => [
    items,
    searchQuery,
    selectedCategoryId,
    paymentMethod,
    customerId,
    customerName,
    saleDiscount,
    [for (final x in splitParts) '${x.method}:${x.amount}'],
    [for (final x in lastSplitParts) '${x.method}:${x.amount}'],
    submitStatus,
    submitError,
    removedUnavailable,
    cartExpanded,
    lastSoldQuantities,
    selectedShopId,
    selectedShopName,
    lastReceiptNumber,
    lastSaleId,
    lastClientSaleId,
    lastCartSnapshot,
    lastTotal,
    lastPaymentMethod,
    lastSaleWasOffline,
    taxConfig,
    lastSubtotal,
    lastTaxAmount,
    lastTaxName,
    lastTaxRate,
    lastTaxInclusive,
  ];
}
