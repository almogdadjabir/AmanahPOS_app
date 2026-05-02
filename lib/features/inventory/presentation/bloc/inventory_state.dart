part of 'inventory_bloc.dart';

enum InventoryStatus { initial, loading, loadingMore, success, failure }

enum StockFilter { all, lowStock, outOfStock }
enum InventorySubmitStatus { idle, loading, success, failure }


class InventoryState extends Equatable {
  final InventoryStatus status;
  final List<StockData> stockList;
  final StockFilter filter;
  final int currentPage;
  final int totalPages;
  final String? responseError;
  final InventorySubmitStatus submitStatus;
  final String? submitError;

  const InventoryState({
    this.status = InventoryStatus.initial,
    this.stockList = const [],
    this.filter = StockFilter.all,
    this.currentPage = 1,
    this.totalPages = 1,
    this.responseError,
    this.submitStatus = InventorySubmitStatus.idle,
    this.submitError,
  });

  factory InventoryState.initial() => const InventoryState();

  bool get hasMorePages => currentPage < totalPages;

  List<StockData> get filtered => switch (filter) {
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
    InventorySubmitStatus? submitStatus,
    String? submitError,
  }) {
    return InventoryState(
      status: status ?? this.status,
      stockList: stockList ?? this.stockList,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      responseError: responseError,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError:  submitError,
    );
  }

  @override
  List<Object?> get props => [
    status, stockList, filter,
    currentPage, totalPages, responseError,
    submitStatus, submitError,
  ];
}