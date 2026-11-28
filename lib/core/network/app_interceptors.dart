import 'dart:async';
import 'dart:convert';

import 'package:amana_pos/core/network/multipart_file_extended.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/config/router/route_strings.dart';
import 'package:amana_pos/features/pin/data/biometric_unlock_service.dart';
import 'package:amana_pos/features/pin/data/pin_vault_service.dart';
import 'package:amana_pos/l10n/app_localizations.dart';
import 'package:amana_pos/utilities/global_snackbar.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppInterceptors extends Interceptor {
  final Dio _dio;
  final CacheStorage _cacheStorage = getIt<CacheStorage>();
  static Future<bool>? _refreshTokenFuture;
  static bool isLoggingOut = false;
  static const String _sessionExpiredSentinel = '__session_expired__';
  static const String _refreshPath = 'api-public/v1/auth/token/refresh/';
  static bool _lastRefreshRejected = false;
  static DioException? _lastRefreshError;
  static const _refreshBackoff = [
    Duration(milliseconds: 500),
    Duration(milliseconds: 1500),
    Duration(seconds: 3),
  ];
  static const _proactiveWindow = Duration(minutes: 2);

  /// Test hook: zero backoff.
  @visibleForTesting
  static List<Duration> backoffOverride = _refreshBackoff;
  static int _logoutEpoch = 0;

  AppInterceptors(this._dio);

  static Future<bool>? get refreshInFlight => _refreshTokenFuture;

  /// The existing forced-logout path (tokens, PIN and Face ID cleared;
  /// offline data and unsent sales KEPT; navigate to login). Exposed for the
  /// sync session guard (flag-gated); existing callers are unchanged.
  static Future<void> forceLogout() =>
      AppInterceptors(getIt<Dio>())._triggerForcedLogout();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_shouldRefreshProactively(options)) {
      await _refreshIfExpiring();
    }
    await _addHeaders(options);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // The refresh call itself runs through this same Dio: its 401 is the
    // rejection signal for _refreshMainToken, never a trigger to refresh
    // again (that would await its own in-flight future forever).
    if (err.requestOptions.path.contains('auth/token/refresh')) {
      handler.next(err);
      return;
    }

    // Tokens are wiped during logout. If a new session has stored a refresh
    // token since, this 401 is legitimate and must be allowed to refresh.
    if (isLoggingOut && !await _hasRefreshToken()) {
      handler.reject(_makeExpiredError(err.requestOptions));
      return;
    }

    await _handleUnauthorizedError(err, handler);
  }

  Future<void> _addHeaders(RequestOptions options) async {
    final authToken = await _cacheStorage.getValue(Constants.authToken);
    final xTenantID = await _cacheStorage.getValue(Constants.xTenantID);

    final requiresAuth =
        options.path.startsWith('api/') || options.path.startsWith('/api/');

    if (authToken != null && requiresAuth) {
      options.headers['Authorization'] = 'Bearer $authToken';
    }

    if (xTenantID != null) {
      options.headers['X-Tenant-ID'] = xTenantID;
    }

    final hasAccept = options.headers.keys.any(
      (k) => k.toString().toLowerCase() == 'accept',
    );
    if (!hasAccept) options.headers['Accept'] = 'application/json';
  }

  Future<void> _handleUnauthorizedError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    _refreshTokenFuture ??= _refreshMainToken();

    bool refreshSucceeded;
    try {
      refreshSucceeded = await _refreshTokenFuture!;
    } catch (e) {
      refreshSucceeded = false;
      if (kDebugMode) debugPrint('[AppInterceptors] refresh threw: $e');
    } finally {
      // Always null out — even on exception — so the next 401 gets a fresh attempt.
      _refreshTokenFuture = null;
    }

    if (!refreshSucceeded) {
      if (_lastRefreshRejected) {
        await _triggerForcedLogout();
        handler.reject(_makeExpiredError(err.requestOptions));
      } else {
        // Network error, timeout, 5xx, 429 or malformed reply: the session
        // is not proven dead. Keep tokens; fail only this request with a
        // network-style error so the UI offers retry, not the login screen.
        final cause = _lastRefreshError;
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            type: cause != null && cause.response == null
                ? cause.type
                : DioExceptionType.connectionError,
            error: cause?.error ?? 'Could not refresh session (transient)',
            message: 'Session refresh failed transiently',
          ),
        );
      }
      return;
    }

    final opts = err.requestOptions;
    final freshToken = await _cacheStorage.getValue(Constants.authToken);
    opts.headers['Authorization'] = 'Bearer $freshToken';

    // Restore FormData from backup if needed (multipart retry).
    final backup = opts.extra['__formDataBackup'];
    if (backup is List<Map<String, dynamic>>) {
      opts.data = _rebuildFormData(backup);
    }

    try {
      final response = await _dio.request<dynamic>(
        opts.path,
        data: opts.data,
        queryParameters: opts.queryParameters,
        options: Options(
          method: opts.method,
          headers: opts.headers,
          responseType: opts.responseType,
        ),
      );
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.reject(retryErr);
    }
  }

  Future<bool> _refreshMainToken() async {
    _lastRefreshRejected = false;
    _lastRefreshError = null;
    final refreshToken = await _readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      // No refresh token at all: there is no session left to keep.
      _lastRefreshRejected = true;
      return false;
    }

    final delays = backoffOverride;
    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        final response = await _dio.post<dynamic>(
          _refreshPath,
          data: {'refresh': refreshToken},
          options: Options(headers: {'Accept': 'application/json'}),
        );

        final data = response.data;
        final newAccess = data is Map ? data['access'] as String? : null;
        final newRefresh = data is Map ? data['refresh'] as String? : null;
        if (response.statusCode != 200 ||
            newAccess == null ||
            newAccess.isEmpty) {
          // Odd 2xx/3xx or malformed body: not proof the session is dead.
          if (attempt < delays.length) {
            await Future<void>.delayed(delays[attempt]);
            continue;
          }
          return false;
        }

        // Replaying an old refresh within the grace window is idempotent
        // server-side, so retrying after a lost response is safe.
        await Future.wait([
          _cacheStorage.save(Constants.authToken, newAccess),
          if (newRefresh != null && newRefresh.isNotEmpty)
            _cacheStorage.save(Constants.refreshToken, newRefresh),
        ]);
        if (newRefresh != null && newRefresh.isNotEmpty) {
          try {
            await getIt<PinVaultService>().updateTokens(
              oldRefresh: refreshToken,
              access: newAccess,
              refresh: newRefresh,
            );
          } catch (_) {}
        }
        return true;
      } on DioException catch (e) {
        if (_isExplicitRejection(e)) {
          // Rotation + blacklist: our token may be refused only because
          // another party (the sync refresher) already rotated the pair.
          final now = await _cacheStorage.getValue(Constants.refreshToken);
          if (now != null && now.isNotEmpty && now != refreshToken) {
            return true;
          }
          _lastRefreshRejected = true;
          return false;
        }
        _lastRefreshError = e;
        if (kDebugMode) {
          debugPrint(
            '[AppInterceptors] refresh transient: ${e.type.name} '
            '${e.response?.statusCode ?? ''}',
          );
        }
        if (attempt < delays.length) {
          await Future<void>.delayed(delays[attempt]);
          continue;
        }
        return false;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[AppInterceptors] refresh error: ${e.runtimeType}');
        }
        return false;
      }
    }
    return false;
  }

  Future<String?> _readRefreshToken() async {
    var t = await _cacheStorage.getValue(Constants.refreshToken);
    if (t == null || t.isEmpty) {
      // A transient secure-storage miss must not read as "logged out".
      await Future<void>.delayed(const Duration(milliseconds: 150));
      t = await _cacheStorage.getValue(Constants.refreshToken);
    }
    return t;
  }

  Future<bool> _hasRefreshToken() async {
    final t = await _cacheStorage.getValue(Constants.refreshToken);
    return t != null && t.isNotEmpty;
  }

  bool _shouldRefreshProactively(RequestOptions options) {
    if (options.path.contains('auth/token/refresh')) return false;
    return options.path.startsWith('api/') || options.path.startsWith('/api/');
  }

  /// Decodes the `exp` claim (no signature check). Null if unreadable.
  @visibleForTesting
  static DateTime? tokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final json = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = json is Map ? json['exp'] : null;
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    } catch (_) {
      return null;
    }
  }

  /// Single-flight refresh when the access token expires within 2 minutes.
  /// Failure here is ignored: the request goes out and the 401 path decides.
  Future<void> _refreshIfExpiring() async {
    if (_refreshTokenFuture == null) {
      final token = await _cacheStorage.getValue(Constants.authToken);
      if (token == null) return;
      final exp = tokenExpiry(token);
      if (exp == null || exp.difference(DateTime.now()) > _proactiveWindow) {
        return;
      }
    }
    final own = _refreshTokenFuture == null;
    _refreshTokenFuture ??= _refreshMainToken();
    final f = _refreshTokenFuture!;
    try {
      final ok = await f;
      if (!ok && own && _lastRefreshRejected) {
        await _triggerForcedLogout();
      }
    } catch (_) {
    } finally {
      if (identical(_refreshTokenFuture, f)) _refreshTokenFuture = null;
    }
  }

  /// Call on AppLifecycleState.resumed.
  static Future<void> refreshIfExpiring() =>
      AppInterceptors(getIt<Dio>())._refreshIfExpiring();

  /// HTTP 401, or 400 with `token_not_valid`, from the refresh endpoint.
  static bool _isExplicitRejection(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return true;
    // Backend contract: 400/401 from the refresh endpoint = dead token.
    return status == 400;
  }

  Future<void> _triggerForcedLogout() async {
    if (isLoggingOut) return;
    isLoggingOut = true;
    final epoch = ++_logoutEpoch;

    try {
      await _cacheStorage.resetTokens();

      // The session is dead, so a PIN or Face ID would unlock into nothing.
      // Offline data (including unsent sales) is kept: signing in as the same
      // user picks it back up, and the login flow wipes it only for another
      // business.
      try {
        await getIt<PinVaultService>().clearVault();
        await getIt<BiometricUnlockService>().disable();
      } catch (_) {}

      await _navigateToLoginSafely();
    } catch (e) {
      if (kDebugMode)
        debugPrint('[AppInterceptors] _triggerForcedLogout error: $e');
    } finally {
      Future.delayed(const Duration(seconds: 4), () {
        if (epoch == _logoutEpoch) isLoggingOut = false;
        if (kDebugMode) debugPrint('[AppInterceptors] isLoggingOut reset');
      });
    }
  }

  Future<void> _navigateToLoginSafely() async {
    for (int attempt = 0; attempt < 5; attempt++) {
      final navigator = Constants.navigatorKey.currentState;

      if (navigator != null && navigator.mounted) {
        try {
          navigator.pushNamedAndRemoveUntil(RouteStrings.login, (_) => false);
          final context = Constants.navigatorKey.currentContext;
          if (context != null) {
            final tr = AppLocalizations.of(context);
            if (tr != null) {
              GlobalSnackBar.showInfo(message: tr.sessionEndedSignInAgain);
            }
          }
          return;
        } catch (e) {
          if (kDebugMode)
            debugPrint(
              '[AppInterceptors] navigation attempt ${attempt + 1} threw: $e',
            );
        }
      }

      if (kDebugMode) {
        debugPrint(
          '[AppInterceptors] navigator not ready (attempt ${attempt + 1}/5), retrying...',
        );
      }

      await Future.delayed(Duration(milliseconds: 100 * (1 << attempt)));
    }

    if (kDebugMode)
      debugPrint(
        '[AppInterceptors] all navigation attempts failed — app restart needed',
      );
  }

  static bool isSessionExpiredError(DioException e) =>
      e.type == DioExceptionType.cancel && e.error == _sessionExpiredSentinel;

  DioException _makeExpiredError(RequestOptions opts) => DioException(
    requestOptions: opts,
    type: DioExceptionType.cancel,
    error: _sessionExpiredSentinel,
  );

  FormData _rebuildFormData(List<Map<String, dynamic>> backup) {
    final formData = FormData();

    for (final item in backup) {
      if (item['type'] == 'field') {
        formData.fields.add(
          MapEntry(item['name'] as String, item['value'] as String),
        );
        continue;
      }

      if (item['type'] == 'file') {
        final filename = item['filename'] as String?;
        final ctString = item['contentType'] as String?;
        final contentType = ctString != null
            ? DioMediaType.parse(ctString)
            : null;
        final filePath = item['filePath'] as String?;
        final bytes = item['bytes'] as List<int>?;

        final multipart = filePath != null
            ? ExtendedMultipartFile.fromFileSync(
                filePath,
                filename: filename,
                contentType: contentType,
              )
            : bytes != null
            ? ExtendedMultipartFile.fromBytesSync(
                bytes,
                filename: filename,
                contentType: contentType,
              )
            : throw StateError('File backup missing both filePath and bytes');

        formData.files.add(MapEntry(item['name'] as String, multipart));
      }
    }

    return formData;
  }
}
