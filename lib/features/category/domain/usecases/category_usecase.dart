import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/category/domain/repositories/category_repository.dart';
import 'package:fpdart/fpdart.dart';

class CategoryUseCase {
  final CategoryRepository repository;

  CategoryUseCase({required this.repository});

  Future<Either<String?, CategoryResponseDto>> getCategories() => repository.getCategories();


}