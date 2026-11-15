import 'dart:math';

import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The four passcode dots: rings that fill as digits are typed, red with a
/// shake on a wrong PIN, brand colour on success. Always left to right.
class PinDots extends StatefulWidget {
  const PinDots({
    super.key,
    required this.filledCount,
    this.length = 4,
    this.hasError = false,
    this.success = false,
  });

  final int filledCount;
  final int length;
  final bool hasError;
  final bool success;

  @override
  State<PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<PinDots> with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(PinDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      HapticFeedback.heavyImpact();
      if (Motion.on) _shake.forward(from: 0);
    }
    if (widget.success && !oldWidget.success) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  double get _offset => sin(_shake.value * pi * 5) * 8 * (1 - _shake.value);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fill = widget.hasError
        ? colors.danger
        : widget.success
        ? colors.primary
        : colors.textPrimary;
    final ring = widget.hasError
        ? colors.danger
        : widget.success
        ? colors.primary
        : colors.textSecondary;

    return Semantics(
      label: '${widget.filledCount}/${widget.length}',
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, child) =>
              Transform.translate(offset: Offset(_offset, 0), child: child),
          child: SizedBox(
            height: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.length; i++) ...[
                  if (i > 0) const SizedBox(width: 22),
                  _Dot(
                    filled:
                        widget.hasError ||
                        widget.success ||
                        i < widget.filledCount,
                    fill: fill,
                    ring: ring,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled, required this.fill, required this.ring});

  final bool filled;
  final Color fill;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: filled ? 1.08 : 1,
      duration: Motion.duration(const Duration(milliseconds: 120)),
      child: AnimatedContainer(
        duration: Motion.duration(const Duration(milliseconds: 120)),
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? fill : Colors.transparent,
          border: Border.all(color: filled ? fill : ring, width: 1.5),
        ),
      ),
    );
  }
}
