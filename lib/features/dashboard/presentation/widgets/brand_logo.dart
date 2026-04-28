import 'package:amana_pos/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Brand mark — gradient square with "A" and a secondary accent dot.
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Text(
            'A',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontSize: size * 0.48,
              height: 1,
            ),
          ),
          Positioned(
            right: size * 0.14,
            bottom: size * 0.14,
            child: Container(
              width: size * 0.18,
              height: size * 0.18,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
