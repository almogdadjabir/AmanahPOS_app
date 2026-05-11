import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class StatusDot extends StatelessWidget {
  final bool isActive;
  final AppThemeColors colors;
  const StatusDot({super.key, required this.isActive, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? const Color(0xFF22C55E)
                : colors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isActive ? 'Active' : 'Inactive',
          style: AppTextStyles.bs100(context).copyWith(
            color: isActive ? const Color(0xFF22C55E) : colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
