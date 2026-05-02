class CategoryProductsResponseDto {
  final String? id;
  final String? name;
  final String? description;
  final bool? isActive;
  final int? count;
  final int? totalPages;
  final int? currentPage;
  final String? next;
  final String? previous;
  final List<ProductData>? products;

  const CategoryProductsResponseDto({
    this.id, this.name, this.description, this.isActive,
    this.count, this.totalPages, this.currentPage,
    this.next, this.previous, this.products,
  });

  factory CategoryProductsResponseDto.fromJson(Map<String, dynamic> json) {
    return CategoryProductsResponseDto(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['is_active'],
      count: json['count'],
      totalPages: json['total_pages'],
      currentPage: json['current_page'],
      next: json['next'],
      previous: json['previous'],
      products: (json['products'] as List?)
          ?.map((e) => ProductData.fromJson(e))
          .toList(),
    );
  }
}

class ProductData {
  final String? id;
  final String? category;
  final String? categoryName;
  final String? name;
  final String? description;
  final String? sku;
  final String? barcode;
  final String? price;
  final String? costPrice;
  final String? image;
  final String? unit;
  final bool? isActive;
  final bool? trackInventory;
  final double? minStockLevel;
  final double? stockLevel;
  final String? createdAt;

  const ProductData({
    this.id, this.category, this.categoryName, this.name,
    this.description, this.sku, this.barcode, this.price,
    this.costPrice, this.image, this.unit, this.isActive,
    this.trackInventory, this.minStockLevel, this.stockLevel,
    this.createdAt,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      id: json['id'],
      category: json['category'],
      categoryName: json['category_name'],
      name: json['name'],
      description: json['description'],
      sku: json['sku'],
      barcode: json['barcode'],
      price: json['price'],
      costPrice: json['cost_price'],
      image: json['image'],
      unit: json['unit'],
      isActive: json['is_active'],
      trackInventory: json['track_inventory'],
      minStockLevel: (json['min_stock_level'] as num?)?.toDouble(),
      stockLevel: (json['stock_level'] as num?)?.toDouble(),
      createdAt: json['created_at'],
    );
  }


  ProductData copyWith({
    double? stockLevel,
  }) {
    return ProductData(
      id: id,
      category: category,
      categoryName: categoryName,
      name: name,
      description: description,
      sku: sku,
      barcode: barcode,
      price: price,
      costPrice: costPrice,
      image: image,
      unit: unit,
      isActive: isActive,
      trackInventory: trackInventory,
      minStockLevel: minStockLevel,
      stockLevel: stockLevel ?? this.stockLevel,
      createdAt: createdAt,
    );
  }
}