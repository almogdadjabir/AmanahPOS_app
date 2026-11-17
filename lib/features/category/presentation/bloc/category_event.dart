part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();
}

class OnCategoryInitial extends CategoryEvent {
  final bool force;
  const OnCategoryInitial({this.force = false});
  @override List<Object?> get props => [];
}

/// A local write or a pull touched [CategoryBloc.watchedTables]: re-read.
class OnCategoriesChanged extends CategoryEvent {
  const OnCategoriesChanged();
  @override List<Object?> get props => [];
}

/// Pull to refresh: ask the server for changes (see `requestCatalogSync`).
class OnCategoriesSyncRequested extends CategoryEvent {
  const OnCategoriesSyncRequested();
  @override List<Object?> get props => [];
}

class OnAddCategory extends CategoryEvent {
  final String name;
  final String? description;
  final String? parentId;

  /// Staged locally and uploaded in the background.
  final PickedAppImage? image;

  const OnAddCategory({
    required this.name,
    this.description,
    this.parentId,
    this.image,
  });

  @override List<Object?> get props => [name, description, parentId, image];
}

class OnEditCategory extends CategoryEvent {
  final String categoryId;
  final String name;
  final String? description;

  /// A new image (null = unchanged), staged and uploaded in the background.
  final PickedAppImage? image;

  const OnEditCategory({
    required this.categoryId,
    required this.name,
    this.description,
    this.image,
  });

  @override List<Object?> get props => [categoryId, name, description, image];
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

class OnLoadCategoryProducts extends CategoryEvent {
  final String categoryId;
  final int page;

  const OnLoadCategoryProducts({required this.categoryId, this.page = 1});

  @override List<Object?> get props => [categoryId, page];
}

class OnLoadMoreCategoryProducts extends CategoryEvent {
  final String categoryId;
  const OnLoadMoreCategoryProducts({required this.categoryId});
  @override List<Object?> get props => [categoryId];
}

class OnDeleteCategory extends CategoryEvent {
  final String categoryId;
  const OnDeleteCategory({required this.categoryId});
  @override List<Object?> get props => [categoryId];
}

class OnCategoryReset extends CategoryEvent {
  const OnCategoryReset();

  @override List<Object?> get props => throw UnimplementedError();
}
