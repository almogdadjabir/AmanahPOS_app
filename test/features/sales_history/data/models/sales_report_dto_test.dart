import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesReportDto.fromJson', () {
    final json = {
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

    test('isEmpty is true when salesCount is 0', () {
      const emptyJson = {
        'range': {'from': '2026-06-10', 'to': '2026-06-10'},
        'currency': 'SDG',
        'summary': {
          'gross_sales_amount': 0.0,
          'net_sales_amount': 0.0,
          'sales_count': 0,
          'average_sale_amount': 0.0,
          'refund_amount': 0.0,
          'refund_count': 0,
        },
        'trend': {'interval': 'hour', 'points': []},
        'payment_methods': [],
        'top_products': [],
        'top_categories': [],
        'peak_hours': [],
        'day_of_week': [],
      };
      expect(SalesReportDto.fromJson(emptyJson).toDomain().isEmpty, true);
    });

    test('isEmpty is false when salesCount is non-zero', () {
      final report = SalesReportDto.fromJson(json).toDomain();
      expect(report.isEmpty, false);
    });
  });
}
