
import 'package:amana_pos/features/business/data/models/requests/add_business_request_dto.dart';
import 'package:amana_pos/features/business/data/models/requests/add_shop_request_dto.dart';
import 'package:amana_pos/features/business/data/models/requests/edit_business_request_dto.dart';
import 'package:amana_pos/features/business/data/models/requests/edit_shop_request_dto.dart';
import 'package:amana_pos/features/business/data/models/responses/add_business_response_dto.dart';
import 'package:amana_pos/features/business/data/models/responses/add_shop_response_dto.dart';
import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class BusinessRepository {
  Future<Either<String?, BusinessResponseDTO>> getBusinessList();
  Future<Either<String?, AddBusinessResponseDto>> addBusiness(AddBusinessRequestDto request);
  Future<Either<String?, bool>> deactivateBusiness(String businessId);
  Future<Either<String?, bool>> editBusiness(String businessId, EditBusinessRequestDto request);
  Future<Either<String?, AddShopResponseDto>> addShop(String businessId, AddShopRequestDto request);
  Future<Either<String?, bool>> editShop(String businessId, String shopId, EditShopRequestDto request);
}
