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

  /// Keep this as String? if many old UI/code places depend on it.
  /// But fromJson will safely accept int/double/String.
  final String? quantity;

  final bool? isLowStock;
  final bool? isOutOfStock;
  final String? updatedAt;

  const StockData({
    this.id,
    this.product,
    this.productName,
    this.productSku,
    this.shop,
    this.shopName,
    this.quantity,
    this.isLowStock,
    this.isOutOfStock,
    this.updatedAt,
  });

  factory StockData.fromJson(Map<String, dynamic> json) {
    final qty = _parseQuantityAsString(json['quantity']);

    return StockData(
      id: json['id']?.toString(),
      product: json['product']?.toString(),
      productName: json['product_name']?.toString(),
      productSku: json['product_sku']?.toString(),
      shop: json['shop']?.toString(),
      shopName: json['shop_name']?.toString(),
      quantity: qty,
      isLowStock: _parseBool(json['is_low_stock']),
      isOutOfStock: _parseBool(json['is_out_of_stock']),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  double get qty {
    final raw = quantity;
    if (raw == null || raw.trim().isEmpty) return 0;
    return double.tryParse(raw) ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product,
      'product_name': productName,
      'product_sku': productSku,
      'shop': shop,
      'shop_name': shopName,
      'quantity': quantity,
      'is_low_stock': isLowStock,
      'is_out_of_stock': isOutOfStock,
      'updated_at': updatedAt,
    };
  }

  StockData copyWith({
    String? id,
    String? product,
    String? productName,
    String? productSku,
    String? shop,
    String? shopName,
    Object? quantity = _noChange,
    bool? isLowStock,
    bool? isOutOfStock,
    String? updatedAt,
  }) {
    return StockData(
      id: id ?? this.id,
      product: product ?? this.product,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      shop: shop ?? this.shop,
      shopName: shopName ?? this.shopName,
      quantity: quantity == _noChange
          ? this.quantity
          : _parseQuantityAsString(quantity),
      isLowStock: isLowStock ?? this.isLowStock,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String? _parseQuantityAsString(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toString();
    }

    if (value is String) {
      final cleaned = value.trim();
      if (cleaned.isEmpty) return null;

      final parsed = double.tryParse(cleaned);
      return parsed?.toString() ?? cleaned;
    }

    return value.toString();
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;

    if (value is String) {
      final clean = value.trim().toLowerCase();
      if (clean == 'true' || clean == '1' || clean == 'yes') return true;
      if (clean == 'false' || clean == '0' || clean == 'no') return false;
    }

    return null;
  }
}

const Object _noChange = Object();