import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class PosProductsError extends StatelessWidget {
  const PosProductsError({
    super.key,
    this.message,
    required this.onRetry,
  });

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final errorMessage = message?.trim();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsetsDirectional.all(AppDims.s5),
      children: [
        const SizedBox(height: 120),
        Icon(
          SolarIconsOutline.cloudCross,
          size: 48,
          color: colors.textHint,
        ),
        const SizedBox(height: AppDims.s3),
        Text(
          context.tr.failedToLoadProducts,
          textAlign: TextAlign.center,
          style: AppTextStyles.bs500(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (errorMessage != null && errorMessage.isNotEmpty) ...[
          const SizedBox(height: AppDims.s1),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bs200(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: AppDims.s4),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              SolarIconsOutline.restart,
              size: 16,
            ),
            label: Text(context.tr.retry),
          ),
        ),
      ],
    );
  }
}