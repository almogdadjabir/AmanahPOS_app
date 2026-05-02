
import 'package:amana_pos/api/request_handler.dart';
import 'package:amana_pos/features/pos/data/models/requests/create_sale_request_dto.dart';
import 'package:amana_pos/features/pos/domain/repositories/pos_repository.dart';
import 'package:amana_pos/features/users/data/models/responses/add_user_response_dto.dart';
import 'package:fpdart/fpdart.dart';


class PosRepoImpl extends PosRepository {
  final RequestHandler requestHandler;
  PosRepoImpl(this.requestHandler);


  @override
  Future<Either<String?, AddUserResponseDto>> createSale(CreateSaleRequestDto request) {
    return requestHandler.handlePostRequest(
      'api/v1/sales/',
          (data) => AddUserResponseDto.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }


}
