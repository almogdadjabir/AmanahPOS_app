part of 'sales_history_bloc.dart';

enum SalesHistoryBlocStatus { initial, loading, loadingMore, loaded, failure }

class SalesHistoryState extends Equatable {
  final List<SaleHistoryItem> items;
  final SalesHistoryBlocStatus status;
  final int currentPage;
  final bool hasMore;
  final String searchQuery;
  final String? errorMessage;

  const SalesHistoryState({
    required this.items,
    required this.status,
    required this.currentPage,
    required this.hasMore,
    required this.searchQuery,
    this.errorMessage,
  });

  factory SalesHistoryState.initial() => const SalesHistoryState(
    items: [],
    status: SalesHistoryBlocStatus.initial,
    currentPage: 0,
    hasMore: true,
    searchQuery: '',
  );


  bool get isLoading =>
      status == SalesHistoryBlocStatus.loading ||
          status == SalesHistoryBlocStatus.loadingMore;

  bool get isLoadingMore => status == SalesHistoryBlocStatus.loadingMore;
  bool get isFailure => status == SalesHistoryBlocStatus.failure;
  bool get isLoaded => status == SalesHistoryBlocStatus.loaded;

  SalesHistoryState copyWith({
    List<SaleHistoryItem>?  items,
    SalesHistoryBlocStatus? status,
    int? currentPage,
    bool? hasMore,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) =>
      SalesHistoryState(
        items: items ?? this.items,
        status: status ?? this.status,
        currentPage:  currentPage ?? this.currentPage,
        hasMore: hasMore ?? this.hasMore,
        searchQuery: searchQuery ?? this.searchQuery,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props =>
      [items, status, currentPage, hasMore, searchQuery, errorMessage];
}