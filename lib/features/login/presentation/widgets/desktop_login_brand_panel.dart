import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/widgets/amana_logo.dart';
import 'package:flutter/material.dart';

class DesktopLoginBrandPanel extends StatelessWidget {
  const DesktopLoginBrandPanel({super.key});

  static const Color _gradientTop = AppColors.primary;
  static const Color _gradientBottom = Color(0xFF0a4f49);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientTop, _gradientBottom],
          stops: [0.0, 1.0],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s8,
          vertical: AppDims.s8,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo mark + wordmark
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AmanaPosLogoMark(size: 42, isInAppBar: true),
                const SizedBox(width: AppDims.s3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AmanaPOS',
                      style: AppTextStyles.bs600(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Point of Sale Platform',
                      style: AppTextStyles.sm100(context).copyWith(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Headline
            Text(
              'The smarter way\nto run your shop.',
              style: AppTextStyles.lg200(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.18,
                letterSpacing: -0.6,
              ),
            ),

            const SizedBox(height: AppDims.s3),

            // Subline
            Text(
              'Real-time inventory, multi-branch\nmanagement, and instant receipts.',
              style: AppTextStyles.sm300(context).copyWith(
                color: Colors.white.withValues(alpha: 0.60),
                height: 1.55,
              ),
            ),

            const SizedBox(height: AppDims.s6),

            // Feature badges
            const Wrap(
              spacing: AppDims.s2,
              runSpacing: AppDims.s2,
              children: [
                _Badge(icon: '⚡', label: 'Offline-ready'),
                _Badge(icon: '🌐', label: 'Multi-branch'),
                _Badge(icon: '🔐', label: 'Secure'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.sm100(context).copyWith(
                color: Colors.white.withValues(alpha: 0.80),
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
