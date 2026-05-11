import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const BottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = isActive ? colors.primary : colors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 14.0 : 10.0,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? colors.primary.withValues(alpha: 0.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: isActive
                ? Border.all(
                    color: colors.primary.withValues(alpha: 0.20),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              AnimatedSwitcher(
                duration: AppDims.fast,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Icon(
                  icon,
                  key: ValueKey(icon),
                  size: 22,
                  color: color,
                ),
              ),

              const SizedBox(height: 3),


              AnimatedDefaultTextStyle(
                duration: AppDims.fast,
                curve: Curves.easeOut,
                style: AppTextStyles.sm200(context).copyWith(
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: color,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
