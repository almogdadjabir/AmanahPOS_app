import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class CountPill extends StatelessWidget {
  final IconData icon;
  final int count;
  final AppThemeColors colors;
  const CountPill({super.key, required this.icon, required this.count, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: colors.textSecondary),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: AppTextStyles.bs100(context).copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
