import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class QtyButton extends StatelessWidget {
  const QtyButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDims.rSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDims.rSm),
          child: Opacity(
            opacity: enabled ? 1 : 0.38,
            child: SizedBox(
              width: 32,
              height: 34,
              child: Icon(
                icon,
                size: 17,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}