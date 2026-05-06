import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class CatSummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const CatSummaryChip({super.key,
    required this.icon,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: icon == Icons.circle ? 8 : 13,
            color: iconColor ?? colors.textHint,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}