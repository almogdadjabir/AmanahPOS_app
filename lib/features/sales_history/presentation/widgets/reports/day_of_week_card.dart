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

// ISO weekday labels: index 0=Mon … 6=Sun.
const _kDayLabelsEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _kDayLabelsAr = ['إث', 'ث', 'أر', 'خ', 'ج', 'س', 'أح'];
const _kDayFullEn = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];
const _kDayFullAr = [
  'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
];

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

class _DayOfWeekChart extends StatelessWidget {
  const _DayOfWeekChart({required this.dayOfWeek});

  final List<DayOfWeekStat> dayOfWeek;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final dayLabels = isAr ? _kDayLabelsAr : _kDayLabelsEn;
    final dayFull = isAr ? _kDayFullAr : _kDayFullEn;

    final valid = dayOfWeek
        .where((s) => s.weekday >= 1 && s.weekday <= 7)
        .toList()
      ..sort((a, b) => a.weekday.compareTo(b.weekday));

    final rawMax = valid.isEmpty ? 0.0 : valid.map((s) => s.amount).reduce(max);
    final maxY = rawMax <= 0 ? 10.0 : rawMax * 1.25;

    // Find the best day
    final bestStat = valid.isEmpty
        ? null
        : valid.reduce((a, b) => a.amount > b.amount ? a : b);

    final barGroups = <BarChartGroupData>[
      for (final stat in valid)
        _buildGroup(stat: stat, isBest: stat == bestStat),
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
              final index = group.x; // 0-indexed weekday
              final dayName = index >= 0 && index < dayFull.length
                  ? dayFull[index]
                  : '';
              final statIdx = valid.indexWhere((s) => s.weekday - 1 == index);
              if (statIdx < 0) return null;
              final stat = valid[statIdx];
              return BarTooltipItem(
                '$dayName\n',
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
                final index = value.toInt();
                if (index < 0 || index >= dayLabels.length) {
                  return const SizedBox.shrink();
                }
                final isBestIndex = valid
                    .where((s) => s.weekday - 1 == index)
                    .any((s) => s == (valid.isEmpty
                        ? null
                        : valid.reduce((a, b) => a.amount > b.amount ? a : b)));
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    dayLabels[index],
                    style: TextStyle(
                      fontSize: 8,
                      color: isBestIndex
                          ? SalesReportColors.barBest
                          : colors.textHint,
                      fontWeight: isBestIndex
                          ? FontWeight.w700
                          : FontWeight.w500,
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
    required DayOfWeekStat stat,
    required bool isBest,
  }) {
    if (stat.amount <= 0) {
      return BarChartGroupData(
        x: stat.weekday - 1,
        barRods: [
          BarChartRodData(
            toY: 0.5,
            color: SalesReportColors.barMuted,
            width: 18,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      );
    }
    return BarChartGroupData(
      x: stat.weekday - 1,
      barRods: [
        BarChartRodData(
          toY: stat.amount,
          gradient: isBest
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
          width: 18,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}
