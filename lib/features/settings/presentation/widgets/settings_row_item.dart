import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/settings/presentation/widgets/settings_icon_badge.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/directional_icon.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class SettingsRowItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? trailing;

  const SettingsRowItem({
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
            SettingsIconBadge(
              icon: icon,
              color: resolvedIconColor,
              backgroundColor: resolvedIconColor.withValues(alpha: 0.12),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs600(context).copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bs400(context).copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDims.s2),
            if (trailing != null)
              Text(
                trailing!,
                style: AppTextStyles.bs400(context).copyWith(
                  color: colors.textHint,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              DirectionalIcon(
                icon: SolarIconsOutline.altArrowRight,
                size: 15,
                color: colors.textHint,
              ),
          ],
        ),
      ),
    );
  }
}