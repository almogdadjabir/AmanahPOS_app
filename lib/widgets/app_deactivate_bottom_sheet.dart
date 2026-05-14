import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class AppDeactivateBottomSheet extends StatelessWidget {
  final String title;
  final String description;
  final String cancelText;
  final String confirmText;
  final bool isLoading;
  final VoidCallback onConfirm;
  final IconData icon;
  final Color? confirmColor;

  const AppDeactivateBottomSheet({
    super.key,
    required this.title,
    required this.description,
    required this.isLoading,
    required this.onConfirm,
    this.cancelText = 'Cancel',
    this.confirmText = 'Deactivate',
    this.icon = SolarIconsOutline.forbiddenCircle,
    this.confirmColor,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dangerColor = confirmColor ?? colors.danger;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDims.rXl),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppDims.s4,
          AppDims.s3,
          AppDims.s4,
          AppDims.s4 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            const SizedBox(height: AppDims.s4),

            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: dangerColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: dangerColor.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: dangerColor,
              ),
            ),

            const SizedBox(height: AppDims.s3),

            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs700(context).copyWith(
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
                height: 1.1,
              ),
            ),

            const SizedBox(height: AppDims.s2),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s3,
              ),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs300(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),

            const SizedBox(height: AppDims.s5),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(
                          color: colors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDims.rMd),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: AppTextStyles.bs400(context).copyWith(
                          fontWeight: FontWeight.w900,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppDims.s3),

                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: isLoading ? null : onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: dangerColor,
                        disabledBackgroundColor: colors.border,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDims.rMd),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: AppDims.s2),
                          Flexible(
                            child: Text(
                              confirmText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bs400(context).copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
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