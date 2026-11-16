import 'package:equatable/equatable.dart';

enum DashboardSummarySource { remote, cache }

class DashboardSummary extends Equatable {
  final String? serverTime;
  final String timezone;
  final String currency;
  final DashboardScope scope;
  final TodaySalesSummary today;
  final ShiftSalesSummary? shift;
  final SparklineSummary sparkline;
  final List<TopSeller> topSellers;
  final DashboardSyncInfo sync;
  final DashboardSummarySource source;
  final bool includesLocalPendingSales;

  const DashboardSummary({
    required this.serverTime,
    required this.timezone,
    required this.currency,
    required this.scope,
    required this.today,
    required this.shift,
    required this.sparkline,
    required this.topSellers,
    required this.sync,
    this.source = DashboardSummarySource.remote,
    this.includesLocalPendingSales = false,
  });

  DashboardSummary copyWith({
    String? serverTime,
    String? timezone,
    String? currency,
    DashboardScope? scope,
    TodaySalesSummary? today,
    ShiftSalesSummary? shift,
    SparklineSummary? sparkline,
    List<TopSeller>? topSellers,
    DashboardSyncInfo? sync,
    DashboardSummarySource? source,
    bool? includesLocalPendingSales,
  }) {
    return DashboardSummary(
      serverTime: serverTime ?? this.serverTime,
      timezone: timezone ?? this.timezone,
      currency: currency ?? this.currency,
      scope: scope ?? this.scope,
      today: today ?? this.today,
      shift: shift ?? this.shift,
      sparkline: sparkline ?? this.sparkline,
      topSellers: topSellers ?? this.topSellers,
      sync: sync ?? this.sync,
      source: source ?? this.source,
      includesLocalPendingSales:
          includesLocalPendingSales ?? this.includesLocalPendingSales,
    );
  }

  List<double> get sparklineAmounts {
    return sparkline.points.map((e) => e.amount).toList();
  }

  String get liveLabel {
    if (includesLocalPendingSales) return 'OFFLINE + API';
    if (source == DashboardSummarySource.cache) return 'CACHED';
    return 'LIVE';
  }

  factory DashboardSummary.empty({
    required String date,
    String timezone = 'Africa/Khartoum',
    String currency = 'SDG',
    String? businessId,
    String? shopId,
  }) {
    return DashboardSummary(
      serverTime: null,
      timezone: timezone,
      currency: currency,
      scope: DashboardScope(
        businessId: businessId,
        shopId: shopId,
        shopName: null,
      ),
      today: TodaySalesSummary.empty(date: date),
      shift: const ShiftSalesSummary(
        mode: 'inferred',
        cashierId: null,
        cashierName: null,
        shiftStartedAt: null,
        grossSalesAmount: 0,
        salesCount: 0,
        averageSaleAmount: 0,
      ),
      sparkline: const SparklineSummary(interval: 'hour', points: []),
      topSellers: const [],
      sync: const DashboardSyncInfo(
        includesPendingOfflineSales: false,
        lastCalculatedAt: null,
      ),
      source: DashboardSummarySource.cache,
    );
  }

  @override
  List<Object?> get props => [
    serverTime,
    timezone,
    currency,
    scope,
    today,
    shift,
    sparkline,
    topSellers,
    sync,
    source,
    includesLocalPendingSales,
  ];
}

class DashboardScope extends Equatable {
  final String? businessId;
  final String? shopId;
  final String? shopName;

  const DashboardScope({this.businessId, this.shopId, this.shopName});

  @override
  List<Object?> get props => [businessId, shopId, shopName];
}

class TodaySalesSummary extends Equatable {
  final String date;
  final double grossSalesAmount;
  final double netSalesAmount;
  final int salesCount;
  final double averageSaleAmount;
  final double refundAmount;
  final int refundCount;
  final double cashAmount;
  final double bankakAmount;
  final double otherAmount;
  final List<PaymentBreakdownItem> paymentBreakdown;
  final double refundCashAmount;
  final double refundBankakAmount;
  final double customAmount;
  final int customCount;
  final SalesComparison? comparison;

