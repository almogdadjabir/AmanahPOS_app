import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

const _kPlaceholderIconSize = 48.0;

class ReportsPlaceholderView extends StatelessWidget {
  const ReportsPlaceholderView({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              SolarIconsOutline.chartSquare,
              size: _kPlaceholderIconSize,
              color: context.appColors.textHint,
            ),
            const SizedBox(height: AppDims.s3),
            Text(
              context.tr.reportsComingSoon,
              style: AppTextStyles.bs200(context).copyWith(
                color: context.appColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
