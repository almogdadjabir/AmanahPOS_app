import 'dart:math';

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/sales_report_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
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

// ─── Shell card ───────────────────────────────────────────────────────────────

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
            style: AppTextStyles.sm300(context, weight: AppTextStyles.semibold),
          ),
          const SizedBox(height: AppDims.s3),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

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
    final colors = context.appColors;
    final sorted = [...peakHours]..sort((a, b) => a.hour.compareTo(b.hour));

    final rawMax = sorted.isEmpty
        ? 0.0
        : sorted.map((s) => s.amount).reduce(max);
    final maxY = rawMax <= 0 ? 10.0 : rawMax * 1.25;

    // Find the peak hour
    final peakStat = sorted.isEmpty
        ? null
        : sorted.reduce((a, b) => a.amount > b.amount ? a : b);

    final barGroups = <BarChartGroupData>[
      for (final stat in sorted)
        _buildGroup(stat: stat, isPeak: stat == peakStat),
    ];

    return BarChart(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: maxY,
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => SalesReportColors.tooltipBg,
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final idx = sorted.indexWhere((s) => s.hour == group.x);
              if (idx < 0) return null;
              final stat = sorted[idx];
              final hourLabel = _hourLabel(stat.hour);
              return BarTooltipItem(
                '$hourLabel\n',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text: AppFormat.compactMoney(stat.amount),
                    style: const TextStyle(
                      color: SalesReportColors.trendGross,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (stat.salesCount > 0)
                    TextSpan(
                      text: '\n${stat.salesCount} txns',
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
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
                if (hour % 6 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _hourLabel(hour),
                    style: TextStyle(
                      fontSize: 8,
                      color: colors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildGroup({
    required PeakHourStat stat,
    required bool isPeak,
  }) {
    if (stat.amount <= 0) {
      return BarChartGroupData(
        x: stat.hour,
        barRods: [
          BarChartRodData(
            toY: 0.5,
            color: SalesReportColors.barMuted,
            width: 5,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    }

    return BarChartGroupData(
      x: stat.hour,
      barRods: [
        BarChartRodData(
          toY: stat.amount,
          gradient: isPeak
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    SalesReportColors.barBest,
                    SalesReportColors.barBestBottom,
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    SalesReportColors.barGradientTop,
                    SalesReportColors.barGradientBottom,
                  ],
                ),
          width: 5,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  static String _hourLabel(int hour) {
    if (hour == 0) return '12am';
    if (hour == 12) return '12pm';
    return hour < 12 ? '${hour}am' : '${hour - 12}pm';
  }
}
