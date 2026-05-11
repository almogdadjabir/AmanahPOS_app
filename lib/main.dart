import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:amana_pos/app.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/common/services/notifications/fcm_token_service.dart';
import 'package:amana_pos/common/services/notifications/notification_service.dart';
import 'package:amana_pos/firebase_options.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    log('[FCM][background] messageId=${message.messageId}');
    log('[FCM][background] notification=${message.notification?.title}');
    log('[FCM][background] data=${message.data}');
  }

  // Do not show local notification here if your FCM contains "notification".
  // Android/iOS will show it automatically in background/terminated mode.
  //
  // Only show local notification here if your backend sends data-only messages.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  CacheStorage.preloadPrefs(prefs);

  DependenciesProvider.build();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await NotificationService.instance.init();

  runApp(const App());

  unawaited(_initializeFirebaseMessaging());
}

Future<void> _initializeFirebaseMessaging() async {
  try {
    await _requestNotificationPermission();

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final fcmService = DependenciesProvider.provide<FcmTokenService>();
    await fcmService.initialize();

    FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          log('[FCM][foreground] listener error: $error');
        }
      },
    );

    FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTap,
      onError: (Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          log('[FCM][tap] listener error: $error');
        }
      },
    );

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  } catch (e, s) {
    if (kDebugMode) {
      log('[FCM] initialization failed: $e');
      log('$s');
    }
  }
}

Future<void> _requestNotificationPermission() async {
  try {
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (kDebugMode) {
        log('[FCM] iOS permission=${settings.authorizationStatus}');
      }

      return;
    }

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;

      if (status.isDenied || status.isRestricted || status.isLimited) {
        final result = await Permission.notification.request();

        if (kDebugMode) {
          log('[FCM] Android notification permission=$result');
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      log('[FCM] permission request failed: $e');
    }
  }
}

Future<void> _handleForegroundMessage(RemoteMessage message) async {
  if (kDebugMode) {
    log('[FCM][foreground] messageId=${message.messageId}');
    log('[FCM][foreground] title=${message.notification?.title}');
    log('[FCM][foreground] body=${message.notification?.body}');
    log('[FCM][foreground] data=${message.data}');
  }

  final title = _resolveNotificationTitle(message);
  final body = _resolveNotificationBody(message);

  if (title == null || body == null) {
    if (kDebugMode) {
      log('[FCM][foreground] skipped because title/body is missing');
    }
    return;
  }

  await NotificationService.instance.show(
    title: title,
    body: body,
    payload: message.data,
  );
}

void _handleNotificationTap(RemoteMessage message) {
  if (kDebugMode) {
    log('[FCM][tap] messageId=${message.messageId}');
    log('[FCM][tap] data=${message.data}');
  }

  // TODO:
  // Navigate based on message.data when routes are ready.
  // Example data:
  // {
  //   "type": "low_stock",
  //   "business_id": "...",
  //   "shop_id": "...",
  //   "entity_id": "..."
  // }
}

String? _resolveNotificationTitle(RemoteMessage message) {
  final notificationTitle = message.notification?.title;
  if (notificationTitle != null && notificationTitle.trim().isNotEmpty) {
    return notificationTitle.trim();
  }

  final dataTitle = message.data['title']?.toString();
  if (dataTitle != null && dataTitle.trim().isNotEmpty) {
    return dataTitle.trim();
  }

  return null;
}

String? _resolveNotificationBody(RemoteMessage message) {
  final notificationBody = message.notification?.body;
  if (notificationBody != null && notificationBody.trim().isNotEmpty) {
    return notificationBody.trim();
  }

  final dataBody = message.data['body']?.toString();
  if (dataBody != null && dataBody.trim().isNotEmpty) {
    return dataBody.trim();
  }

  return null;
}