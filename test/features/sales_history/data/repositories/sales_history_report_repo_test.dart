import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/domain/repositories/sales_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
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
    final report = result.getOrElse((_) => throw Exception());
    expect(report.summary.salesCount, 3);
    expect(report.summary.grossSalesAmount, 1000.0);
    expect(report.rangeFrom, '2026-06-01');
    expect(report.currency, 'SDG');
  });
}
