import 'package:amana_pos/features/category/data/models/requests/add_category_request_dto.dart';
import 'package:amana_pos/features/category/data/models/requests/edit_category_request_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/add_category_response_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/domain/repositories/category_repository.dart';
import 'package:fpdart/fpdart.dart';

class CategoryUseCase {
  final CategoryRepository repository;

  CategoryUseCase({required this.repository});

  Future<Either<String?, CategoryResponseDto>> getCategories() => repository.getCategories();
  Future<Either<String?, AddCategoryResponseDto>> addCategory(AddCategoryRequestDto request) => repository.addCategory(request);
  Future<Either<String?, bool>> deleteCategory(String categoryId) => repository.deleteCategory(categoryId);
  Future<Either<String?, bool>> editCategory(String categoryId, EditCategoryRequestDto request) => repository.editCategory(categoryId, request);



}