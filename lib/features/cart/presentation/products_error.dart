import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class PosProductsError extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const PosProductsError({super.key,
    this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.all(AppDims.s5),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.cloud_off_rounded,
          size: 46,
          color: context.appColors.textHint,
        ),
        const SizedBox(height: AppDims.s3),
        Text(
          'Failed to load products',
          textAlign: TextAlign.center,
          style: AppTextStyles.bs500(context).copyWith(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppDims.s1),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs200(context).copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppDims.s4),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}