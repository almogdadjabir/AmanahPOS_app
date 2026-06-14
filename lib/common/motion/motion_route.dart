import 'package:amana_pos/common/motion/motion.dart';
import 'package:flutter/material.dart';

/// A page route that animates normally when motion is on, and is instant
/// (no transition) when animations are disabled. Use for direct
/// `Navigator.push` sites that don't go through AppRouter.
PageRoute<T> motionPageRoute<T>(Widget child, {RouteSettings? settings}) {
  if (!Motion.on) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, _, _, c) => c,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
  return MaterialPageRoute<T>(builder: (_) => child, settings: settings);
}
