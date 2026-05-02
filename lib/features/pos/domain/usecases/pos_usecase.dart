import 'package:amana_pos/features/pos/data/models/requests/create_sale_request_dto.dart';
import 'package:amana_pos/features/pos/domain/repositories/pos_repository.dart';
import 'package:amana_pos/features/users/data/models/responses/add_user_response_dto.dart';
import 'package:fpdart/fpdart.dart';

class PosUseCase {
  final PosRepository repository;

  PosUseCase({required this.repository});

  Future<Either<String?, AddUserResponseDto>> createSale(CreateSaleRequestDto request) =>
      repository.createSale(request);

}