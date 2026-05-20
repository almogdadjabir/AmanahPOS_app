import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const BentoCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDims.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDims.rLg),
        child: Container(
          padding: const EdgeInsets.all(AppDims.s4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppDims.rLg),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.06),
                blurRadius: AppDims.s2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class CardHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;

  const CardHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: accent, size: AppDims.s4),
        const SizedBox(width: AppDims.s2),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sm300(context).copyWith(
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double height;
  const ShimmerBox({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: colors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDims.rSm),
      ),
    );
  }
}

class CompactCardScrollArea extends StatelessWidget {
  final Widget child;
  final bool showHint;

  const CompactCardScrollArea({
    super.key,
    required this.child,
    this.showHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Expanded(
      child: Stack(
        children: [
          ScrollConfiguration(
            behavior: const _NoGlowScrollBehavior(),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(
                bottom: AppDims.s2,
              ),
              child: child,
            ),
          ),

          // Soft bottom fade. It makes the card feel premium and hints scroll.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 18,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.surface.withValues(alpha: 0),
                      colors.surface,
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (showHint)
            Positioned(
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colors.border.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context,
      Widget child,
      ScrollableDetails details,
      ) {
    return child;
  }
}