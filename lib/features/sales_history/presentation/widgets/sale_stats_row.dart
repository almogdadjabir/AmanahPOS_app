import 'dart:ui' as ui;

import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class SaleStatsRow extends StatelessWidget {
  const SaleStatsRow({
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
        for (final item in filtered) {
          revenue += item.total;
        }

        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppDims.s4,
            AppDims.s3,
            AppDims.s4,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: _salesLabel(context, activeFilter),
                  value: filtered.length.toString(),
                  background: AppColors.primaryLight,
                  valueColor: AppColors.primaryDark,
                  labelColor: AppColors.primary,
                  icon: SolarIconsOutline.billList,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _StatCard(
                  label: _revenueLabel(context, activeFilter),
                  value: AppFormat.compactMoney(revenue),
                  forceValueLtr: true,
                  background: AppColors.secondaryLight,
                  valueColor: AppColors.secondaryDark,
                  labelColor: AppColors.secondaryDark,
                  icon: SolarIconsOutline.walletMoney,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.background,
    required this.valueColor,
    required this.labelColor,
    required this.icon,
    this.forceValueLtr = false,
  });

  final String label;
  final String value;
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
        fontSize: 18,
        height: 1.1,
        letterSpacing: -0.25,
      ),
    );

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: valueColor.withValues(alpha: 0.08),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDims.s3,
            vertical: AppDims.s2 + 2,
          ),
          child: Row(
            children: [
              _StatIconBox(
                icon: icon,
                color: valueColor,
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatIconBox extends StatelessWidget {
  const _StatIconBox({
    required this.icon,
    required this.color,
  });

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
        child: Icon(
          icon,
          size: 17,
          color: color,
        ),
      ),
    );
  }
}

String _salesLabel(BuildContext context, SaleFilter filter) {
  return switch (filter) {
    SaleFilter.all => context.tr.allLoadedSales,
    SaleFilter.today => context.tr.todaysSalesCount,
    SaleFilter.completed => context.tr.completedSalesCount,
    SaleFilter.refunded => context.tr.returnedSalesCount,
    SaleFilter.pending => context.tr.pendingSalesCount,
  };
}

String _revenueLabel(BuildContext context, SaleFilter filter) {
  return switch (filter) {
    SaleFilter.all => context.tr.allLoadedRevenue,
    SaleFilter.today => context.tr.todaysRevenue,
    SaleFilter.completed => context.tr.completedRevenue,
    SaleFilter.refunded => context.tr.returnedRevenue,
    SaleFilter.pending => context.tr.pendingRevenue,
  };
}