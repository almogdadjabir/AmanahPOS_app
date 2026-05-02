part of 'customers_bloc.dart';

enum CustomersStatus { initial, loading, loadingMore, success, failure }

enum CustomerSubmitStatus { idle, loading, success, failure }

class CustomersState extends Equatable {
  final CustomersStatus status;
  final List<CustomerData> customers;
  final String searchQuery;
  final int currentPage;
  final int totalPages;
  final String? responseError;

  final CustomerSubmitStatus submitStatus;
  final String? submitError;

  const CustomersState({
    required this.status,
    required this.customers,
    required this.searchQuery,
    required this.currentPage,
    required this.totalPages,
    this.responseError,
    required this.submitStatus,
    this.submitError,
  });

  factory CustomersState.initial() {
    return const CustomersState(
      status: CustomersStatus.initial,
      customers: [],
      searchQuery: '',
      currentPage: 1,
      totalPages: 1,
      submitStatus: CustomerSubmitStatus.idle,
    );
  }

  bool get hasMorePages => currentPage < totalPages;

  List<CustomerData> get filteredCustomers {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) return customers;

    return customers.where((customer) {
      final name = customer.name?.toLowerCase() ?? '';
      final phone = customer.phone?.toLowerCase() ?? '';
      final email = customer.email?.toLowerCase() ?? '';

      return name.contains(query) ||
          phone.contains(query) ||
          email.contains(query);
    }).toList(growable: false);
  }

  CustomersState copyWith({
    CustomersStatus? status,
    List<CustomerData>? customers,
    String? searchQuery,
    int? currentPage,
    int? totalPages,
    String? responseError,
    CustomerSubmitStatus? submitStatus,
    String? submitError,
  }) {
    return CustomersState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
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
    currentPage,
    totalPages,
    responseError,
    submitStatus,
    submitError,
  ];
}