import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared press feel: scale to 0.97 over 120ms, subtle dim, no ripple.
/// Replaces bare InkWell / GestureDetector on tappable cards, rows and tiles.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final HitTestBehavior behavior;
  final String? semanticLabel;

  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.scale = AppDims.pressScale,
    this.haptic = false,
    this.behavior = HitTestBehavior.opaque,
    this.semanticLabel,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _set(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final duration = Motion.duration(AppDims.fast);

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap == null ? null : _handleTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _pressed ? widget.scale : 1,
          duration: duration,
          curve: AppDims.ease,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.88 : 1,
            duration: duration,
            curve: AppDims.ease,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