  const TodaySalesSummary({
    required this.date,
    required this.grossSalesAmount,
    required this.netSalesAmount,
    required this.salesCount,
    required this.averageSaleAmount,
    required this.refundAmount,
    required this.refundCount,
    required this.cashAmount,
    required this.bankakAmount,
    this.otherAmount = 0,
    this.paymentBreakdown = const [],
    this.refundCashAmount = 0,
    this.refundBankakAmount = 0,
    this.customAmount = 0,
    this.customCount = 0,
    this.comparison,
  });

  factory TodaySalesSummary.empty({required String date}) {
    return TodaySalesSummary(
      date: date,
      grossSalesAmount: 0,
      netSalesAmount: 0,
      salesCount: 0,
      averageSaleAmount: 0,
      refundAmount: 0,
      refundCount: 0,
      cashAmount: 0,
      bankakAmount: 0,
    );
  }

  TodaySalesSummary copyWith({
    String? date,
    double? grossSalesAmount,
    double? netSalesAmount,
    int? salesCount,
    double? averageSaleAmount,
    double? refundAmount,
    int? refundCount,
    double? cashAmount,
    double? bankakAmount,
    double? otherAmount,
    List<PaymentBreakdownItem>? paymentBreakdown,
  }) {
    return TodaySalesSummary(
      date: date ?? this.date,
      grossSalesAmount: grossSalesAmount ?? this.grossSalesAmount,
      netSalesAmount: netSalesAmount ?? this.netSalesAmount,
      salesCount: salesCount ?? this.salesCount,
      averageSaleAmount: averageSaleAmount ?? this.averageSaleAmount,
      refundAmount: refundAmount ?? this.refundAmount,
      refundCount: refundCount ?? this.refundCount,
      cashAmount: cashAmount ?? this.cashAmount,
      bankakAmount: bankakAmount ?? this.bankakAmount,
      otherAmount: otherAmount ?? this.otherAmount,
      paymentBreakdown: paymentBreakdown ?? this.paymentBreakdown,
      refundCashAmount: refundCashAmount,
      refundBankakAmount: refundBankakAmount,
      customAmount: customAmount,
      customCount: customCount,
      comparison: comparison,
    );
  }

  TodaySalesSummary recalculateAverage() {
    return copyWith(
      averageSaleAmount: salesCount == 0 ? 0 : grossSalesAmount / salesCount,
    );
  }

  @override
  List<Object?> get props => [
    date,
    grossSalesAmount,
    netSalesAmount,
    salesCount,
    averageSaleAmount,
    refundAmount,
    refundCount,
    cashAmount,
    bankakAmount,
    otherAmount,
    paymentBreakdown,
    refundCashAmount,
    refundBankakAmount,
    customAmount,
    customCount,
    comparison,
  ];
}

class PaymentBreakdownItem extends Equatable {
  final String method;
  final double amount;
  final int count;

  const PaymentBreakdownItem({
    required this.method,
    required this.amount,
    required this.count,
  });

