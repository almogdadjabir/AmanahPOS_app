import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              'A',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: size * 0.42,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Positioned(
            right: size * 0.14,
            bottom: size * 0.14,
            child: Container(
              width: size * 0.18,
              height: size * 0.18,
              decoration: BoxDecoration(
                color: colors.secondary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.secondary.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
