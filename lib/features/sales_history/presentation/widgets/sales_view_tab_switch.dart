import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

enum SalesView { transactions, reports }

class SalesViewTabSwitch extends StatelessWidget {
  const SalesViewTabSwitch({
    super.key,
    required this.active,
    required this.onChanged,
  });

  final SalesView active;
  final ValueChanged<SalesView> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Tab(
              label: context.tr.salesViewTransactions,
              active: active == SalesView.transactions,
              onTap: () => onChanged(SalesView.transactions),
            ),
            _Tab(
              label: context.tr.salesViewReports,
              active: active == SalesView.reports,
              onTap: () => onChanged(SalesView.reports),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDims.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: AppDims.s3, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDims.rSm),
        ),
        child: Text(
          label,
          style: AppTextStyles.sm100(context).copyWith(
            color: active ? Colors.white : context.appColors.textSecondary,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
