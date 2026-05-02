import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FloatingStoreHero extends StatelessWidget {
  const FloatingStoreHero({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 156,
          height: 156,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary.withValues(alpha: 0.06),
          ),
        )
            .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
            .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1.05, 1.05),
          duration: 1800.ms,
          curve: Curves.easeInOut,
        ),

        Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary.withValues(alpha: 0.18),
                colors.primary.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.14),
                blurRadius: 38,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.28),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        )
            .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
            .moveY(
          begin: 0,
          end: -8,
          duration: 1600.ms,
          curve: Curves.easeInOut,
        ),

        Positioned(
          right: 18,
          top: 26,
          child: miniFloatingIcon(
            context: context,
            icon: Icons.receipt_long_rounded,
            delay: 200.ms,
          ),
        ),

        Positioned(
          left: 14,
          bottom: 30,
          child: miniFloatingIcon(
            context: context,
            icon: Icons.bar_chart_rounded,
            delay: 420.ms,
          ),
        ),

        Positioned(
          right: 22,
          bottom: 18,
          child: miniFloatingIcon(
            context: context,
            icon: Icons.inventory_2_rounded,
            delay: 640.ms,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 420.ms)
        .scale(
      begin: const Offset(0.88, 0.88),
      end: const Offset(1, 1),
      curve: Curves.easeOutBack,
    );
  }

  Widget miniFloatingIcon({required BuildContext context , required IconData icon, required Duration delay}){
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(AppDims.rMd),
        border: Border.all(
          color: context.appColors.primary.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: context.appColors.primary,
        size: 20,
      ),
    )
        .animate(
      delay: delay,
      onPlay: (controller) => controller.repeat(reverse: true),
    )
        .moveY(
      begin: 0,
      end: -7,
      duration: 1400.ms,
      curve: Curves.easeInOut,
    );
  }
}