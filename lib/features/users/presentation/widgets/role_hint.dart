import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class RoleHint extends StatelessWidget {
  final String role;
  const RoleHint({super.key, required this.role});

  String get _hint => switch (role) {
    'admin'   => 'Full access — can manage everything including users and settings.',
    'manager' => 'Can view reports, manage inventory and orders.',
    _ => 'Can process sales and manage the POS terminal.',
  };

  IconData get _icon => switch (role) {
    'admin'   => Icons.shield_outlined,
    'manager' => Icons.manage_accounts_outlined,
    _ => Icons.point_of_sale_rounded,
  };

  Color _color(BuildContext context) => switch (role) {
    'admin'   => const Color(0xFF8B5CF6),
    'manager' => const Color(0xFF0EA5E9),
    _ => const Color(0xFF0D9488),
  };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(role),
        width: double.infinity,
        padding: const EdgeInsets.all(AppDims.s3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppDims.rMd),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(_icon, size: 16, color: color),
            const SizedBox(width: AppDims.s2),
            Expanded(
              child: Text(
                _hint,
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
    );
  }
}