// ─── Domain models ────────────────────────────────────────────────────────────

class SalesReportSummary {
  final double grossSalesAmount;
  final double netSalesAmount;
  final int salesCount;
  final double averageSaleAmount;
  final double refundAmount;
  final int refundCount;

  const SalesReportSummary({
    required this.grossSalesAmount,
    required this.netSalesAmount,
    required this.salesCount,
    required this.averageSaleAmount,
    required this.refundAmount,
    required this.refundCount,
  });
}

class SalesTrendPoint {
  final String label;
  final double grossAmount;
  final double netAmount;
  final int salesCount;

  const SalesTrendPoint({
    required this.label,
    required this.grossAmount,
    required this.netAmount,
    required this.salesCount,
  });
}

class SalesTrend {
  final String interval; // "day" or "hour"
  final List<SalesTrendPoint> points;

  const SalesTrend({required this.interval, required this.points});
}

class PaymentMethodBreakdown {
  final String method;
  final double amount;
  final int count;

  const PaymentMethodBreakdown({
    required this.method,
    required this.amount,
    required this.count,
  });
}

class SalesTopProduct {
  final String productId;
  final String name;
  final double quantitySold;
  final double grossAmount;
  final String? thumbnailUrl;

  const SalesTopProduct({
    required this.productId,
    required this.name,
    required this.quantitySold,
    required this.grossAmount,
    this.thumbnailUrl,
  });
}

class SalesTopCategory {
  final String categoryId;
  final String name;
  final double quantitySold;
  final double grossAmount;

  const SalesTopCategory({
    required this.categoryId,
    required this.name,
    required this.quantitySold,
    required this.grossAmount,
  });
}

class PeakHourStat {
  final int hour;
  final int salesCount;
  final double amount;

  const PeakHourStat({
    required this.hour,
    required this.salesCount,
    required this.amount,
  });
}

class DayOfWeekStat {
  final int weekday; // 1=Monday … 7=Sunday (ISO)
  final int salesCount;
  final double amount;

  const DayOfWeekStat({
    required this.weekday,
    required this.salesCount,
    required this.amount,
  });
}

class SalesReport {
  final String rangeFrom;
  final String rangeTo;
  final String currency;
  final SalesReportSummary summary;
  final SalesTrend trend;
  final List<PaymentMethodBreakdown> paymentMethods;
  final List<SalesTopProduct> topProducts;
  final List<SalesTopCategory> topCategories;
  final List<PeakHourStat> peakHours;
  final List<DayOfWeekStat> dayOfWeek;

  const SalesReport({
    required this.rangeFrom,
    required this.rangeTo,
    required this.currency,
    required this.summary,
    required this.trend,
    required this.paymentMethods,
    required this.topProducts,
    required this.topCategories,
    required this.peakHours,
    required this.dayOfWeek,
  });

  bool get isEmpty => summary.salesCount == 0;
}

// ─── DTOs ─────────────────────────────────────────────────────────────────────

class SalesReportDto {
  final Map<String, dynamic> _json;
  const SalesReportDto._(this._json);

  factory SalesReportDto.fromJson(Map<String, dynamic> json) =>
      SalesReportDto._(json);

  SalesReport toDomain() {
    final range = (_json['range'] as Map<String, dynamic>?) ?? const {};
    final summaryJson = (_json['summary'] as Map<String, dynamic>?) ?? const {};
    final trendJson = (_json['trend'] as Map<String, dynamic>?) ?? const {};

    return SalesReport(
      rangeFrom: (range['from'] as String?) ?? '',
      rangeTo: (range['to'] as String?) ?? '',
      currency: _json['currency'] as String? ?? 'SDG',
      summary: SalesReportSummary(
        grossSalesAmount: (_summaryDouble(summaryJson, 'gross_sales_amount')),
        netSalesAmount: (_summaryDouble(summaryJson, 'net_sales_amount')),
        salesCount: summaryJson['sales_count'] as int? ?? 0,
        averageSaleAmount: (_summaryDouble(summaryJson, 'average_sale_amount')),
        refundAmount: (_summaryDouble(summaryJson, 'refund_amount')),
        refundCount: summaryJson['refund_count'] as int? ?? 0,
      ),
      trend: SalesTrend(
        interval: trendJson['interval'] as String? ?? 'day',
        points: (trendJson['points'] as List<dynamic>? ?? const []).map((p) {
          final pt = p as Map<String, dynamic>;
          return SalesTrendPoint(
            label: (pt['label'] as String?) ?? '',
            grossAmount: _d(pt['gross_amount']),
            netAmount: _d(pt['net_amount']),
            salesCount: pt['sales_count'] as int? ?? 0,
          );
        }).toList(),
      ),
      paymentMethods: (_json['payment_methods'] as List<dynamic>? ?? const []).map((p) {
        final m = p as Map<String, dynamic>;
        return PaymentMethodBreakdown(
          method: (m['method'] as String?) ?? '',
          amount: _d(m['amount']),
          count: m['count'] as int? ?? 0,
        );
      }).toList(),
      topProducts: (_json['top_products'] as List<dynamic>? ?? const []).map((p) {
        final prod = p as Map<String, dynamic>;
        return SalesTopProduct(
          productId: (prod['product_id'] as String?) ?? '',
          name: (prod['name'] as String?) ?? '',
          quantitySold: _d(prod['quantity_sold']),
          grossAmount: _d(prod['gross_amount']),
          thumbnailUrl: prod['thumbnail_url'] as String?,
        );
      }).toList(),
      topCategories: (_json['top_categories'] as List<dynamic>? ?? const []).map((p) {
        final cat = p as Map<String, dynamic>;
        return SalesTopCategory(
          categoryId: (cat['category_id'] as String?) ?? '',
          name: (cat['name'] as String?) ?? '',
          quantitySold: _d(cat['quantity_sold']),
          grossAmount: _d(cat['gross_amount']),
        );
      }).toList(),
      peakHours: (_json['peak_hours'] as List<dynamic>? ?? const []).map((p) {
        final h = p as Map<String, dynamic>;
        return PeakHourStat(
          hour: (h['hour'] as int?) ?? 0,
          salesCount: h['sales_count'] as int? ?? 0,
          amount: _d(h['amount']),
        );
      }).toList(),
      dayOfWeek: (_json['day_of_week'] as List<dynamic>? ?? const []).map((p) {
        final d = p as Map<String, dynamic>;
        return DayOfWeekStat(
          weekday: (d['weekday'] as int?) ?? 0,
          salesCount: d['sales_count'] as int? ?? 0,
          amount: _d(d['amount']),
        );
      }).toList(),
    );
  }

  static double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
  static double _summaryDouble(Map<String, dynamic> m, String key) =>
      _d(m[key]);
}
