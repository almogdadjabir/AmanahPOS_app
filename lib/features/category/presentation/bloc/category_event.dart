part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
}

class OnCategoryInitial extends CategoryEvent {
  const OnCategoryInitial();
  @override List<Object?> get props => [];
}

class OnAddCategory extends CategoryEvent {
  final String name;
  final String? description;
  final String? parentId;

  const OnAddCategory({
    required this.name,
    this.description,
    this.parentId,
  });

  @override List<Object?> get props => [name, description, parentId];
}

class OnEditCategory extends CategoryEvent {
  final String categoryId;
  final String name;
  final String? description;

  const OnEditCategory({
    required this.categoryId,
    required this.name,
    this.description,
  });

  @override List<Object?> get props => [categoryId, name, description];
}

class OnToggleCategoryActive extends CategoryEvent {
  final String categoryId;
  final bool isActive;

  const OnToggleCategoryActive({
    required this.categoryId,
    required this.isActive,
  });

  @override List<Object?> get props => [categoryId, isActive];
}