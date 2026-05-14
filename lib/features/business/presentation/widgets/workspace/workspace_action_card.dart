import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WorkspaceActionCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final String? value;
  final String? badgeText;
  final bool isDisabled;
  final VoidCallback onTap;

  const WorkspaceActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.value,
    this.badgeText,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return RepaintBoundary(
      child: Opacity(
        opacity: isDisabled ? 0.72 : 1,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDims.rXl),
          clipBehavior: Clip.none,
          child: InkWell(
            onTap: isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(AppDims.rXl),
            splashColor: colors.primary.withValues(alpha: 0.08),
            highlightColor: colors.primary.withValues(alpha: 0.04),
            child: Ink(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppDims.rXl),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.75),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDims.s3),
                child: Row(
                  children: [
                    Expanded(
                      child: _CardTextContent(
                        title: title,
                        subtitle: subtitle,
                        value: value,
                        badgeText: badgeText,
                      ),
                    ),
                    const SizedBox(width: AppDims.s3),
                    _IconBox(
                      icon: icon,
                      isDisabled: isDisabled,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms)
        .slideY(
      begin: 0.06,
      end: 0,
      curve: Curves.easeOutCubic,
    );
  }
}

class _CardTextContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? value;
  final String? badgeText;

  const _CardTextContent({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bs500(context).copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: AppDims.s2),
        Row(
          children: [
            if (value != null) ...[
              Text(
                value!,
                style: AppTextStyles.bs300(context).copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: AppDims.s2),
            ],
            Flexible(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bs100(context).copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.05,
                ),
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: AppDims.s2),
              Flexible(
                child: Text(
                  badgeText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs100(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  final Widget icon;
  final bool isDisabled;

  const _IconBox({
    required this.icon,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: isDisabled ? 0.08 : 0.13),
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(
          color: colors.primary.withValues(alpha: isDisabled ? 0.22 : 0.45),
        ),
      ),
      child: Center(
        child: IconTheme(
          data: IconThemeData(
            color: colors.primary.withValues(alpha: isDisabled ? 0.70 : 1),
            size: 28,
          ),
          child: icon,
        ),
      ),
    );
  }
}