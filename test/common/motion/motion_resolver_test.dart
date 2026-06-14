// test/common/motion/motion_resolver_test.dart
import 'package:amana_pos/common/motion/motion_resolver.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveAnimationsEnabled', () {
    test('alwaysOn -> true regardless of memory', () {
      expect(resolveAnimationsEnabled(AnimationPreference.alwaysOn, 512), isTrue);
    });

    test('alwaysOff -> false regardless of memory', () {
      expect(resolveAnimationsEnabled(AnimationPreference.alwaysOff, 8192), isFalse);
    });

    test('auto -> off at or below 2 GB threshold', () {
      expect(resolveAnimationsEnabled(AnimationPreference.auto, 1024), isFalse);
      expect(resolveAnimationsEnabled(AnimationPreference.auto, 2048), isFalse);
    });

    test('auto -> on above 2 GB threshold', () {
      expect(resolveAnimationsEnabled(AnimationPreference.auto, 3072), isTrue);
    });

    test('auto with unknown memory -> on (conservative)', () {
      expect(resolveAnimationsEnabled(AnimationPreference.auto, null), isTrue);
    });
  });
}
