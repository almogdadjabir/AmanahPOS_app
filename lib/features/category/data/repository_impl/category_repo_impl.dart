import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/core/sync/catalog_result.dart';
import 'package:amana_pos/features/category/data/models/requests/edit_category_request_dto.dart';
import 'package:amana_pos/features/category/domain/category_service.dart';
import 'package:amana_pos/features/category/domain/repositories/category_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Local-only: every write goes through [CategoryService]. No REST client.
class CategoryRepoImpl extends CategoryRepository {
  CategoryRepoImpl({required CategoryService Function() service})
    : _service = service;

  final CategoryService Function() _service;

  @override
  Future<Either<String, String>> addCategory({
    required String name,
    String? description,
    String? parent,
    PickedAppImage? image,
  }) => catalogResult(
    () => _service().create(
      name: name,
      description: description,
      parent: parent,
      image: image,
    ),
  );

  @override
  Future<Either<String, Unit>> editCategory(
    String categoryId,
    EditCategoryRequestDto request, {
    PickedAppImage? image,
  }) => catalogResult(() async {
    await _service().update(categoryId, request, image: image);
    return unit;
  });

  @override
  Future<Either<String, Unit>> deleteCategory(String categoryId) =>
      catalogResult(() async {
        await _service().delete(categoryId);
        return unit;
      });
}
