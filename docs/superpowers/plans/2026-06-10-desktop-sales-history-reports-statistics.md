# Desktop Sales History — Reports & Statistics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `ReportsPlaceholderView` with a fully functional Reports & Statistics tab backed by the new `/api/v1/sales/reports/` endpoint.

**Architecture:** New `SalesReportBloc` (separate from `SalesHistoryBloc`) fetches `SalesReport` from the existing repository/use-case via a new `getSalesReport` method. `FeatureBlocProviders.salesHistory` becomes a `MultiBlocProvider`. The `ReportsTabView` widget assembles `DateRangeBar` + `ReportsKpiRow` + a bento grid of 6 fl_chart cards inside a `Column`/`SliverToBoxAdapter`.

**Tech Stack:** Flutter, flutter_bloc, fl_chart ^0.69.0, fpdart, GetIt, flutter_animate, solar_icons

---

## File Summary

**New source files:**
- `lib/features/sales_history/data/models/sales_report_dto.dart` — all DTOs + domain model
- `lib/features/sales_history/presentation/bloc/sales_report_event.dart`
- `lib/features/sales_history/presentation/bloc/sales_report_state.dart`
- `lib/features/sales_history/presentation/bloc/sales_report_bloc.dart`
- `lib/features/sales_history/presentation/widgets/reports/sales_report_colors.dart`
- `lib/features/sales_history/presentation/widgets/reports/date_range_bar.dart`
- `lib/features/sales_history/presentation/widgets/reports/reports_kpi_row.dart`
- `lib/features/sales_history/presentation/widgets/reports/revenue_trend_card.dart`
- `lib/features/sales_history/presentation/widgets/reports/payment_breakdown_card.dart`
- `lib/features/sales_history/presentation/widgets/reports/peak_hours_card.dart`
- `lib/features/sales_history/presentation/widgets/reports/day_of_week_card.dart`
- `lib/features/sales_history/presentation/widgets/reports/top_products_card.dart`
- `lib/features/sales_history/presentation/widgets/reports/top_categories_card.dart`
- `lib/features/sales_history/presentation/widgets/reports/reports_status_views.dart`
- `lib/features/sales_history/presentation/widgets/reports/reports_tab_view.dart`

**Modified source files:**
- `lib/features/sales_history/domain/repositories/sales_history_repository.dart` — add `getSalesReport`
- `lib/features/sales_history/data/repositories/sales_history_repo_impl.dart` — implement it
- `lib/features/sales_history/domain/usecases/sales_history_usecase.dart` — delegate it
- `lib/config/providers/feature_bloc_providers.dart` — `salesHistory` → `MultiBlocProvider`
- `lib/l10n/app_en.arb` + `lib/l10n/app_ar.arb` — 13 new keys
- `lib/features/sales_history/presentation/widgets/desktop_sales_history_view.dart` — swap placeholder for `ReportsTabView`

---

## Task 1: SalesReport DTOs + Domain Model

