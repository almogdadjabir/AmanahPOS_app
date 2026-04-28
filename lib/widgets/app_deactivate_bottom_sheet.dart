import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

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
    this.icon = Icons.block_rounded,
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
    final dangerColor = confirmColor ?? context.appColors.danger;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDims.rXl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDims.s4,
        AppDims.s3,
        AppDims.s4,
        AppDims.s5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.appColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),

          const SizedBox(height: AppDims.s4),

          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.appColors.dangerContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: context.appColors.danger,
            ),
          ),

          const SizedBox(height: AppDims.s3),

          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs600(context).copyWith(
              fontWeight: FontWeight.w800,
              color: context.appColors.textPrimary,
            ),
          ),

          const SizedBox(height: AppDims.s2),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDims.s4),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs400(context).copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: AppDims.s5),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDims.s3,
                    ),
                    side: BorderSide(
                      color: context.appColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDims.rMd),
                    ),
                  ),
                  child: Text(
                    cancelText,
                    style: AppTextStyles.bs400(context).copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppDims.s3),

              Expanded(
                child: FilledButton(
                  onPressed: isLoading ? null : onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: dangerColor,
                    disabledBackgroundColor: context.appColors.border,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDims.s3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDims.rMd),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    confirmText,
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
    );
  }
}