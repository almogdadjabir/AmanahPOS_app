import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const TotalRow({super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bs300(context).copyWith(
            color: isTotal ? colors.textPrimary : colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: (isTotal
              ? AppTextStyles.lg100(context)
              : AppTextStyles.bs400(context))
              .copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}