**Files:**
- Create: `lib/features/sales_history/data/models/sales_report_dto.dart`
- Test: `test/features/sales_history/data/models/sales_report_dto_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/sales_history/data/models/sales_report_dto_test.dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesReportDto.fromJson', () {
    const json = {
      'range': {'from': '2026-06-01', 'to': '2026-06-10'},
      'currency': 'SDG',
      'summary': {
        'gross_sales_amount': 16140.0,
        'net_sales_amount': 16140.0,
        'sales_count': 5,
        'average_sale_amount': 3228.0,
        'refund_amount': 0.0,
        'refund_count': 0,
      },
      'trend': {
        'interval': 'day',
        'points': [
          {'label': '2026-06-01', 'gross_amount': 0.0, 'net_amount': 0.0, 'sales_count': 0},
          {'label': '2026-06-02', 'gross_amount': 16140.0, 'net_amount': 16140.0, 'sales_count': 5},
        ],
      },
      'payment_methods': [
        {'method': 'cash', 'amount': 16140.0, 'count': 5},
      ],
      'top_products': [
        {'product_id': 'p1', 'name': 'ببسي', 'quantity_sold': 269.0, 'gross_amount': 16140.0, 'thumbnail_url': null},
      ],
      'top_categories': [
        {'category_id': 'c1', 'name': 'مشروبات', 'quantity_sold': 269.0, 'gross_amount': 16140.0},
      ],
      'peak_hours': List.generate(24, (h) => {'hour': h, 'sales_count': 0, 'amount': 0.0}),
      'day_of_week': List.generate(7, (d) => {'weekday': d + 1, 'sales_count': 0, 'amount': 0.0}),
    };

    test('parses summary correctly', () {
      final report = SalesReportDto.fromJson(json).toDomain();
      expect(report.summary.grossSalesAmount, 16140.0);
      expect(report.summary.salesCount, 5);
      expect(report.summary.averageSaleAmount, 3228.0);
      expect(report.summary.refundCount, 0);
    });

    test('parses trend with 2 points', () {
      final report = SalesReportDto.fromJson(json).toDomain();
      expect(report.trend.interval, 'day');
      expect(report.trend.points.length, 2);
      expect(report.trend.points[1].grossAmount, 16140.0);
    });

    test('parses payment methods', () {
      final report = SalesReportDto.fromJson(json).toDomain();
      expect(report.paymentMethods.length, 1);
      expect(report.paymentMethods[0].method, 'cash');
      expect(report.paymentMethods[0].amount, 16140.0);
    });

    test('parses 24 peak hours', () {
      final report = SalesReportDto.fromJson(json).toDomain();
      expect(report.peakHours.length, 24);
      expect(report.peakHours[0].hour, 0);
    });

    test('parses 7 day-of-week entries', () {
      final report = SalesReportDto.fromJson(json).toDomain();
      expect(report.dayOfWeek.length, 7);
      expect(report.dayOfWeek[0].weekday, 1);
    });

    test('top products and categories', () {
      final report = SalesReportDto.fromJson(json).toDomain();
      expect(report.topProducts[0].name, 'ببسي');
      expect(report.topCategories[0].name, 'مشروبات');
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL with "not found"**

```bash
flutter test test/features/sales_history/data/models/sales_report_dto_test.dart --no-pub
```

- [ ] **Step 3: Create the DTO + domain model file**

```dart
// lib/features/sales_history/data/models/sales_report_dto.dart

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
    final range = _json['range'] as Map<String, dynamic>;
    final summaryJson = _json['summary'] as Map<String, dynamic>;
    final trendJson = _json['trend'] as Map<String, dynamic>;

    return SalesReport(
      rangeFrom: range['from'] as String,
      rangeTo: range['to'] as String,
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
        points: (trendJson['points'] as List<dynamic>).map((p) {
          final pt = p as Map<String, dynamic>;
          return SalesTrendPoint(
            label: pt['label'] as String,
            grossAmount: _d(pt['gross_amount']),
            netAmount: _d(pt['net_amount']),
            salesCount: pt['sales_count'] as int? ?? 0,
          );
        }).toList(),
      ),
      paymentMethods: (_json['payment_methods'] as List<dynamic>).map((p) {
        final m = p as Map<String, dynamic>;
        return PaymentMethodBreakdown(
          method: m['method'] as String,
          amount: _d(m['amount']),
          count: m['count'] as int? ?? 0,
        );
      }).toList(),
      topProducts: (_json['top_products'] as List<dynamic>).map((p) {
        final prod = p as Map<String, dynamic>;
        return SalesTopProduct(
          productId: prod['product_id'] as String,
          name: prod['name'] as String,
          quantitySold: _d(prod['quantity_sold']),
          grossAmount: _d(prod['gross_amount']),
          thumbnailUrl: prod['thumbnail_url'] as String?,
        );
      }).toList(),
      topCategories: (_json['top_categories'] as List<dynamic>).map((p) {
        final cat = p as Map<String, dynamic>;
        return SalesTopCategory(
          categoryId: cat['category_id'] as String,
          name: cat['name'] as String,
          quantitySold: _d(cat['quantity_sold']),
          grossAmount: _d(cat['gross_amount']),
        );
      }).toList(),
      peakHours: (_json['peak_hours'] as List<dynamic>).map((p) {
        final h = p as Map<String, dynamic>;
        return PeakHourStat(
          hour: h['hour'] as int,
          salesCount: h['sales_count'] as int? ?? 0,
          amount: _d(h['amount']),
        );
      }).toList(),
      dayOfWeek: (_json['day_of_week'] as List<dynamic>).map((p) {
        final d = p as Map<String, dynamic>;
        return DayOfWeekStat(
          weekday: d['weekday'] as int,
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
```

- [ ] **Step 4: Run test — expect PASS**

```bash
flutter test test/features/sales_history/data/models/sales_report_dto_test.dart --no-pub
```

Expected: 6/6 PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/sales_history/data/models/sales_report_dto.dart test/features/sales_history/data/models/sales_report_dto_test.dart
git commit -m "feat(sales-history): add SalesReport domain model + DTOs"
```

---

## Task 2: Repository + UseCase Extension

**Files:**
- Modify: `lib/features/sales_history/domain/repositories/sales_history_repository.dart`
- Modify: `lib/features/sales_history/data/repositories/sales_history_repo_impl.dart`
- Modify: `lib/features/sales_history/domain/usecases/sales_history_usecase.dart`
- Test: `test/features/sales_history/data/repositories/sales_history_report_repo_test.dart`

- [ ] **Step 1: Read the existing files first**

Read all three files before touching them. Specifically look at how `getSalesPage` makes the HTTP request in `SalesHistoryRepoImpl` — the `RequestHandler` API, how query parameters are passed, and how the response JSON is parsed. You will follow that exact same pattern for `getSalesReport`.

- [ ] **Step 2: Add abstract method to repository**

In `lib/features/sales_history/domain/repositories/sales_history_repository.dart`, add:

```dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';

// Inside the abstract class:
Future<Either<String?, SalesReport>> getSalesReport({
  required DateTime from,
  required DateTime to,
  String? shopId,
  String? timezone,
});
```

- [ ] **Step 3: Write the failing test**

```dart
// test/features/sales_history/data/repositories/sales_history_report_repo_test.dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/domain/repositories/sales_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesHistoryRepo extends Mock implements SalesHistoryRepository {}

void main() {
  late MockSalesHistoryRepo repo;

  setUp(() {
    repo = MockSalesHistoryRepo();
  });

  test('getSalesReport returns SalesReport on success', () async {
    final fakeReport = SalesReport(
      rangeFrom: '2026-06-01',
      rangeTo: '2026-06-10',
      currency: 'SDG',
      summary: const SalesReportSummary(
        grossSalesAmount: 1000,
        netSalesAmount: 1000,
        salesCount: 3,
        averageSaleAmount: 333,
        refundAmount: 0,
        refundCount: 0,
      ),
      trend: const SalesTrend(interval: 'day', points: []),
      paymentMethods: const [],
      topProducts: const [],
      topCategories: const [],
      peakHours: const [],
      dayOfWeek: const [],
    );

    when(() => repo.getSalesReport(
      from: any(named: 'from'),
      to: any(named: 'to'),
    )).thenAnswer((_) async => right(fakeReport));

    final result = await repo.getSalesReport(
      from: DateTime(2026, 6, 1),
      to: DateTime(2026, 6, 10),
    );

    expect(result.isRight(), true);
    expect(result.getOrElse((_) => throw Exception()), equals(fakeReport));
  });
}
```

Run to verify FAIL: `flutter test test/features/sales_history/data/repositories/sales_history_report_repo_test.dart --no-pub`

- [ ] **Step 4: Implement `getSalesReport` in `SalesHistoryRepoImpl`**

Follow the exact same HTTP request pattern as `getSalesPage`. The endpoint is `api/v1/sales/reports/` with query params:
- `date_from`: `YYYY-MM-DD` (format `from` using `DateFormat('yyyy-MM-dd')` from `intl` or manual formatting)
- `date_to`: `YYYY-MM-DD`
- `shop_id`: (optional)
- `timezone`: (optional)

The response has `{ "success": true, "data": { ... } }`. Parse `response['data']` into `SalesReportDto.fromJson(...)`.toDomain()`.

Add a private helper `String _formatDate(DateTime d)` → `'${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}'`.

- [ ] **Step 5: Add `getSalesReport` to `SalesHistoryUseCase`**

```dart
Future<Either<String?, SalesReport>> getSalesReport({
  required DateTime from,
  required DateTime to,
  String? shopId,
  String? timezone,
}) => repository.getSalesReport(from: from, to: to, shopId: shopId, timezone: timezone);
```

- [ ] **Step 6: Run tests — expect PASS**

```bash
flutter test test/features/sales_history/data/repositories/sales_history_report_repo_test.dart --no-pub
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/sales_history/domain/repositories/sales_history_repository.dart \
        lib/features/sales_history/data/repositories/sales_history_repo_impl.dart \
        lib/features/sales_history/domain/usecases/sales_history_usecase.dart \
        test/features/sales_history/data/repositories/sales_history_report_repo_test.dart
git commit -m "feat(sales-history): add getSalesReport to repository and use case"
```

---

## Task 3: SalesReportBloc + DI Wiring

**Files:**
- Create: `lib/features/sales_history/presentation/bloc/sales_report_event.dart`
- Create: `lib/features/sales_history/presentation/bloc/sales_report_state.dart`
- Create: `lib/features/sales_history/presentation/bloc/sales_report_bloc.dart`
- Modify: `lib/config/providers/feature_bloc_providers.dart`
- Test: `test/features/sales_history/presentation/bloc/sales_report_bloc_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/sales_history/presentation/bloc/sales_report_bloc_test.dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/domain/usecases/sales_history_usecase.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesHistoryUseCase extends Mock implements SalesHistoryUseCase {}

SalesReport _fakeReport() => SalesReport(
  rangeFrom: '2026-06-10',
  rangeTo: '2026-06-10',
  currency: 'SDG',
  summary: const SalesReportSummary(
    grossSalesAmount: 500,
    netSalesAmount: 500,
    salesCount: 2,
    averageSaleAmount: 250,
    refundAmount: 0,
    refundCount: 0,
  ),
  trend: const SalesTrend(interval: 'hour', points: []),
  paymentMethods: const [],
  topProducts: const [],
  topCategories: const [],
  peakHours: const [],
  dayOfWeek: const [],
);

void main() {
  late MockSalesHistoryUseCase useCase;

  setUpAll(() => registerFallbackValue(DateTime.now()));

  setUp(() {
    useCase = MockSalesHistoryUseCase();
    when(() => useCase.getSalesReport(
      from: any(named: 'from'),
      to: any(named: 'to'),
      shopId: any(named: 'shopId'),
      timezone: any(named: 'timezone'),
    )).thenAnswer((_) async => right(_fakeReport()));
  });

  blocTest<SalesReportBloc, SalesReportState>(
    'emits loading then loaded after Today preset on creation',
    build: () => SalesReportBloc(useCase: useCase),
    expect: () => [
      isA<SalesReportState>().having((s) => s.status, 'loading', SalesReportBlocStatus.loading),
      isA<SalesReportState>()
          .having((s) => s.status, 'loaded', SalesReportBlocStatus.loaded)
          .having((s) => s.report, 'report not null', isNotNull),
    ],
  );

  blocTest<SalesReportBloc, SalesReportState>(
    'emits failure when useCase returns error',
    setUp: () {
      when(() => useCase.getSalesReport(
        from: any(named: 'from'),
        to: any(named: 'to'),
        shopId: any(named: 'shopId'),
        timezone: any(named: 'timezone'),
      )).thenAnswer((_) async => left('Network error'));
    },
    build: () => SalesReportBloc(useCase: useCase),
    expect: () => [
      isA<SalesReportState>().having((s) => s.status, 'loading', SalesReportBlocStatus.loading),
      isA<SalesReportState>()
          .having((s) => s.status, 'failure', SalesReportBlocStatus.failure)
          .having((s) => s.errorMessage, 'error message', 'Network error'),
    ],
  );

  blocTest<SalesReportBloc, SalesReportState>(
    'SalesReportRangeChanged fetches with new preset',
    build: () => SalesReportBloc(useCase: useCase),
    act: (bloc) => bloc.add(
      const SalesReportRangeChanged(preset: ReportPreset.yesterday),
    ),
    skip: 2, // skip auto-load of today
    expect: () => [
      isA<SalesReportState>().having((s) => s.preset, 'yesterday', ReportPreset.yesterday),
      isA<SalesReportState>().having((s) => s.status, 'loaded', SalesReportBlocStatus.loaded),
    ],
  );
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/features/sales_history/presentation/bloc/sales_report_bloc_test.dart --no-pub
```

- [ ] **Step 3: Create `sales_report_event.dart`**

```dart
// lib/features/sales_history/presentation/bloc/sales_report_event.dart
import 'package:flutter/material.dart';

enum ReportPreset { today, yesterday, custom }

sealed class SalesReportEvent {
  const SalesReportEvent();
}

class SalesReportRangeChanged extends SalesReportEvent {
  final ReportPreset preset;
  final DateTimeRange? customRange;
  const SalesReportRangeChanged({required this.preset, this.customRange});
}

class SalesReportRefreshed extends SalesReportEvent {
  const SalesReportRefreshed();
}
```

- [ ] **Step 4: Create `sales_report_state.dart`**

```dart
// lib/features/sales_history/presentation/bloc/sales_report_state.dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:flutter/material.dart';

enum SalesReportBlocStatus { initial, loading, loaded, failure }

class SalesReportState {
  final SalesReportBlocStatus status;
  final ReportPreset preset;
  final DateTimeRange? customRange;
  final SalesReport? report;
  final String? errorMessage;

  const SalesReportState({
    this.status = SalesReportBlocStatus.initial,
    this.preset = ReportPreset.today,
    this.customRange,
    this.report,
    this.errorMessage,
  });

  SalesReportState copyWith({
    SalesReportBlocStatus? status,
    ReportPreset? preset,
    DateTimeRange? customRange,
    SalesReport? report,
    String? errorMessage,
    bool clearReport = false,
    bool clearError = false,
  }) =>
      SalesReportState(
        status: status ?? this.status,
        preset: preset ?? this.preset,
        customRange: customRange ?? this.customRange,
        report: clearReport ? null : (report ?? this.report),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}
```

- [ ] **Step 5: Create `sales_report_bloc.dart`**

```dart
// lib/features/sales_history/presentation/bloc/sales_report_bloc.dart
import 'package:amana_pos/features/sales_history/domain/usecases/sales_history_usecase.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesReportBloc extends Bloc<SalesReportEvent, SalesReportState> {
  final SalesHistoryUseCase _useCase;

  SalesReportBloc({required SalesHistoryUseCase useCase})
      : _useCase = useCase,
        super(const SalesReportState()) {
    on<SalesReportRangeChanged>(_onRangeChanged);
    on<SalesReportRefreshed>(_onRefreshed);
    add(const SalesReportRangeChanged(preset: ReportPreset.today));
  }

  Future<void> _onRangeChanged(
    SalesReportRangeChanged event,
    Emitter<SalesReportState> emit,
  ) async {
    emit(state.copyWith(
      status: SalesReportBlocStatus.loading,
      preset: event.preset,
      customRange: event.customRange,
    ));
    await _fetch(emit);
  }

  Future<void> _onRefreshed(
    SalesReportRefreshed event,
    Emitter<SalesReportState> emit,
  ) async {
    emit(state.copyWith(status: SalesReportBlocStatus.loading));
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<SalesReportState> emit) async {
    final (from, to) = _resolvedDates;
    final result = await _useCase.getSalesReport(from: from, to: to);
    result.fold(
      (error) => emit(state.copyWith(
        status: SalesReportBlocStatus.failure,
        errorMessage: error ?? 'Failed to load report',
      )),
      (report) => emit(state.copyWith(
        status: SalesReportBlocStatus.loaded,
        report: report,
        clearError: true,
      )),
    );
  }

  (DateTime, DateTime) get _resolvedDates {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (state.preset) {
      ReportPreset.today => (today, today),
      ReportPreset.yesterday => (
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 1)),
        ),
      ReportPreset.custom => (
          state.customRange?.start ?? today,
          state.customRange?.end ?? today,
        ),
    };
  }
}
```

- [ ] **Step 6: Update `feature_bloc_providers.dart` — salesHistory → MultiBlocProvider**

Read the file first. Change the `salesHistory` factory from a single `BlocProvider` to a `MultiBlocProvider`:

```dart
// Before:
static Widget salesHistory({required Widget child}) {
  return BlocProvider(
    create: (_) => SalesHistoryBloc(useCase: getIt<SalesHistoryUseCase>()),
    child: child,
  );
}

// After:
static Widget salesHistory({required Widget child}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => SalesHistoryBloc(useCase: getIt<SalesHistoryUseCase>()),
      ),
      BlocProvider(
        create: (_) => SalesReportBloc(useCase: getIt<SalesHistoryUseCase>()),
      ),
    ],
    child: child,
  );
}
```

Add import: `import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_bloc.dart';`

