// test/common/motion/motion_test.dart
import 'package:amana_pos/common/motion/motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => Motion.animationsEnabled.value = true);

  test('on reflects the notifier value', () {
    Motion.animationsEnabled.value = false;
    expect(Motion.on, isFalse);
    Motion.animationsEnabled.value = true;
    expect(Motion.on, isTrue);
  });

  test('duration returns full when on and zero when off', () {
    const full = Duration(milliseconds: 300);
    Motion.animationsEnabled.value = true;
    expect(Motion.duration(full), full);
    Motion.animationsEnabled.value = false;
    expect(Motion.duration(full), Duration.zero);
  });
}
