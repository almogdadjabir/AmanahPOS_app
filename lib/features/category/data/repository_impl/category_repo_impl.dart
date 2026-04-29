
import 'package:amana_pos/api/request_handler.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/domain/repositories/category_repository.dart';
import 'package:fpdart/fpdart.dart';

class CategoryRepoImpl extends CategoryRepository {
  final RequestHandler requestHandler;
  CategoryRepoImpl(this.requestHandler);


  @override
  Future<Either<String?, CategoryResponseDto>> getCategories() {
    return requestHandler.handleGetRequest(
      'api/v1/products/categories/',
          (data) => CategoryResponseDto.fromJson(data as Map<String, dynamic>),
    );
  }

  // @override
  // Future<Either<String?, AddUserResponseDto>> addCategory(AddUserRequestDto request) {
  //   return requestHandler.handlePostRequest(
  //     'api/v1/products/categories/',
  //         (data) => AddUserResponseDto.fromJson(data as Map<String, dynamic>),
  //     data: request.toJson(),
  //   );
  // }
  //
  // @override
  // Future<Either<String?, bool>> deactivateUser(String userId) {
  //   return requestHandler.handleDeleteRequest(
  //     'api/v1/users/$userId',
  //         (_) => true,
  //   );
  // }
  //
  // @override
  // Future<Either<String?, bool>> editCategory(String userId, EditUserRequestDto request) {
  //   return requestHandler.handlePatchRequest(
  //     'api/v1/users/$userId/',
  //         (_) => true,
  //     data: request.toJson(),
  //   );
  // }

}
