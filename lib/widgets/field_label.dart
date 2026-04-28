import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class FieldLabel extends StatelessWidget {
  final String label;
  final bool required;
  const FieldLabel({super.key, required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bs400(context).copyWith(
            fontWeight: FontWeight.w700,
            color: context.appColors.textSecondary,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          Text('*',
              style: AppTextStyles.bs400(context).copyWith(
                  color: context.appColors.danger,
                  fontWeight: FontWeight.w800)),
        ],
      ],
    );
  }
}