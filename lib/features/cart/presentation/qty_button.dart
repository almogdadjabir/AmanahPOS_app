import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/widgets/pressable.dart';
import 'package:flutter/material.dart';

class QtyButton extends StatelessWidget {
  const QtyButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = onTap != null;

    return Pressable(
      onTap: onTap,
      haptic: true,
      scale: 0.9,
      child: Opacity(
        opacity: enabled ? 1 : 0.38,
        child: SizedBox(
          width: 34,
          height: 32,
          child: Icon(icon, size: 16, color: colors.textSecondary),
        ),
      ),
    );
  }
}
