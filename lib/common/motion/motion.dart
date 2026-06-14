// lib/common/motion/motion.dart
import 'package:flutter/foundation.dart';

/// App-wide motion switch. Context-free so it can be read from the static
/// router, flutter_animate call sites, and widgets alike. Owned by ThemeBloc.
class Motion {
  Motion._();

  static final ValueNotifier<bool> animationsEnabled = ValueNotifier<bool>(true);

  static bool get on => animationsEnabled.value;

  static set on(bool value) => animationsEnabled.value = value;

  /// [full] when motion is on, [Duration.zero] when off.
  static Duration duration(Duration full) => on ? full : Duration.zero;
}
