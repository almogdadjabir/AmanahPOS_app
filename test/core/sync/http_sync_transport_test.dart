import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/transport/http_sync_transport.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Captured {
  _Captured(this.options, this.body);
  final RequestOptions options;
  final List<int> body;
}

class _FakeAdapter implements HttpClientAdapter {
  _Captured? last;
  Future<ResponseBody> Function(RequestOptions o)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = <int>[];
    if (requestStream != null) {
      await for (final c in requestStream) {
        body.addAll(c);
      }
    }
    last = _Captured(options, body);
    return handler!(options);
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
  late _FakeAdapter adapter;
  late HttpSyncTransport transport;

  setUp(() {
    adapter = _FakeAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'))
      ..httpClientAdapter = adapter;
    transport = HttpSyncTransport(dio);
  });

  Future<SyncTransportException> failing(Future<Object?> Function() f) async {
    try {
      await f();
    } on SyncTransportException catch (e) {
      return e;
    }
    fail('expected SyncTransportException');
  }

  final pingOk = {
    'ok': true,
    'server_time': '2026-11-16T10:00:00Z',
    'maintenance': false,
    'capabilities': ['push', 'pull'],
  };

  OutboxEntry entry(int seq, {Map<String, dynamic>? payload}) => OutboxEntry(
    seq: seq,
    mutationId: 'm$seq',
    entity: 'product',
    op: 'create',
    entityId: 'e$seq',
    baseVersion: 3,
    occurredAt: DateTime.utc(2026, 11, 16, 9),
    payload: payload ?? {'name': 'x'},
  );

  group('ping', () {
    test('GET ping with 5s timeouts', () async {
      adapter.handler = (_) async => _json(200, pingOk);
      final r = await transport.ping();
      expect(r.ok, isTrue);
      expect(r.capabilities, {'push', 'pull'});
      expect(adapter.last!.options.method, 'GET');
      expect(adapter.last!.options.path, 'api/v1/sync/ping/');
      expect(adapter.last!.options.connectTimeout, const Duration(seconds: 5));
      expect(adapter.last!.options.receiveTimeout, const Duration(seconds: 5));
    });
  });

  group('pull', () {
    final pullOk = {
      'server_time': '2026-11-16T10:00:00Z',
      'changes': [],
      'next_cursor': 'c2',
      'has_more': false,
      'full_resync_required': false,
    };

    test('omits cursor when null, sends limit', () async {
      adapter.handler = (_) async => _json(200, pullOk);
      final r = await transport.pull(limit: 200, scope: 'u1|t1');
      expect(r.nextCursor, 'c2');
      expect(adapter.last!.options.path, 'api/v1/sync/pull/');
      expect(adapter.last!.options.queryParameters, {'limit': 200});
      expect(adapter.last!.options.receiveTimeout, const Duration(seconds: 15));
    });

    test('sends cursor when present', () async {
      adapter.handler = (_) async => _json(200, pullOk);
      await transport.pull(cursor: 'abc', scope: 'u1|t1');
      expect(adapter.last!.options.queryParameters, {
        'cursor': 'abc',
        'limit': 500,
      });
    });
  });

  group('push', () {
    final pushOk = {
      'server_time': '2026-11-16T10:00:02Z',
      'results': [
        {'mutation_id': 'm1', 'status': 'applied'},
      ],
    };

    test('small body is plain JSON in contract shape', () async {
      adapter.handler = (_) async => _json(200, pushOk);
      final r = await transport.push(
        deviceId: 'dev1',
        appVersion: '1.2.3',
        mutations: [entry(1)],
        scope: 'u1|t1',
      );
      expect(r.results.single.mutationId, 'm1');
      final o = adapter.last!.options;
      expect(o.method, 'POST');
      expect(o.path, 'api/v1/sync/push/');
      expect(o.receiveTimeout, const Duration(seconds: 15));
      expect(o.headers['Content-Encoding'], isNull);
      final body = jsonDecode(utf8.decode(adapter.last!.body)) as Map;
      expect(body['device_id'], 'dev1');
      expect(body['app_version'], '1.2.3');
      expect(body['client_time'], isA<String>());
      final m = (body['mutations'] as List).single as Map;
      expect(m.keys.toSet(), {
        'mutation_id',
        'seq',
        'entity',
        'op',
        'entity_id',
        'base_version',
        'occurred_at',
        'payload',
      });
      expect(m['occurred_at'], '2026-11-16T09:00:00.000Z');
    });

    test('large body is gzipped, decodes to exact JSON incl Arabic', () async {
      adapter.handler = (_) async => _json(200, pushOk);
      final arabic = 'منتج جديد ' * 1000;
      await transport.push(
        deviceId: 'dev1',
        appVersion: '1.2.3',
        mutations: [
          entry(1, payload: {'name': arabic}),
        ],
        scope: 'u1|t1',
      );
      final o = adapter.last!.options;
      expect(o.headers['Content-Encoding'], 'gzip');
      expect(o.contentType, startsWith('application/json'));
      final raw = adapter.last!.body;
      expect(raw.length, greaterThan(0));
      final decoded =
          jsonDecode(utf8.decode(gzip.decode(raw))) as Map<String, dynamic>;
      final m = (decoded['mutations'] as List).single as Map;
      expect((m['payload'] as Map)['name'], arabic);
      expect(decoded['device_id'], 'dev1');
    });
  });

