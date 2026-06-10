import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/presentation/widgets/sale_stat_card.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class DesktopSalesStatsRow extends StatelessWidget {
  const DesktopSalesStatsRow({
    super.key,
    required this.activeFilter,
    required this.applyFilter,
  });

  final SaleFilter activeFilter;
  final List<SaleHistoryItem> Function(List<SaleHistoryItem>) applyFilter;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SalesHistoryBloc, SalesHistoryState, List<SaleHistoryItem>>(
      selector: (state) => state.items,
      builder: (context, allItems) {
        final filtered = applyFilter(allItems);

        double revenue = 0;
        double refundAmount = 0;
        int refundCount = 0;

        for (final item in filtered) {
          revenue += item.total;
          final isRefund = item.status == SaleHistoryStatus.refunded ||
              item.status == SaleHistoryStatus.partialRefund;
          if (isRefund) {
            refundCount++;
            refundAmount += item.total;
          }
        }

        final count = filtered.length;
        final avgSale = count > 0 ? revenue / count : 0.0;

        return Row(
          children: [
            Expanded(
              child: SaleStatCard(
                label: activeFilter.salesCountLabel(context),
                value: count.toString(),
                background: AppColors.primaryLight,
                valueColor: AppColors.primaryDark,
                labelColor: AppColors.primary,
                icon: SolarIconsOutline.billList,
              ),
            ),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: SaleStatCard(
                label: activeFilter.revenueLabel(context),
                value: AppFormat.compactMoney(revenue),
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
                label: context.tr.avgSale,
                value: AppFormat.compactMoney(avgSale),
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
                value: '$refundCount · ${AppFormat.compactMoney(refundAmount)}',
                forceValueLtr: true,
                background: AppColors.dangerLight,
                valueColor: AppColors.danger,
                labelColor: AppColors.danger,
                icon: SolarIconsOutline.undoLeft,
              ),
            ),
          ],
        );
      },
    );
  }
}
