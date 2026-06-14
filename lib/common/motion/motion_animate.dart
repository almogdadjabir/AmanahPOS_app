// lib/common/motion/motion_animate.dart
import 'package:amana_pos/common/motion/motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension MotionAnimate on Widget {
  /// Drop-in for [Widget.animate]. When motion is off, renders the effect
  /// chain at its end state instantly (no autoplay, value pinned to 1.0,
  /// and onPlay/target suppressed to prevent assertion failures and
  /// unintended animateTo calls) so entrance effects (fadeIn/slideY/etc.)
  /// show the final appearance without running.
  Animate mAnimate({
    Key? key,
    List<Effect>? effects,
    AnimateCallback? onInit,
    AnimateCallback? onPlay,
    AnimateCallback? onComplete,
    bool? autoPlay,
    Duration? delay,
    AnimationController? controller,
    Adapter? adapter,
    double? target,
    double? value,
  }) {
    final motionOff = !Motion.on;
    return animate(
      key: key,
      effects: effects,
      onInit: onInit,
      onPlay: motionOff ? null : onPlay,
      onComplete: onComplete,
      autoPlay: motionOff ? false : autoPlay,
      delay: delay,
      controller: controller,
      adapter: adapter,
      target: motionOff ? null : target,
      value: motionOff ? 1.0 : value,
    );
  }
}
