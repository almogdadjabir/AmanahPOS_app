import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class NotificationErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const NotificationErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: colors.textHint),
            const SizedBox(height: AppDims.s4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs100(context).copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDims.s4),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary.withValues(alpha: 0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
