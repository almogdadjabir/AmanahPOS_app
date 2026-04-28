
import 'package:amana_pos/api/request_handler.dart';
import 'package:amana_pos/features/business/data/models/requests/add_business_request_dto.dart';
import 'package:amana_pos/features/business/data/models/requests/edit_business_request_dto.dart';
import 'package:amana_pos/features/business/data/models/responses/add_business_response_dto.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/business/domain/repositories/business_repository.dart';
import 'package:fpdart/fpdart.dart';

class BusinessRepoImpl extends BusinessRepository {
  final RequestHandler requestHandler;
  BusinessRepoImpl(this.requestHandler);


  @override
  Future<Either<String?, BusinessResponseDTO>> getBusinessList() {
    return requestHandler.handleGetRequest(
      'api/v1/tenants/businesses/',
        (data) => BusinessResponseDTO.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<String?, AddBusinessResponseDto>> addBusiness(AddBusinessRequestDto request) {
    return requestHandler.handlePostRequest(
      'api/v1/tenants/businesses/',
          (data) => AddBusinessResponseDto.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }

  @override
  Future<Either<String?, bool>> deactivateBusiness(String businessId) {
    return requestHandler.handleDeleteRequest(
      'api/v1/tenants/businesses/$businessId/',
          (_) => true,
    );
  }

  @override
  Future<Either<String?, bool>> editBusiness(String businessId, EditBusinessRequestDto request) {
    return requestHandler.handlePatchRequest(
      'api/v1/tenants/businesses/$businessId/',
          (_) => true,
      data: request.toJson(),
    );
  }

}
