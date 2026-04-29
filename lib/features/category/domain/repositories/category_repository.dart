
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:fpdart/fpdart.dart';

abstract class CategoryRepository {

  Future<Either<String?, CategoryResponseDto>> getCategories();
}
