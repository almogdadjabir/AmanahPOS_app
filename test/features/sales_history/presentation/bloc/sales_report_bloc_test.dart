import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/domain/usecases/sales_history_usecase.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:flutter/material.dart';
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
    skip: 2, // skip loading+loaded emitted by the constructor auto-fire (Today preset)
    expect: () => [
      isA<SalesReportState>().having((s) => s.preset, 'yesterday', ReportPreset.yesterday),
      isA<SalesReportState>().having((s) => s.status, 'loaded', SalesReportBlocStatus.loaded),
    ],
  );

  blocTest<SalesReportBloc, SalesReportState>(
    'SalesReportRangeChanged with custom range passes correct dates to useCase',
    build: () => SalesReportBloc(useCase: useCase),
    act: (bloc) => bloc.add(
      SalesReportRangeChanged(
        preset: ReportPreset.custom,
        customRange: DateTimeRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 10),
        ),
      ),
    ),
    skip: 2, // skip loading+loaded emitted by the constructor auto-fire (Today preset)
    verify: (_) {
      verify(() => useCase.getSalesReport(
        from: DateTime(2026, 6, 1),
        to: DateTime(2026, 6, 10),
        shopId: any(named: 'shopId'),
        timezone: any(named: 'timezone'),
      )).called(1);
    },
  );
}
