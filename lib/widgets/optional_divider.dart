import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class OptionalDivider extends StatelessWidget {
  const OptionalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(child: Divider(color: colors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s2),
          child: Text(
            'OPTIONAL',
            style: AppTextStyles.bs300(context).copyWith(
              fontWeight: FontWeight.w800,
              color: colors.textHint,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: colors.border)),
      ],
    );
  }
}