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

class RevenueTrendCard extends StatelessWidget {
  const RevenueTrendCard({super.key, required this.trend});

  final SalesTrend trend;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return _ReportCard(
      title: tr.revenueAndSalesTrend,
      headerTrailing: _TrendLegend(tr: tr),
      child: trend.points.isEmpty
          ? _EmptyState(message: tr.reportsNoSalesInRange)
          : _TrendChart(trend: trend),
    );
  }
}

// ─── Shell card ───────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.child,
    this.headerTrailing,
  });

  final String title;
  final Widget child;
  final Widget? headerTrailing;

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
          Row(
            children: [
              Text(
                title,
                style: AppTextStyles.sm300(context, weight: AppTextStyles.semibold),
              ),
              if (headerTrailing != null) ...[
                const Spacer(),
                headerTrailing!,
              ],
            ],
          ),
          const SizedBox(height: AppDims.s3),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class _TrendLegend extends StatelessWidget {
  const _TrendLegend({required this.tr});

  final dynamic tr;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(color: SalesReportColors.trendGross),
        const SizedBox(width: 4),
        Text(
          context.tr.reportsGross,
          style: AppTextStyles.sm100(context, color: colors.textSecondary),
        ),
        const SizedBox(width: AppDims.s3),
        _LegendDot(color: SalesReportColors.trendNet),
        const SizedBox(width: 4),
        Text(
          context.tr.reportsNet,
          style: AppTextStyles.sm100(context, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

// ─── LineChart ────────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.trend});

  final SalesTrend trend;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;
    final points = trend.points;

    final grossSpots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].grossAmount),
    ];
    final netSpots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].netAmount),
    ];

    final allGross = points.map((p) => p.grossAmount);
    final rawMax = allGross.isEmpty ? 0.0 : allGross.reduce(max);
    final maxY = rawMax <= 0 ? 100.0 : rawMax * 1.25;
    final labelInterval = max(1, (points.length / 5).ceil()).toDouble();

    return LineChart(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      LineChartData(
        minY: 0,
        maxY: maxY,
        clipData: const FlClipData.all(),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => SalesReportColors.tooltipBg,
            tooltipRoundedRadius: 10,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            getTooltipItems: (spots) {
              return spots.asMap().entries.map((entry) {
                final i = entry.key;
                final spot = entry.value;
                final idx = spot.x.toInt().clamp(0, points.length - 1);
                final isGross = spot.barIndex == 0;
                final color = isGross
                    ? SalesReportColors.trendGross
                    : SalesReportColors.trendNet;
                final label = isGross ? tr.reportsGross : tr.reportsNet;
                final prefix = i == 0 ? '${points[idx].label}\n' : '';
                return LineTooltipItem(
                  '$prefix$label  ${AppFormat.compactMoney(spot.y)}',
                  TextStyle(
                    color: i == 0 ? Colors.white : color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  children: i == 0 && points[idx].salesCount > 0
                      ? [
                          TextSpan(
                            text: '\n${points[idx].salesCount} txns',
                            style: TextStyle(
                              color: Colors.white.withAlpha(128),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ]
                      : null,
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: Colors.white.withAlpha(40),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, idx) =>
                      FlDotCirclePainter(
                    radius: 5,
                    color: bar.color ?? Colors.white,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              );
            }).toList();
          },
        ),
        lineBarsData: [
          // Gross line
          LineChartBarData(
            spots: grossSpots,
            color: SalesReportColors.trendGross,
            barWidth: 2.5,
            isCurved: true,
            curveSmoothness: 0.3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SalesReportColors.trendGrossGradientTop,
                  SalesReportColors.trendGrossGradientBottom,
                ],
              ),
            ),
          ),
          // Net line
          LineChartBarData(
            spots: netSpots,
            color: SalesReportColors.trendNet,
            barWidth: 2,
            isCurved: true,
            curveSmoothness: 0.3,
            dotData: const FlDotData(show: false),
            dashArray: [6, 3],
            belowBarData: BarAreaData(
              show: true,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SalesReportColors.trendNetGradientTop,
                  SalesReportColors.trendNetGradientBottom,
                ],
              ),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colors.border,
            strokeWidth: 0.5,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: Text(
                    AppFormat.compactMoney(value),
                    style: TextStyle(
                      fontSize: 9,
                      color: colors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelInterval,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    points[idx].label,
                    style: TextStyle(
                      fontSize: 9,
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
}
