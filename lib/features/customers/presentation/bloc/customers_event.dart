part of 'customers_bloc.dart';

sealed class CustomersEvent extends Equatable {
  const CustomersEvent();

  @override
  List<Object?> get props => [];
}

/// Loads page 1 with the current search and status filter. [silent] keeps
/// the current rows on screen instead of showing the skeleton (pull to
/// refresh, after a save).
class OnCustomersInitial extends CustomersEvent {
  final bool silent;

  /// Completed when the load has finished (used by pull to refresh).
  final Completer<void>? done;

  const OnCustomersInitial({this.silent = false, this.done});

  @override
  List<Object?> get props => [silent];
}

class OnLoadMoreCustomers extends CustomersEvent {
  const OnLoadMoreCustomers();
}

/// Debounced, server-side search: reloads page 1 with `search=`.
class OnCustomerSearchChanged extends CustomersEvent {
  final String query;

  const OnCustomerSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Switches between the Active and Inactive chips (server-side `is_active`).
class OnCustomerFilterChanged extends CustomersEvent {
  final CustomerActiveFilter filter;

  const OnCustomerFilterChanged(this.filter);

  @override
  List<Object?> get props => [filter];
}

class OnCreateCustomer extends CustomersEvent {
  final CustomerRequestDto dto;

  const OnCreateCustomer({required this.dto});

  @override
  List<Object?> get props => [dto];
}

class OnUpdateCustomer extends CustomersEvent {
  final String customerId;
  final CustomerRequestDto dto;

  const OnUpdateCustomer({required this.customerId, required this.dto});

  @override
  List<Object?> get props => [customerId, dto];
}

/// PATCH is_active. false = deactivate, true = reactivate.
class OnSetCustomerActive extends CustomersEvent {
  final String customerId;
  final bool isActive;

  const OnSetCustomerActive({required this.customerId, required this.isActive});

  @override
  List<Object?> get props => [customerId, isActive];
}

class OnAcknowledgeCustomerSubmit extends CustomersEvent {
  const OnAcknowledgeCustomerSubmit();
}
