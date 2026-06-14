// test/common/theme_bloc/theme_bloc_animations_test.dart
import 'package:amana_pos/common/motion/device_memory_probe.dart';
import 'package:amana_pos/common/motion/motion.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/common/theme_bloc/theme_bloc.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/config/enum.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCacheStorage extends Mock implements CacheStorage {}

class _FakeMemoryProbe implements DeviceMemoryProbe {
  _FakeMemoryProbe(this.value);
  final int? value;
  @override
  Future<int?> totalMemoryMb() async => value;
}

void main() {
  late _MockCacheStorage cache;

  setUp(() {
    cache = _MockCacheStorage();
    // Defaults so the constructor's _loadAccessibilitySettings resolves cleanly.
    when(() => cache.getBool(any())).thenAnswer((_) async => false);
    when(() => cache.getValue(any())).thenAnswer((_) async => null);
    when(() => cache.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => cache.save(any(), any())).thenAnswer((_) async => true);
    Motion.animationsEnabled.value = true;
  });

  ThemeBloc build({int? memMb = 4096}) => ThemeBloc(
        cacheStorage: cache,
        memoryProbe: _FakeMemoryProbe(memMb),
      );

  group('OnAnimationsPreferenceChanged', () {
    blocTest<ThemeBloc, ThemeState>(
      'alwaysOff disables animations and persists',
      build: () => build(),
      act: (bloc) =>
          bloc.add(const OnAnimationsPreferenceChanged(AnimationPreference.alwaysOff)),
      wait: const Duration(milliseconds: 10),
      verify: (_) {
        verify(() => cache.save(Constants.animationPreference, 'alwaysOff')).called(1);
        expect(Motion.on, isFalse);
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'auto on a 1 GB device resolves to off',
      build: () => build(memMb: 1024),
      act: (bloc) =>
          bloc.add(const OnAnimationsPreferenceChanged(AnimationPreference.auto)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.animationsEnabled, isFalse);
        expect(Motion.on, isFalse);
      },
    );

    blocTest<ThemeBloc, ThemeState>(
      'auto on a 4 GB device resolves to on',
      build: () => build(memMb: 4096),
      act: (bloc) =>
          bloc.add(const OnAnimationsPreferenceChanged(AnimationPreference.auto)),
      wait: const Duration(milliseconds: 10),
      verify: (bloc) {
        expect(bloc.state.animationsEnabled, isTrue);
        expect(Motion.on, isTrue);
      },
    );
  });
}
