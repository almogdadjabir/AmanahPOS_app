import 'dart:math' as math;

import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

class AmanaPosLogoMark extends StatelessWidget {
  const AmanaPosLogoMark({
    super.key,
    this.size = 36.0,
    this.isInAppBar = false,
  });

  final double size;
  final bool isInAppBar;

  static const Color _emerald = Color(0xFF0E5A48);
  static const Color _emeraldLight = Color(0xFF127558);
  static const Color _emeraldDark = Color(0xFF073126);
  static const Color _ivory = Color(0xFFF6F1E6);

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 56 / 256),
          boxShadow: isInAppBar
              ? null
              : [
            BoxShadow(
              color: _emerald.withValues(alpha: 0.22),
              blurRadius: size * 0.42,
              offset: Offset(0, size * 0.18),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: size * 0.24,
              offset: Offset(0, size * 0.10),
            ),
          ],
        ),
        child: CustomPaint(
          painter: const _AmanaPosLogoMarkPainter(
            emerald: _emerald,
            emeraldLight: _emeraldLight,
            emeraldDark: _emeraldDark,
            ivory: _ivory,
            drawBackground: true,
          ),
        ),
      ),
    );
  }
}

class AmanaPosLogo extends StatelessWidget {
  const AmanaPosLogo({
    super.key,
    this.markSize = 36.0,
    this.showArabicName = true,
    this.showSeparator = true,
    this.showLatinName = true,
  });

  final double markSize;
  final bool showArabicName;
  final bool showSeparator;
  final bool showLatinName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final gap = markSize * 12 / 36;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AmanaPosLogoMark(size: markSize),
        if (showArabicName) ...[
          SizedBox(width: gap),
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
        ],
        if (showSeparator) ...[
          SizedBox(width: gap),
          SizedBox(
            width: 1,
            height: markSize * 0.72,
            child: ColoredBox(
              color: colors.border,
            ),
          ),
        ],
        if (showLatinName) ...[
          SizedBox(width: gap),
          Text(
            'AmanaPOS',
            style: AppTextStyles.sm200(
              context,
              color: colors.textHint,
            ).copyWith(
              fontSize: markSize * 10 / 36,
              fontWeight: FontWeight.w700,
              letterSpacing: markSize * 10 / 36 * 0.20,
              height: 1,
            ),
          ),
        ],
      ],
    );
  }
}

class AmanaPosLogoMarkOnly extends StatelessWidget {
  const AmanaPosLogoMarkOnly({
    super.key,
    this.size = 36,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final markColor = color ?? context.appColors.primary;

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _AmanaPosLogoMarkPainter(
          emerald: markColor,
          emeraldLight: markColor,
          emeraldDark: markColor,
          ivory: markColor,
          drawBackground: false,
        ),
      ),
    );
  }
}

class _AmanaPosLogoMarkPainter extends CustomPainter {
  const _AmanaPosLogoMarkPainter({
    required this.emerald,
    required this.emeraldLight,
    required this.emeraldDark,
    required this.ivory,
    required this.drawBackground,
  });

  final Color emerald;
  final Color emeraldLight;
  final Color emeraldDark;
  final Color ivory;
  final bool drawBackground;

  static const double _viewBox = 256;

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = math.min(size.width, size.height);
    final dx = (size.width - shortestSide) / 2;
    final dy = (size.height - shortestSide) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(shortestSide / _viewBox);

    if (drawBackground) {
      _drawAppIconBackground(canvas);
      _drawIvoryLogo(canvas);
    } else {
      _drawMonoMark(canvas);
    }

    canvas.restore();
  }

  void _drawAppIconBackground(Canvas canvas) {
    final bgRect = const Rect.fromLTWH(0, 0, 256, 256);
    final bgRRect = RRect.fromRectAndRadius(
      bgRect,
      const Radius.circular(56),
    );

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          emeraldLight,
          emeraldDark,
        ],
      ).createShader(bgRect);

    canvas.drawRRect(bgRRect, bgPaint);
  }

  void _drawIvoryLogo(Canvas canvas) {
    _drawOuterBorder(canvas, ivory.withValues(alpha: 1.0));
    _drawStitchedBorders(canvas, ivory.withValues(alpha: 0.55));
    _drawStem(canvas, ivory);
    _drawCircle(canvas, ivory);
  }

  void _drawMonoMark(Canvas canvas) {
    _drawOuterBorder(canvas, emerald.withValues(alpha: 1.0));
    _drawStitchedBorders(canvas, emerald.withValues(alpha: 0.42));
    _drawStem(canvas, emerald);
    _drawCircle(canvas, emerald);
  }

  void _drawOuterBorder(Canvas canvas, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(1.25, 1.25, 253.5, 253.5),
      const Radius.circular(56),
    );

    canvas.drawRRect(rrect, paint);
  }

  void _drawStitchedBorders(Canvas canvas, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final first = RRect.fromRectAndRadius(
      const Rect.fromLTWH(14, 14, 228, 228),
      const Radius.circular(44),
    );

    final second = RRect.fromRectAndRadius(
      const Rect.fromLTWH(22, 22, 212, 212),
      const Radius.circular(38),
    );

    _drawDashedRRect(
      canvas: canvas,
      rrect: first,
      paint: paint,
      dashLength: 2,
      gapLength: 4,
    );

    _drawDashedRRect(
      canvas: canvas,
      rrect: second,
      paint: paint,
      dashLength: 2,
      gapLength: 4,
    );
  }

  void _drawStem(Canvas canvas, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(116, 88, 24, 120),
      const Radius.circular(12),
    );

    canvas.drawRRect(rrect, paint);
  }

  void _drawCircle(Canvas canvas, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      const Offset(128, 58),
      18,
      paint,
    );
  }

  void _drawDashedRRect({
    required Canvas canvas,
    required RRect rrect,
    required Paint paint,
    required double dashLength,
    required double gapLength,
  }) {
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;

      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        final dashPath = metric.extractPath(distance, end);
        canvas.drawPath(dashPath, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AmanaPosLogoMarkPainter oldDelegate) {
    return oldDelegate.emerald != emerald ||
        oldDelegate.emeraldLight != emeraldLight ||
        oldDelegate.emeraldDark != emeraldDark ||
        oldDelegate.ivory != ivory ||
        oldDelegate.drawBackground != drawBackground;
  }
}