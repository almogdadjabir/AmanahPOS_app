import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const QtyButton({super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDims.rSm),
      child: SizedBox(
        width: 30,
        height: 32,
        child: Icon(
          icon,
          size: 16,
          color: context.appColors.textPrimary,
        ),
      ),
    );
  }
}