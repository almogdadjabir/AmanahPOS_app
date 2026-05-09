import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class OwnerHeader extends StatelessWidget {
  final String? fullName;
  final String? phone;
  final String? role;

  const OwnerHeader({super.key,
    this.fullName,
    this.phone,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final name = fullName?.trim().isNotEmpty == true
        ? fullName!.trim()
        : 'User';

    return Container(
      padding: const EdgeInsets.all(AppDims.s4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colors.primaryContainer,
            child: Text(
              name.characters.first.toUpperCase(),
              style: AppTextStyles.bs600(context).copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AppDims.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs600(context).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone?.trim().isNotEmpty == true
                      ? phone!.trim()
                      : 'AmanaPOS account',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bs200(context).copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          roleBadge(role, context),
        ],
      ),
    );
  }

  Widget roleBadge(String? role, BuildContext context) {
    final (label, color) = switch (role?.toLowerCase().trim()) {
      'owner'   => ('Owner',   const Color(0xFF0D9488)),
      'manager' => ('Manager', const Color(0xFF0EA5E9)),
      'cashier' => ('Cashier', const Color(0xFF8B5CF6)),
      _         => ('User',    const Color(0xFF6B7280)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDims.s2, vertical: 5),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bs100(context).copyWith(
          color:      color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
