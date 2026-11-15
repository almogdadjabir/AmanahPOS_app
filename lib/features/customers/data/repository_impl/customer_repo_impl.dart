import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/features/customers/data/models/requests/customer_request_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/add_customer_response_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/customers/domain/repositories/customer_repository.dart';
import 'package:fpdart/fpdart.dart';

class CustomerRepoImpl extends CustomerRepository {
  final RequestHandler requestHandler;
  CustomerRepoImpl(this.requestHandler);

  @override
  Future<Either<String?, CustomerResponseDto>> getCustomers({
    required int page,
    required int pageSize,
    String search = '',
    CustomerActiveFilter isActive = CustomerActiveFilter.active,
  }) {
    final query = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      if (search.trim().isNotEmpty) 'search': search.trim(),
      'is_active': isActive.queryValue,
    };
    final qs = query.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    return requestHandler.handleGetRequest(
      'api/v1/customers/?$qs',
      (data) => CustomerResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, AddCustomerResponseDto>> createCustomer({
    required CustomerRequestDto request,
  }) {
    return requestHandler.handlePostRequest(
      'api/v1/customers/',
      (data) => AddCustomerResponseDto.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, AddCustomerResponseDto>> updateCustomer({
    required String customerId,
    required CustomerRequestDto request,
  }) {
    return requestHandler.handlePatchRequest(
      'api/v1/customers/$customerId/',
      (data) => AddCustomerResponseDto.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, AddCustomerResponseDto>> setCustomerActive({
    required String customerId,
    required bool isActive,
  }) {
    return requestHandler.handlePatchRequest(
      'api/v1/customers/$customerId/',
      (data) => AddCustomerResponseDto.fromJson(data as Map<String, dynamic>),
      data: {'is_active': isActive},
    );
  }
}
