import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class SettingsIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const SettingsIconBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDims.rMd),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }
}