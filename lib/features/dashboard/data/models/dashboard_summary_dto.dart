import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';

class DashboardSummaryDto {
  final String? serverTime;
  final String timezone;
  final String currency;
  final DashboardScopeDto scope;
  final TodaySalesSummaryDto today;
  final ShiftSalesSummaryDto? shift;
  final SparklineSummaryDto sparkline;
  final List<TopSellerDto> topSellers;
  final DashboardSyncInfoDto sync;

  const DashboardSummaryDto({
    required this.serverTime,
    required this.timezone,
    required this.currency,
    required this.scope,
    required this.today,
    required this.shift,
    required this.sparkline,
    required this.topSellers,
    required this.sync,
  });

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryDto(
      serverTime: _asString(json['server_time']),
      timezone: _asString(json['timezone']) ?? 'Africa/Khartoum',
      currency: _asString(json['currency']) ?? 'SDG',
      scope: DashboardScopeDto.fromJson(
        _asMap(json['scope']),
      ),
      today: TodaySalesSummaryDto.fromJson(
        _asMap(json['today']),
      ),
      shift: json['shift'] == null
          ? null
          : ShiftSalesSummaryDto.fromJson(
        _asMap(json['shift']),
      ),
      sparkline: SparklineSummaryDto.fromJson(
        _asMap(json['sparkline']),
      ),
      topSellers: _asList(json['top_sellers'])
          .map((e) => TopSellerDto.fromJson(_asMap(e)))
          .toList(),
      sync: DashboardSyncInfoDto.fromJson(
        _asMap(json['sync']),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server_time': serverTime,
      'timezone': timezone,
      'currency': currency,
      'scope': scope.toJson(),
      'today': today.toJson(),
      'shift': shift?.toJson(),
      'sparkline': sparkline.toJson(),
      'top_sellers': topSellers.map((e) => e.toJson()).toList(),
      'sync': sync.toJson(),
    };
  }

  DashboardSummary toEntity({
    DashboardSummarySource source = DashboardSummarySource.remote,
  }) {
    return DashboardSummary(
      serverTime: serverTime,
      timezone: timezone,
      currency: currency,
      scope: scope.toEntity(),
      today: today.toEntity(),
      shift: shift?.toEntity(),
      sparkline: sparkline.toEntity(),
      topSellers: topSellers.map((e) => e.toEntity()).toList(),
      sync: sync.toEntity(),
      source: source,
    );
  }

  factory DashboardSummaryDto.fromEntity(DashboardSummary entity) {
    return DashboardSummaryDto(
      serverTime: entity.serverTime,
      timezone: entity.timezone,
      currency: entity.currency,
      scope: DashboardScopeDto.fromEntity(entity.scope),
      today: TodaySalesSummaryDto.fromEntity(entity.today),
      shift: entity.shift == null
          ? null
          : ShiftSalesSummaryDto.fromEntity(entity.shift!),
      sparkline: SparklineSummaryDto.fromEntity(entity.sparkline),
      topSellers:
      entity.topSellers.map((e) => TopSellerDto.fromEntity(e)).toList(),
      sync: DashboardSyncInfoDto.fromEntity(entity.sync),
    );
  }
}

class DashboardScopeDto {
  final String? businessId;
  final String? shopId;
  final String? shopName;

  const DashboardScopeDto({
    required this.businessId,
    required this.shopId,
    required this.shopName,
  });

  factory DashboardScopeDto.fromJson(Map<String, dynamic> json) {
    return DashboardScopeDto(
      businessId: _asString(json['business_id']),
      shopId: _asString(json['shop_id']),
      shopName: _asString(json['shop_name']),
    );
  }

  factory DashboardScopeDto.fromEntity(DashboardScope entity) {
    return DashboardScopeDto(
      businessId: entity.businessId,
      shopId: entity.shopId,
      shopName: entity.shopName,
    );
  }

  DashboardScope toEntity() {
    return DashboardScope(
      businessId: businessId,
      shopId: shopId,
      shopName: shopName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'shop_id': shopId,
      'shop_name': shopName,
    };
  }
}

class TodaySalesSummaryDto {
  final String date;
  final double grossSalesAmount;
  final double netSalesAmount;
  final int salesCount;
  final double averageSaleAmount;
  final double refundAmount;
  final int refundCount;
  final double cashAmount;
  final double bankakAmount;

