class CategoryResponseDto {
  final bool? success;
  final List<CategoryData>? data;

  const CategoryResponseDto({this.success, this.data});

  factory CategoryResponseDto.fromJson(Map<String, dynamic> json) {
    return CategoryResponseDto(
      success: json['success'],
      data: (json['data'] as List?)
          ?.map((e) => CategoryData.fromJson(e))
          .toList(),
    );
  }
}

class CategoryData {
  final String? id;
  final String? tenant;
  final String? parent;
  final String? name;
  final String? description;
  final String? image;
  final bool? isActive;
  final int? sortOrder;
  final List<CategoryData>? children;
  final String? createdAt;
  final String? updatedAt;

  const CategoryData({
    this.id,
    this.tenant,
    this.parent,
    this.name,
    this.description,
    this.image,
    this.isActive,
    this.sortOrder,
    this.children,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      id:          json['id'],
      tenant:      json['tenant'],
      parent:      json['parent'],
      name:        json['name'],
      description: json['description'],
      image:       json['image'],
      isActive:    json['is_active'],
      sortOrder:   json['sort_order'],
      children:    (json['children'] as List?)
          ?.map((e) => CategoryData.fromJson(e))
          .toList(),
      createdAt:   json['created_at'],
      updatedAt:   json['updated_at'],
    );
  }

  CategoryData copyWith({
    String? name,
    String? description,
    bool? isActive,
    int? sortOrder,
    List<CategoryData>? children,
  }) {
    return CategoryData(
      id:          id,
      tenant:      tenant,
      parent:      parent,
      name:        name        ?? this.name,
      description: description ?? this.description,
      image:       image,
      isActive:    isActive    ?? this.isActive,
      sortOrder:   sortOrder   ?? this.sortOrder,
      children:    children    ?? this.children,
      createdAt:   createdAt,
      updatedAt:   updatedAt,
    );
  }
}