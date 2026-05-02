import 'package:amana_pos/features/category/data/models/requests/add_category_request_dto.dart';
import 'package:amana_pos/features/category/data/models/requests/edit_category_request_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/add_category_response_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/domain/repositories/category_repository.dart';
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
  }) => repository.getCustomers(page: page, pageSize: pageSize);

  Future<Either<String?, AddCustomerResponseDto>> createCustomer({
    required CustomerRequestDto request,
  }) => repository.createCustomer(request: request);
}