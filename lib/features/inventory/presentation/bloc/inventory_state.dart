part of 'inventory_bloc.dart';

enum InventoryStatus { initial, loading, loadingMore, success, failure }

enum StockFilter { all, healthy, lowStock, outOfStock }
enum InventorySubmitStatus { idle, loading, success, queued, failure }

class InventoryState extends Equatable {
  final InventoryStatus status;
  final List<StockData> stockList;
  final StockFilter filter;
  final int currentPage;
  final int totalPages;
  final String? responseError;
  final InventorySubmitStatus submitStatus;
  final String? submitError;

  /// True when the last inbound transaction was saved locally and will sync later.
  final bool inboundQueuedOffline;

  /// True when stock came from SQLite cache.
  final bool isFromCache;

  const InventoryState({
    this.status = InventoryStatus.initial,
    this.stockList = const [],
    this.filter = StockFilter.all,
    this.currentPage = 1,
    this.totalPages = 1,
    this.responseError,
    this.submitStatus = InventorySubmitStatus.idle,
    this.submitError,
    this.inboundQueuedOffline = false,
    this.isFromCache = false,
  });

  factory InventoryState.initial() => const InventoryState();

  bool get hasMorePages => !isFromCache && currentPage < totalPages;

  List<StockData> get filtered => switch (filter) {
    StockFilter.healthy => stockList.where((s) {
      final isLow = s.isLowStock ?? false;
      final isOut = s.isOutOfStock ?? false;
      return !isLow && !isOut;
    }).toList(),
    StockFilter.lowStock => stockList.where((s) => s.isLowStock ?? false).toList(),
    StockFilter.outOfStock => stockList.where((s) => s.isOutOfStock ?? false).toList(),
    StockFilter.all => stockList,
  };

  InventoryState copyWith({
    InventoryStatus? status,
    List<StockData>? stockList,
    StockFilter? filter,
    int? currentPage,
    int? totalPages,
    String? responseError,
    bool clearResponseError = false,
    InventorySubmitStatus? submitStatus,
    String? submitError,
    bool clearSubmitError = false,
    bool? inboundQueuedOffline,
    bool? isFromCache,
  }) {
    return InventoryState(
      status: status ?? this.status,
      stockList: stockList ?? this.stockList,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      responseError: clearResponseError
          ? null
          : responseError ?? this.responseError,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: clearSubmitError
          ? null
          : submitError ?? this.submitError,
      inboundQueuedOffline: inboundQueuedOffline ?? this.inboundQueuedOffline,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
  @override
  List<Object?> get props => [
    status,
    stockList,
    filter,
    currentPage,
    totalPages,
    responseError,
    submitStatus,
    submitError,
    inboundQueuedOffline,
    isFromCache,
  ];
}