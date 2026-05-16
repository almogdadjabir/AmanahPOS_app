class VendorSummaryItem {
  final String vendorId;
  final String vendorName;
  final int transactionsCount;
  final String totalQuantity;

  const VendorSummaryItem({
    required this.vendorId,
    required this.vendorName,
    required this.transactionsCount,
    required this.totalQuantity,
  });

  factory VendorSummaryItem.fromJson(Map<String, dynamic> json) {
    return VendorSummaryItem(
      vendorId: json['vendor_id']?.toString() ?? '',
      vendorName: json['vendor_name']?.toString() ?? '',
      transactionsCount: (json['transactions_count'] as num?)?.toInt() ?? 0,
      totalQuantity: json['total_quantity']?.toString() ?? '0',
    );
  }
}

class VendorSummaryData {
  final int totalTransactions;
  final String totalQuantity;
  final List<VendorSummaryItem> vendors;

  const VendorSummaryData({
    required this.totalTransactions,
    required this.totalQuantity,
    required this.vendors,
  });

  factory VendorSummaryData.fromJson(Map<String, dynamic> json) {
    // API wraps payload: {"success": true, "data": {...}}
    final d = json['data'] as Map<String, dynamic>? ?? json;
    return VendorSummaryData(
      totalTransactions: (d['total_transactions'] as num?)?.toInt() ?? 0,
      totalQuantity: d['total_quantity']?.toString() ?? '0',
      vendors: (d['vendors'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(VendorSummaryItem.fromJson)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'total_transactions': totalTransactions,
        'total_quantity': totalQuantity,
        'vendors': vendors
            .map((v) => {
                  'vendor_id': v.vendorId,
                  'vendor_name': v.vendorName,
                  'transactions_count': v.transactionsCount,
                  'total_quantity': v.totalQuantity,
                })
            .toList(),
      };
}
