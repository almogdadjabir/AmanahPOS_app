part of 'sales_history_bloc.dart';

enum SalesHistoryBlocStatus { initial, loading, loadingMore, loaded, failure }

enum SalesDatePreset { any, today, yesterday, last7, month, custom }

/// Server-side filters of the sales list. `null` / `any` means no filter.
class SalesHistoryFilters extends Equatable {
  final SalesDatePreset date;
  final DateTime? customFrom;
  final DateTime? customTo;

  /// Payment method key as the backend knows it: cash, bankak, card.
  final String? payment;

  /// Sale status key: completed, partial_refund, refunded, cancelled.
  final String? status;
  final bool onlyUnsynced;

  const SalesHistoryFilters({
    this.date = SalesDatePreset.any,
    this.customFrom,
    this.customTo,
    this.payment,
    this.status,
    this.onlyUnsynced = false,
  });

  bool get isActive =>
      date != SalesDatePreset.any ||
      payment != null ||
      status != null ||
      onlyUnsynced;

  /// Inclusive local-date range for the date preset, or null for any date.
  ({DateTime from, DateTime to})? get range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (date) {
      case SalesDatePreset.any:
        return null;
      case SalesDatePreset.today:
        return (from: today, to: today);
      case SalesDatePreset.yesterday:
        final y = today.subtract(const Duration(days: 1));
        return (from: y, to: y);
      case SalesDatePreset.last7:
        return (from: today.subtract(const Duration(days: 6)), to: today);
      case SalesDatePreset.month:
        return (from: DateTime(today.year, today.month, 1), to: today);
      case SalesDatePreset.custom:
        if (customFrom == null || customTo == null) return null;
        return (from: customFrom!, to: customTo!);
    }
  }

  SalesHistoryFilters copyWith({
    SalesDatePreset? date,
    DateTime? customFrom,
    DateTime? customTo,
    String? payment,
    bool clearPayment = false,
    String? status,
    bool clearStatus = false,
    bool? onlyUnsynced,
  }) =>
      SalesHistoryFilters(
        date: date ?? this.date,
        customFrom: customFrom ?? this.customFrom,
        customTo: customTo ?? this.customTo,
        payment: clearPayment ? null : (payment ?? this.payment),
        status: clearStatus ? null : (status ?? this.status),
        onlyUnsynced: onlyUnsynced ?? this.onlyUnsynced,
      );

  @override
  List<Object?> get props =>
      [date, customFrom, customTo, payment, status, onlyUnsynced];
}

class SalesHistoryState extends Equatable {
  final List<SaleHistoryItem> items;
  final SalesHistoryBlocStatus status;
  final int currentPage;
  final bool hasMore;
  final String searchQuery;
  final String? errorMessage;
  final SalesHistoryFilters filters;

  /// Server count for the current filters (null until the first page loads).
  final int? totalCount;

  const SalesHistoryState({
    required this.items,
    required this.status,
    required this.currentPage,
    required this.hasMore,
    required this.searchQuery,
    this.errorMessage,
    this.filters = const SalesHistoryFilters(),
    this.totalCount,
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
    SalesHistoryFilters? filters,
    int? totalCount,
    bool clearTotal = false,
  }) =>
      SalesHistoryState(
        items: items ?? this.items,
        status: status ?? this.status,
        currentPage:  currentPage ?? this.currentPage,
        hasMore: hasMore ?? this.hasMore,
        searchQuery: searchQuery ?? this.searchQuery,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        filters: filters ?? this.filters,
        totalCount: clearTotal ? null : (totalCount ?? this.totalCount),
      );

  @override
  List<Object?> get props =>
      [items, status, currentPage, hasMore, searchQuery, errorMessage, filters, totalCount];
}