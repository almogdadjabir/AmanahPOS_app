import 'package:amana_pos/features/business/data/models/requests/add_business_request_dto.dart';
import 'package:amana_pos/features/business/data/models/requests/edit_business_request_dto.dart';
import 'package:amana_pos/features/business/data/models/responses/add_business_response_dto.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/domain/repositories/business_repository.dart';
import 'package:fpdart/fpdart.dart';

class BusinessUseCase {
  final BusinessRepository repository;

  BusinessUseCase({required this.repository});

  Future<Either<String?, BusinessResponseDTO>> getBusinessList() => repository.getBusinessList();
  Future<Either<String?, AddBusinessResponseDto>> addBusiness(AddBusinessRequestDto request) => repository.addBusiness(request);
  Future<Either<String?, bool>> deactivateBusiness(String businessId) => repository.deactivateBusiness(businessId);
  Future<Either<String?, bool>> editBusiness(String businessId, EditBusinessRequestDto request) => repository.editBusiness(businessId, request);

}