import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

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

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.all(AppDims.s6),
        child: RepaintBoundary(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child: Icon(icon, size: 38, color: colors.primary),
                ),
              ),
              const SizedBox(height: AppDims.s4),
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
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bs300(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (ctaLabel != null && onCta != null) ...[
                const SizedBox(height: AppDims.s5),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: onCta,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDims.rMd),
                      ),
                    ),
                    icon: ctaIcon != null
                        ? Icon(ctaIcon, size: 19, color: Colors.white)
                        : const SizedBox.shrink(),
                    label: Text(
                      ctaLabel!,
                      style: AppTextStyles.bs500(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
