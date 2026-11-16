import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import 'sync_state_store.dart';

/// Best-effort `POST api/v1/sync/devices/` so the server knows this device
/// (revocation, last-seen, wake-up pushes).
///
/// * only when the server advertises the `devices` capability;
/// * once per distinct (user, tenant, app version, FCM token) signature:
///   first run, after each login as another user/tenant, after an update or
///   a new FCM token; a failure stores nothing, so the next start retries;
/// * never throws, never blocks: callers fire and forget.
///
/// Uses the sync Dio (headers only via `SyncAuthInterceptor`: bearer,
/// X-Tenant-ID, X-Device-ID; no refresh, no logout, no retry).
class SyncDeviceRegistrar {
  SyncDeviceRegistrar({
    required Dio dio,
    required SyncStateStore state,
    required Future<Set<String>> Function() capabilities,
    required Future<String> Function() appVersion,
    required String platform,
    required String name,
    Future<String?> Function()? fcmToken,
    Duration timeout = const Duration(seconds: 15),
  }) : _dio = dio,
       _state = state,
       _capabilities = capabilities,
       _appVersion = appVersion,
       _platform = platform,
       _name = name,
       _fcmToken = fcmToken,
       _timeout = timeout;

  static const String path = 'api/v1/sync/devices/';
  static const String capability = 'devices';

  final Dio _dio;
  final SyncStateStore _state;
  final Future<Set<String>> Function() _capabilities;
  final Future<String> Function() _appVersion;
  final String _platform;
  final String _name;
  final Future<String?> Function()? _fcmToken;
  final Duration _timeout;

  Future<bool>? _inFlight;

  /// Returns true when the device is (now or already) registered under the
  /// current signature. [userKey] identifies the signed-in user + tenant.
  Future<bool> registerIfNeeded({String userKey = ''}) {
    return _inFlight ??= _register(
      userKey,
    ).whenComplete(() => _inFlight = null);
  }

  Future<bool> _register(String userKey) async {
    try {
      final caps = await _capabilities();
      if (!caps.contains(capability)) return false;

      final deviceId = await _state.deviceId();
      final version = await _safe(_appVersion) ?? '';
      final fcm = _fcmToken == null ? null : await _safe(_fcmToken);
      final name = _clip(_name, 120);
      final platform = _clip(_platform, 20);
      final appVersion = _clip(version, 30);

      final signature = sha256
          .convert(
            utf8.encode(
              [
                userKey,
                deviceId,
                name,
                platform,
                appVersion,
                fcm ?? '',
              ].join('|'),
            ),
          )
          .toString();
      if (await _state.deviceRegistration() == signature) return true;

      final res = await _dio.post<dynamic>(
        path,
        data: {
          'device_id': deviceId,
          'name': name,
          'platform': platform,
          'app_version': appVersion,
          if (fcm != null && fcm.isNotEmpty) 'fcm_token': fcm,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      );
      final status = res.statusCode ?? 0;
      if (status < 200 || status >= 300) return false;
      await _state.setDeviceRegistration(signature);
      return true;
    } catch (e, st) {
      // 403 (device of another tenant / revoked), offline, timeout, ...:
      // nothing is stored, the next start tries again.
      developer.log(
        'device registration failed',
        name: 'SyncDeviceRegistrar',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  static Future<String?> _safe(Future<String?> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return null;
    }
  }

  static String _clip(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);
}
