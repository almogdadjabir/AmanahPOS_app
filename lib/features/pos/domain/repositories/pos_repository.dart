import 'package:amana_pos/features/pos/data/models/requests/create_sale_request_dto.dart';
import 'package:amana_pos/features/users/data/models/responses/add_user_response_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class PosRepository {
  Future<Either<String?, AddUserResponseDto>> createSale(CreateSaleRequestDto request);
}
