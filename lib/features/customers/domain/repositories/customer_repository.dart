import 'package:amana_pos/features/customers/data/models/requests/customer_request_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/add_customer_response_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:fpdart/fpdart.dart';

/// Server-side status filter for the customer list.
enum CustomerActiveFilter {
  active,
  inactive,
  all;

  String get queryValue => switch (this) {
    CustomerActiveFilter.active => 'true',
    CustomerActiveFilter.inactive => 'false',
    CustomerActiveFilter.all => 'all',
  };
}

abstract class CustomerRepository {
  Future<Either<String?, CustomerResponseDto>> getCustomers({
    required int page,
    required int pageSize,
    String search = '',
    CustomerActiveFilter isActive = CustomerActiveFilter.active,
  });

  Future<Either<String?, AddCustomerResponseDto>> createCustomer({
    required CustomerRequestDto request,
  });

  Future<Either<String?, AddCustomerResponseDto>> updateCustomer({
    required String customerId,
    required CustomerRequestDto request,
  });

  /// PATCH is_active. Used for both deactivate and reactivate.
  Future<Either<String?, AddCustomerResponseDto>> setCustomerActive({
    required String customerId,
    required bool isActive,
  });
}
