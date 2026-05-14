import 'package:equatable/equatable.dart';

enum DashboardSummarySource {
  remote,
  cache,
}

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

  DashboardSummary mergePendingSales(PendingSalesDelta delta) {
    if (delta.isEmpty) return this;

    final mergedToday = today.copyWith(
      grossSalesAmount: today.grossSalesAmount + delta.grossAmount,
      netSalesAmount: today.netSalesAmount + delta.netAmount,
      salesCount: today.salesCount + delta.salesCount,
      cashAmount: today.cashAmount + delta.cashAmount,
      bankakAmount: today.bankakAmount + delta.bankakAmount,
    ).recalculateAverage();

    final mergedShift = shift == null
        ? null
        : shift!
        .copyWith(
      grossSalesAmount: shift!.grossSalesAmount + delta.grossAmount,
      salesCount: shift!.salesCount + delta.salesCount,
    )
        .recalculateAverage();

    return copyWith(
      today: mergedToday,
      shift: mergedShift,
      sparkline: sparkline.mergePending(delta.sparklinePoints),
      topSellers: _mergeTopSellers(topSellers, delta.topSellers),
      includesLocalPendingSales: true,
      sync: sync.copyWith(
        includesPendingOfflineSales: true,
      ),
    );
  }

  List<TopSeller> _mergeTopSellers(
      List<TopSeller> remote,
      List<TopSeller> pending,
      ) {
    if (pending.isEmpty) return remote;

    final map = <String, TopSeller>{};

    for (final item in remote) {
      map[item.productId] = item;
    }

    for (final item in pending) {
      final old = map[item.productId];
      if (old == null) {
        map[item.productId] = item;
      } else {
        map[item.productId] = old.copyWith(
          quantitySold: old.quantitySold + item.quantitySold,
          grossAmount: old.grossAmount + item.grossAmount,
        );
      }
    }

    final result = map.values.toList()
      ..sort((a, b) {
        final qtyCompare = b.quantitySold.compareTo(a.quantitySold);
        if (qtyCompare != 0) return qtyCompare;
        return b.grossAmount.compareTo(a.grossAmount);
      });

    return result.take(5).toList();
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
      sparkline: const SparklineSummary(
        interval: 'hour',
        points: [],
      ),
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

  const DashboardScope({
    this.businessId,
    this.shopId,
    this.shopName,
  });

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
  });

  factory TodaySalesSummary.empty({
    required String date,
  }) {
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

  const SparklineSummary({
    required this.interval,
    required this.points,
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

    return SparklineSummary(
      interval: interval,
      points: merged,
    );
  }

  @override
  List<Object?> get props => [interval, points];
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

  SparklinePoint copyWith({
    String? label,
    double? amount,
    int? salesCount,
  }) {
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
  List<Object?> get props => [
    includesPendingOfflineSales,
    lastCalculatedAt,
  ];
}

class PendingSalesDelta extends Equatable {
  final double grossAmount;
  final double netAmount;
  final int salesCount;
  final double cashAmount;
  final double bankakAmount;
  final List<SparklinePoint> sparklinePoints;
  final List<TopSeller> topSellers;

  const PendingSalesDelta({
    required this.grossAmount,
    required this.netAmount,
    required this.salesCount,
    required this.cashAmount,
    required this.bankakAmount,
    required this.sparklinePoints,
    required this.topSellers,
  });

  factory PendingSalesDelta.empty() {
    return const PendingSalesDelta(
      grossAmount: 0,
      netAmount: 0,
      salesCount: 0,
      cashAmount: 0,
      bankakAmount: 0,
      sparklinePoints: [],
      topSellers: [],
    );
  }

  bool get isEmpty => salesCount == 0 && grossAmount == 0;

  @override
  List<Object?> get props => [
    grossAmount,
    netAmount,
    salesCount,
    cashAmount,
    bankakAmount,
    sparklinePoints,
    topSellers,
  ];
}

