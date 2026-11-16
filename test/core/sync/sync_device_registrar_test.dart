import 'dart:convert';
import 'dart:typed_data';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/sync_device_registrar.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/core/sync/transport/http_sync_transport.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_db.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <Map<String, dynamic>>[];
  Future<ResponseBody> Function() reply = () async => ResponseBody.fromString(
    '{"device_id":"x"}',
    201,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

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
    requests.add(options);
    bodies.add(jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
    return reply();
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late OfflineDb odb;
  late SyncStateStore state;
  late _Adapter adapter;
  late Set<String> caps;
  String? fcm;

  setUp(() async {
    odb = await openTestDb();
    state = SyncStateStore(odb);
    adapter = _Adapter();
    caps = {'push', 'pull', 'devices'};
    fcm = 'fcm-token-1';
  });
  tearDown(() async => (await odb.database).close());

  SyncDeviceRegistrar make() {
    final dio = HttpSyncTransport.createDio(
      baseUrl: 'https://api.test/',
      readAccessToken: () async => 'access',
      readTenantId: () async => 'tenant-1',
      readDeviceId: state.deviceId,
      adapter: adapter,
    );
    return SyncDeviceRegistrar(
      dio: dio,
      state: state,
      capabilities: () async => caps,
      appVersion: () async => '1.2.3',
      platform: 'android',
      name: 'android 14',
      fcmToken: () async => fcm,
    );
  }

  test('registers once with the contract body and sync auth headers', () async {
    final r = make();
    expect(await r.registerIfNeeded(userKey: 'u1|t1'), isTrue);
    final deviceId = await state.deviceId();
    final req = adapter.requests.single;
    expect(req.uri.toString(), 'https://api.test/api/v1/sync/devices/');
    expect(req.method, 'POST');
    expect(req.headers['Authorization'], 'Bearer access');
    expect(req.headers['X-Tenant-ID'], 'tenant-1');
    expect(req.headers['X-Device-ID'], deviceId);
    expect(adapter.bodies.single, {
      'device_id': deviceId,
      'name': 'android 14',
      'platform': 'android',
      'app_version': '1.2.3',
      'fcm_token': 'fcm-token-1',
    });

    // Same signature: no second request (also across a new instance).
    expect(await make().registerIfNeeded(userKey: 'u1|t1'), isTrue);
    expect(adapter.requests.length, 1);
  });

  test(
    'another login (user/tenant) or a new FCM token registers again',
    () async {
      await make().registerIfNeeded(userKey: 'u1|t1');
      await make().registerIfNeeded(userKey: 'u2|t1');
      expect(adapter.requests.length, 2);
      fcm = 'fcm-token-2';
      await make().registerIfNeeded(userKey: 'u2|t1');
      expect(adapter.requests.length, 3);
    },
  );

  test('no fcm token -> field omitted', () async {
    fcm = null;
    await make().registerIfNeeded();
    expect(adapter.bodies.single.containsKey('fcm_token'), isFalse);
  });

  test('without the devices capability nothing is sent', () async {
    caps = {'push', 'pull'};
    expect(await make().registerIfNeeded(), isFalse);
    expect(adapter.requests, isEmpty);
  });

  test('failure never throws and is retried on the next call', () async {
    adapter.reply = () async => ResponseBody.fromString(
      '{"detail":"forbidden"}',
      403,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
    expect(await make().registerIfNeeded(), isFalse);
    adapter.reply = () async => throw DioException.connectionError(
      requestOptions: RequestOptions(),
      reason: 'offline',
    );
    expect(await make().registerIfNeeded(), isFalse);
    expect(await state.deviceRegistration(), isNull);

    adapter.reply = () async => ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
    expect(await make().registerIfNeeded(), isTrue);
    expect(adapter.requests.length, 3);
  });

  test('capability lookup failure is swallowed', () async {
    final r = SyncDeviceRegistrar(
      dio: Dio(),
      state: state,
      capabilities: () async => throw StateError('ping failed'),
      appVersion: () async => '1',
      platform: 'ios',
      name: 'ios',
    );
    expect(await r.registerIfNeeded(), isFalse);
  });

  test('concurrent calls share one request', () async {
    final r = make();
    final results = await Future.wait([
      r.registerIfNeeded(userKey: 'u'),
      r.registerIfNeeded(userKey: 'u'),
    ]);
    expect(results, [true, true]);
    expect(adapter.requests.length, 1);
  });
}
