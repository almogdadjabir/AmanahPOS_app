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

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.paymentMethods});

  final List<PaymentMethodBreakdown> paymentMethods;

  @override
  Widget build(BuildContext context) {
    final palette = SalesReportColors.donutPalette;

    final sections = <PieChartSectionData>[
      for (var i = 0; i < paymentMethods.length; i++)
        PieChartSectionData(
          value: paymentMethods[i].amount,
          color: palette[i % palette.length],
          radius: 24,
          title: '',
        ),
    ];

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < paymentMethods.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: palette[i % palette.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${paymentMethods[i].method}  ${AppFormat.compactMoney(paymentMethods[i].amount)}',
                      style: const TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
