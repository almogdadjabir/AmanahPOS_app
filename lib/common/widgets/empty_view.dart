import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// The one empty state: soft icon tile, calm copy, one action.
class AppEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final IconData? ctaIcon;
  final VoidCallback? onCta;

  const AppEmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.ctaIcon,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppDims.s6),
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
                title,
                textAlign: TextAlign.center,
                style: text.titleLarge!.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppDims.s2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: text.bodyMedium!.copyWith(color: colors.textSecondary),
              ),
              if (ctaLabel != null && onCta != null) ...[
                const SizedBox(height: AppDims.s6),
                AppButton.wide(
                  label: ctaLabel!,
                  onPressed: onCta,
                  prefixIcon: ctaIcon != null ? Icon(ctaIcon) : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
