import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class NotificationPermissionGateway {
  bool get isSupported;
  bool get isIOS;
  Future<void> requestIos();
  Future<bool> androidIsDenied();
  Future<void> requestAndroid();
}

class _RealGateway implements NotificationPermissionGateway {
  @override
  bool get isSupported => !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  @override
  bool get isIOS => Platform.isIOS;
  @override
  Future<void> requestIos() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @override
  Future<bool> androidIsDenied() async =>
      (await Permission.notification.status).isDenied;
  @override
  Future<void> requestAndroid() async {
    await Permission.notification.request();
  }
}

bool _asked = false;

@visibleForTesting
void resetNotificationPermissionAskedForTest() => _asked = false;

Future<void> requestNotificationPermissionInContext({
  NotificationPermissionGateway? gateway,
}) async {
  final g = gateway ?? _RealGateway();
  if (_asked || !g.isSupported) return;
  _asked = true;
  try {
    if (g.isIOS) {
      await g.requestIos();
    } else if (await g.androidIsDenied()) {
      await g.requestAndroid();
    }
  } catch (e) {
    if (kDebugMode) log('[FCM] permission request failed: $e');
  }
}
