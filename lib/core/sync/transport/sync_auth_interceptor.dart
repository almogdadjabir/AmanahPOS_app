import 'dart:convert';

import 'package:dio/dio.dart';

/// Attaches the same auth headers the app's `AppInterceptors` attaches
/// (Authorization bearer for `api/` paths, X-Tenant-ID, default Accept) plus
/// `X-Device-ID` when a device id is available.
///
/// Deliberately does NOT refresh tokens, retry, log out or navigate: an
/// unreachable server must never end the user's session. All 401s pass through
/// untouched for the transport to classify.
/// Marker carried by the [DioException] the interceptor rejects with when the
/// current session no longer matches the request's scope.
class SyncScopeMismatch implements Exception {
  const SyncScopeMismatch();
}

/// [RequestOptions.extra] key holding the `userId|tenantId` a request was
/// built for.
const String kSyncScopeExtra = 'sync_scope';

class SyncAuthInterceptor extends Interceptor {
  SyncAuthInterceptor({
    required this.readAccessToken,
    required this.readTenantId,
    this.readDeviceId,
    this.readSessionKey,
  });

  final Future<String?> Function() readAccessToken;
  final Future<String?> Function() readTenantId;
  final Future<String?> Function()? readDeviceId;

  /// Current `userId|tenantId` of the signed-in session. When set, a request
  /// carrying a different [kSyncScopeExtra] is refused before it is sent, so
  /// one user's rows can never go out under another user's token.
  final Future<String?> Function()? readSessionKey;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final deviceId = await readDeviceId?.call();
    // Read in this order, and compare before anything else is awaited: the
    // values checked are exactly the ones about to be sent.
    final token = await readAccessToken();
    final tenant = await readTenantId();
    final sessionKey = await readSessionKey?.call();

    final expected = options.extra[kSyncScopeExtra];
    if (expected is String && !_matchesScope(expected, token, tenant)) {
      return _refuse(options, handler);
    }
    if (expected is String &&
        readSessionKey != null &&
        sessionKey != expected) {
      return _refuse(options, handler);
    }

    final requiresAuth =
        options.path.startsWith('api/') || options.path.startsWith('/api/');
    if (token != null && requiresAuth) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    if (tenant != null) {
      options.headers['X-Tenant-ID'] = tenant;
    }
    if (deviceId != null) {
      options.headers['X-Device-ID'] = deviceId;
    }
    final hasAccept = options.headers.keys.any(
      (k) => k.toLowerCase() == 'accept',
    );
    if (!hasAccept) options.headers['Accept'] = 'application/json';
    handler.next(options);
  }

  void _refuse(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
        error: const SyncScopeMismatch(),
      ),
      true,
    );
  }

  /// The credentials about to be sent must belong to [scope]
  /// (`userId|tenantId`): the tenant header equals its tenant part and the
  /// bearer's `user_id` claim (SimpleJWT `USER_ID_CLAIM`, decoded locally
  /// without verification) equals its user part. Anything undecodable fails.
  static bool _matchesScope(String scope, String? token, String? tenant) {
    final i = scope.indexOf('|');
    if (i <= 0 || token == null || tenant == null) return false;
    if (tenant != scope.substring(i + 1)) return false;
    return jwtUserId(token) == scope.substring(0, i);
  }

  /// `user_id` claim of an (unverified) JWT, or null when not decodable.
  static String? jwtUserId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claim = (jsonDecode(payload) as Map)['user_id'];
      return claim?.toString();
    } catch (_) {
      return null;
    }
  }
}
