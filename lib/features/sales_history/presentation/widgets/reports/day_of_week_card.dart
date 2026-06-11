import 'dart:math';

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/sales_report_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

// ISO weekday abbreviations (locale-neutral fallback): index 0=Mon … 6=Sun.
// Used only when the bar-chart bottom-title widget cannot access context.
const _kDayLabelsEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _kDayLabelsAr = ['إث', 'ث', 'أر', 'خ', 'ج', 'س', 'أح'];

class DayOfWeekCard extends StatelessWidget {
  const DayOfWeekCard({super.key, required this.dayOfWeek});

  final List<DayOfWeekStat> dayOfWeek;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return _ReportCard(
      title: tr.dayOfWeekTitle,
      child: dayOfWeek.isEmpty
          ? _EmptyState(message: tr.reportsNoSalesInRange)
          : _DayOfWeekChart(dayOfWeek: dayOfWeek),
    );
  }
}

// ─── Shell card ──────────────────────────────────────────────────────────────

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
          Text(
            title,
            style: AppTextStyles.sm300(context,
                weight: AppTextStyles.semibold),
          ),
          const SizedBox(height: AppDims.s3),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Text(
        message,
        style: AppTextStyles.sm200(context, color: colors.textHint),
      ),
    );
  }
}

// ─── BarChart ─────────────────────────────────────────────────────────────────

class _DayOfWeekChart extends StatelessWidget {
  const _DayOfWeekChart({required this.dayOfWeek});

  final List<DayOfWeekStat> dayOfWeek;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final dayLabels = isAr ? _kDayLabelsAr : _kDayLabelsEn;

    // Skip entries with invalid weekday (0 = missing data from API)
    final valid = dayOfWeek
        .where((s) => s.weekday >= 1 && s.weekday <= 7)
        .toList()
      ..sort((a, b) => a.weekday.compareTo(b.weekday));

    final rawMax = valid.isEmpty
        ? 0.0
        : valid.map((s) => s.amount).reduce(max);
    final maxY = rawMax <= 0 ? 10.0 : rawMax * 1.2;

    // x value = weekday - 1 (0-indexed) → maps directly into dayLabels
    final barGroups = <BarChartGroupData>[
      for (final stat in valid)
        BarChartGroupData(
          x: stat.weekday - 1,
          barRods: [
            BarChartRodData(
              toY: stat.amount,
              color: stat.amount > 0
                  ? SalesReportColors.barPrimary
                  : SalesReportColors.barMuted,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
    ];

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dayLabels.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  dayLabels[index],
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(enabled: false),
      ),
    );
  }
}
