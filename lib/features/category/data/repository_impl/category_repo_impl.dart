
import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/features/category/data/models/requests/add_category_request_dto.dart';
import 'package:amana_pos/features/category/data/models/requests/edit_category_request_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/add_category_response_dto.dart';
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



  @override
  Future<Either<String?, AddCategoryResponseDto>> addCategory(AddCategoryRequestDto request) {
    return requestHandler.handlePostRequest(
      'api/v1/products/categories/',
          (data) => AddCategoryResponseDto.fromJson(data as Map<String, dynamic>),
      data: request.toJson(),
    );
  }


  @override
  Future<Either<String?, bool>> deleteCategory(String categoryId) {
    return requestHandler.handleDeleteRequest(
      'api/v1/products/categories/$categoryId/',
          (_) => true,
    );
  }

  @override
  Future<Either<String?, bool>> editCategory(String categoryId, EditCategoryRequestDto request) {
    return requestHandler.handlePatchRequest(
      'api/v1/products/categories/$categoryId/',
          (_) => true,
      data: request.toJson(),
    );
  }

}
