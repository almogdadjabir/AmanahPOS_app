part of 'premium_inventory_bloc.dart';

enum PremiumInventoryStatus { initial, loading, success, failure }

class PremiumInventoryState extends Equatable {
  final PremiumInventoryStatus status;
  final PremiumSummaryData? premiumSummary;
  final List<StockData> stockPage;
  final List<StockData> lowStockItems;
  final List<ExpiryReportItem> expiryPreview;
  final VendorSummaryData? vendorSummary;
  final List<InboundTransactionData> recentInbound;
  final bool isFromCache;
  final String? responseError;

  const PremiumInventoryState({
    this.status = PremiumInventoryStatus.initial,
    this.premiumSummary,
    this.stockPage = const [],
    this.lowStockItems = const [],
    this.expiryPreview = const [],
    this.vendorSummary,
    this.recentInbound = const [],
    this.isFromCache = false,
    this.responseError,
  });

  factory PremiumInventoryState.initial() => const PremiumInventoryState();

  PremiumInventoryState copyWith({
    PremiumInventoryStatus? status,
    PremiumSummaryData? premiumSummary,
    List<StockData>? stockPage,
    List<StockData>? lowStockItems,
    List<ExpiryReportItem>? expiryPreview,
    VendorSummaryData? vendorSummary,
    List<InboundTransactionData>? recentInbound,
    bool? isFromCache,
    String? responseError,
    bool clearResponseError = false,
  }) {
    return PremiumInventoryState(
      status: status ?? this.status,
      premiumSummary: premiumSummary ?? this.premiumSummary,
      stockPage: stockPage ?? this.stockPage,
      lowStockItems: lowStockItems ?? this.lowStockItems,
      expiryPreview: expiryPreview ?? this.expiryPreview,
      vendorSummary: vendorSummary ?? this.vendorSummary,
      recentInbound: recentInbound ?? this.recentInbound,
      isFromCache: isFromCache ?? this.isFromCache,
      responseError: clearResponseError ? null : responseError ?? this.responseError,
    );
  }

  @override
  List<Object?> get props => [
    status, premiumSummary, stockPage, lowStockItems,
    expiryPreview, vendorSummary, recentInbound, isFromCache, responseError,
  ];
}
