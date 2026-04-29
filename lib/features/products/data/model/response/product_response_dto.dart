import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';

class ProductListResponseDto {
  final int? count;
  final int? totalPages;
  final int? currentPage;
  final String? next;
  final String? previous;
  final List<ProductData>? results;

  const ProductListResponseDto({
    this.count, this.totalPages, this.currentPage,
    this.next, this.previous, this.results,
  });

  factory ProductListResponseDto.fromJson(Map<String, dynamic> json) {
    return ProductListResponseDto(
      count: json['count'],
      totalPages:  json['total_pages'],
      currentPage: json['current_page'],
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List?)
          ?.map((e) => ProductData.fromJson(e))
          .toList(),
    );
  }
}