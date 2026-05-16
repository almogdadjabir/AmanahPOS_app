class ExpiryReportItem {
  final String id;
  final String productName;
  final String? productSku;
  final String? shopName;
  final String? batchNumber;
  final String quantity;
  final String expiryDate;
  final int daysRemaining;
  final bool isExpired;

  const ExpiryReportItem({
    required this.id,
    required this.productName,
    this.productSku,
    this.shopName,
    this.batchNumber,
    required this.quantity,
    required this.expiryDate,
    required this.daysRemaining,
    required this.isExpired,
  });

  factory ExpiryReportItem.fromJson(Map<String, dynamic> json) {
    return ExpiryReportItem(
      id: json['id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      productSku: json['product_sku']?.toString(),
      shopName: json['shop_name']?.toString(),
      batchNumber: json['batch_number']?.toString(),
      quantity: json['quantity']?.toString() ?? '0',
      expiryDate: json['expiry_date']?.toString() ?? '',
      daysRemaining: (json['days_remaining'] as num?)?.toInt() ?? 0,
      isExpired: json['is_expired'] == true,
    );
  }
}

class ExpiryReportResponseDto {
  final int count;
  final int totalPages;
  final List<ExpiryReportItem> results;

  const ExpiryReportResponseDto({
    required this.count,
    required this.totalPages,
    required this.results,
  });

  factory ExpiryReportResponseDto.fromJson(Map<String, dynamic> json) {
    return ExpiryReportResponseDto(
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      results: (json['results'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ExpiryReportItem.fromJson)
              .toList() ??
          const [],
    );
  }
}
