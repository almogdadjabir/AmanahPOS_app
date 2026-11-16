import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../contract/sync_contract.dart';
import '../outbox/outbox_entry.dart';
import 'sync_auth_interceptor.dart';
import 'sync_transport.dart';

/// Dio-backed [SyncTransport].
///
/// The injected [Dio] must NOT carry retry interceptors (idempotency is by
/// `mutation_id`, the engine owns retry policy) and must not refresh tokens or
/// log out on its own: it only attaches headers (see [SyncAuthInterceptor]).
/// Token refresh is the engine's concern.
class HttpSyncTransport implements SyncTransport {
  HttpSyncTransport(this._dio);

  /// Builds a dedicated, retry-free Dio for sync with [SyncAuthInterceptor]
  /// (headers only: no refresh, no logout). Token refresh is a separate
  /// component owned by the sync engine.
  factory HttpSyncTransport.create({
    required String baseUrl,
    required Future<String?> Function() readAccessToken,
    required Future<String?> Function() readTenantId,
    Future<String?> Function()? readDeviceId,
    Future<String?> Function()? readSessionKey,
    HttpClientAdapter? adapter,
  }) => HttpSyncTransport(
    createDio(
      baseUrl: baseUrl,
      readAccessToken: readAccessToken,
      readTenantId: readTenantId,
      readDeviceId: readDeviceId,
      readSessionKey: readSessionKey,
      adapter: adapter,
    ),
  );

  /// The sync Dio on its own (headers only, no retry/refresh/logout), for
  /// other sync-owned calls such as device registration.
  static Dio createDio({
    required String baseUrl,
    required Future<String?> Function() readAccessToken,
    required Future<String?> Function() readTenantId,
    Future<String?> Function()? readDeviceId,
    Future<String?> Function()? readSessionKey,
    HttpClientAdapter? adapter,
  }) {
    final dio = Dio(
      BaseOptions(baseUrl: baseUrl, receiveDataWhenStatusError: true),
    );
    if (adapter != null) dio.httpClientAdapter = adapter;
    dio.interceptors.add(
      SyncAuthInterceptor(
        readAccessToken: readAccessToken,
        readTenantId: readTenantId,
        readDeviceId: readDeviceId,
        readSessionKey: readSessionKey,
      ),
    );
    return dio;
  }

  final Dio _dio;

  static const _pingTimeout = Duration(seconds: 5);
  static const _syncTimeout = Duration(seconds: 15);
  static const _gzipThresholdBytes = 2048;

  @override
  Future<PingResponse> ping() => _run(() async {
    final res = await _send('GET', 'api/v1/sync/ping/', _pingTimeout);
    return PingResponse.fromJson(_asMap(res.data));
  });

  @override
  Future<PushResponse> push({
    required String deviceId,
    required String appVersion,
    required List<OutboxEntry> mutations,
    required String scope,
  }) => _run(() async {
    final json = buildPushRequestJson(
      deviceId: deviceId,
      appVersion: appVersion,
      clientTime: DateTime.now().toUtc(),
      mutations: mutations,
    );
    final bytes = utf8.encode(jsonEncode(json));
    final gz = bytes.length > _gzipThresholdBytes;
    final res = await _send(
      'POST',
      'api/v1/sync/push/',
      _syncTimeout,
      data: Uint8List.fromList(gz ? gzip.encode(bytes) : bytes),
      headers: {'Content-Encoding': ?(gz ? 'gzip' : null)},
      scope: scope,
    );
    return PushResponse.fromJson(_asMap(res.data));
  });

  @override
  Future<PullResponse> pull({
    String? cursor,
    int limit = 500,
    required String scope,
  }) =>
      _run(() async {
        final res = await _send(
          'GET',
          'api/v1/sync/pull/',
          _syncTimeout,
          query: {'cursor': ?cursor, 'limit': limit},
          scope: scope,
        );
        return PullResponse.fromJson(_asMap(res.data));
      });

