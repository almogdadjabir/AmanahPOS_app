import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/features/category/data/models/requests/edit_category_request_dto.dart';
import 'package:amana_pos/features/category/domain/repositories/category_repository.dart';
import 'package:fpdart/fpdart.dart';

class CategoryUseCase {
  final CategoryRepository repository;

  CategoryUseCase({required this.repository});

  Future<Either<String, String>> addCategory({
    required String name,
    String? description,
    String? parent,
    PickedAppImage? image,
  }) => repository.addCategory(
    name: name,
    description: description,
    parent: parent,
    image: image,
  );

  Future<Either<String, Unit>> editCategory(
    String categoryId,
    EditCategoryRequestDto request, {
    PickedAppImage? image,
  }) => repository.editCategory(categoryId, request, image: image);

  Future<Either<String, Unit>> deleteCategory(String categoryId) =>
      repository.deleteCategory(categoryId);
}