  const TodaySalesSummaryDto({
    required this.date,
    required this.grossSalesAmount,
    required this.netSalesAmount,
    required this.salesCount,
    required this.averageSaleAmount,
    required this.refundAmount,
    required this.refundCount,
    required this.cashAmount,
    required this.bankakAmount,
  });

  factory TodaySalesSummaryDto.fromJson(Map<String, dynamic> json) {
    return TodaySalesSummaryDto(
      date: _asString(json['date']) ?? _formatDate(DateTime.now()),
      grossSalesAmount: _asDouble(json['gross_sales_amount']),
      netSalesAmount: _asDouble(json['net_sales_amount']),
      salesCount: _asInt(json['sales_count']),
      averageSaleAmount: _asDouble(json['average_sale_amount']),
      refundAmount: _asDouble(json['refund_amount']),
      refundCount: _asInt(json['refund_count']),
      cashAmount: _asDouble(json['cash_amount']),
      bankakAmount: _asDouble(json['bankak_amount']),
    );
  }

  factory TodaySalesSummaryDto.fromEntity(TodaySalesSummary entity) {
    return TodaySalesSummaryDto(
      date: entity.date,
      grossSalesAmount: entity.grossSalesAmount,
      netSalesAmount: entity.netSalesAmount,
      salesCount: entity.salesCount,
      averageSaleAmount: entity.averageSaleAmount,
      refundAmount: entity.refundAmount,
      refundCount: entity.refundCount,
      cashAmount: entity.cashAmount,
      bankakAmount: entity.bankakAmount,
    );
  }

  TodaySalesSummary toEntity() {
    return TodaySalesSummary(
      date: date,
      grossSalesAmount: grossSalesAmount,
      netSalesAmount: netSalesAmount,
      salesCount: salesCount,
      averageSaleAmount: averageSaleAmount,
      refundAmount: refundAmount,
      refundCount: refundCount,
      cashAmount: cashAmount,
      bankakAmount: bankakAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'gross_sales_amount': grossSalesAmount,
      'net_sales_amount': netSalesAmount,
      'sales_count': salesCount,
      'average_sale_amount': averageSaleAmount,
      'refund_amount': refundAmount,
      'refund_count': refundCount,
      'cash_amount': cashAmount,
      'bankak_amount': bankakAmount,
    };
  }
}

class ShiftSalesSummaryDto {
  final String mode;
  final String? cashierId;
  final String? cashierName;
  final String? shiftStartedAt;
  final double grossSalesAmount;
  final int salesCount;
  final double averageSaleAmount;

  const ShiftSalesSummaryDto({
    required this.mode,
    required this.cashierId,
    required this.cashierName,
    required this.shiftStartedAt,
    required this.grossSalesAmount,
    required this.salesCount,
    required this.averageSaleAmount,
  });

  factory ShiftSalesSummaryDto.fromJson(Map<String, dynamic> json) {
    return ShiftSalesSummaryDto(
      mode: _asString(json['mode']) ?? 'inferred',
      cashierId: _asString(json['cashier_id']),
      cashierName: _asString(json['cashier_name']),
      shiftStartedAt: _asString(json['shift_started_at']),
      grossSalesAmount: _asDouble(json['gross_sales_amount']),
      salesCount: _asInt(json['sales_count']),
      averageSaleAmount: _asDouble(json['average_sale_amount']),
    );
  }

  factory ShiftSalesSummaryDto.fromEntity(ShiftSalesSummary entity) {
    return ShiftSalesSummaryDto(
      mode: entity.mode,
      cashierId: entity.cashierId,
      cashierName: entity.cashierName,
      shiftStartedAt: entity.shiftStartedAt,
      grossSalesAmount: entity.grossSalesAmount,
      salesCount: entity.salesCount,
      averageSaleAmount: entity.averageSaleAmount,
    );
  }

  ShiftSalesSummary toEntity() {
    return ShiftSalesSummary(
      mode: mode,
      cashierId: cashierId,
      cashierName: cashierName,
      shiftStartedAt: shiftStartedAt,
      grossSalesAmount: grossSalesAmount,
      salesCount: salesCount,
      averageSaleAmount: averageSaleAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'cashier_id': cashierId,
      'cashier_name': cashierName,
      'shift_started_at': shiftStartedAt,
      'gross_sales_amount': grossSalesAmount,
      'sales_count': salesCount,
      'average_sale_amount': averageSaleAmount,
    };
  }
}

