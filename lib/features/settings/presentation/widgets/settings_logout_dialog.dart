import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SettingsLogoutDialog extends StatelessWidget {
  const SettingsLogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = context.appColors;
    final dangerColor = colors.danger;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDims.rXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: dangerColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDims.rLg),
              ),
              child: Icon(
                Icons.logout_rounded,
                size: 26,
                color: dangerColor,
              ),
            ),
            const SizedBox(height: AppDims.s4),
            Text(
              tr.settingsSignOutTitle,
              style: AppTextStyles.bs600(context).copyWith(
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDims.s2),
            Text(
              tr.settingsSignOutMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs300(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppDims.s5),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDims.rMd),
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      tr.commonCancel,
                      style: AppTextStyles.bs400(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDims.s3),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: dangerColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDims.rMd),
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(
                      tr.settingsSignOut,
                      style: AppTextStyles.bs400(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}