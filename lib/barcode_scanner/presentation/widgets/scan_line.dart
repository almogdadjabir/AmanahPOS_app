import 'package:flutter/material.dart';

class ScanLine extends StatelessWidget {
  static const double scanHeight = 180;
  static const double horizontalPadding = 30;

  final Animation<double> animation;

  const ScanLine({super.key,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final size = MediaQuery.sizeOf(context);

        final scanWidth = size.width * 0.78;
        final left = (size.width - scanWidth) / 2;
        final top = (size.height - scanHeight) / 2;

        final minY = top + 32;
        final maxY = top + scanHeight - 32;
        final currentY = minY + ((maxY - minY) * animation.value);

        return Positioned(
          left: left + horizontalPadding,
          top: currentY,
          width: scanWidth - (horizontalPadding * 2),
          child: IgnorePointer(
            child: Container(
              height: 3.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(
                  colors: [
                    Colors.greenAccent.withOpacity(0),
                    Colors.greenAccent.withOpacity(1),
                    Colors.greenAccent.withOpacity(0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.75),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
