import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class SaleErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const SaleErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72,
              decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 36, color: AppColors.danger)),
          const SizedBox(height: AppDims.s4),
          Text('Could not load sales',
              style: AppTextStyles.bs400(context)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppDims.s2),
          Text(message,
              style: AppTextStyles.bs100(context)
                  .copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: AppDims.s4),
          FilledButton.icon(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ]),
      ),
    );
  }
}
