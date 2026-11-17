import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/features/category/data/models/requests/edit_category_request_dto.dart';
import 'package:fpdart/fpdart.dart';

/// Category writes (Phase 3): local row + outbox through `CategoryService`,
/// never REST. Reads come from SQLite. Left = a user-facing message.
abstract class CategoryRepository {
  /// Returns the new category id; [image] is staged for upload.
  Future<Either<String, String>> addCategory({
    required String name,
    String? description,
    String? parent,
    PickedAppImage? image,
  });

  Future<Either<String, Unit>> editCategory(
    String categoryId,
    EditCategoryRequestDto request, {
    PickedAppImage? image,
  });

  Future<Either<String, Unit>> deleteCategory(String categoryId);
}
