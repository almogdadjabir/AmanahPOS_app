import 'dart:math';

import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

/// The four PIN dots. Filled dots glow emerald — the same gesture as the
/// splash progress beam, now driven by the person typing. Shakes once when an
/// error first appears (mirrors the OTP field), never when clearing.
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

class _PinDotsState extends State<PinDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void didUpdateWidget(PinDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  double get _offset =>
      sin(_shake.value * pi * 5) * 10 * (1 - _shake.value);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_offset, 0), child: child),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.length, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: _Dot(
              filled: i < widget.filledCount,
              hasError: widget.hasError,
              success: widget.success,
            ),
          );
        }),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.filled,
    required this.hasError,
    required this.success,
  });

  final bool filled;
  final bool hasError;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final Color active =
        hasError ? colors.danger : (success ? colors.success : colors.primary);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: filled ? 18 : 14,
      height: filled ? 18 : 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? active : Colors.transparent,
        border: filled
            ? null
            : Border.all(
                color: hasError
                    ? colors.danger.withValues(alpha: 0.6)
                    : colors.border,
                width: 1.5,
              ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: active.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
    );
  }
}
