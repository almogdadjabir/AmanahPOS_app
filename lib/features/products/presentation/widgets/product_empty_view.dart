import 'dart:math' as math;

import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProductEmptyView extends StatelessWidget {
  final String title;
  final String message;
  final bool hasCategories;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionText;

  const ProductEmptyView({
    super.key,
    required this.title,
    required this.message,
    this.hasCategories = true,
    this.onPrimaryAction,
    this.primaryActionText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s5,
          vertical: AppDims.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Catalog preview grid ──────────────────────────────────────
            const _CatalogGrid()
                .animate()
                .fadeIn(duration: 380.ms)
                .scale(
                  begin: const Offset(0.93, 0.93),
                  end: const Offset(1, 1),
                  duration: 420.ms,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: AppDims.s8),

            // ── Title ─────────────────────────────────────────────────────
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs500(context).copyWith(
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
                height: 1.1,
                letterSpacing: -0.4,
              ),
            )
                .animate(delay: 150.ms)
                .fadeIn(duration: 300.ms)
                .slideY(
                  begin: 0.28,
                  end: 0,
                  curve: Curves.easeOutCubic,
                  duration: 300.ms,
                ),

            const SizedBox(height: AppDims.s3),

            // ── Subtitle ──────────────────────────────────────────────────
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bs100(context).copyWith(
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
                height: 1.58,
              ),
            )
                .animate(delay: 210.ms)
                .fadeIn(duration: 300.ms)
                .slideY(
                  begin: 0.28,
                  end: 0,
                  curve: Curves.easeOutCubic,
                  duration: 300.ms,
                ),

            // ── CTA button ────────────────────────────────────────────────
            if (onPrimaryAction != null && primaryActionText != null) ...[
              const SizedBox(height: AppDims.s8),
              _AddProductButton(
                label: primaryActionText!,
                onPressed: onPrimaryAction!,
              )
                  .animate(delay: 270.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(
                    begin: 0.28,
                    end: 0,
                    curve: Curves.easeOutCubic,
                    duration: 300.ms,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Catalog preview grid ────────────────────────────────────────────────────

class _CatalogGrid extends StatelessWidget {
  const _CatalogGrid();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _FilledCard(
                accentColor: colors.warning,
                icon: Icons.inventory_2_rounded,
              )
                  .animate(delay: 40.ms)
                  .fadeIn(duration: 280.ms)
                  .scale(
                    begin: const Offset(0.82, 0.82),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
            ),
            const SizedBox(width: AppDims.s3),
            Expanded(
              child: _FilledCard(
                accentColor: colors.success,
                icon: Icons.local_offer_rounded,
              )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 280.ms)
                  .scale(
                    begin: const Offset(0.82, 0.82),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppDims.s3),
        Row(
          children: [
            Expanded(
              child: _FilledCard(
                accentColor: colors.info,
                icon: Icons.category_rounded,
              )
                  .animate(delay: 160.ms)
                  .fadeIn(duration: 280.ms)
                  .scale(
                    begin: const Offset(0.82, 0.82),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
            ),
            const SizedBox(width: AppDims.s3),
            // The "your product goes here" slot
            Expanded(
              child: const _EmptySlot()
                  .animate(delay: 220.ms)
                  .fadeIn(duration: 280.ms)
                  .scale(
                    begin: const Offset(0.82, 0.82),
                    end: const Offset(1, 1),
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Simulated filled product card ───────────────────────────────────────────

class _FilledCard extends StatelessWidget {
  final Color accentColor;
  final IconData icon;

  const _FilledCard({required this.accentColor, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDims.rXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image area
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.11),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDims.rXl),
                  topRight: Radius.circular(AppDims.rXl),
                ),
              ),
              child: Center(
                child: Icon(icon, size: 34, color: accentColor),
              ),
            ),
          ),
          // Info skeleton
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDims.s3,
                vertical: AppDims.s2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.border.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 6,
                    width: 46,
                    decoration: BoxDecoration(
                      color: colors.border.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(3),
                    ),
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

// ── "Your product goes here" empty slot ─────────────────────────────────────

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    // Continuous gentle breathing — GPU transform only, no repaints
    return SizedBox(
      height: 132,
      child: CustomPaint(
        foregroundPainter: _DashBorderPainter(
          color: colors.primary.withValues(alpha: 0.42),
          radius: AppDims.rXl,
          strokeWidth: 1.6,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(AppDims.rXl),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppDims.s2),
                Text(
                  'Your product',
                  style: AppTextStyles.sm200(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 1.0,
          end: 1.026,
          duration: 2400.ms,
          curve: Curves.easeInOut,
        );
  }
}

// ── CTA button ───────────────────────────────────────────────────────────────

class _AddProductButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _AddProductButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDims.rXl),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, size: 22, color: Colors.white),
            const SizedBox(width: AppDims.s2),
            Text(
              label,
              style: AppTextStyles.bs300(context).copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashed border painter ────────────────────────────────────────────────────
// Efficient: shouldRepaint only on color/size change. The path is computed
// fresh each paint call but this widget is static — paint fires once on mount.

class _DashBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;

  const _DashBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  static const double _dashLen = 7.0;
  static const double _gapLen = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final inset = strokeWidth / 2;
    final r = math.max(0.0, radius - inset);

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2),
          Radius.circular(r),
        ),
      );

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final pm = metrics.first;

    double distance = 0;
    while (distance < pm.length) {
      final end = math.min(distance + _dashLen, pm.length);
      canvas.drawPath(pm.extractPath(distance, end), paint);
      distance += _dashLen + _gapLen;
    }
  }

  @override
  bool shouldRepaint(_DashBorderPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth || old.radius != radius;
}
