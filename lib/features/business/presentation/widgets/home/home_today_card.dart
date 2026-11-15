import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_card.dart';
import 'package:amana_pos/features/business/presentation/widgets/home/home_format.dart';
import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_amount.dart';
import 'package:flutter/material.dart';

/// Hero: gross sales, hourly bars, then sales / average / refunds.
class HomeTodayCard extends StatelessWidget {
  final DashboardSummary? summary;

  const HomeTodayCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;
    final s = summary;
    final today = s?.today;
    final isEmpty =
        s == null || (today!.salesCount == 0 && today.grossSalesAmount == 0);

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.homeGrossSales,
                  style: text.bodyMedium!.copyWith(
                    fontSize: 15,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                AppAmount(
                  value: homeMoney(today?.grossSalesAmount ?? 0),
                  unit: s?.currency ?? 'SDG',
                  textAlign: TextAlign.start,
                  unitColor: colors.textHint,
                  style: text.displayLarge!.copyWith(
                    fontSize: 46,
                    height: 1.08,
                    letterSpacing: -1.2,
                    color: isEmpty ? colors.disabled : colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                HourlyBars(
                  points: s?.sparkline.points ?? const [],
                  firstSaleHour: s?.sparkline.firstSaleHour,
                  isToday: today != null && today.date == _todayIso(),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          if (!isEmpty) ...[
            const HomeHairline(),
            IntrinsicHeight(
              child: Row(
                children: [
                  _Stat(
                    value: today.salesCount.toString(),
                    label: tr.homeStatSales,
                  ),
                  const VerticalDivider(
                    width: 0.5,
                    thickness: 0.5,
                    indent: 12,
                    endIndent: 14,
                  ),
                  _Stat(
                    value: homeMoney(today.averageSaleAmount),
                    label: tr.homeStatAverage,
                  ),
                  const VerticalDivider(
                    width: 0.5,
                    thickness: 0.5,
                    indent: 12,
                    endIndent: 14,
                  ),
                  _Stat(
                    value: today.refundCount.toString(),
                    label: tr.homeStatRefunds,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _todayIso() {
  final n = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${n.year}-${two(n.month)}-${two(n.day)}';
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppAmount(
                value: value,
                textAlign: TextAlign.start,
                style: text.titleLarge!.copyWith(color: colors.textPrimary),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: text.bodyMedium!.copyWith(
                fontSize: 13,
                color: colors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hourly bars. Leading empty hours are trimmed (at least 8 bars stay),
/// the peak hour is tinted and the current hour is solid.
class HourlyBars extends StatelessWidget {
  static const double height = 78;

  final List<SparklinePoint> points;
  final bool isToday;
  final String? firstSaleHour;

  const HourlyBars({
    super.key,
    required this.points,
    required this.isToday,
    this.firstSaleHour,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    if (points.isEmpty) {
      return Column(
        children: [
          SizedBox(
            height: height,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Divider(height: 0.5, thickness: 0.5, color: colors.border),
            ),
          ),
        ],
      );
    }

    var start = firstSaleHour == null
        ? -1
        : points.indexWhere((p) => p.label == firstSaleHour);
    if (start < 0) start = points.indexWhere((p) => p.amount > 0);
    if (start < 0) start = 0;
    if (points.length - start < 8) start = (points.length - 8).clamp(0, start);
    final shown = points.sublist(start);

    final maxV = shown.map((p) => p.amount).reduce((a, b) => a > b ? a : b);
    final peak = maxV > 0 ? shown.indexWhere((p) => p.amount == maxV) : -1;
    final nowIndex = isToday ? shown.length - 1 : -1;

    final base = colors.primaryContainer;
    final peakColor = Color.lerp(base, colors.primary, 0.38)!;

    final hours = [for (final p in shown) _hour(p.label)];
    final ticks = shown.length >= 4
        ? [
            for (var i = 0; i < 4; i++)
              hours[((shown.length - 1) * i / 3).round()],
          ]
        : [hours.first, hours.last];

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: maxV <= 0
                          ? 3
                          : (shown[i].amount / maxV * height).clamp(3, height),
                      decoration: BoxDecoration(
                        color: i == nowIndex
                            ? colors.primary
                            : i == peak
                            ? peakColor
                            : base,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                          bottom: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final h in ticks)
                Text(
                  '$h',
                  style: text.bodySmall!
                      .copyWith(color: colors.textHint)
                      .tabular,
                ),
            ],
          ),
        ],
      ),
    );
  }

  static int _hour(String label) => int.tryParse(label.split(':').first) ?? 0;
}
