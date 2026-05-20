import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final AppThemeColors colors;

  const StepBtn({super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, size: 16, color: colors.textPrimary),
        ),
      ),
    );
  }
}