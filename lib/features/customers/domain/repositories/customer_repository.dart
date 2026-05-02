import 'package:amana_pos/features/customers/data/models/requests/customer_request_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/add_customer_response_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class CustomerRepository {

  Future<Either<String?, CustomerResponseDto>> getCustomers({
    required int page,
    required int pageSize,
  });

  Future<Either<String?, AddCustomerResponseDto>> createCustomer({
    required CustomerRequestDto request,
  });

}
