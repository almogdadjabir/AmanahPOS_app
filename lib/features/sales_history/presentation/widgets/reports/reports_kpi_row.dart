import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_stat_card.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class ReportsKpiRow extends StatelessWidget {
  const ReportsKpiRow({super.key, required this.summary});

  final SalesReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final refundValue = summary.refundCount > 0
        ? '${summary.refundCount} · ${AppFormat.compactMoney(summary.refundAmount)}'
        : AppFormat.moneyWithUnit(summary.refundAmount);

    return Row(
      children: [
        Expanded(
          child: SaleStatCard(
            label: context.tr.reportsRevenue,
            value: AppFormat.moneyWithUnit(summary.grossSalesAmount),
            forceValueLtr: true,
            background: AppColors.secondaryLight,
            valueColor: AppColors.secondaryDark,
            labelColor: AppColors.secondaryDark,
            icon: SolarIconsOutline.walletMoney,
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: SaleStatCard(
            label: context.tr.customerSalesPrefix,
            value: summary.salesCount.toString(),
            background: AppColors.primaryLight,
            valueColor: AppColors.primaryDark,
            labelColor: AppColors.primary,
            icon: SolarIconsOutline.billList,
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: SaleStatCard(
            label: context.tr.avgSale,
            value: AppFormat.moneyWithUnit(summary.averageSaleAmount),
            forceValueLtr: true,
            background: AppColors.infoLight,
            valueColor: AppColors.info,
            labelColor: AppColors.info,
            icon: SolarIconsOutline.chartSquare,
          ),
        ),
        const SizedBox(width: AppDims.s2),
        Expanded(
          child: SaleStatCard(
            label: context.tr.refunds,
            value: refundValue,
            forceValueLtr: true,
            background: AppColors.dangerLight,
            valueColor: AppColors.danger,
            labelColor: AppColors.danger,
            icon: SolarIconsOutline.undoLeft,
          ),
        ),
      ],
    );
  }
}
