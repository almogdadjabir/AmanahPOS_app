import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _channelId = 'amana_pos_default_channel';
  static const String _channelName = 'AmanaPOS Notifications';
  static const String _channelDescription = 'General AmanaPOS notifications';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('ic_notification');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
      notificationTapBackgroundHandler,
    );

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;

    if (kDebugMode) {
      log('[NotificationService] initialized');
    }
  }

  Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
  }) async {
    try {
      if (!_initialized) {
        await init();
      }

      final id = _buildNotificationId(payload);

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: 'ic_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.show(
        id,
        title,
        body,
        details,
        payload: jsonEncode(payload),
      );

      if (kDebugMode) {
        log('[NotificationService] shown id=$id title=$title payload=$payload');
      }
    } catch (e, s) {
      if (kDebugMode) {
        log('[NotificationService] show failed: $e');
        log('$s');
      }
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      log('[NotificationService] tapped payload=${response.payload}');
    }

    // TODO:
    // Later connect this to your app router/navigation service.
  }

  int _buildNotificationId(Map<String, dynamic> payload) {
    final rawId = payload['notification_id'] ??
        payload['notificationId'] ??
        payload['id'] ??
        payload['entity_id'];

    if (rawId != null) {
      final parsed = int.tryParse(rawId.toString());
      if (parsed != null) return parsed.abs() & 0x7FFFFFFF;

      return rawId.toString().hashCode.abs() & 0x7FFFFFFF;
    }

    return Random().nextInt(0x7FFFFFFF);
  }
}

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse response) {
  if (kDebugMode) {
    log('[NotificationService] background tap payload=${response.payload}');
  }
}