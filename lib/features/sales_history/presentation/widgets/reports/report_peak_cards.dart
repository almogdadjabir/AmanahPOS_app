import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/report_cards.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/report_trend_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Busiest hours of the day (only for ranges longer than one day).
class ReportPeakHoursCard extends StatelessWidget {
  final List<PeakHourStat> hours;

  const ReportPeakHoursCard({super.key, required this.hours});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final values = List<double>.filled(24, 0);
    for (final h in hours) {
      if (h.hour >= 0 && h.hour < 24) values[h.hour] = h.amount;
    }
    var peak = 0;
    for (var i = 1; i < 24; i++) {
      if (values[i] > values[peak]) peak = i;
    }

    return ReportCard(
      title: tr.rpPeakHours,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportHeadline(
            value:
                '${reportHourLabel(context, peak)} – ${reportHourLabel(context, (peak + 1) % 24)}',
            hint: tr.rpBusiest,
          ),
          ReportBars(values: values),
          ReportAxis(
            labels: [
              for (final h in [0, 6, 12, 18, 23]) reportHourLabel(context, h),
            ],
          ),
        ],
      ),
    );
  }
}

/// Busiest days of the week (only for ranges of a week or more).
class ReportDayOfWeekCard extends StatelessWidget {
  final List<DayOfWeekStat> days;

  const ReportDayOfWeekCard({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final locale = Localizations.localeOf(context).toLanguageTag();
    // 2024-01-01 is a Monday, ISO weekday 1.
    DateTime dayOf(int weekday) => DateTime(2024, 1, weekday);
    final values = List<double>.filled(7, 0);
    for (final d in days) {
      if (d.weekday >= 1 && d.weekday <= 7) values[d.weekday - 1] = d.amount;
    }
    var peak = 0;
    for (var i = 1; i < 7; i++) {
      if (values[i] > values[peak]) peak = i;
    }

    return ReportCard(
      title: tr.rpBusiestDays,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportHeadline(
            value: DateFormat.EEEE(locale).format(dayOf(peak + 1)),
            hint: tr.rpBusiest,
          ),
          ReportBars(values: values, height: 90),
          ReportCellAxis(
            labels: [
              for (var i = 1; i <= 7; i++)
                DateFormat.E(locale).format(dayOf(i)),
            ],
          ),
        ],
      ),
    );
  }
}