  Future<Response<dynamic>> _send(
    String method,
    String path,
    Duration timeout, {
    Object? data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,

    /// Null only for ping, which carries no user data.
    String? scope,
  }) {
    final isPost = method == 'POST';
    return _dio.fetch<dynamic>(
      RequestOptions(
        path: path,
        method: method,
        baseUrl: _dio.options.baseUrl,
        data: data,
        queryParameters: query ?? const {},
        headers: headers,
        extra: {kSyncScopeExtra: ?scope},
        contentType: isPost ? 'application/json; charset=utf-8' : null,
        responseType: ResponseType.json,
        connectTimeout: timeout,
        sendTimeout: timeout,
        receiveTimeout: timeout,
      ),
    );
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Response body is not a JSON object');
  }

  Future<T> _run<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on SyncTransportException {
      rethrow;
    } on DioException catch (e) {
      throw _map(e);
    } on FormatException catch (e) {
      throw SyncTransportException(
        kind: SyncTransportKind.server,
        code: 'malformed_response',
        message: e.message,
      );
    } on TypeError catch (e) {
      throw SyncTransportException(
        kind: SyncTransportKind.server,
        code: 'malformed_response',
        message: e.toString(),
      );
    }
  }

  SyncTransportException _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return SyncTransportException(
          kind: SyncTransportKind.timeout,
          message: e.message,
        );
      case DioExceptionType.connectionError:
        return SyncTransportException(
          kind: SyncTransportKind.network,
          message: e.message,
        );
      case DioExceptionType.cancel:
        if (e.error is SyncScopeMismatch) {
          return SyncTransportException(
            kind: SyncTransportKind.scopeChanged,
            code: 'scope_changed',
          );
        }
        return SyncTransportException(
          kind: SyncTransportKind.network,
          code: 'cancelled',
          message: e.message,
        );
      case DioExceptionType.badResponse:
        return _mapStatus(e);
      case DioExceptionType.badCertificate:
        return SyncTransportException(
          kind: SyncTransportKind.network,
          code: 'bad_certificate',
          message: e.message,
        );
      case DioExceptionType.unknown:
        // Socket-level failures surface as unknown with an IO error.
        return SyncTransportException(
          kind: e.error is IOException
              ? SyncTransportKind.network
              : SyncTransportKind.server,
          message: e.message ?? e.error?.toString(),
        );
    }
  }

  SyncTransportException _mapStatus(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final root = data is Map ? data : const <dynamic, dynamic>{};
    // Live backend nests typed errors under `error`; fall back to top-level
    // `code`/`message`/`detail` (DRF-style shapes).
    final nested = root['error'] is Map ? root['error'] as Map : null;
    String? str(Object? v) => v is String ? v : null;
    final code = str(nested?['code']) ?? str(root['code']);
    final message =
        str(nested?['message']) ?? str(root['message']) ?? str(root['detail']);

    // Retry-After in HTTP-date form is not parsed (-> null); negative values
    // are ignored.
    int? seconds(Object? v) {
      final n = v is int ? v : (v is String ? int.tryParse(v.trim()) : null);
      return (n != null && n >= 0) ? n : null;
    }

    final retryAfter =
        seconds(nested?['retry_after']) ??
        seconds(root['retry_after']) ??
        seconds(e.response?.headers.value('retry-after'));
    final maintenanceFlag =
        root['maintenance'] == true || nested?['maintenance'] == true;

    SyncTransportException make(
      SyncTransportKind k, {
      String? overrideCode,
      bool withRetry = false,
    }) => SyncTransportException(
      kind: k,
      httpStatus: status,
      code: overrideCode ?? code,
      message: message,
      retryAfterSeconds: withRetry ? retryAfter : null,
    );

    if (status == 401) {
      switch (code) {
        case 'token_invalid':
          return make(SyncTransportKind.unauthorized);
        case 'token_expired':
          return make(SyncTransportKind.tokenExpired);
        case 'account_disabled':
          return make(SyncTransportKind.accountDisabled);
        case 'device_revoked':
          return make(SyncTransportKind.deviceRevoked);
      }
      return make(SyncTransportKind.unauthorized);
    }
    if (status == 413) return make(SyncTransportKind.tooLarge);
    if (status == 503 || maintenanceFlag) {
      return make(SyncTransportKind.maintenance, withRetry: true);
    }
    if (status == 429) {
      return make(
        SyncTransportKind.server,
        overrideCode: 'rate_limited',
        withRetry: true,
      );
    }
    if (status != null && status >= 400 && status < 500) {
      return make(SyncTransportKind.server, overrideCode: 'http_$status');
    }
    return make(SyncTransportKind.server);
  }
}
