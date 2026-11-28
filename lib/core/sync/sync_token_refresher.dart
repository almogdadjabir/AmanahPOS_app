import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../common/services/local/local_storage.dart';
import '../../config/constants.dart';
import '../../features/pin/data/pin_vault_service.dart';
import '../../utilities/dependencies_provider.dart' show getIt;
import 'sync_engine.dart' show RefreshOutcome;

/// Refreshes the access token for the sync engine (its `refreshToken`
/// callback).
///
/// Uses its OWN Dio: no `AppInterceptors`, no retry, no logout, no
/// navigation, 15 s timeouts. The outcome is only a classification:
///  * 200 with an `access` token -> the pair is stored in the same keys the
///    app uses ([Constants.authToken] / [Constants.refreshToken]) ->
///    [RefreshOutcome.refreshed];
///  * explicit 401, or 400 `token_not_valid`, from the refresh endpoint ->
///    [RefreshOutcome.rejected] (the session is really over);
///  * anything else (offline, timeout, 5xx, malformed body, logout racing
///    us) -> [RefreshOutcome.transient]. An unreachable server never ends
///    the session.
///
/// Single flight: concurrent callers share one request. If the main API
/// client is already refreshing ([mainRefreshInFlight]) its result is
/// reused instead of racing it. The reverse race (the main client starting
/// a refresh while ours is in flight) is made safe by the backend's
/// `refresh_grace` (the same old refresh token returns the same new pair for
/// 60 s) plus the compare-and-set below, which never overwrites a pair that
/// changed while our request was in flight.
class SyncTokenRefresher {
  SyncTokenRefresher({
    required String baseUrl,
    required CacheStorage storage,
    Future<bool>? Function()? mainRefreshInFlight,
    bool Function()? isLoggingOut,
    HttpClientAdapter? adapter,
    Duration timeout = const Duration(seconds: 15),
  }) : _storage = storage,
       _mainRefreshInFlight = mainRefreshInFlight,
       _isLoggingOut = isLoggingOut,
       _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: timeout,
           sendTimeout: timeout,
           receiveTimeout: timeout,
           responseType: ResponseType.json,
           // Every status is classified here; Dio must not throw on 4xx/5xx.
           validateStatus: (_) => true,
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }

  static const String refreshPath = 'api-public/v1/auth/token/refresh/';

  final CacheStorage _storage;
  final Future<bool>? Function()? _mainRefreshInFlight;
  final bool Function()? _isLoggingOut;
  final Dio _dio;

  Future<RefreshOutcome>? _inFlight;

  Future<RefreshOutcome> refresh() {
    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  Future<RefreshOutcome> _refresh() async {
    try {
      if (_isLoggingOut?.call() ?? false) return RefreshOutcome.transient;

      final main = _mainRefreshInFlight?.call();
      if (main != null) {
        // The main client owns this refresh (and its logout on failure).
        final ok = await main.catchError((Object _) => false);
        return ok ? RefreshOutcome.refreshed : RefreshOutcome.transient;
      }

      final sent = await _storage.getValue(Constants.refreshToken);
      if (sent == null || sent.isEmpty) return RefreshOutcome.rejected;

      final Response<dynamic> res;
      try {
        res = await _dio.post<dynamic>(
          refreshPath,
          data: {'refresh': sent},
          options: Options(
            headers: {'Accept': 'application/json'},
            contentType: Headers.jsonContentType,
          ),
        );
      } on DioException catch (e) {
        _log('refresh request failed: ${e.type.name}');
        return RefreshOutcome.transient;
      }

      final status = res.statusCode ?? 0;
      final body = res.data;
      if (status == 200) return _store(sent, body);
      if (status == 401 || (status == 400 && _isInvalidToken(body))) {
        // Someone else (the main client) may have rotated the token while we
        // were in flight: then our old token is legitimately refused.
        final now = await _storage.getValue(Constants.refreshToken);
        if (now != null && now.isNotEmpty && now != sent) {
          return RefreshOutcome.refreshed;
        }
        return RefreshOutcome.rejected;
      }
      _log('refresh returned HTTP $status');
      return RefreshOutcome.transient;
    } catch (e, st) {
      _log('refresh failed', e, st);
      return RefreshOutcome.transient;
    }
  }

  Future<RefreshOutcome> _store(String sent, Object? body) async {
    final map = body is Map ? body : null;
    final access = map?['access'];
    final refresh = map?['refresh'];
    if (access is! String || access.isEmpty) {
      _log('refresh 200 without an access token');
      return RefreshOutcome.transient;
    }
    // Compare-and-set: only replace the pair our request was based on.
    final current = await _storage.getValue(Constants.refreshToken);
    if (current == null || current.isEmpty) {
      // Logged out while we were in flight: never resurrect the session.
      return RefreshOutcome.transient;
    }
    if (current != sent) {
      // A newer pair is already stored (main client refreshed meanwhile).
      return RefreshOutcome.refreshed;
    }
    // Same write shape as AppInterceptors._refreshMainToken.
    await Future.wait([
      _storage.save(Constants.authToken, access),
      if (refresh is String && refresh.isNotEmpty)
        _storage.save(Constants.refreshToken, refresh),
    ]);
    if (refresh is String && refresh.isNotEmpty) {
      try {
        await getIt<PinVaultService>().updateTokens(
          oldRefresh: sent,
          access: access,
          refresh: refresh,
        );
      } catch (_) {} // vault unavailable (e.g. background isolate)
    }
    return RefreshOutcome.refreshed;
  }

  static bool _isInvalidToken(Object? body) {
    if (body is! Map) return false;
    final nested = body['error'] is Map ? body['error'] as Map : null;
    final code = nested?['code'] ?? body['code'];
    return code == 'token_not_valid' ||
        code == 'token_invalid' ||
        code == 'token_expired';
  }

  void _log(String msg, [Object? e, StackTrace? st]) {
    developer.log(msg, name: 'SyncTokenRefresher', error: e, stackTrace: st);
  }
}
