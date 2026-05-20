import 'package:amana_pos/features/sales_history/utility/sale_utility.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SaleEmptyState extends StatelessWidget {
  final SaleFilter filter;
  final bool hasSearch;
  const SaleEmptyState({super.key, required this.filter, required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (icon, title, subtitle) = hasSearch
        ? (Icons.search_off_rounded, 'No matching sales',
    'Try a different search term')
        : switch (filter) {
      SaleFilter.today   => (Icons.today_rounded,
      'No sales today', 'Sales made today will appear here'),
      SaleFilter.pending => (Icons.pending_outlined,
      'No pending sales', 'All offline sales have been synced'),
      _                   => (Icons.receipt_long_rounded,
      'No ${filter.label.toLowerCase()} sales',
      'Matching sales will appear here'),
    };

    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72,
            decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, size: 36, color: AppColors.primary)),
        const SizedBox(height: AppDims.s3),
        Text(title,
            style: AppTextStyles.bs400(context)
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppDims.s2),
        Text(subtitle,
            style: AppTextStyles.bs100(context)
                .copyWith(color: colors.textSecondary)),
      ]),
    );
  }
}