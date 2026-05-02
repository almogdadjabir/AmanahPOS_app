part of 'customers_bloc.dart';

sealed class CustomersEvent extends Equatable {
  const CustomersEvent();

  @override
  List<Object?> get props => [];
}

class OnCustomersInitial extends CustomersEvent {
  const OnCustomersInitial();
}

class OnLoadMoreCustomers extends CustomersEvent {
  const OnLoadMoreCustomers();
}

class OnCustomerSearchChanged extends CustomersEvent {
  final String query;

  const OnCustomerSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class OnCreateCustomer extends CustomersEvent {
  final CustomerRequestDto dto;

  const OnCreateCustomer({
    required this.dto,
  });

  @override
  List<Object?> get props => [dto];
}

class OnUpdateCustomer extends CustomersEvent {
  final String customerId;
  final CustomerRequestDto dto;

  const OnUpdateCustomer({
    required this.customerId,
    required this.dto,
  });

  @override
  List<Object?> get props => [customerId, dto];
}

class OnDeleteCustomer extends CustomersEvent {
  final String customerId;

  const OnDeleteCustomer({
    required this.customerId,
  });

  @override
  List<Object?> get props => [customerId];
}

class OnAcknowledgeCustomerSubmit extends CustomersEvent {
  const OnAcknowledgeCustomerSubmit();
}