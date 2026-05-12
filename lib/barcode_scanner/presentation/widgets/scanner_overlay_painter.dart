import 'package:flutter/material.dart';

class ScannerOverlayPainter extends CustomPainter {
  static const double scanHeight = 180;
  static const double borderRadius = 30;
  static const double cornerLength = 34;
  static const double cornerStroke = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final scanWidth = size.width * 0.78;
    final left = (size.width - scanWidth) / 2;
    final top = (size.height - scanHeight) / 2;

    final rect = Rect.fromLTWH(left, top, scanWidth, scanHeight);

    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(borderRadius),
    );

    final overlayPath = Path()
      ..addRect(Offset.zero & size);

    final cutoutPath = Path()
      ..addRRect(rrect);

    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.62)
      ..style = PaintingStyle.fill;

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        overlayPath,
        cutoutPath,
      ),
      overlayPaint,
    );

    final softBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(rrect, softBorderPaint);

    final glowPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.16)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawRRect(rrect, glowPaint);

    final cornerPaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = cornerStroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawTopLeftCorner(canvas, rect, cornerPaint);
    _drawTopRightCorner(canvas, rect, cornerPaint);
    _drawBottomLeftCorner(canvas, rect, cornerPaint);
    _drawBottomRightCorner(canvas, rect, cornerPaint);
  }

  void _drawTopLeftCorner(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()
      ..moveTo(rect.left, rect.top + borderRadius + cornerLength)
      ..lineTo(rect.left, rect.top + borderRadius)
      ..quadraticBezierTo(
        rect.left,
        rect.top,
        rect.left + borderRadius,
        rect.top,
      )
      ..lineTo(rect.left + borderRadius + cornerLength, rect.top);

    canvas.drawPath(path, paint);
  }

  void _drawTopRightCorner(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()
      ..moveTo(rect.right - borderRadius - cornerLength, rect.top)
      ..lineTo(rect.right - borderRadius, rect.top)
      ..quadraticBezierTo(
        rect.right,
        rect.top,
        rect.right,
        rect.top + borderRadius,
      )
      ..lineTo(rect.right, rect.top + borderRadius + cornerLength);

    canvas.drawPath(path, paint);
  }

  void _drawBottomLeftCorner(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()
      ..moveTo(rect.left + borderRadius + cornerLength, rect.bottom)
      ..lineTo(rect.left + borderRadius, rect.bottom)
      ..quadraticBezierTo(
        rect.left,
        rect.bottom,
        rect.left,
        rect.bottom - borderRadius,
      )
      ..lineTo(rect.left, rect.bottom - borderRadius - cornerLength);

    canvas.drawPath(path, paint);
  }

  void _drawBottomRightCorner(Canvas canvas, Rect rect, Paint paint) {
    final path = Path()
      ..moveTo(rect.right, rect.bottom - borderRadius - cornerLength)
      ..lineTo(rect.right, rect.bottom - borderRadius)
      ..quadraticBezierTo(
        rect.right,
        rect.bottom,
        rect.right - borderRadius,
        rect.bottom,
      )
      ..lineTo(rect.right - borderRadius - cornerLength, rect.bottom);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
