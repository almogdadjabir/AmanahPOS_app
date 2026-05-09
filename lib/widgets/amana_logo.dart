import 'package:flutter/material.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:amana_pos/theme/app_text_styles.dart';

class AmanaPosLogoMark extends StatelessWidget {
  final bool isInAppBar;
  const AmanaPosLogoMark({super.key, this.size = 36.0, this.isInAppBar = false});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(size * 8 / 36);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: radius,
        border: Border.all(color: colors.primary, width: 1),
        boxShadow: isInAppBar ? null : [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
          ),
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.10),
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 2, left: 2, right: 2, bottom: 2,
            child: CustomPaint(
              painter: _DashedRoundedRectPainter(
                color: colors.primary.withValues(alpha: 0.30),
                radius: size * 6 / 36,
                dashLength: 3,
                gapLength: 3,
                strokeWidth: 1,
              ),
            ),
          ),
          Center(
            child: Text(
              'أ',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: colors.primary,
                fontSize: size * 18 / 36,
                fontWeight: AppTextStyles.bold,
                height: 1,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AmanaPosLogo extends StatelessWidget {
  const AmanaPosLogo({super.key, this.markSize = 36.0});

  final double markSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final gap = markSize * 12 / 36;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AmanaPosLogoMark(size: markSize),
        SizedBox(width: gap),

        // Arabic name
        Text(
          'أمانة',
          textDirection: TextDirection.rtl,
          style: AppTextStyles.lg100(
            context,
            weight: AppTextStyles.semibold,
            color: colors.textPrimary,
          ).copyWith(
            fontSize: markSize * 22 / 36,
            letterSpacing: markSize * 22 / 36 * -0.01,
            height: 1,
          ),
        ),

        SizedBox(width: gap),

        // Separator
        SizedBox(
          width: 1,
          height: markSize * 0.72,
          child: ColoredBox(color: colors.border),
        ),

        SizedBox(width: gap),

        // Latin name
        Text(
          'AmanaPOS',
          style: AppTextStyles.sm200(
            context,
            color: colors.textHint,
          ).copyWith(
            fontSize: markSize * 10 / 36,
            letterSpacing: markSize * 10 / 36 * 0.24,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double dashLength;
  final double gapLength;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool drawing = true;
      while (distance < metric.length) {
        final segLen = drawing ? dashLength : gapLength;
        if (drawing) {
          final end = (distance + segLen).clamp(0.0, metric.length);
          canvas.drawPath(metric.extractPath(distance, end), paint);
        }
        distance += segLen;
        drawing = !drawing;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedRectPainter old) =>
      old.color != color ||
          old.radius != radius ||
          old.dashLength != dashLength ||
          old.gapLength != gapLength ||
          old.strokeWidth != strokeWidth;
}