import 'dart:math' as math;
import 'package:amana_pos/features/inventory/data/models/responses/premium_summary_dto.dart';
import 'package:amana_pos/features/inventory/presentation/premium/premium_colors.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/bento_shared.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class HealthRingCard extends StatelessWidget {
  final PremiumSummaryData? summary;
  final bool isLoading;
  final VoidCallback? onTap;

  const HealthRingCard({
    super.key,
    this.summary,
    required this.isLoading,
    this.onTap,
  });

  double _healthPct(PremiumSummaryData? s) {
    if (s == null || s.stockItemsCount == 0) return 0;
    final unhealthy = s.lowStockCount + s.outOfStockCount;
    return math.max(
        0,
        math.min(
            100,
            (s.stockItemsCount - unhealthy) / s.stockItemsCount * 100));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final s = summary;
    final pct = _healthPct(s);

    return BentoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(
            title: 'Health Ring',
            icon: SolarIconsOutline.chart,
            accent: goldDeep,
          ),
          const SizedBox(height: AppDims.s3),
          isLoading
              ? const ShimmerBox(height: 120)
              : SizedBox(
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 2,
                      centerSpaceRadius: 34,
                      sections: [
                        PieChartSectionData(
                          value: pct,
                          color: goldDeep,
                          radius: 18,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          value: 100 - pct,
                          color: colors.surface.withValues(alpha: 0.14),
                          radius: 14,
                          showTitle: false,
                        ),
                      ],
                    ),
                    duration: Duration.zero,
                  ),
                ),
          if (!isLoading) ...[
            const SizedBox(height: AppDims.s2),
            _StatChipRow(
              chips: [
                _StatChip(
                  label: 'Healthy',
                  value:
                      '${(s?.stockItemsCount ?? 0) - (s?.lowStockCount ?? 0) - (s?.outOfStockCount ?? 0)}',
                  color: const Color(0xFF5EEAD4),
                ),
                _StatChip(
                  label: 'Low',
                  value: '${s?.lowStockCount ?? 0}',
                  color: const Color(0xFFFCD34D),
                ),
                _StatChip(
                  label: 'Out',
                  value: '${s?.outOfStockCount ?? 0}',
                  color: const Color(0xFFFCA5A5),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChipRow extends StatelessWidget {
  final List<_StatChip> chips;
  const _StatChipRow({required this.chips});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: chips,
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        '$value $label',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