No new DI registrations needed — `SalesReportBloc` takes `SalesHistoryUseCase` which is already registered.

- [ ] **Step 7: Run tests — expect PASS**

```bash
flutter test test/features/sales_history/presentation/bloc/sales_report_bloc_test.dart --no-pub
```

- [ ] **Step 8: Commit**

```bash
git add lib/features/sales_history/presentation/bloc/sales_report_event.dart \
        lib/features/sales_history/presentation/bloc/sales_report_state.dart \
        lib/features/sales_history/presentation/bloc/sales_report_bloc.dart \
        lib/config/providers/feature_bloc_providers.dart \
        test/features/sales_history/presentation/bloc/sales_report_bloc_test.dart
git commit -m "feat(sales-history): add SalesReportBloc + MultiBlocProvider wiring"
```

---

## Task 4: l10n Keys

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`

- [ ] **Step 1: Add 13 new keys to `app_en.arb`**

Find the block containing `reportsComingSoon` (the last key added in the previous plan) and insert these immediately after it:

```json
"reportsRevenue": "Revenue",
"reportsGross": "Gross",
"reportsNet": "Net",
"revenueAndSalesTrend": "Revenue & Sales Trend",
"paymentMethodsTitle": "Payment Methods",
"peakHoursTitle": "Peak Hours",
"topProductsTitle": "Top Products",
"topCategoriesTitle": "Top Categories",
"dayOfWeekTitle": "Day of Week",
"selectDateRange": "Select date range",
"reportsNoSalesInRange": "No sales in this period.",
"reportsLoadError": "Failed to load report.",
"reportsRefresh": "Refresh report"
```

Note: `today`, `yesterday`, `retry` already exist — do NOT add them again.

- [ ] **Step 2: Add Arabic translations to `app_ar.arb`**

```json
"reportsRevenue": "الإيرادات",
"reportsGross": "الإجمالي",
"reportsNet": "الصافي",
"revenueAndSalesTrend": "اتجاه الإيرادات والمبيعات",
"paymentMethodsTitle": "طرق الدفع",
"peakHoursTitle": "أوقات الذروة",
"topProductsTitle": "أفضل المنتجات",
"topCategoriesTitle": "أفضل الفئات",
"dayOfWeekTitle": "يوم الأسبوع",
"selectDateRange": "اختر نطاق التاريخ",
"reportsNoSalesInRange": "لا توجد مبيعات في هذه الفترة.",
"reportsLoadError": "فشل تحميل التقرير.",
"reportsRefresh": "تحديث التقرير"
```

- [ ] **Step 3: Run gen-l10n**

```bash
flutter gen-l10n
```

Expected: No errors. Verify the new keys appear in the generated `app_localizations_en.dart`.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ar.arb
git commit -m "feat(l10n): add 13 report & statistics l10n keys"
```

