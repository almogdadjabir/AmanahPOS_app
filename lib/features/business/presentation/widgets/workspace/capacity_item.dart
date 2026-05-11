import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class CapacityItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? value;
  final AppThemeColors colors;
  const CapacityItem({super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                value != null ? '$value' : '∞',
                style: AppTextStyles.bs300(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}