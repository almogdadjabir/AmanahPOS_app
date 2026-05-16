part of 'stock_levels_bloc.dart';

enum StockLevelsStatus { initial, loading, loadingMore, success, failure }
enum StockLevelsFilter { all, lowStock, outOfStock }

class StockLevelsState extends Equatable {
  final StockLevelsStatus status;
  final List<StockData> items;
  final StockLevelsFilter filter;
  final String search;
  final int currentPage;
  final int totalPages;
  final bool lowStockOnly;
  final String? responseError;

  const StockLevelsState({
    this.status = StockLevelsStatus.initial,
    this.items = const [],
    this.filter = StockLevelsFilter.all,
    this.search = '',
    this.currentPage = 1,
    this.totalPages = 1,
    this.lowStockOnly = false,
    this.responseError,
  });

  factory StockLevelsState.initial() => const StockLevelsState();

  bool get hasMorePages => currentPage < totalPages;

  List<StockData> get filtered {
    var list = items;
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) {
        final name = (s.productName ?? '').toLowerCase();
        final sku = (s.productSku ?? '').toLowerCase();
        return name.contains(q) || sku.contains(q);
      }).toList();
    }
    return switch (filter) {
      StockLevelsFilter.lowStock => list.where((s) => s.isLowStock ?? false).toList(),
      StockLevelsFilter.outOfStock => list.where((s) => s.isOutOfStock ?? false).toList(),
      StockLevelsFilter.all => list,
    };
  }

  StockLevelsState copyWith({
    StockLevelsStatus? status,
    List<StockData>? items,
    StockLevelsFilter? filter,
    String? search,
    int? currentPage,
    int? totalPages,
    bool? lowStockOnly,
    String? responseError,
    bool clearResponseError = false,
  }) {
    return StockLevelsState(
      status: status ?? this.status,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      search: search ?? this.search,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      responseError: clearResponseError ? null : responseError ?? this.responseError,
    );
  }

  @override
  List<Object?> get props => [status, items, filter, search, currentPage, totalPages, lowStockOnly, responseError];
}