  PaymentBreakdownItem copyWith({double? amount, int? count}) {
    return PaymentBreakdownItem(
      method: method,
      amount: amount ?? this.amount,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [method, amount, count];
}

/// Previous-day figures from the server; null when that day had no sales.
class SalesComparison extends Equatable {
  final String date;
  final double grossSalesAmount;
  final int salesCount;
  final double grossSalesAmountSameTime;

  const SalesComparison({
    required this.date,
    required this.grossSalesAmount,
    required this.salesCount,
    required this.grossSalesAmountSameTime,
  });

  @override
  List<Object?> get props => [
    date,
    grossSalesAmount,
    salesCount,
    grossSalesAmountSameTime,
  ];
}

class ShiftSalesSummary extends Equatable {
  final String mode;
  final String? cashierId;
  final String? cashierName;
  final String? shiftStartedAt;
  final double grossSalesAmount;
  final int salesCount;
  final double averageSaleAmount;

  const ShiftSalesSummary({
    required this.mode,
    required this.cashierId,
    required this.cashierName,
    required this.shiftStartedAt,
    required this.grossSalesAmount,
    required this.salesCount,
    required this.averageSaleAmount,
  });

  ShiftSalesSummary copyWith({
    String? mode,
    String? cashierId,
    String? cashierName,
    String? shiftStartedAt,
    double? grossSalesAmount,
    int? salesCount,
    double? averageSaleAmount,
  }) {
    return ShiftSalesSummary(
      mode: mode ?? this.mode,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      shiftStartedAt: shiftStartedAt ?? this.shiftStartedAt,
      grossSalesAmount: grossSalesAmount ?? this.grossSalesAmount,
      salesCount: salesCount ?? this.salesCount,
      averageSaleAmount: averageSaleAmount ?? this.averageSaleAmount,
    );
  }

  ShiftSalesSummary recalculateAverage() {
    return copyWith(
      averageSaleAmount: salesCount == 0 ? 0 : grossSalesAmount / salesCount,
    );
  }

  @override
  List<Object?> get props => [
    mode,
    cashierId,
    cashierName,
    shiftStartedAt,
    grossSalesAmount,
    salesCount,
    averageSaleAmount,
  ];
}

class SparklineSummary extends Equatable {
  final String interval;
  final List<SparklinePoint> points;

  /// First hour with a sale ("HH:00"), or null when there are none yet.
  final String? firstSaleHour;

  const SparklineSummary({
    required this.interval,
    required this.points,
    this.firstSaleHour,
  });

  SparklineSummary mergePending(List<SparklinePoint> pendingPoints) {
    if (pendingPoints.isEmpty) return this;

    final map = <String, SparklinePoint>{};

    for (final point in points) {
      map[point.label] = point;
    }

    for (final point in pendingPoints) {
      final old = map[point.label];

      if (old == null) {
        map[point.label] = point;
      } else {
        map[point.label] = old.copyWith(
          amount: old.amount + point.amount,
          salesCount: old.salesCount + point.salesCount,
        );
      }
    }

    final merged = map.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    final pendingFirst = pendingPoints
        .where((e) => e.amount > 0)
        .map((e) => e.label)
        .fold<String?>(
          firstSaleHour,
          (a, b) => a == null || b.compareTo(a) < 0 ? b : a,
        );

    return SparklineSummary(
      interval: interval,
      points: merged,
      firstSaleHour: pendingFirst,
    );
  }

  @override
  List<Object?> get props => [interval, points, firstSaleHour];
}

class SparklinePoint extends Equatable {
  final String label;
  final double amount;
  final int salesCount;

  const SparklinePoint({
    required this.label,
    required this.amount,
    required this.salesCount,
  });

  SparklinePoint copyWith({String? label, double? amount, int? salesCount}) {
    return SparklinePoint(
      label: label ?? this.label,
      amount: amount ?? this.amount,
      salesCount: salesCount ?? this.salesCount,
    );
  }

  @override
  List<Object?> get props => [label, amount, salesCount];
}

class TopSeller extends Equatable {
  final String productId;
  final String name;
  final double quantitySold;
  final double grossAmount;
  final String? thumbnailUrl;

  const TopSeller({
    required this.productId,
    required this.name,
    required this.quantitySold,
    required this.grossAmount,
    this.thumbnailUrl,
  });

  TopSeller copyWith({
    String? productId,
    String? name,
    double? quantitySold,
    double? grossAmount,
    String? thumbnailUrl,
  }) {
    return TopSeller(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantitySold: quantitySold ?? this.quantitySold,
      grossAmount: grossAmount ?? this.grossAmount,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    name,
    quantitySold,
    grossAmount,
    thumbnailUrl,
  ];
}

class DashboardSyncInfo extends Equatable {
  final bool includesPendingOfflineSales;
  final String? lastCalculatedAt;

  const DashboardSyncInfo({
    required this.includesPendingOfflineSales,
    required this.lastCalculatedAt,
  });

  DashboardSyncInfo copyWith({
    bool? includesPendingOfflineSales,
    String? lastCalculatedAt,
  }) {
    return DashboardSyncInfo(
      includesPendingOfflineSales:
          includesPendingOfflineSales ?? this.includesPendingOfflineSales,
      lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
    );
  }

  @override
  List<Object?> get props => [includesPendingOfflineSales, lastCalculatedAt];
}
