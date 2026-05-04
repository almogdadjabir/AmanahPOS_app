
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
  }) {
    return requestHandler.handleGetRequest(
      'api/v1/customers/?page=$page&page_size=$pageSize',
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

}