class SparklineSummaryDto {
  final String interval;
  final List<SparklinePointDto> points;

  const SparklineSummaryDto({
    required this.interval,
    required this.points,
  });

  factory SparklineSummaryDto.fromJson(Map<String, dynamic> json) {
    return SparklineSummaryDto(
      interval: _asString(json['interval']) ?? 'hour',
      points: _asList(json['points'])
          .map((e) => SparklinePointDto.fromJson(_asMap(e)))
          .toList(),
    );
  }

  factory SparklineSummaryDto.fromEntity(SparklineSummary entity) {
    return SparklineSummaryDto(
      interval: entity.interval,
      points: entity.points.map((e) => SparklinePointDto.fromEntity(e)).toList(),
    );
  }

  SparklineSummary toEntity() {
    return SparklineSummary(
      interval: interval,
      points: points.map((e) => e.toEntity()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interval': interval,
      'points': points.map((e) => e.toJson()).toList(),
    };
  }
}

class SparklinePointDto {
  final String label;
  final double amount;
  final int salesCount;

  const SparklinePointDto({
    required this.label,
    required this.amount,
    required this.salesCount,
  });

  factory SparklinePointDto.fromJson(Map<String, dynamic> json) {
    return SparklinePointDto(
      label: _asString(json['label']) ?? '',
      amount: _asDouble(json['amount']),
      salesCount: _asInt(json['sales_count']),
    );
  }

  factory SparklinePointDto.fromEntity(SparklinePoint entity) {
    return SparklinePointDto(
      label: entity.label,
      amount: entity.amount,
      salesCount: entity.salesCount,
    );
  }

  SparklinePoint toEntity() {
    return SparklinePoint(
      label: label,
      amount: amount,
      salesCount: salesCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'amount': amount,
      'sales_count': salesCount,
    };
  }
}

class TopSellerDto {
  final String productId;
  final String name;
  final double quantitySold;
  final double grossAmount;
  final String? thumbnailUrl;

  const TopSellerDto({
    required this.productId,
    required this.name,
    required this.quantitySold,
    required this.grossAmount,
    required this.thumbnailUrl,
  });

  factory TopSellerDto.fromJson(Map<String, dynamic> json) {
    return TopSellerDto(
      productId: _asString(json['product_id']) ?? '',
      name: _asString(json['name']) ?? 'Product',
      quantitySold: _asDouble(json['quantity_sold']),
      grossAmount: _asDouble(json['gross_amount']),
      thumbnailUrl: _asString(json['thumbnail_url']),
    );
  }

  factory TopSellerDto.fromEntity(TopSeller entity) {
    return TopSellerDto(
      productId: entity.productId,
      name: entity.name,
      quantitySold: entity.quantitySold,
      grossAmount: entity.grossAmount,
      thumbnailUrl: entity.thumbnailUrl,
    );
  }

  TopSeller toEntity() {
    return TopSeller(
      productId: productId,
      name: name,
      quantitySold: quantitySold,
      grossAmount: grossAmount,
      thumbnailUrl: thumbnailUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'quantity_sold': quantitySold,
      'gross_amount': grossAmount,
      'thumbnail_url': thumbnailUrl,
    };
  }
}

class DashboardSyncInfoDto {
  final bool includesPendingOfflineSales;
  final String? lastCalculatedAt;

  const DashboardSyncInfoDto({
    required this.includesPendingOfflineSales,
    required this.lastCalculatedAt,
  });

  factory DashboardSyncInfoDto.fromJson(Map<String, dynamic> json) {
    return DashboardSyncInfoDto(
      includesPendingOfflineSales:
      json['includes_pending_offline_sales'] == true,
      lastCalculatedAt: _asString(json['last_calculated_at']),
    );
  }

  factory DashboardSyncInfoDto.fromEntity(DashboardSyncInfo entity) {
    return DashboardSyncInfoDto(
      includesPendingOfflineSales: entity.includesPendingOfflineSales,
      lastCalculatedAt: entity.lastCalculatedAt,
    );
  }

  DashboardSyncInfo toEntity() {
    return DashboardSyncInfo(
      includesPendingOfflineSales: includesPendingOfflineSales,
      lastCalculatedAt: lastCalculatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'includes_pending_offline_sales': includesPendingOfflineSales,
      'last_calculated_at': lastCalculatedAt,
    };
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double _asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}