---

## Task 5: `sales_report_colors.dart` + `date_range_bar.dart`

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/reports/sales_report_colors.dart`
- Create: `lib/features/sales_history/presentation/widgets/reports/date_range_bar.dart`
- Test: `test/features/sales_history/presentation/widgets/reports/date_range_bar_test.dart`

- [ ] **Step 1: Create `sales_report_colors.dart`**

```dart
// lib/features/sales_history/presentation/widgets/reports/sales_report_colors.dart
import 'package:flutter/material.dart';

abstract final class SalesReportColors {
  // Trend line: gross (primary blue) / net (secondary teal)
  static const trendGross = Color(0xFF3B82F6);  // blue-500
  static const trendNet   = Color(0xFF14B8A6);  // teal-500

  // Payment method donut segments (up to 6 distinct methods)
  static const List<Color> donutPalette = [
    Color(0xFF6366F1), // indigo
    Color(0xFF8B5CF6), // violet
    Color(0xFF3B82F6), // blue
    Color(0xFF14B8A6), // teal
    Color(0xFF10B981), // emerald
    Color(0xFFF59E0B), // amber
  ];

  // Bar charts
  static const barPrimary  = Color(0xFF6366F1); // indigo
  static const barMuted    = Color(0xFFE0E7FF); // indigo-100 (zero-value bars)

  // Ranked list progress bar
  static const rankBar = Color(0xFF6366F1);
}
```

- [ ] **Step 2: Write the failing test for `DateRangeBar`**

```dart
// test/features/sales_history/presentation/widgets/reports/date_range_bar_test.dart
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/date_range_bar.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesReportBloc extends MockBloc<SalesReportEvent, SalesReportState>
    implements SalesReportBloc {}

