import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

/// Compact settings row for the desktop content column. Mirrors
/// [SettingsRowItem]'s structure but at desktop type scale (matches
/// DesktopManageTile sizing) so dense groups don't read as oversized.
class DesktopSettingsRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;

  const DesktopSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final resolvedIconColor = iconColor ?? colors.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s4,
          vertical: AppDims.s3,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: resolvedIconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDims.rMd),
              ),
              child: Icon(icon, size: 18, color: resolvedIconColor),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs200(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sm300(context).copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDims.s2),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTextStyles.sm300(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              DirectionalIcon(
                icon: SolarIconsOutline.altArrowRight,
                size: 14,
                color: colors.textHint,
              ),
          ],
        ),
      ),
    );
  }
}
