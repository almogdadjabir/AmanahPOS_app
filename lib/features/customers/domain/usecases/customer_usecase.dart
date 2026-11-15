import 'package:amana_pos/features/customers/data/models/requests/customer_request_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/add_customer_response_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/domain/repositories/customer_repository.dart';
import 'package:fpdart/fpdart.dart';

class CustomerUseCase {
  final CustomerRepository repository;

  CustomerUseCase({required this.repository});

  Future<Either<String?, CustomerResponseDto>> getCustomers({
    required int page,
    required int pageSize,
    String search = '',
    CustomerActiveFilter isActive = CustomerActiveFilter.active,
  }) => repository.getCustomers(
    page: page,
    pageSize: pageSize,
    search: search,
    isActive: isActive,
  );

  Future<Either<String?, AddCustomerResponseDto>> createCustomer({
    required CustomerRequestDto request,
  }) => repository.createCustomer(request: request);

  Future<Either<String?, AddCustomerResponseDto>> updateCustomer({
    required String customerId,
    required CustomerRequestDto request,
  }) => repository.updateCustomer(customerId: customerId, request: request);

  Future<Either<String?, AddCustomerResponseDto>> setCustomerActive({
    required String customerId,
    required bool isActive,
  }) =>
      repository.setCustomerActive(customerId: customerId, isActive: isActive);
}
