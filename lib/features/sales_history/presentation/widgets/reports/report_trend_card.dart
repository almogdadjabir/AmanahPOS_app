import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/report_cards.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_format.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String reportHourLabel(BuildContext context, int hour) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.j(locale).format(DateTime(2000, 1, 1, hour));
}

/// Sales by hour (single day) or by day (longer ranges).
class ReportTrendCard extends StatelessWidget {
  final SalesTrend trend;

  const ReportTrendCard({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final hourly = trend.interval == 'hour';
    final values = [for (final p in trend.points) p.netAmount];

    var peak = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[peak]) peak = i;
    }
    final peakValue = values.isEmpty ? 0.0 : values[peak];

    final DateTime? peakDate = hourly || trend.points.isEmpty
        ? null
        : DateTime.tryParse(trend.points[peak].label);
    final where = hourly
        ? reportHourLabel(context, peak)
        : (peakDate == null ? '' : DateFormat.MMMd(locale).format(peakDate));

    List<String> axis;
    if (hourly) {
      axis = [
        for (final h in [0, 6, 12, 18, 23]) reportHourLabel(context, h),
      ];
    } else {
      final n = trend.points.length;
      final idx = {
        0,
        (n - 1) ~/ 4 * 1,
        (n - 1) ~/ 2,
        (n - 1) * 3 ~/ 4,
        n - 1,
      }.toList()..sort();
      axis = [
        for (final i in idx)
          if (i >= 0 && i < n)
            DateTime.tryParse(trend.points[i].label)?.day.toString() ?? '',
      ];
    }

    return ReportCard(
      title: hourly ? tr.rpTrendHour : tr.rpTrendDay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 0),
          ReportHeadline(
            value: saleNumber(peakValue),
            hint: where.isEmpty ? tr.rpBusiest : '${tr.rpBusiest} · $where',
          ),
          ReportBars(values: values),
          ReportAxis(labels: axis),
        ],
      ),
    );
  }
}
