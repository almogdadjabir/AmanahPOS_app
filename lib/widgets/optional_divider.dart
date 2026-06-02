import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class OptionalDivider extends StatelessWidget {
  final String? label;

  const OptionalDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = label ?? context.tr.optional;

    return Row(
      children: [
        Expanded(child: Divider(color: colors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDims.s2),
          child: Text(
            text,
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