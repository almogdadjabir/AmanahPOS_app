import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailingText;
  final String? logoAsset;
  final VoidCallback onTap;

  const SettingsActionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.onTap,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s4),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: colors.border.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _IconBox(
                icon: icon,
                iconColor: iconColor,
                logoAsset: logoAsset,
              ),
              const SizedBox(width: AppDims.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs500(context).copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bs300(context).copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDims.s3),
              _TrailingAction(
                text: trailingText,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String? logoAsset;

  const _IconBox({
    required this.icon,
    required this.iconColor,
    required this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (logoAsset != null) {
      return Container(
        width: 58,
        height: 58,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.border.withValues(alpha: 0.8),
          ),
        ),
        child: Image.asset(
          logoAsset!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Icon(icon, color: iconColor, size: 25);
          },
        ),
      );
    }

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.22),
        ),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 25,
      ),
    );
  }
}

class _TrailingAction extends StatelessWidget {
  final String text;
  final Color color;

  const _TrailingAction({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isActive = text.toLowerCase() == 'active';

    if (isActive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            SolarIconsOutline.checkCircle,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.bs300(context).copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s3,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: AppTextStyles.bs300(context).copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            SolarIconsOutline.altArrowRight,
            color: colors.textPrimary,
            size: 16,
          ),
        ],
      ),
    );
  }
}