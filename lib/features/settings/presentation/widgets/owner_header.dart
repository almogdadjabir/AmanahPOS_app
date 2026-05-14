import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class OwnerHeader extends StatelessWidget {
  final String? fullName;
  final String? phone;
  final String? role;

  const OwnerHeader({
    super.key,
    this.fullName,
    this.phone,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = fullName?.trim().isNotEmpty == true
        ? fullName!.trim()
        : 'User';

    final initials = _initials(name);
    final roleData = _roleData(role);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        border: Border.all(
          color: colors.primary.withValues(alpha: isDark ? 0.26 : 0.16),
          width: 1.1,
        ),
        gradient: RadialGradient(
          center: const Alignment(0.65, -0.95),
          radius: 1.35,
          colors: [
            colors.primary.withValues(alpha: isDark ? 0.22 : 0.09),
            colors.surface.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.66],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDims.rXl),
        child: Stack(
          children: [
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (rect) {
                  return RadialGradient(
                    center: const Alignment(0.45, -0.65),
                    radius: 0.95,
                    colors: [
                      colors.textPrimary,
                      Colors.transparent,
                    ],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: CustomPaint(
                  painter: _OwnerHeaderGridPainter(
                    color: colors.primary.withValues(
                      alpha: isDark ? 0.065 : 0.04,
                    ),
                    spacing: 24,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppDims.s5),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: colors.primary.withValues(alpha: 0.12),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.38),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: AppTextStyles.bs600(context).copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDims.s4),
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
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          phone?.trim().isNotEmpty == true
                              ? phone!.trim()
                              : 'AmanaPOS account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bs300(context).copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: AppDims.s3),
                        _RolePill(
                          label: roleData.label,
                          color: roleData.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return '${parts.first.characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }

  static _RoleData _roleData(String? role) {
    return switch (role?.toLowerCase().trim()) {
      'owner' => const _RoleData('Owner', Color(0xFF2DD4BF)),
      'manager' => const _RoleData('Manager', Color(0xFF38BDF8)),
      'cashier' => const _RoleData('Cashier', Color(0xFFA78BFA)),
      _ => const _RoleData('User', Color(0xFF94A3B8)),
    };
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  final Color color;

  const _RolePill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDims.s3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.34),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.50),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.bs100(context).copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleData {
  final String label;
  final Color color;

  const _RoleData(this.label, this.color);
}

class _OwnerHeaderGridPainter extends CustomPainter {
  final Color color;
  final double spacing;

  const _OwnerHeaderGridPainter({
    required this.color,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OwnerHeaderGridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.spacing != spacing;
  }
}