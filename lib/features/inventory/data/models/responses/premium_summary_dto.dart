class PremiumSummaryData {
  final int stockItemsCount;
  final int lowStockCount;
  final int outOfStockCount;
  final int expiringSoonCount;
  final int expiredCount;
  final int activeVendorsCount;
  final int inboundThisMonthCount;
  final String receivedQuantityThisMonth;

  const PremiumSummaryData({
    required this.stockItemsCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.expiringSoonCount,
    required this.expiredCount,
    required this.activeVendorsCount,
    required this.inboundThisMonthCount,
    required this.receivedQuantityThisMonth,
  });

  factory PremiumSummaryData.fromJson(Map<String, dynamic> json) {
    // API wraps payload: {"success": true, "data": {...}}
    final d = json['data'] as Map<String, dynamic>? ?? json;
    return PremiumSummaryData(
      stockItemsCount: (d['stock_items_count'] as num?)?.toInt() ?? 0,
      lowStockCount: (d['low_stock_count'] as num?)?.toInt() ?? 0,
      outOfStockCount: (d['out_of_stock_count'] as num?)?.toInt() ?? 0,
      expiringSoonCount: (d['expiring_soon_count'] as num?)?.toInt() ?? 0,
      expiredCount: (d['expired_count'] as num?)?.toInt() ?? 0,
      activeVendorsCount: (d['active_vendors_count'] as num?)?.toInt() ?? 0,
      inboundThisMonthCount:
          (d['inbound_this_month_count'] ?? d['inbound_this_month'] as num?)
                  ?.toInt() ??
              0,
      receivedQuantityThisMonth:
          (d['received_quantity_this_month'] ?? d['units_received'])
                  ?.toString() ??
              '0',
    );
  }

  Map<String, dynamic> toJson() => {
        'stock_items_count': stockItemsCount,
        'low_stock_count': lowStockCount,
        'out_of_stock_count': outOfStockCount,
        'expiring_soon_count': expiringSoonCount,
        'expired_count': expiredCount,
        'active_vendors_count': activeVendorsCount,
        'inbound_this_month_count': inboundThisMonthCount,
        'received_quantity_this_month': receivedQuantityThisMonth,
      };
}
