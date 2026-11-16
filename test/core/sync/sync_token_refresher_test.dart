import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_token_refresher.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorage implements CacheStorage {
  final values = <String, String?>{};
  final writes = <String>[];

  @override
  Future<String?> getValue(String key) async => values[key];

  @override
  Future<bool> save(String key, String? value) async {
    writes.add(key);
    values[key] = value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Adapter implements HttpClientAdapter {
  final requests = <Map<String, dynamic>>[];
  final paths = <String>[];
  late Future<ResponseBody> Function() reply;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final c in requestStream) {
        bytes.addAll(c);
      }
    }
    paths.add(options.uri.toString());
    requests.add(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
    return reply();
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  late _FakeStorage storage;
  late _Adapter adapter;

  SyncTokenRefresher make({
    Future<bool>? Function()? main,
    bool Function()? loggingOut,
  }) => SyncTokenRefresher(
    baseUrl: 'https://api.test/',
    storage: storage,
    adapter: adapter,
    mainRefreshInFlight: main,
    isLoggingOut: loggingOut,
  );

  setUp(() {
    storage = _FakeStorage()
      ..values[Constants.authToken] = 'old-access'
      ..values[Constants.refreshToken] = 'old-refresh';
    adapter = _Adapter();
  });

  test('200 stores the new pair and returns refreshed', () async {
    adapter.reply = () async =>
        _json(200, {'access': 'new-access', 'refresh': 'new-refresh'});
    expect(await make().refresh(), RefreshOutcome.refreshed);
    expect(adapter.paths.single,
        'https://api.test/api-public/v1/auth/token/refresh/');
    expect(adapter.requests.single, {'refresh': 'old-refresh'});
    expect(storage.values[Constants.authToken], 'new-access');
    expect(storage.values[Constants.refreshToken], 'new-refresh');
  });

  test('401 from the refresh endpoint -> rejected, nothing stored', () async {
    adapter.reply = () async =>
        _json(401, {'detail': 'Token is blacklisted', 'code': 'token_not_valid'});
    expect(await make().refresh(), RefreshOutcome.rejected);
    expect(storage.writes, isEmpty);
  });

  test('400 token_not_valid -> rejected; other 400 -> transient', () async {
    adapter.reply = () async => _json(400, {'code': 'token_not_valid'});
    expect(await make().refresh(), RefreshOutcome.rejected);
    adapter.reply = () async => _json(400, {'refresh': ['bad']});
    expect(await make().refresh(), RefreshOutcome.transient);
    expect(storage.writes, isEmpty);
  });

  for (final status in [500, 502, 503, 429]) {
    test('$status -> transient, nothing stored', () async {
      adapter.reply = () async => _json(status, {'detail': 'x'});
      expect(await make().refresh(), RefreshOutcome.transient);
      expect(storage.writes, isEmpty);
    });
  }

  test('network error / timeout -> transient', () async {
    adapter.reply = () async =>
        throw const SocketException('Network is unreachable');
    expect(await make().refresh(), RefreshOutcome.transient);
    adapter.reply = () async => throw DioException.connectionTimeout(
      timeout: const Duration(seconds: 15),
      requestOptions: RequestOptions(),
    );
    expect(await make().refresh(), RefreshOutcome.transient);
    expect(storage.writes, isEmpty);
  });

  test('malformed 200 -> transient, nothing stored', () async {
    adapter.reply = () async => _json(200, {'refresh': 'only-refresh'});
    expect(await make().refresh(), RefreshOutcome.transient);
    adapter.reply = () async => ResponseBody.fromString('<html>', 200);
    expect(await make().refresh(), RefreshOutcome.transient);
    expect(storage.writes, isEmpty);
  });

  test('no stored refresh token -> rejected without a request', () async {
    storage.values.remove(Constants.refreshToken);
    expect(await make().refresh(), RefreshOutcome.rejected);
    expect(adapter.requests, isEmpty);
  });

  test('single flight: concurrent callers share one request', () async {
    final gate = Completer<void>();
    adapter.reply = () async {
      await gate.future;
      return _json(200, {'access': 'a2', 'refresh': 'r2'});
    };
    final r = make();
    final futures = [r.refresh(), r.refresh(), r.refresh()];
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    expect(await Future.wait(futures), everyElement(RefreshOutcome.refreshed));
    expect(adapter.requests.length, 1);
    // After completion a new call makes a new request.
    adapter.reply = () async => _json(200, {'access': 'a3', 'refresh': 'r3'});
    await r.refresh();
    expect(adapter.requests.length, 2);
    expect(adapter.requests.last, {'refresh': 'r2'});
  });

  test('reuses the main client in-flight refresh instead of racing it',
      () async {
    adapter.reply = () async => fail('must not call the network');
    expect(await make(main: () => Future.value(true)).refresh(),
        RefreshOutcome.refreshed);
    // A failed main refresh is the main client's logout, not ours.
    expect(await make(main: () => Future.value(false)).refresh(),
        RefreshOutcome.transient);
  });

  test('while the app is logging out -> transient, no request', () async {
    adapter.reply = () async => fail('must not call the network');
    expect(await make(loggingOut: () => true).refresh(),
        RefreshOutcome.transient);
  });

  test('a newer pair stored meanwhile is not overwritten', () async {
    adapter.reply = () async {
      // Main client rotated while our request was in flight.
      storage.values[Constants.authToken] = 'main-access';
      storage.values[Constants.refreshToken] = 'main-refresh';
      return _json(200, {'access': 'ours', 'refresh': 'ours-r'});
    };
    expect(await make().refresh(), RefreshOutcome.refreshed);
    expect(storage.values[Constants.authToken], 'main-access');
    expect(storage.values[Constants.refreshToken], 'main-refresh');
  });

  test('401 after someone else rotated the token -> refreshed', () async {
    adapter.reply = () async {
      storage.values[Constants.refreshToken] = 'main-refresh';
      return _json(401, {'code': 'token_not_valid'});
    };
    expect(await make().refresh(), RefreshOutcome.refreshed);
  });

  test('logout during the request: tokens are never written back', () async {
    adapter.reply = () async {
      storage.values.remove(Constants.authToken);
      storage.values.remove(Constants.refreshToken);
      return _json(200, {'access': 'a', 'refresh': 'r'});
    };
    expect(await make().refresh(), RefreshOutcome.transient);
    expect(storage.values[Constants.authToken], isNull);
    expect(storage.writes, isEmpty);
  });
}
