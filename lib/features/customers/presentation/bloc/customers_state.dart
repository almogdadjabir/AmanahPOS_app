part of 'customers_bloc.dart';

enum CustomersStatus { initial, loading, loadingMore, success, failure }

enum CustomerSubmitStatus { idle, loading, success, failure }

class CustomersState extends Equatable {
  final CustomersStatus status;

  /// Rows loaded so far for the current search and filter. A customer that was
  /// just (de)activated stays here, so an open detail screen can keep showing
  /// it; [visibleCustomers] hides it from the list.
  final List<CustomerData> customers;
  final String searchQuery;
  final CustomerActiveFilter filter;
  final int currentPage;
  final int totalPages;

  /// `count` from the server: all customers matching search and filter.
  final int totalCount;
  final String? responseError;

  final CustomerSubmitStatus submitStatus;
  final String? submitError;

  const CustomersState({
    required this.status,
    required this.customers,
    required this.searchQuery,
    required this.filter,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    this.responseError,
    required this.submitStatus,
    this.submitError,
  });

  factory CustomersState.initial() {
    return const CustomersState(
      status: CustomersStatus.initial,
      customers: [],
      searchQuery: '',
      filter: CustomerActiveFilter.active,
      currentPage: 1,
      totalPages: 1,
      totalCount: 0,
      submitStatus: CustomerSubmitStatus.idle,
    );
  }

  bool get hasMorePages => currentPage < totalPages;

  bool get isSearching => searchQuery.trim().isNotEmpty;

  /// Rows that belong in the current list: those whose status still matches
  /// the chip (a row just toggled from its detail drops out). Not a search
  /// filter, searching is done by the server.
  List<CustomerData> get visibleCustomers {
    final wantActive = filter == CustomerActiveFilter.active;
    return customers
        .where((c) => (c.isActive != false) == wantActive)
        .toList(growable: false);
  }

  CustomersState copyWith({
    CustomersStatus? status,
    List<CustomerData>? customers,
    String? searchQuery,
    CustomerActiveFilter? filter,
    int? currentPage,
    int? totalPages,
    int? totalCount,
    String? responseError,
    CustomerSubmitStatus? submitStatus,
    String? submitError,
  }) {
    return CustomersState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      responseError: responseError,
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: submitError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    customers,
    searchQuery,
    filter,
    currentPage,
    totalPages,
    totalCount,
    responseError,
    submitStatus,
    submitError,
  ];
}
