import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SettingsSectionLabel extends StatelessWidget {
  final String label;

  const SettingsSectionLabel(
      this.label, {
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.bs100(context).copyWith(
        color: context.appColors.textHint,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}