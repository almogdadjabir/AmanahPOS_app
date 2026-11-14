import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:amana_pos/theme/phosphor_icons.dart';

/// The one error state: calm copy, one retry action.
class AppErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  final IconData icon;

  const AppErrorView({
    super.key,
    required this.onRetry,
    this.message,
    this.icon = PhosphorIconsRegular.cloudX,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    final tr = context.tr;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDims.s6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: AppDims.borderXl,
                ),
                child: Icon(icon, size: 32, color: colors.textSecondary),
              ),
              const SizedBox(height: AppDims.s5),
              Text(
                tr.somethingWentWrong,
                textAlign: TextAlign.center,
                style: text.titleLarge!.copyWith(color: colors.textPrimary),
              ),
              if (message != null) ...[
                const SizedBox(height: AppDims.s2),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium!.copyWith(color: colors.textSecondary),
                ),
              ],
              const SizedBox(height: AppDims.s6),
              AppButton(
                label: tr.retry,
                variant: AppButtonVariant.secondary,
                pill: true,
                prefixIcon: const Icon(PhosphorIconsRegular.arrowsClockwise),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
