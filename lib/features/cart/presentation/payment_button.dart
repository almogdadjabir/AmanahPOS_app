  import 'package:amana_pos/theme/app_spacing.dart';
  import 'package:amana_pos/theme/app_text_styles.dart';
  import 'package:amana_pos/theme/app_theme_colors.dart';
  import 'package:flutter/material.dart';

  class PaymentButton extends StatelessWidget {
    final IconData icon;
    final String label;
    final bool selected;
    final VoidCallback onTap;

    const PaymentButton({super.key,
      required this.icon,
      required this.label,
      required this.selected,
      required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
      final colors = context.appColors;

      return Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.08)
            : colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDims.rMd),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDims.rMd),
              border: Border.all(
                color: selected ? colors.primary : colors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? colors.primary : colors.textSecondary,
                ),
                const SizedBox(width: AppDims.s2),
                Text(
                  label,
                  style: AppTextStyles.bs300(context).copyWith(
                    color: selected ? colors.primary : colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }