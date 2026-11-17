import 'dart:io';

import 'package:amana_pos/common/services/notifications/notification_permission.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fake implements NotificationPermissionGateway {
  _Fake({
    this.supported = true,
    this.ios = false,
    this.denied = true,
    this.boom = false,
  });
  final bool supported, ios, denied, boom;
  int iosCalls = 0, androidCalls = 0;
  @override
  bool get isSupported => supported;
  @override
  bool get isIOS => ios;
  @override
  Future<void> requestIos() async {
    iosCalls++;
    if (boom) throw StateError('x');
  }

  @override
  Future<bool> androidIsDenied() async => denied;
  @override
  Future<void> requestAndroid() async {
    androidCalls++;
    if (boom) throw StateError('x');
  }
}

void main() {
  setUp(resetNotificationPermissionAskedForTest);

  test('iOS: asks once, a second call is a no-op', () async {
    final g = _Fake(ios: true);
    await requestNotificationPermissionInContext(gateway: g);
    await requestNotificationPermissionInContext(gateway: g);
    expect(g.iosCalls, 1);
  });

  test('Android: asks only when denied', () async {
    final denied = _Fake(denied: true);
    await requestNotificationPermissionInContext(gateway: denied);
    expect(denied.androidCalls, 1);
    resetNotificationPermissionAskedForTest();
    final granted = _Fake(denied: false);
    await requestNotificationPermissionInContext(gateway: granted);
    expect(granted.androidCalls, 0);
  });

  test('unsupported platform: never asks', () async {
    final g = _Fake(supported: false, ios: true);
    await requestNotificationPermissionInContext(gateway: g);
    expect(g.iosCalls + g.androidCalls, 0);
  });

  test('a throwing platform call never escapes', () async {
    await requestNotificationPermissionInContext(
      gateway: _Fake(ios: true, boom: true),
    );
    resetNotificationPermissionAskedForTest();
    await requestNotificationPermissionInContext(gateway: _Fake(boom: true));
  });

  group('wiring guards (the move out of main.dart must not lose anything)', () {
    final main = File('lib/main.dart').readAsStringSync();
    test('main.dart no longer asks for permission at startup', () {
      expect(main.contains('requestPermission('), isFalse);
      expect(main.contains('Permission.notification'), isFalse);
    });
    test('main.dart still wires every FCM piece', () {
      for (final needle in [
        'FirebaseMessaging.onBackgroundMessage(',
        'NotificationService.instance.init()',
        'fcmService.initialize()',
        'setForegroundNotificationPresentationOptions(',
        'FirebaseMessaging.onMessage.listen(',
        'FirebaseMessaging.onMessageOpenedApp.listen(',
        'getInitialMessage()',
      ]) {
        expect(main.contains(needle), isTrue, reason: 'missing $needle');
      }
    });
    test('the main screen asks after sign-in', () {
      final s = File(
        'lib/features/main_screen/presentation/main_screen.dart',
      ).readAsStringSync();
      expect(s.contains('requestNotificationPermissionInContext'), isTrue);
    });
    test('release builds never default to a LAN address', () {
      final e = File(
        'lib/config/environment/environment.dart',
      ).readAsStringSync();
      expect(e.contains('!kDebugMode) return prodBaseURL'), isTrue);
    });
    test('login sends the real platform', () {
      final s = File(
        'lib/features/login/presentation/bloc/login_bloc.dart',
      ).readAsStringSync();
      expect(s.contains("platform: 'android'"), isFalse);
    });
  });
}
