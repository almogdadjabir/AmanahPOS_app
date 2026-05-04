import 'package:amana_pos/features/business/data/models/responses/business_response_dto.dart';
import 'package:amana_pos/features/category/data/models/responses/category_response_dto.dart';
import 'package:amana_pos/features/customers/data/models/responses/customer_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/products/data/model/response/category_products_response_dto.dart';

class OfflineBootstrapDto {
  final bool success;
  final String? serverTime;
  final List<BusinessData> businesses;
  final List<Shops> shops;
  final List<CategoryData> categories;
  final List<ProductData> products;
  final List<CustomerData> customers;
  final List<StockData> stock;

  const OfflineBootstrapDto({
    required this.success,
    required this.serverTime,
    required this.businesses,
    required this.shops,
    required this.categories,
    required this.products,
    required this.customers,
    required this.stock,
  });

  factory OfflineBootstrapDto.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;

    return OfflineBootstrapDto(
      success: map['success'] == true,
      serverTime: map['server_time']?.toString(),
      businesses: (map['businesses'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BusinessData.fromJson)
          .toList(),
      shops: (map['shops'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Shops.fromJson)
          .toList(),
      categories: (map['categories'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CategoryData.fromJson)
          .toList(),
      products: (map['products'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ProductData.fromJson)
          .toList(),
      customers: (map['customers'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CustomerData.fromJson)
          .toList(),
      stock: (map['stock'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(StockData.fromJson)
          .toList(),
    );
  }

  bool get hasUsableData {
    return businesses.isNotEmpty || products.isNotEmpty || categories.isNotEmpty;
  }
}