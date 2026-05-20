import 'package:amana_pos/features/sales_history/data/models/sale_history_item.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_history_bloc.dart';
import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SaleStatsRow extends StatelessWidget {
  final SaleFilter activeFilter;
  final List<SaleHistoryItem> Function(List<SaleHistoryItem>)  applyFilter;

  const SaleStatsRow({super.key, required this.activeFilter, required this.applyFilter});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SalesHistoryBloc, SalesHistoryState,
        List<SaleHistoryItem>>(
      selector: (state) => state.items,
      builder: (context, allItems) {
        final filtered = applyFilter(allItems);
        final revenue  = filtered.fold<double>(0, (s, i) => s + i.total);
        final prefix   = activeFilter.statsLabel;

        return Padding(
          padding: const EdgeInsets.fromLTRB(AppDims.s4, AppDims.s3, AppDims.s4, 0),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: '$prefix sales',
                  value: filtered.length.toString(),
                  background: AppColors.primaryLight,
                  valueColor: AppColors.primaryDark,
                  labelColor: AppColors.primary,
                  icon:       Icons.receipt_long_rounded,
                ),
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: _StatCard(
                  label: '$prefix revenue',
                  value: AppFormat.compactMoney(revenue),
                  background: AppColors.secondaryLight,
                  valueColor: AppColors.secondaryDark,
                  labelColor: AppColors.secondaryDark,
                  icon: Icons.payments_rounded,
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
  final String label, value;
  final Color  background, valueColor, labelColor;
  final IconData icon;

  const _StatCard({
    required this.label,   required this.value,
    required this.background, required this.valueColor,
    required this.labelColor, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3, vertical: AppDims.s2 + 2),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color:        valueColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: valueColor),
          ),
          const SizedBox(width: AppDims.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: AppTextStyles.sm100(context).copyWith(
                      color: labelColor, fontSize: 9,
                      letterSpacing: 0.5, fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 1),
                Text(value,
                    style: AppTextStyles.bs400(context).copyWith(
                      color: valueColor, fontWeight: FontWeight.w800,
                      fontSize: 18, height: 1.1,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
