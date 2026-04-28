import 'dart:async';

import 'package:amana_pos/api/network/multipart_file_extended.dart';
import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AppInterceptors extends Interceptor {
  final Dio _dio;
  final CacheStorage _cacheStorage = getIt<CacheStorage>();
  static Future<bool>? _refreshTokenFuture;
  static bool isLoggingOut = false;
  static const String _sessionExpiredSentinel = '__session_expired__';

  AppInterceptors(this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await _addHeaders(options);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (isLoggingOut) {
      handler.reject(_makeExpiredError(err.requestOptions));
      return;
    }

    await _handleUnauthorizedError(err, handler);
  }

 Future<void> _addHeaders(RequestOptions options) async {
    final authToken = await _cacheStorage.getValue(Constants.authToken);

    final requiresAuth = options.path.startsWith('api/') || options.path.startsWith('/api/');

    if (authToken != null && requiresAuth) {
      options.headers['Authorization'] = 'Bearer $authToken';
    }

    final hasAccept = options.headers.keys
        .any((k) => k.toString().toLowerCase() == 'accept');
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
      await _triggerForcedLogout();
      handler.reject(_makeExpiredError(err.requestOptions));
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
    final refreshToken = await _cacheStorage.getValue(Constants.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _dio.post<dynamic>(
        'api-public/v1/auth/token/refresh/',
        data: {'refresh': refreshToken},
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final newAccess  = response.data['access']  as String?;
        final newRefresh = response.data['refresh'] as String?;

        if (newAccess == null) return false;

        // Write both atomically so a partial write never leaves the app
        // with a valid access token but an expired refresh token.
        await Future.wait([
          _cacheStorage.save(Constants.authToken, newAccess),
          if (newRefresh != null)
            _cacheStorage.save(Constants.refreshToken, newRefresh),
        ]);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('[AppInterceptors] _refreshMainToken error: $e');
      return false;
    }
  }

  Future<void> _triggerForcedLogout() async {
    if (isLoggingOut) return;
    isLoggingOut = true;

    try {
      await _cacheStorage.resetTokens();

      await _navigateToLoginSafely();
    } catch (e) {
      if (kDebugMode) debugPrint('[AppInterceptors] _triggerForcedLogout error: $e');
    } finally {
      Future.delayed(const Duration(seconds: 4), () {
        isLoggingOut = false;
        if (kDebugMode) debugPrint('[AppInterceptors] isLoggingOut reset');
      });
    }
  }

  Future<void> _navigateToLoginSafely() async {
    for (int attempt = 0; attempt < 5; attempt++) {
      final navigator = Constants.navigatorKey.currentState;

      if (navigator != null && navigator.mounted) {
        try {
          return;
        } catch (e) {
          if (kDebugMode) debugPrint('[AppInterceptors] navigation attempt ${attempt + 1} threw: $e');
        }
      }

      if (kDebugMode) {
        debugPrint('[AppInterceptors] navigator not ready (attempt ${attempt + 1}/5), retrying...');
      }

      await Future.delayed(Duration(milliseconds: 100 * (1 << attempt)));
    }

    if (kDebugMode) debugPrint('[AppInterceptors] all navigation attempts failed — app restart needed');
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
        formData.fields.add(MapEntry(item['name'] as String, item['value'] as String));
        continue;
      }

      if (item['type'] == 'file') {
        final filename    = item['filename']    as String?;
        final ctString    = item['contentType'] as String?;
        final contentType = ctString != null ? DioMediaType.parse(ctString) : null;
        final filePath    = item['filePath']    as String?;
        final bytes       = item['bytes']       as List<int>?;

        final multipart = filePath != null
            ? ExtendedMultipartFile.fromFileSync(filePath,
            filename: filename, contentType: contentType)
            : bytes != null
            ? ExtendedMultipartFile.fromBytesSync(bytes,
            filename: filename, contentType: contentType)
            : throw StateError('File backup missing both filePath and bytes');

        formData.files.add(MapEntry(item['name'] as String, multipart));
      }
    }

    return formData;
  }
}