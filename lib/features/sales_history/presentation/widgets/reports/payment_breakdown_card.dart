import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/reports/sales_report_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PaymentBreakdownCard extends StatelessWidget {
  const PaymentBreakdownCard({super.key, required this.paymentMethods});

  final List<PaymentMethodBreakdown> paymentMethods;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return _ReportCard(
      title: tr.paymentMethodsTitle,
      child: paymentMethods.isEmpty
          ? _EmptyState(message: tr.reportsNoSalesInRange)
          : _DonutChart(paymentMethods: paymentMethods),
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

// ─── Donut chart + legend ─────────────────────────────────────────────────────

class _DonutChart extends StatefulWidget {
  const _DonutChart({required this.paymentMethods});

  final List<PaymentMethodBreakdown> paymentMethods;

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final palette = SalesReportColors.donutPalette;
    final methods = widget.paymentMethods;
    final total = methods.fold(0.0, (s, m) => s + m.amount);

    final sections = <PieChartSectionData>[
      for (var i = 0; i < methods.length; i++)
        _buildSection(
          i: i,
          method: methods[i],
          color: palette[i % palette.length],
          total: total,
          isTouched: i == _touchedIndex,
        ),
    ];

    return Row(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 34,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response?.touchedSection == null) {
                        setState(() => _touchedIndex = -1);
                        return;
                      }
                      setState(() {
                        _touchedIndex =
                            response!.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                ),
              ),
              if (_touchedIndex >= 0 && _touchedIndex < methods.length)
                _CenterLabel(
                  method: methods[_touchedIndex],
                  total: total,
                  color: palette[_touchedIndex % palette.length],
                )
              else
                _CenterLabel(
                  method: null,
                  total: total,
                  color: colors.textHint,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < methods.length; i++)
                _LegendRow(
                  method: methods[i],
                  total: total,
                  color: palette[i % palette.length],
                  isHighlighted: i == _touchedIndex,
                  onTap: () => setState(
                    () => _touchedIndex = _touchedIndex == i ? -1 : i,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  PieChartSectionData _buildSection({
    required int i,
    required PaymentMethodBreakdown method,
    required Color color,
    required double total,
    required bool isTouched,
  }) {
    final pct = total > 0 ? (method.amount / total * 100) : 0.0;
    return PieChartSectionData(
      value: method.amount,
      color: color,
      radius: isTouched ? 30 : 24,
      title: isTouched ? '${pct.toStringAsFixed(0)}%' : '',
      titleStyle: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

class _CenterLabel extends StatelessWidget {
  const _CenterLabel({
    required this.method,
    required this.total,
    required this.color,
  });

  final PaymentMethodBreakdown? method;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (method == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppFormat.compactMoney(total),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          Text(
            'Total',
            style: TextStyle(fontSize: 8, color: colors.textHint),
          ),
        ],
      );
    }
    final pct = total > 0 ? (method!.amount / total * 100) : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          AppFormat.compactMoney(method!.amount),
          style: TextStyle(fontSize: 9, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.method,
    required this.total,
    required this.color,
    required this.isHighlighted,
    required this.onTap,
  });

  final PaymentMethodBreakdown method;
  final double total;
  final Color color;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final pct = total > 0 ? (method.amount / total * 100) : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: isHighlighted ? color.withAlpha(18) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    method.method,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isHighlighted
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isHighlighted ? color : colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${AppFormat.compactMoney(method.amount)}  ${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 8,
                      color: colors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
