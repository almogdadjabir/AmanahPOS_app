class StockResponseDto {
  final int? count;
  final int? totalPages;
  final int? currentPage;
  final String? next;
  final String? previous;
  final List<StockData>? results;

  const StockResponseDto({
    this.count, this.totalPages, this.currentPage,
    this.next, this.previous, this.results,
  });

  factory StockResponseDto.fromJson(Map<String, dynamic> json) {
    return StockResponseDto(
      count: json['count'],
      totalPages:  json['total_pages'],
      currentPage: json['current_page'],
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List?)
          ?.map((e) => StockData.fromJson(e))
          .toList(),
    );
  }
}

class StockData {
  final String? id;
  final String? product;
  final String? productName;
  final String? productSku;
  final String? shop;
  final String? shopName;
  final String? quantity;
  final bool? isLowStock;
  final bool? isOutOfStock;
  final String? updatedAt;

  const StockData({
    this.id, this.product, this.productName, this.productSku,
    this.shop, this.shopName, this.quantity,
    this.isLowStock, this.isOutOfStock, this.updatedAt,
  });

  factory StockData.fromJson(Map<String, dynamic> json) {
    return StockData(
      id: json['id'],
      product: json['product'],
      productName: json['product_name'],
      productSku: json['product_sku'],
      shop: json['shop'],
      shopName: json['shop_name'],
      quantity: json['quantity'],
      isLowStock: json['is_low_stock'],
      isOutOfStock: json['is_out_of_stock'],
      updatedAt: json['updated_at'],
    );
  }

  double get qty => double.tryParse(quantity ?? '0') ?? 0;
}