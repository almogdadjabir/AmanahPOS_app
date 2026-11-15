import 'package:amana_pos/features/returns/data/models/requests/refund_request_dto.dart';
import 'package:amana_pos/features/returns/data/models/responses/refund_response_dto.dart';
import 'package:amana_pos/features/returns/domain/repositories/returns_repository.dart';
import 'package:fpdart/fpdart.dart';

class ReturnsUseCase {
  final ReturnsRepository repository;
  ReturnsUseCase({required this.repository});

  Future<Either<String?, RefundResponseDto>> processRefund({
    required String saleId,
    required RefundRequestDto request,
  }) => repository.processRefund(saleId: saleId, request: request);
}