void main() {
  late MockSalesReportBloc bloc;

  setUpAll(() => registerFallbackValue(const SalesReportRangeChanged(preset: ReportPreset.today)));

  setUp(() {
    bloc = MockSalesReportBloc();
    when(() => bloc.state).thenReturn(const SalesReportState());
  });

  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: BlocProvider<SalesReportBloc>.value(value: bloc, child: w),
    ),
  );

  testWidgets('renders Today and Yesterday chips', (tester) async {
    await tester.pumpWidget(wrap(const DateRangeBar()));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
  });

  testWidgets('tapping Yesterday dispatches SalesReportRangeChanged', (tester) async {
    await tester.pumpWidget(wrap(const DateRangeBar()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yesterday'));
    verify(() => bloc.add(const SalesReportRangeChanged(preset: ReportPreset.yesterday))).called(1);
  });
}
```

Run: `flutter test test/features/sales_history/presentation/widgets/reports/date_range_bar_test.dart --no-pub` — expect FAIL.

- [ ] **Step 3: Create `date_range_bar.dart`**

```dart
// lib/features/sales_history/presentation/widgets/reports/date_range_bar.dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DateRangeBar extends StatelessWidget {
  const DateRangeBar({super.key});

  @override
  Widget build(BuildContext context) {
    final preset = context.select((SalesReportBloc b) => b.state.preset);
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDims.s2),
      child: Row(
        children: [
          _PresetChip(
            label: context.tr.today,
            active: preset == ReportPreset.today,
            onTap: () => context.read<SalesReportBloc>().add(
              const SalesReportRangeChanged(preset: ReportPreset.today),
            ),
          ),
          const SizedBox(width: AppDims.s2),
          _PresetChip(
            label: context.tr.yesterday,
            active: preset == ReportPreset.yesterday,
            onTap: () => context.read<SalesReportBloc>().add(
              const SalesReportRangeChanged(preset: ReportPreset.yesterday),
            ),
          ),
          const SizedBox(width: AppDims.s2),
          _CustomRangeButton(preset: preset),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.tr.reportsRefresh,
            onPressed: () => context.read<SalesReportBloc>().add(
              const SalesReportRefreshed(),
            ),
            color: colors.textSecondary,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: AppDims.s2,
        ),
        decoration: BoxDecoration(
          color: active ? colors.primary : colors.background,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(
            color: active ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.sm200(context).copyWith(
            color: active ? Colors.white : colors.textSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _CustomRangeButton extends StatelessWidget {
  const _CustomRangeButton({required this.preset});
  final ReportPreset preset;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = preset == ReportPreset.custom;
    final state = context.watch<SalesReportBloc>().state;

    String label = context.tr.selectDateRange;
    if (isActive && state.customRange != null) {
      final r = state.customRange!;
      final fmt = (DateTime d) =>
          '${d.day}/${d.month}/${d.year}';
      label = '${fmt(r.start)} – ${fmt(r.end)}';
    }

    return GestureDetector(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: state.customRange,
        );
        if (picked != null && context.mounted) {
          context.read<SalesReportBloc>().add(
            SalesReportRangeChanged(
              preset: ReportPreset.custom,
              customRange: picked,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: AppDims.s2,
        ),
        decoration: BoxDecoration(
          color: isActive ? colors.primary : colors.background,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(
            color: isActive ? colors.primary : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 14,
              color: isActive ? Colors.white : colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.sm200(context).copyWith(
                color: isActive ? Colors.white : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests — expect PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/reports/date_range_bar_test.dart --no-pub
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/sales_history/presentation/widgets/reports/sales_report_colors.dart \
        lib/features/sales_history/presentation/widgets/reports/date_range_bar.dart \
        test/features/sales_history/presentation/widgets/reports/date_range_bar_test.dart
git commit -m "feat(sales-history): add SalesReportColors palette + DateRangeBar"
```

---

## Task 6: `reports_kpi_row.dart`

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/reports/reports_kpi_row.dart`
- Test: `test/features/sales_history/presentation/widgets/reports/reports_kpi_row_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/sales_history/presentation/widgets/reports/reports_kpi_row_test.dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_kpi_row.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SalesReportSummary _makeSummary() => const SalesReportSummary(
  grossSalesAmount: 16140.0,
  netSalesAmount: 16140.0,
  salesCount: 5,
  averageSaleAmount: 3228.0,
  refundAmount: 210.0,
  refundCount: 1,
);

void main() {
  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: w),
  );

  testWidgets('renders 4 KPI cards with correct labels', (tester) async {
    await tester.pumpWidget(wrap(ReportsKpiRow(summary: _makeSummary())));
    await tester.pumpAndSettle();

    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text('Sales count'), findsWidgets); // uses existing salesCount key
    expect(find.text('Avg sale'), findsOneWidget);
    expect(find.text('Refunds'), findsOneWidget);
  });

  testWidgets('revenue value is formatted with unit', (tester) async {
    await tester.pumpWidget(wrap(ReportsKpiRow(summary: _makeSummary())));
    await tester.pumpAndSettle();
    // AppFormat.moneyWithUnit(16140) → "16,140 SDG"
    expect(find.textContaining('16,140'), findsWidgets);
  });
}
```

Run to verify FAIL.

- [ ] **Step 2: Create `reports_kpi_row.dart`**

```dart
// lib/features/sales_history/presentation/widgets/reports/reports_kpi_row.dart
import 'dart:ui' as ui;

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_stat_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ReportsKpiRow extends StatelessWidget {
  const ReportsKpiRow({super.key, required this.summary});
  final SalesReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final refundValue = summary.refundCount > 0
        ? '${summary.refundCount} · ${AppFormat.compactMoney(summary.refundAmount)}'
        : AppFormat.moneyWithUnit(summary.refundAmount);

    return Row(
      children: [
        Expanded(
          child: SaleStatCard(
            label: context.tr.reportsRevenue,
            value: AppFormat.moneyWithUnit(summary.grossSalesAmount),
            background: colors.secondaryLight,
            valueColor: colors.secondary,
            labelColor: colors.textSecondary,
            icon: SolarIconsOutline.walletMoney,
            forceValueLtr: true,
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: SaleStatCard(
            label: context.tr.salesCount,
            value: summary.salesCount.toString(),
            background: colors.primaryLight,
            valueColor: colors.primary,
            labelColor: colors.textSecondary,
            icon: SolarIconsOutline.billList,
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: SaleStatCard(
            label: context.tr.avgSale,
            value: AppFormat.moneyWithUnit(summary.averageSaleAmount),
            background: colors.infoLight,
            valueColor: colors.info,
            labelColor: colors.textSecondary,
            icon: SolarIconsOutline.chartSquare,
            forceValueLtr: true,
          ),
        ),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: SaleStatCard(
            label: context.tr.refunds,
            value: refundValue,
            background: colors.dangerLight,
            valueColor: colors.danger,
            labelColor: colors.textSecondary,
            icon: SolarIconsOutline.undoLeft,
            forceValueLtr: true,
          ),
        ),
      ],
    );
  }
}
```

Note: `context.tr.salesCount` may need to be verified — check the existing l10n keys. If it doesn't exist, use a key that means "Number of sales" (check `allLoadedSales` or similar). The label should say "Sales" or "Sales count".

- [ ] **Step 3: Run tests — fix label key if needed, then verify PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/reports/reports_kpi_row_test.dart --no-pub
```

Adjust the test's expected label string if needed to match what the l10n key actually produces.

- [ ] **Step 4: Commit**

```bash
git add lib/features/sales_history/presentation/widgets/reports/reports_kpi_row.dart \
        test/features/sales_history/presentation/widgets/reports/reports_kpi_row_test.dart
git commit -m "feat(sales-history): add ReportsKpiRow — 4 read-only KPI cards"
```

---

## Task 7: `revenue_trend_card.dart`

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/reports/revenue_trend_card.dart`
- Test: `test/features/sales_history/presentation/widgets/reports/revenue_trend_card_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/sales_history/presentation/widgets/reports/revenue_trend_card_test.dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/revenue_trend_card.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SalesTrend _makeTrend() => SalesTrend(
  interval: 'day',
  points: [
    const SalesTrendPoint(label: '2026-06-01', grossAmount: 0, netAmount: 0, salesCount: 0),
    const SalesTrendPoint(label: '2026-06-02', grossAmount: 16140, netAmount: 16140, salesCount: 5),
  ],
);

void main() {
  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 600, height: 360, child: w)),
  );

  testWidgets('renders title and LineChart', (tester) async {
    await tester.pumpWidget(wrap(RevenueTrendCard(trend: _makeTrend())));
    await tester.pumpAndSettle();

    expect(find.text('Revenue & Sales Trend'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });
}
```

- [ ] **Step 2: Create `revenue_trend_card.dart`**

```dart
// lib/features/sales_history/presentation/widgets/reports/revenue_trend_card.dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/sales_report_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RevenueTrendCard extends StatelessWidget {
  const RevenueTrendCard({super.key, required this.trend});
  final SalesTrend trend;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return _ReportCard(
      title: context.tr.revenueAndSalesTrend,
      child: trend.points.isEmpty
          ? Center(child: Text(context.tr.reportsNoSalesInRange,
              style: AppTextStyles.sm200(context).copyWith(color: colors.textHint)))
          : _TrendChart(trend: trend),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.trend});
  final SalesTrend trend;

  @override
  Widget build(BuildContext context) {
    final grossSpots = trend.points.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.grossAmount))
        .toList();
    final netSpots = trend.points.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.netAmount))
        .toList();

    final maxY = trend.points.fold(0.0, (m, p) => m > p.grossAmount ? m : p.grossAmount);
    final labelInterval = (trend.points.length / 5).ceilToDouble().clamp(1.0, double.infinity);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 100 : maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: context.appColors.border,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (v, _) => Text(
                AppFormat.compactMoney(v),
                style: AppTextStyles.sm100(context).copyWith(
                  color: context.appColors.textHint,
                  fontSize: 9,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelInterval,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= trend.points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    trend.points[i].label,
                    style: AppTextStyles.sm100(context).copyWith(
                      color: context.appColors.textHint,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: grossSpots,
            isCurved: true,
            color: SalesReportColors.trendGross,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: SalesReportColors.trendGross.withAlpha(25),
            ),
          ),
          LineChartBarData(
            spots: netSpots,
            isCurved: true,
            color: SalesReportColors.trendNet,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: SalesReportColors.trendNet.withAlpha(25),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.sm200(context)
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppDims.s3),
          Expanded(child: child),
        ],
      ),
    );
  }
}
```

Note: `_ReportCard` is defined here and will be **copied** into each chart card file (or extracted to `_report_card.dart` — the implementer may choose to extract it as a shared private file, but it's fine to duplicate it across the 6 card files since it's tiny).

- [ ] **Step 3: Run tests — expect PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/reports/revenue_trend_card_test.dart --no-pub
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/sales_history/presentation/widgets/reports/revenue_trend_card.dart \
        test/features/sales_history/presentation/widgets/reports/revenue_trend_card_test.dart
git commit -m "feat(sales-history): add RevenueTrendCard (fl_chart LineChart)"
```

---

## Task 8: `payment_breakdown_card.dart`

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/reports/payment_breakdown_card.dart`
- Test: `test/features/sales_history/presentation/widgets/reports/payment_breakdown_card_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/sales_history/presentation/widgets/reports/payment_breakdown_card_test.dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/payment_breakdown_card.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 300, height: 200, child: w)),
  );

  testWidgets('renders PieChart with payment methods', (tester) async {
    final methods = [
      const PaymentMethodBreakdown(method: 'cash', amount: 1000, count: 3),
      const PaymentMethodBreakdown(method: 'card', amount: 500, count: 2),
    ];
    await tester.pumpWidget(wrap(PaymentBreakdownCard(paymentMethods: methods)));
    await tester.pumpAndSettle();

    expect(find.text('Payment Methods'), findsOneWidget);
    expect(find.byType(PieChart), findsOneWidget);
  });

  testWidgets('shows empty message when no payment methods', (tester) async {
    await tester.pumpWidget(wrap(PaymentBreakdownCard(paymentMethods: const [])));
    await tester.pumpAndSettle();

    expect(find.byType(PieChart), findsNothing);
    expect(find.text('No sales in this period.'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Create `payment_breakdown_card.dart`**

```dart
// lib/features/sales_history/presentation/widgets/reports/payment_breakdown_card.dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/sales_report_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PaymentBreakdownCard extends StatelessWidget {
  const PaymentBreakdownCard({super.key, required this.paymentMethods});
  final List<PaymentMethodBreakdown> paymentMethods;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return _ReportCard(
      title: context.tr.paymentMethodsTitle,
      child: paymentMethods.isEmpty
          ? Center(
              child: Text(
                context.tr.reportsNoSalesInRange,
                style: AppTextStyles.sm200(context)
                    .copyWith(color: colors.textHint),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                      sections: paymentMethods.asMap().entries.map((e) {
                        final color = SalesReportColors.donutPalette[
                            e.key % SalesReportColors.donutPalette.length];
                        return PieChartSectionData(
                          value: e.value.amount,
                          color: color,
                          radius: 24,
                          title: '',
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: AppDims.s2),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: paymentMethods.asMap().entries.map((e) {
                    final color = SalesReportColors.donutPalette[
                        e.key % SalesReportColors.donutPalette.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${e.value.method}  ${AppFormat.compactMoney(e.value.amount)}',
                            style: AppTextStyles.sm100(context).copyWith(
                              color: colors.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}

// Shared card shell — copy from revenue_trend_card.dart (or import if extracted)
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.sm200(context)
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppDims.s3),
          Expanded(child: child),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Run tests — expect PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/reports/payment_breakdown_card_test.dart --no-pub
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/sales_history/presentation/widgets/reports/payment_breakdown_card.dart \
        test/features/sales_history/presentation/widgets/reports/payment_breakdown_card_test.dart
git commit -m "feat(sales-history): add PaymentBreakdownCard (fl_chart PieChart donut)"
```

---

## Task 9: `peak_hours_card.dart` + `day_of_week_card.dart`

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/reports/peak_hours_card.dart`
- Create: `lib/features/sales_history/presentation/widgets/reports/day_of_week_card.dart`
- Test: `test/features/sales_history/presentation/widgets/reports/peak_hours_card_test.dart`
- Test: `test/features/sales_history/presentation/widgets/reports/day_of_week_card_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/features/sales_history/presentation/widgets/reports/peak_hours_card_test.dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/peak_hours_card.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 300, height: 200, child: w)),
  );

  testWidgets('renders BarChart with 24 bars', (tester) async {
    final hours = List.generate(24, (h) => PeakHourStat(hour: h, salesCount: h == 14 ? 5 : 0, amount: h == 14 ? 500 : 0));
    await tester.pumpWidget(wrap(PeakHoursCard(peakHours: hours)));
    await tester.pumpAndSettle();
    expect(find.text('Peak Hours'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });
}
```

```dart
// test/features/sales_history/presentation/widgets/reports/day_of_week_card_test.dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/day_of_week_card.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 300, height: 200, child: w)),
  );

  testWidgets('renders BarChart with 7 bars', (tester) async {
    final days = List.generate(7, (d) => DayOfWeekStat(weekday: d + 1, salesCount: d == 1 ? 3 : 0, amount: 0));
    await tester.pumpWidget(wrap(DayOfWeekCard(dayOfWeek: days)));
    await tester.pumpAndSettle();
    expect(find.text('Day of Week'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });
}
```

- [ ] **Step 2: Create `peak_hours_card.dart`**

```dart
// lib/features/sales_history/presentation/widgets/reports/peak_hours_card.dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/sales_report_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PeakHoursCard extends StatelessWidget {
  const PeakHoursCard({super.key, required this.peakHours});
  final List<PeakHourStat> peakHours;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      title: context.tr.peakHoursTitle,
      child: _PeakHoursBarChart(peakHours: peakHours),
    );
  }
}

class _PeakHoursBarChart extends StatelessWidget {
  const _PeakHoursBarChart({required this.peakHours});
  final List<PeakHourStat> peakHours;

  @override
  Widget build(BuildContext context) {
    final maxY = peakHours.fold(0.0, (m, h) => m > h.amount ? m : h.amount);

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 10 : maxY * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 4,
              getTitlesWidget: (value, _) {
                final h = value.toInt();
                if (h % 4 != 0) return const SizedBox.shrink();
                return Text(
                  '${h}h',
                  style: AppTextStyles.sm100(context)
                      .copyWith(color: context.appColors.textHint, fontSize: 9),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: peakHours.map((h) {
          final isActive = h.amount > 0;
          return BarChartGroupData(
            x: h.hour,
            barRods: [
              BarChartRodData(
                toY: h.amount,
                color: isActive
                    ? SalesReportColors.barPrimary
                    : SalesReportColors.barMuted,
                width: 6,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// Shared card shell
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.sm200(context)
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppDims.s3),
          Expanded(child: child),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create `day_of_week_card.dart`**

ISO weekdays: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun. Use abbreviated day labels.

```dart
// lib/features/sales_history/presentation/widgets/reports/day_of_week_card.dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/sales_report_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const _kDayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class DayOfWeekCard extends StatelessWidget {
  const DayOfWeekCard({super.key, required this.dayOfWeek});
  final List<DayOfWeekStat> dayOfWeek;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      title: context.tr.dayOfWeekTitle,
      child: _DayOfWeekBarChart(dayOfWeek: dayOfWeek),
    );
  }
}

class _DayOfWeekBarChart extends StatelessWidget {
  const _DayOfWeekBarChart({required this.dayOfWeek});
  final List<DayOfWeekStat> dayOfWeek;

  @override
  Widget build(BuildContext context) {
    final maxY = dayOfWeek.fold(0.0, (m, d) => m > d.amount ? m : d.amount);

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 10 : maxY * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final i = value.toInt() - 1;
                if (i < 0 || i >= _kDayLabels.length) return const SizedBox.shrink();
                return Text(
                  _kDayLabels[i],
                  style: AppTextStyles.sm100(context)
                      .copyWith(color: context.appColors.textHint, fontSize: 9),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: dayOfWeek.map((d) {
          return BarChartGroupData(
            x: d.weekday,
            barRods: [
              BarChartRodData(
                toY: d.amount,
                color: d.amount > 0
                    ? SalesReportColors.barPrimary
                    : SalesReportColors.barMuted,
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// Shared card shell
class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.sm200(context)
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppDims.s3),
          Expanded(child: child),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run both tests — expect PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/reports/peak_hours_card_test.dart test/features/sales_history/presentation/widgets/reports/day_of_week_card_test.dart --no-pub
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/sales_history/presentation/widgets/reports/peak_hours_card.dart \
        lib/features/sales_history/presentation/widgets/reports/day_of_week_card.dart \
        test/features/sales_history/presentation/widgets/reports/peak_hours_card_test.dart \
        test/features/sales_history/presentation/widgets/reports/day_of_week_card_test.dart
git commit -m "feat(sales-history): add PeakHoursCard + DayOfWeekCard (fl_chart BarChart)"
```

---

## Task 10: `top_products_card.dart` + `top_categories_card.dart`

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/reports/top_products_card.dart`
- Create: `lib/features/sales_history/presentation/widgets/reports/top_categories_card.dart`
- Test: `test/features/sales_history/presentation/widgets/reports/top_products_card_test.dart`
- Test: `test/features/sales_history/presentation/widgets/reports/top_categories_card_test.dart`

Both cards are ranked lists with a progress bar showing relative contribution. The pattern is identical — only the data type and title key differ.

- [ ] **Step 1: Write failing tests**

```dart
// test/features/sales_history/presentation/widgets/reports/top_products_card_test.dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/top_products_card.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 300, height: 220, child: w)),
  );

  testWidgets('renders product names', (tester) async {
    final products = [
      const SalesTopProduct(productId: 'p1', name: 'ببسي', quantitySold: 100, grossAmount: 500),
      const SalesTopProduct(productId: 'p2', name: 'ماء', quantitySold: 50, grossAmount: 250),
    ];
    await tester.pumpWidget(wrap(TopProductsCard(products: products)));
    await tester.pumpAndSettle();
    expect(find.text('Top Products'), findsOneWidget);
    expect(find.text('ببسي'), findsOneWidget);
    expect(find.text('ماء'), findsOneWidget);
  });

  testWidgets('shows empty message when no products', (tester) async {
    await tester.pumpWidget(wrap(TopProductsCard(products: const [])));
    await tester.pumpAndSettle();
    expect(find.text('No sales in this period.'), findsOneWidget);
  });
}
```

```dart
// test/features/sales_history/presentation/widgets/reports/top_categories_card_test.dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/top_categories_card.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SizedBox(width: 300, height: 220, child: w)),
  );

  testWidgets('renders category names', (tester) async {
    final cats = [
      const SalesTopCategory(categoryId: 'c1', name: 'مشروبات', quantitySold: 200, grossAmount: 750),
    ];
    await tester.pumpWidget(wrap(TopCategoriesCard(categories: cats)));
    await tester.pumpAndSettle();
    expect(find.text('Top Categories'), findsOneWidget);
    expect(find.text('مشروبات'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Create `top_products_card.dart`**

```dart
// lib/features/sales_history/presentation/widgets/reports/top_products_card.dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/sales_report_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';

class TopProductsCard extends StatelessWidget {
  const TopProductsCard({super.key, required this.products});
  final List<SalesTopProduct> products;

  @override
  Widget build(BuildContext context) {
    return _RankedListCard(
      title: context.tr.topProductsTitle,
      items: products.map((p) => (name: p.name, amount: p.grossAmount)).toList(),
      emptyMessage: context.tr.reportsNoSalesInRange,
    );
  }
}

class _RankedListCard extends StatelessWidget {
  const _RankedListCard({
    required this.title,
    required this.items,
    required this.emptyMessage,
  });

  final String title;
  final List<({String name, double amount})> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxAmount = items.fold(0.0, (m, i) => m > i.amount ? m : i.amount);

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.sm200(context)
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppDims.s3),
          if (items.isEmpty)
            Expanded(
              child: Center(
                child: Text(emptyMessage,
                    style: AppTextStyles.sm200(context)
                        .copyWith(color: colors.textHint)),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: items.length > 5 ? 5 : items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDims.s2),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final ratio =
                      maxAmount > 0 ? item.amount / maxAmount : 0.0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.sm200(context)
                                  .copyWith(color: colors.textPrimary),
                            ),
                          ),
                          Text(
                            AppFormat.compactMoney(item.amount),
                            style: AppTextStyles.sm100(context).copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: colors.border,
                          valueColor: const AlwaysStoppedAnimation(
                              SalesReportColors.rankBar),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Create `top_categories_card.dart`**

```dart
// lib/features/sales_history/presentation/widgets/reports/top_categories_card.dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/top_products_card.dart';
import 'package:flutter/material.dart';

class TopCategoriesCard extends StatelessWidget {
  const TopCategoriesCard({super.key, required this.categories});
  final List<SalesTopCategory> categories;

  @override
  Widget build(BuildContext context) {
    return _RankedListCard(
      title: context.tr.topCategoriesTitle,
      items: categories
          .map((c) => (name: c.name, amount: c.grossAmount))
          .toList(),
      emptyMessage: context.tr.reportsNoSalesInRange,
    );
  }
}
```

Note: `_RankedListCard` is imported from `top_products_card.dart`. If `_RankedListCard` is private, make it `RankedListCard` (public, no underscore) so it can be reused. Update the test accordingly.

- [ ] **Step 4: Run tests — expect PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/reports/top_products_card_test.dart test/features/sales_history/presentation/widgets/reports/top_categories_card_test.dart --no-pub
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/sales_history/presentation/widgets/reports/top_products_card.dart \
        lib/features/sales_history/presentation/widgets/reports/top_categories_card.dart \
        test/features/sales_history/presentation/widgets/reports/top_products_card_test.dart \
        test/features/sales_history/presentation/widgets/reports/top_categories_card_test.dart
git commit -m "feat(sales-history): add TopProductsCard + TopCategoriesCard ranked list"
```

---

## Task 11: `reports_status_views.dart`

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/reports/reports_status_views.dart`
- Test: `test/features/sales_history/presentation/widgets/reports/reports_status_views_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/sales_history/presentation/widgets/reports/reports_status_views_test.dart
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_status_views.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: CustomScrollView(slivers: [w])),
  );

  testWidgets('ReportsLoadingSkeleton renders shimmer placeholders', (tester) async {
    await tester.pumpWidget(wrap(const ReportsLoadingSkeleton()));
    await tester.pump(); // don't settle — shimmer animates
    expect(find.byType(ReportsLoadingSkeleton), findsOneWidget);
  });

  testWidgets('ReportsEmptyView shows no-sales message', (tester) async {
    await tester.pumpWidget(wrap(const ReportsEmptyView()));
    await tester.pumpAndSettle();
    expect(find.text('No sales in this period.'), findsOneWidget);
  });

  testWidgets('ReportsErrorView shows error message and retry button', (tester) async {
    bool retried = false;
    await tester.pumpWidget(wrap(
      ReportsErrorView(
        message: 'Failed to load report.',
        onRetry: () => retried = true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Failed to load report.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, true);
  });
}
```

- [ ] **Step 2: Create `reports_status_views.dart`**

```dart
// lib/features/sales_history/presentation/widgets/reports/reports_status_views.dart
import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ReportsLoadingSkeleton extends StatelessWidget {
  const ReportsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDims.s4),
        child: Column(
          children: [
            // KPI row skeleton
            Row(
              children: List.generate(4, (_) =>
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppDims.s2),
                    child: _Shimmer(height: 64, color: colors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDims.s4),
            // Chart area skeleton
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _Shimmer(height: 320, color: colors.border),
                ),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _Shimmer(height: 155, color: colors.border),
                      const SizedBox(height: AppDims.s3),
                      _Shimmer(height: 155, color: colors.border),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer({required this.height, required this.color});
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withAlpha(60),
        borderRadius: BorderRadius.circular(AppDims.rXl),
      ),
    );
  }
}

class ReportsEmptyView extends StatelessWidget {
  const ReportsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              SolarIconsOutline.chartSquare,
              size: 48,
              color: context.appColors.textHint,
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              context.tr.reportsNoSalesInRange,
              style: AppTextStyles.bs200(context)
                  .copyWith(color: context.appColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportsErrorView extends StatelessWidget {
  const ReportsErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              SolarIconsOutline.closeCircle,
              size: 40,
              color: colors.danger,
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              message,
              style: AppTextStyles.bs200(context)
                  .copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDims.s3),
            TextButton(
              onPressed: onRetry,
              child: Text(context.tr.retry),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run tests — expect PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/reports/reports_status_views_test.dart --no-pub
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/sales_history/presentation/widgets/reports/reports_status_views.dart \
        test/features/sales_history/presentation/widgets/reports/reports_status_views_test.dart
git commit -m "feat(sales-history): add ReportsLoadingSkeleton + ReportsEmptyView + ReportsErrorView"
```

---

## Task 12: `reports_tab_view.dart` + Wire into `DesktopSalesHistoryView`

**Files:**
- Create: `lib/features/sales_history/presentation/widgets/reports/reports_tab_view.dart`
- Modify: `lib/features/sales_history/presentation/widgets/desktop_sales_history_view.dart`
- Test: `test/features/sales_history/presentation/widgets/reports/reports_tab_view_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/sales_history/presentation/widgets/reports/reports_tab_view_test.dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_status_views.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_tab_view.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesReportBloc
    extends MockBloc<SalesReportEvent, SalesReportState>
    implements SalesReportBloc {}

SalesReport _fakeReport() => SalesReport(
  rangeFrom: '2026-06-10',
  rangeTo: '2026-06-10',
  currency: 'SDG',
  summary: const SalesReportSummary(
    grossSalesAmount: 500,
    netSalesAmount: 500,
    salesCount: 2,
    averageSaleAmount: 250,
    refundAmount: 0,
    refundCount: 0,
  ),
  trend: const SalesTrend(interval: 'hour', points: []),
  paymentMethods: const [],
  topProducts: const [],
  topCategories: const [],
  peakHours: List.generate(24, (h) => PeakHourStat(hour: h, salesCount: 0, amount: 0)),
  dayOfWeek: List.generate(7, (d) => DayOfWeekStat(weekday: d + 1, salesCount: 0, amount: 0)),
);

void main() {
  late MockSalesReportBloc bloc;

  setUpAll(() => registerFallbackValue(const SalesReportRangeChanged(preset: ReportPreset.today)));

  setUp(() => bloc = MockSalesReportBloc());

  Widget wrap(Widget sliver) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: BlocProvider<SalesReportBloc>.value(
        value: bloc,
        child: CustomScrollView(slivers: [sliver]),
      ),
    ),
  );

  testWidgets('shows ReportsLoadingSkeleton when loading', (tester) async {
    when(() => bloc.state).thenReturn(
      const SalesReportState(status: SalesReportBlocStatus.loading),
    );
    await tester.pumpWidget(wrap(const ReportsTabView()));
    await tester.pump();
    expect(find.byType(ReportsLoadingSkeleton), findsOneWidget);
  });

  testWidgets('shows ReportsErrorView when failure', (tester) async {
    when(() => bloc.state).thenReturn(
      const SalesReportState(
        status: SalesReportBlocStatus.failure,
        errorMessage: 'Network error',
      ),
    );
    await tester.pumpWidget(wrap(const ReportsTabView()));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsErrorView), findsOneWidget);
  });

  testWidgets('shows ReportsEmptyView when report is empty', (tester) async {
    final empty = _fakeReport();
    // Override salesCount to 0 by creating a modified report
    final emptyReport = SalesReport(
      rangeFrom: empty.rangeFrom,
      rangeTo: empty.rangeTo,
      currency: empty.currency,
      summary: const SalesReportSummary(
        grossSalesAmount: 0,
        netSalesAmount: 0,
        salesCount: 0,
        averageSaleAmount: 0,
        refundAmount: 0,
        refundCount: 0,
      ),
      trend: empty.trend,
      paymentMethods: empty.paymentMethods,
      topProducts: empty.topProducts,
      topCategories: empty.topCategories,
      peakHours: empty.peakHours,
      dayOfWeek: empty.dayOfWeek,
    );
    when(() => bloc.state).thenReturn(
      SalesReportState(status: SalesReportBlocStatus.loaded, report: emptyReport),
    );
    await tester.pumpWidget(wrap(const ReportsTabView()));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsEmptyView), findsOneWidget);
  });

  testWidgets('shows DateRangeBar + KPI row when loaded with data', (tester) async {
    when(() => bloc.state).thenReturn(
      SalesReportState(status: SalesReportBlocStatus.loaded, report: _fakeReport()),
    );
    await tester.pumpWidget(wrap(const ReportsTabView()));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);       // DateRangeBar
    expect(find.text('Revenue'), findsOneWidget);     // ReportsKpiRow
  });
}
```

- [ ] **Step 2: Create `reports_tab_view.dart`**

Layout:
- `DateRangeBar` (outside BlocBuilder — always shows)
- `BlocBuilder<SalesReportBloc, SalesReportState>` for the rest:
  - loading → `ReportsLoadingSkeleton`
  - failure → `ReportsErrorView`
  - loaded + `report.isEmpty` → `ReportsEmptyView`
  - loaded + data → KPI row + bento grid

Bento constants:
```dart
const _kTrendHeight  = 360.0;
const _kSmallCardH   = 175.0;
const _kBottomCardH  = 220.0;
```

```dart
// lib/features/sales_history/presentation/widgets/reports/reports_tab_view.dart
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/date_range_bar.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/day_of_week_card.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/payment_breakdown_card.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/peak_hours_card.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_kpi_row.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_status_views.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/revenue_trend_card.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/top_categories_card.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/top_products_card.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _kTrendHeight  = 360.0;
const _kSmallCardH   = 175.0;
const _kBottomCardH  = 220.0;

class ReportsTabView extends StatelessWidget {
  const ReportsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: const DateRangeBar()),
        BlocBuilder<SalesReportBloc, SalesReportState>(
          builder: (context, state) {
            if (state.status == SalesReportBlocStatus.loading) {
              return const ReportsLoadingSkeleton();
            }
            if (state.status == SalesReportBlocStatus.failure) {
              return ReportsErrorView(
                message: state.errorMessage ?? '',
                onRetry: () => context
                    .read<SalesReportBloc>()
                    .add(const SalesReportRefreshed()),
              );
            }
            final report = state.report;
            if (report == null || report.isEmpty) {
              return const ReportsEmptyView();
            }
            return SliverToBoxAdapter(child: _ReportsContent(report: report));
          },
        ),
      ],
    );
  }
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({required this.report});
  final SalesReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppDims.s3),
        ReportsKpiRow(summary: report.summary),
        const SizedBox(height: AppDims.s4),
        // Bento row 1: trend (2/3) + payment & peak hours stacked (1/3)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: _kTrendHeight,
                child: RevenueTrendCard(trend: report.trend),
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  SizedBox(
                    height: _kSmallCardH,
                    child: PaymentBreakdownCard(
                        paymentMethods: report.paymentMethods),
                  ),
                  const SizedBox(height: AppDims.s3),
                  SizedBox(
                    height: _kSmallCardH,
                    child: PeakHoursCard(peakHours: report.peakHours),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDims.s3),
        // Bento row 2: top products / top categories / day-of-week (equal thirds)
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: _kBottomCardH,
                child: TopProductsCard(products: report.topProducts),
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: SizedBox(
                height: _kBottomCardH,
                child: TopCategoriesCard(categories: report.topCategories),
              ),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: SizedBox(
                height: _kBottomCardH,
                child: DayOfWeekCard(dayOfWeek: report.dayOfWeek),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDims.s4),
      ],
    );
  }
}
```

- [ ] **Step 3: Run tests — expect PASS**

```bash
flutter test test/features/sales_history/presentation/widgets/reports/reports_tab_view_test.dart --no-pub
```

- [ ] **Step 4: Replace placeholder in `DesktopSalesHistoryView`**

In `lib/features/sales_history/presentation/widgets/desktop_sales_history_view.dart`, find the reports branch in `_buildSlivers`:

```dart
// Before:
if (_activeView == SalesView.reports) {
  return const [ReportsPlaceholderView()];
}

// After:
if (_activeView == SalesView.reports) {
  return const [ReportsTabView()];
}
```

Add import:
```dart
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/reports_tab_view.dart';
```

Remove the old `reports_placeholder_view.dart` import.

- [ ] **Step 5: Run all feature tests to verify nothing broke**

```bash
flutter test test/features/sales_history/ test/core/permissions/app_permissions_sales_history_test.dart --no-pub
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/sales_history/presentation/widgets/reports/reports_tab_view.dart \
        lib/features/sales_history/presentation/widgets/desktop_sales_history_view.dart \
        test/features/sales_history/presentation/widgets/reports/reports_tab_view_test.dart
git commit -m "feat(sales-history): assemble ReportsTabView + wire into DesktopSalesHistoryView"
```

---

## Self-Review

### Spec coverage

| Spec requirement | Task |
|---|---|
| `SalesReport` entity + nested DTOs | Task 1 |
| `getSalesReport` on repo/use-case | Task 2 |
| `SalesReportBloc` (range, loading, loaded, failure) | Task 3 |
| `FeatureBlocProviders.salesHistory` → `MultiBlocProvider` | Task 3 |
| 13 l10n keys | Task 4 |
| `DateRangeBar` (Today/Yesterday/Custom range picker) | Task 5 |
| `SalesReportColors` palette | Task 5 |
| `ReportsKpiRow` — 4 read-only KPI cards | Task 6 |
| `RevenueTrendCard` — `LineChart` gross + net | Task 7 |
| `PaymentBreakdownCard` — donut `PieChart` | Task 8 |
| `PeakHoursCard` — 24-bar `BarChart` | Task 9 |
| `DayOfWeekCard` — 7-bar `BarChart` | Task 9 |
| `TopProductsCard` — ranked list with progress bars | Task 10 |
| `TopCategoriesCard` — ranked list | Task 10 |
| `ReportsLoadingSkeleton` / `ReportsEmptyView` / `ReportsErrorView` | Task 11 |
| `ReportsTabView` — assembles all | Task 12 |
| Replace placeholder in `DesktopSalesHistoryView` | Task 12 |

All spec requirements covered. ✅

### Type consistency

- `SalesReport` used in Task 2 repo, Task 3 bloc state, Task 6–12 UI — consistent.
- `SalesReportBlocStatus` enum used in bloc state + all status-checking UI — consistent.
- `ReportPreset` enum defined in `sales_report_event.dart`, used in `date_range_bar.dart` + bloc — consistent.
- `_RankedListCard` shared between `top_products_card.dart` and `top_categories_card.dart` — Task 10 notes to make it public (`RankedListCard`) so it's importable.

### No placeholders

All steps contain complete code. ✅
