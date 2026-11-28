import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/core/network/app_interceptors.dart';
import 'package:amana_pos/utilities/dependencies_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorage implements CacheStorage {
  final values = <String, String?>{
    Constants.authToken: 'old-access',
    Constants.refreshToken: 'old-refresh',
  };
  int resetCalls = 0;

  @override
  Future<String?> getValue(String key) async => values[key];

  @override
  Future<bool> save(String key, String? value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> resetTokens() async {
    resetCalls++;
    values.clear();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Adapter implements HttpClientAdapter {
  int refreshCalls = 0;
  int dataCalls = 0;
  late Future<ResponseBody> Function() refreshReply;

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('token/refresh')) {
      refreshCalls++;
      return refreshReply();
    }
    dataCalls++;
    final auth = options.headers['Authorization'];
    if (auth == 'Bearer new-access') return _json(200, {'ok': true});
    return _json(401, {'detail': 'expired'});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeStorage storage;
  late _Adapter adapter;
  late Dio dio;

  setUp(() async {
    await getIt.reset();
    storage = _FakeStorage();
    adapter = _Adapter();
    dio = Dio(BaseOptions(baseUrl: 'https://x.test/'))
      ..httpClientAdapter = adapter;
    getIt.registerSingleton<CacheStorage>(storage);
    getIt.registerSingleton<Dio>(dio);
    dio.interceptors.add(AppInterceptors(dio));
    AppInterceptors.isLoggingOut = false;
    AppInterceptors.backoffOverride = const [
      Duration.zero,
      Duration.zero,
      Duration.zero,
    ];
  });

  tearDown(() async {
    AppInterceptors.isLoggingOut = false;
    await getIt.reset();
  });

  Future<Object?> call() async {
    try {
      return await dio.get<dynamic>('api/data');
    } on DioException catch (e) {
      return e;
    }
  }

  test(
    'refresh connectionError: no logout, tokens kept, original 401',
    () async {
      adapter.refreshReply = () async => throw DioException(
        requestOptions: RequestOptions(path: 'x'),
        type: DioExceptionType.connectionError,
      );
      final r = await call();
      expect(r, isA<DioException>());
      expect((r as DioException).type, DioExceptionType.connectionError);
      expect(r.response, isNull);
      expect(AppInterceptors.isSessionExpiredError(r), isFalse);
      expect(storage.resetCalls, 0);
      expect(storage.values[Constants.refreshToken], 'old-refresh');
      expect(AppInterceptors.isLoggingOut, isFalse);
    },
  );

  test('refresh timeout: no logout', () async {
    adapter.refreshReply = () async => throw DioException(
      requestOptions: RequestOptions(path: 'x'),
      type: DioExceptionType.receiveTimeout,
    );
    final r = await call();
    expect(AppInterceptors.isSessionExpiredError(r as DioException), isFalse);
    expect(r.response, isNull);
    expect(storage.resetCalls, 0);
  });

  test('refresh 5xx: no logout, original error', () async {
    adapter.refreshReply = () async => _json500();
    final r = await call();
    expect(AppInterceptors.isSessionExpiredError(r as DioException), isFalse);
    expect(r.response, isNull);
    expect(storage.resetCalls, 0);
    expect(storage.values[Constants.refreshToken], 'old-refresh');
  });

  test('refresh 429: no logout', () async {
    adapter.refreshReply = () async => adapter._json(429, {'detail': 'slow'});
    final r = await call();
    expect(AppInterceptors.isSessionExpiredError(r as DioException), isFalse);
    expect(r.response, isNull);
    expect(storage.resetCalls, 0);
  });

  test('refresh 400 any body: logout (backend contract)', () async {
    adapter.refreshReply = () async => adapter._json(400, {'code': 'bad'});
    await call();
    expect(storage.resetCalls, 1);
  });

  test('transient refresh failure is retried 3 times then surfaces', () async {
    adapter.refreshReply = () async => _json500();
    await call();
    expect(adapter.refreshCalls, 4);
  });

  test('refresh succeeds after a transient failure', () async {
    var n = 0;
    adapter.refreshReply = () async => n++ == 0
        ? _json500()
        : adapter._json(200, {'access': 'new-access', 'refresh': 'r2'});
    final r = await call();
    expect((r as Response).statusCode, 200);
    expect(storage.values[Constants.refreshToken], 'r2');
    expect(storage.values[Constants.authToken], 'new-access');
  });

  test(
    'stale isLoggingOut flag does not block refresh of new session',
    () async {
      AppInterceptors.isLoggingOut = true;
      adapter.refreshReply = () async =>
          adapter._json(200, {'access': 'new-access', 'refresh': 'r2'});
      final r = await call();
      expect((r as Response).statusCode, 200);
    },
  );

  test(
    'access token expiring in <2 min refreshes before the request',
    () async {
      String jwt(int exp) {
        String b(Object o) =>
            base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
        return '${b({'alg': 'none'})}.${b({'exp': exp})}.sig';
      }

      storage.values[Constants.authToken] = jwt(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 30,
      );
      adapter.refreshReply = () async =>
          adapter._json(200, {'access': 'new-access', 'refresh': 'r2'});
      final r = await call();
      expect((r as Response).statusCode, 200);
      expect(adapter.refreshCalls, 1);
      expect(adapter.dataCalls, 1); // no 401 round-trip
    },
  );

  test('refresh 401: logout exactly once', () async {
    adapter.refreshReply = () async => adapter._json(401, {'detail': 'no'});
    final r = await call();
    expect(AppInterceptors.isSessionExpiredError(r as DioException), isTrue);
    expect(storage.resetCalls, 1);
  });

  test('refresh 400 token_not_valid: logout', () async {
    adapter.refreshReply = () async =>
        adapter._json(400, {'code': 'token_not_valid'});
    await call();
    expect(storage.resetCalls, 1);
  });

  test('concurrent 401s share one refresh and both succeed', () async {
    final gate = Completer<void>();
    adapter.refreshReply = () async {
      await gate.future;
      return adapter._json(200, {'access': 'new-access', 'refresh': 'r2'});
    };
    final a = call();
    final b = call();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    gate.complete();
    final res = await Future.wait([a, b]);
    expect(adapter.refreshCalls, 1);
    expect(res.every((r) => r is Response && r.statusCode == 200), isTrue);
    expect(storage.resetCalls, 0);
  });

  test(
    'refresh 401 but another party stored a new pair: retry, no logout',
    () async {
      adapter.refreshReply = () async {
        // SyncTokenRefresher rotated the pair while ours was in flight.
        storage.values[Constants.authToken] = 'new-access';
        storage.values[Constants.refreshToken] = 'T2';
        return adapter._json(401, {'detail': 'blacklisted'});
      };
      final r = await call();
      expect(r, isA<Response>());
      expect((r as Response).statusCode, 200);
      expect(storage.resetCalls, 0);
      expect(storage.values[Constants.refreshToken], 'T2');
    },
  );

  test(
    'refresh 400 token_not_valid but pair changed meanwhile: no logout',
    () async {
      adapter.refreshReply = () async {
        storage.values[Constants.authToken] = 'new-access';
        storage.values[Constants.refreshToken] = 'T2';
        return adapter._json(400, {'code': 'token_not_valid'});
      };
      final r = await call();
      expect((r as Response).statusCode, 200);
      expect(storage.resetCalls, 0);
    },
  );

  test(
    'concurrent waiters, network failure: original errors, no logout',
    () async {
      adapter.refreshReply = () async => throw DioException(
        requestOptions: RequestOptions(path: 'x'),
        type: DioExceptionType.connectionError,
      );
      final res = await Future.wait([call(), call(), call()]);
      expect(adapter.refreshCalls, 4); // one single-flight, 1+3 retries
      for (final r in res) {
        expect(
          AppInterceptors.isSessionExpiredError(r as DioException),
          isFalse,
        );
        expect(r.response, isNull);
      }
      expect(storage.resetCalls, 0);
    },
  );

  test('concurrent 401s with 401 refresh: one refresh, one logout', () async {
    adapter.refreshReply = () async => adapter._json(401, {'detail': 'no'});
    final res = await Future.wait([call(), call()]);
    expect(adapter.refreshCalls, 1);
    expect(storage.resetCalls, 1);
    expect(res.length, 2);
  });
}

ResponseBody _json500() => ResponseBody.fromString(
  '{}',
  503,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);
