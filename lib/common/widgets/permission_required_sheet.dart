import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> showPermissionRequiredSheet(
    BuildContext context, {
      required String title,
      required String message,
    }) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) {
      final colors = context.appColors;

      return Container(
        padding: const EdgeInsets.fromLTRB(
          AppDims.s4,
          AppDims.s3,
          AppDims.s4,
          AppDims.s4,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDims.rXl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: AppDims.s4),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                color: colors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: AppDims.s4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs600(context).copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppDims.s2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs300(context).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppDims.s5),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await openAppSettings();
                },
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open Settings'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDims.rMd),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDims.s2),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Not Now',
                  style: AppTextStyles.bs300(context).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}