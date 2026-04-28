import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'brand_logo.dart';

/// Top app bar: hamburger, brand block, notifications.
class PosAppBar extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback? onNotifTap;
  final bool hasNotifications;

  const PosAppBar({
    super.key,
    required this.onMenuTap,
    this.onNotifTap,
    this.hasNotifications = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconButton(icon: Icons.menu_rounded, onTap: onMenuTap),
        const SizedBox(width: AppDims.s2),
        const BrandLogo(),
        const SizedBox(width: AppDims.s3),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AmanaPOS',
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 14, fontWeight: FontWeight.w800,
                  color: context.appColors.textPrimary, letterSpacing: -0.2,
                ),
              ),
              Text(
                'Khartoum · Reg #2',
                style: TextStyle(
                  fontFamily: 'NunitoSans', fontSize: 10.5, fontWeight: FontWeight.w600,
                  color: context.appColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _IconButton(icon: Icons.notifications_outlined, onTap: onNotifTap),
            if (hasNotifications)
              Positioned(
                right: 8, top: 8,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: context.appColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.appColors.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _IconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rSm),
        child: SizedBox(
          width: 40, height: 40,
          child: Icon(icon, size: 22, color: context.appColors.textPrimary),
        ),
      ),
    );
  }
}
