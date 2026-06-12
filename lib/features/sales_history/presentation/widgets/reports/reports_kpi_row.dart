import 'dart:ui' as ui;

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:solar_icons/solar_icons.dart';

class ReportsKpiRow extends StatelessWidget {
  const ReportsKpiRow({super.key, required this.summary});

  final SalesReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final refundValue = summary.refundCount > 0
        ? '${summary.refundCount} · ${AppFormat.compactMoney(summary.refundAmount)}'
        : AppFormat.moneyWithUnit(summary.refundAmount);

    final cards = [
      _KpiCard(
        label: context.tr.reportsRevenue,
        value: AppFormat.moneyWithUnit(summary.grossSalesAmount),
        subtitle: '${context.tr.reportsNet}: ${AppFormat.compactMoney(summary.netSalesAmount)}',
        forceValueLtr: true,
        background: AppColors.secondaryLight,
        valueColor: AppColors.secondaryDark,
        labelColor: AppColors.secondaryDark,
        icon: SolarIconsOutline.walletMoney,
      ),
      _KpiCard(
        label: context.tr.reportsSalesCount,
        value: summary.salesCount.toString(),
        background: AppColors.primaryLight,
        valueColor: AppColors.primaryDark,
        labelColor: AppColors.primary,
        icon: SolarIconsOutline.billList,
      ),
      _KpiCard(
        label: context.tr.avgSale,
        value: AppFormat.moneyWithUnit(summary.averageSaleAmount),
        forceValueLtr: true,
        background: AppColors.infoLight,
        valueColor: AppColors.info,
        labelColor: AppColors.info,
        icon: SolarIconsOutline.chartSquare,
      ),
      _KpiCard(
        label: context.tr.reportsNetSales,
        value: AppFormat.moneyWithUnit(summary.netSalesAmount),
        forceValueLtr: true,
        background: const Color(0xFFDCFCE7), // green-100
        valueColor: AppColors.success,
        labelColor: AppColors.success,
        icon: SolarIconsOutline.chart,
      ),
      if (summary.totalTaxCollected > 0)
        _KpiCard(
          label: context.tr.taxCollected,
          value: AppFormat.moneyWithUnit(summary.totalTaxCollected),
          forceValueLtr: true,
          background: AppColors.warningLight,
          valueColor: AppColors.warning,
          labelColor: AppColors.warning,
          icon: SolarIconsOutline.documentText,
        ),
      _KpiCard(
        label: context.tr.refunds,
        value: refundValue,
        forceValueLtr: true,
        background: AppColors.dangerLight,
        valueColor: AppColors.danger,
        labelColor: AppColors.danger,
        icon: SolarIconsOutline.undoLeft,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(
            child: cards[i]
                .animate(delay: (i * 60).ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.08, end: 0, duration: 350.ms, curve: Curves.easeOutCubic),
          ),
          if (i < cards.length - 1) const SizedBox(width: AppDims.s2),
        ],
      ],
    );
  }
}

// ─── Individual KPI card ──────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.background,
    required this.valueColor,
    required this.labelColor,
    required this.icon,
    this.subtitle,
    this.forceValueLtr = false,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color background;
  final Color valueColor;
  final Color labelColor;
  final IconData icon;
  final bool forceValueLtr;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final displayLabel = locale == 'ar' ? label : label.toUpperCase();

    final valueText = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.start,
      style: AppTextStyles.bs400(context).copyWith(
        color: valueColor,
        fontWeight: FontWeight.w900,
        fontSize: 17,
        height: 1.1,
        letterSpacing: -0.25,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: valueColor.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppDims.s3,
          vertical: AppDims.s2 + 2,
        ),
        child: Row(
          children: [
            _IconBox(icon: icon, color: valueColor),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sm100(context).copyWith(
                      color: labelColor,
                      fontSize: 9,
                      letterSpacing: locale == 'ar' ? 0 : 0.7,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  forceValueLtr
                      ? Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: valueText,
                        )
                      : valueText,
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sm100(context).copyWith(
                        color: labelColor.withValues(alpha: 0.7),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}
