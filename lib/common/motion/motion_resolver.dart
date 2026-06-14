// lib/common/motion/motion_resolver.dart
import 'package:amana_pos/config/enum.dart';

/// Devices with total RAM at or below this (MB) are treated as low-end.
const int kLowEndMemoryThresholdMb = 2048;

/// Resolves a user preference into an effective on/off value.
/// For [AnimationPreference.auto], unknown memory resolves to ON so a good
/// device is never accidentally degraded.
bool resolveAnimationsEnabled(AnimationPreference pref, int? totalMemoryMb) {
  switch (pref) {
    case AnimationPreference.alwaysOn:
      return true;
    case AnimationPreference.alwaysOff:
      return false;
    case AnimationPreference.auto:
      if (totalMemoryMb == null) return true;
      return totalMemoryMb > kLowEndMemoryThresholdMb;
  }
}
