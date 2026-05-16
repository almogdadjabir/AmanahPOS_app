import 'package:amana_pos/features/inventory/data/models/responses/inbound_response_dto.dart';
import 'package:amana_pos/features/inventory/presentation/premium/premium_colors.dart';
import 'package:amana_pos/features/inventory/presentation/premium/widgets/bento_shared.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class InboundVelocityCard extends StatelessWidget {
  final List<InboundTransactionData> recentInbound;
  final bool isLoading;
  final VoidCallback? onTap;

  const InboundVelocityCard({
    super.key,
    required this.recentInbound,
    required this.isLoading,
    this.onTap,
  });

  List<double> _last7DaysCounts() {
    final now = DateTime.now();
    final counts = List<double>.filled(7, 0);
    for (final tx in recentInbound) {
      if (tx.createdAt == null) continue;
      final date = DateTime.tryParse(tx.createdAt!);
      if (date == null) continue;
      final diff = now.difference(date).inDays;
      if (diff >= 0 && diff < 7) {
        counts[6 - diff]++;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dayCounts = _last7DaysCounts();
    final maxY = dayCounts.isEmpty
        ? 1.0
        : (dayCounts.reduce((a, b) => a > b ? a : b) + 1);

    return BentoCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeader(
            title: 'Inbound Velocity',
            icon: SolarIconsOutline.chart,
            accent: Color(0xFF93C5FD),
          ),
          const SizedBox(height: AppDims.s3),
          isLoading
              ? const ShimmerBox(height: 100)
              : SizedBox(
                  height: 100,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                              final now = DateTime.now();
                              final dayIdx =
                                  (now.weekday - 1 + 7 - (6 - value.toInt())) %
                                      7;
                              return Text(
                                days[dayIdx.toInt()],
                                style: TextStyle(
                                  color: colors.textSecondary
                                      .withValues(alpha: 0.5),
                                  fontSize: 9,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(7, (i) {
                        final isToday = i == 6;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: dayCounts[i] == 0 ? 0.2 : dayCounts[i],
                              color: isToday
                                  ? goldDeep
                                  : goldDeep.withValues(alpha: 0.35),
                              width: 10,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }),
                    ),
                    duration: Duration.zero,
                  ),
                ),
        ],
      ),
    );
  }
}