  group('error mapping', () {
    test('connection error -> network', () async {
      adapter.handler = (o) async =>
          throw DioException.connectionError(requestOptions: o, reason: 'down');
      final e = await failing(() => transport.ping());
      expect(e.kind, SyncTransportKind.network);
    });

    for (final t in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    ]) {
      test('$t -> timeout', () async {
        adapter.handler = (o) async =>
            throw DioException(requestOptions: o, type: t);
        final e = await failing(() => transport.ping());
        expect(e.kind, SyncTransportKind.timeout);
      });
    }

    for (final c in {
      'token_expired': SyncTransportKind.tokenExpired,
      'account_disabled': SyncTransportKind.accountDisabled,
      'device_revoked': SyncTransportKind.deviceRevoked,
    }.entries) {
      test('401 ${c.key} -> ${c.value}', () async {
        adapter.handler = (_) async => _json(401, {'code': c.key});
        final e = await failing(() => transport.ping());
        expect(e.kind, c.value);
        expect(e.httpStatus, 401);
        expect(e.code, c.key);
      });
    }

    test('other 401 -> unauthorized', () async {
      adapter.handler = (_) async => _json(401, {'detail': 'nope'});
      final e = await failing(() => transport.ping());
      expect(e.kind, SyncTransportKind.unauthorized);
    });

    test('413 -> tooLarge', () async {
      adapter.handler = (_) async => _json(413, {});
      final e = await failing(() => transport.pull(scope: 'u1|t1'));
      expect(e.kind, SyncTransportKind.tooLarge);
    });

    test('503 -> maintenance', () async {
      adapter.handler = (_) async => _json(503, {});
      final e = await failing(() => transport.ping());
      expect(e.kind, SyncTransportKind.maintenance);
    });

    test('maintenance:true body -> maintenance', () async {
      adapter.handler = (_) async => _json(500, {'maintenance': true});
      final e = await failing(() => transport.ping());
      expect(e.kind, SyncTransportKind.maintenance);
    });

    test('500 -> server', () async {
      adapter.handler = (_) async => _json(500, {});
      final e = await failing(() => transport.ping());
      expect(e.kind, SyncTransportKind.server);
      expect(e.httpStatus, 500);
    });

    test('malformed 200 body -> server/malformed_response', () async {
      adapter.handler = (_) async => _json(200, {'ok': 'yes'});
      final e = await failing(() => transport.ping());
      expect(e.kind, SyncTransportKind.server);
      expect(e.code, 'malformed_response');
    });

    test('non-object 200 body -> malformed_response', () async {
      adapter.handler = (_) async => _json(200, [1, 2]);
      final e = await failing(() => transport.pull(scope: 'u1|t1'));
      expect(e.code, 'malformed_response');
    });

    test('never retries on failure', () async {
      var calls = 0;
      adapter.handler = (_) async {
        calls++;
        return _json(500, {});
      };
      await failing(() => transport.ping());
      expect(calls, 1);
    });
  });

  group('review fixes', () {
    ResponseBody html(int status, {Map<String, List<String>>? headers}) =>
        ResponseBody.fromString(
          '<html>bad gateway</html>',
          status,
          headers: {
            Headers.contentTypeHeader: ['text/html'],
            ...?headers,
          },
        );

    test('cancel -> network/cancelled', () async {
      adapter.handler = (o) async =>
          throw DioException.requestCancelled(requestOptions: o, reason: 'x');
      final e = await failing(() => transport.ping());
      expect(e.kind, SyncTransportKind.network);
      expect(e.code, 'cancelled');
    });

    test('badCertificate -> network/bad_certificate', () async {
      adapter.handler = (o) async =>
          throw DioException.badCertificate(requestOptions: o);
      final e = await failing(() => transport.ping());
      expect(e.kind, SyncTransportKind.network);
      expect(e.code, 'bad_certificate');
    });

    test('HTML 502 body -> server', () async {
      adapter.handler = (_) async => html(502);
      final e = await failing(() => transport.ping());
      expect(e.kind, SyncTransportKind.server);
      expect(e.httpStatus, 502);
    });

    test('HTML 401 body -> unauthorized', () async {
      adapter.handler = (_) async => html(401);
      final e = await failing(() => transport.ping());
      expect(e.kind, SyncTransportKind.unauthorized);
    });

    test('retry_after from body on 503', () async {
      adapter.handler = (_) async => _json(503, {'retry_after': 42});
      final e = await failing(() => transport.ping());
      expect(e.kind, SyncTransportKind.maintenance);
      expect(e.retryAfterSeconds, 42);
    });

    test('Retry-After header on 503', () async {
      adapter.handler = (_) async => html(
        503,
        headers: {
          'retry-after': ['30'],
        },
      );
      final e = await failing(() => transport.ping());
      expect(e.retryAfterSeconds, 30);
    });

    test('429 -> server/rate_limited with retry', () async {
      adapter.handler = (_) async => html(
        429,
        headers: {
          'retry-after': ['7'],
        },
      );
      final e = await failing(() => transport.pull(scope: 'u1|t1'));
      expect(e.kind, SyncTransportKind.server);
      expect(e.code, 'rate_limited');
      expect(e.retryAfterSeconds, 7);
    });

    test('other 4xx -> server/http_<status>', () async {
      adapter.handler = (_) async => _json(400, {});
      final e = await failing(() => transport.pull(scope: 'u1|t1'));
      expect(e.kind, SyncTransportKind.server);
      expect(e.code, 'http_400');
    });

    test('per-request timeouts override 60s Dio defaults', () async {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.test/',
          connectTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      )..httpClientAdapter = adapter;
      adapter.handler = (_) async => _json(200, pingOk);
      await HttpSyncTransport(dio).ping();
      final o = adapter.last!.options;
      expect(o.connectTimeout, const Duration(seconds: 5));
      expect(o.sendTimeout, const Duration(seconds: 5));
      expect(o.receiveTimeout, const Duration(seconds: 5));
    });

    test('cursor is URL-encoded on the final URI', () async {
      adapter.handler = (_) async => _json(200, {
        'server_time': '2026-11-16T10:00:00Z',
        'changes': [],
        'next_cursor': 'c',
        'has_more': false,
        'full_resync_required': false,
      });
      await transport.pull(cursor: 'a+b/c=', scope: 'u1|t1');
      final uri = adapter.last!.options.uri;
      expect(uri.queryParameters['cursor'], 'a+b/c=');
      expect(uri.query, contains('cursor=a%2Bb%2Fc%3D'));
    });
  });

  group('create() + SyncAuthInterceptor', () {
    HttpSyncTransport make({
      Future<String?> Function()? token,
      Future<String?> Function()? tenant,
    }) => HttpSyncTransport.create(
      baseUrl: 'https://example.test/',
      readAccessToken: token ?? () async => 'tok',
      readTenantId: tenant ?? () async => 'ten',
      adapter: adapter,
    );

    test('attaches exactly the auth headers', () async {
      adapter.handler = (_) async => _json(200, pingOk);
      await make().ping();
      final h = adapter.last!.options.headers;
      expect(h['Authorization'], 'Bearer tok');
      expect(h['X-Tenant-ID'], 'ten');
      expect(h['Accept'], 'application/json');
    });

    test('null readers do not crash and add no auth headers', () async {
      adapter.handler = (_) async => _json(200, pingOk);
      await make(token: () async => null, tenant: () async => null).ping();
      final h = adapter.last!.options.headers;
      expect(h.containsKey('Authorization'), isFalse);
      expect(h.containsKey('X-Tenant-ID'), isFalse);
    });

    test('401 is not refreshed or retried: 1 call, tokenExpired', () async {
      var calls = 0;
      var tokenReads = 0;
      adapter.handler = (_) async {
        calls++;
        return _json(401, {'code': 'token_expired'});
      };
      final jwt =
          '${base64Url.encode(utf8.encode('{}'))}.'
          '${base64Url.encode(utf8.encode('{"user_id":"u1"}'))}.s';
      final t = make(
        token: () async {
          tokenReads++;
          return jwt;
        },
        tenant: () async => 't1',
      );

      final e = await failing(
        () => t.push(
          deviceId: 'd',
          appVersion: '1',
          mutations: [entry(1)],
          scope: 'u1|t1',
        ),
      );
      expect(e.kind, SyncTransportKind.tokenExpired);
      expect(calls, 1);
      expect(tokenReads, 1);
    });

    test('401 without code -> unauthorized, single call', () async {
      var calls = 0;
      adapter.handler = (_) async {
        calls++;
        return _json(401, {'detail': 'x'});
      };
      final e = await failing(() => make().ping());
      expect(e.kind, SyncTransportKind.unauthorized);
      expect(calls, 1);
    });

    test('unreachable server surfaces network, no side effects', () async {
      adapter.handler = (o) async =>
          throw DioException.connectionError(requestOptions: o, reason: 'x');
      final e = await failing(() => make().ping());
      expect(e.kind, SyncTransportKind.network);
    });
  });

  group('live backend shapes', () {
    HttpSyncTransport make({Future<String?> Function()? device}) =>
        HttpSyncTransport.create(
          baseUrl: 'https://example.test/',
          readAccessToken: () async => 'tok',
          readTenantId: () async => 'ten',
          readDeviceId: device,
          adapter: adapter,
        );

    Map<String, dynamic> nested(String code, {Object? retry}) => {
      'success': false,
      'error': {'code': code, 'message': 'msg', 'retry_after': ?retry},
    };

    for (final c in {
      'token_expired': SyncTransportKind.tokenExpired,
      'token_invalid': SyncTransportKind.unauthorized,
      'account_disabled': SyncTransportKind.accountDisabled,
      'device_revoked': SyncTransportKind.deviceRevoked,
    }.entries) {
      test('nested 401 ${c.key} -> ${c.value}', () async {
        adapter.handler = (_) async => _json(401, nested(c.key));
        final e = await failing(() => make().ping());
        expect(e.kind, c.value);
        expect(e.code, c.key);
        expect(e.message, 'msg');
      });
    }

    test('top-level code fallback still works', () async {
      adapter.handler = (_) async => _json(401, {'code': 'device_revoked'});
      final e = await failing(() => make().ping());
      expect(e.kind, SyncTransportKind.deviceRevoked);
    });

    test('retry_after read from error.retry_after', () async {
      adapter.handler = (_) async =>
          _json(503, nested('maintenance', retry: 9));
      final e = await failing(() => make().ping());
      expect(e.kind, SyncTransportKind.maintenance);
      expect(e.retryAfterSeconds, 9);
    });

    test('negative retry_after ignored', () async {
      adapter.handler = (_) async => _json(503, nested('x', retry: -5));
      final e = await failing(() => make().ping());
      expect(e.retryAfterSeconds, isNull);
    });

    test('Retry-After HTTP-date -> null', () async {
      adapter.handler = (_) async => ResponseBody.fromString(
        '{}',
        503,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
          'retry-after': ['Wed, 21 Oct 2026 07:28:00 GMT'],
        },
      );
      final e = await failing(() => make().ping());
      expect(e.retryAfterSeconds, isNull);
    });

    test('X-Device-ID attached when reader returns id', () async {
      adapter.handler = (_) async => _json(200, pingOk);
      await make(device: () async => 'dev-uuid').ping();
      expect(adapter.last!.options.headers['X-Device-ID'], 'dev-uuid');
    });

    test('X-Device-ID omitted when null or no reader', () async {
      adapter.handler = (_) async => _json(200, pingOk);
      await make(device: () async => null).ping();
      expect(adapter.last!.options.headers.containsKey('X-Device-ID'), isFalse);
      await make().ping();
      expect(adapter.last!.options.headers.containsKey('X-Device-ID'), isFalse);
    });
  });
}
