import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class RoleHint extends StatelessWidget {
  final String role;

  const RoleHint({
    super.key,
    required this.role,
  });

  String _hint(BuildContext context) {
    switch (role.trim().toLowerCase()) {
      case 'admin':
        return context.tr.adminRoleHint;
      case 'manager':
        return context.tr.managerRoleHint;
      case 'cashier':
      default:
        return context.tr.cashierRoleHint;
    }
  }

  IconData get _icon {
    switch (role.trim().toLowerCase()) {
      case 'admin':
        return SolarIconsOutline.shieldUser;
      case 'manager':
        return SolarIconsOutline.userCheckRounded;
      case 'cashier':
      default:
        return SolarIconsOutline.cashOut;
    }
  }

  Color get _color {
    switch (role.trim().toLowerCase()) {
      case 'admin':
        return const Color(0xFF8B5CF6);
      case 'manager':
        return const Color(0xFF0EA5E9);
      case 'cashier':
      default:
        return const Color(0xFF0D9488);
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedRole = role.trim().toLowerCase();
    final color = _color;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: DecoratedBox(
        key: ValueKey(normalizedRole),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(
            color: color.withValues(alpha: 0.20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDims.s3),
          child: Row(
            children: [
              Icon(
                _icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: AppDims.s2),
              Expanded(
                child: Text(
                  _hint(context),
                  style: AppTextStyles.bs200(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}