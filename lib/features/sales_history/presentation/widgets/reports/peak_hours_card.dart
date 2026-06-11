import 'dart:math';

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
    final tr = context.tr;
    return _ReportCard(
      title: tr.peakHoursTitle,
      child: peakHours.isEmpty
          ? _EmptyState(message: tr.reportsNoSalesInRange)
          : _PeakHoursChart(peakHours: peakHours),
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

class _PeakHoursChart extends StatelessWidget {
  const _PeakHoursChart({required this.peakHours});

  final List<PeakHourStat> peakHours;

  @override
  Widget build(BuildContext context) {
    // Build bar groups — one per hour in the list (sorted by hour)
    final sorted = [...peakHours]..sort((a, b) => a.hour.compareTo(b.hour));

    final rawMax = sorted.isEmpty
        ? 0.0
        : sorted.map((s) => s.amount).reduce(max);
    final maxY = rawMax <= 0 ? 10.0 : rawMax * 1.2;

    final barGroups = <BarChartGroupData>[
      for (final stat in sorted)
        BarChartGroupData(
          x: stat.hour,
          barRods: [
            BarChartRodData(
              toY: stat.amount,
              color: stat.amount > 0
                  ? SalesReportColors.barPrimary
                  : SalesReportColors.barMuted,
              width: 6,
              borderRadius: BorderRadius.circular(2),
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
                final hour = value.toInt();
                // Show labels every 4 hours: 0, 4, 8, 12, 16, 20
                if (hour % 4 != 0) return const SizedBox.shrink();
                return Text(
                  '${hour}h',
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
