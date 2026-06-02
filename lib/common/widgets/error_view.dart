import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class AppErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  final IconData icon;

  const AppErrorView({
    super.key,
    required this.onRetry,
    this.message,
    this.icon = SolarIconsOutline.cloudCross,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tr = context.tr;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.textHint),
            const SizedBox(height: AppDims.s3),
            Text(
              tr.somethingWentWrong,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs600(context).copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppDims.s2),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs300(context).copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppDims.s4),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(SolarIconsOutline.refresh, size: 16),
              label: Text(
                tr.retry,
                style: AppTextStyles.bs400(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
