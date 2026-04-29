
import 'package:amana_pos/features/category/data/models/requests/add_category_request_dto.dart';
import 'package:amana_pos/features/category/data/models/requests/edit_category_request_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/add_category_response_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class CategoryRepository {

  Future<Either<String?, CategoryResponseDto>> getCategories();
  Future<Either<String?, AddCategoryResponseDto>> addCategory(AddCategoryRequestDto request);
  Future<Either<String?, bool>> deleteCategory(String categoryId);
  Future<Either<String?, bool>> editCategory(String categoryId, EditCategoryRequestDto request);
}
