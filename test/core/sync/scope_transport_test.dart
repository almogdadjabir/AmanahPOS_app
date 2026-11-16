import 'dart:convert';
import 'dart:typed_data';

import 'package:amana_pos/core/sync/transport/http_sync_transport.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingAdapter implements HttpClientAdapter {
  int sent = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sent++;
    return ResponseBody.fromString(
      jsonEncode({
        'server_time': '2026-11-16T10:00:00Z',
        'changes': <Object>[],
        'next_cursor': 'c',
        'has_more': false,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

String _jwt(Object? userId) {
  String b64(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${b64({'alg': 'HS256'})}.${b64({'user_id': userId})}.sig';
}

void main() {
  late _CountingAdapter adapter;
  var token = _jwt('u1');
  var tenant = 't1';
  var session = 'u1|t1';

  HttpSyncTransport make() => HttpSyncTransport.create(
    baseUrl: 'https://example.test/',
    readAccessToken: () async => token,
    readTenantId: () async => tenant,
    readSessionKey: () async => session,
    adapter: adapter,
  );

  setUp(() {
    adapter = _CountingAdapter();
    token = _jwt('u1');
    tenant = 't1';
    session = 'u1|t1';
  });

  Future<void> expectRefused() async {
    final before = adapter.sent;
    await expectLater(
      make().pull(scope: 'u1|t1'),
      throwsA(
        isA<SyncTransportException>().having(
          (e) => e.kind,
          'kind',
          SyncTransportKind.scopeChanged,
        ),
      ),
    );
    expect(adapter.sent, before, reason: 'nothing reached the network');
  }

  test('everything matches: the request goes out', () async {
    await make().pull(scope: 'u1|t1');
    expect(adapter.sent, 1);
  });

  test('live session switched: refused', () async {
    session = 'u1|t2';
    await expectRefused();
  });

  test('tenant header switched (token not yet): refused', () async {
    tenant = 't2';
    await expectRefused();
  });

  test('bearer of another user of the same tenant: refused', () async {
    token = _jwt('u2');
    await expectRefused();
  });

  test('undecodable token: refused', () async {
    token = 'not-a-jwt';
    await expectRefused();
    token = 'a.%%%.c';
    await expectRefused();
    token = _jwt(null);
    await expectRefused();
  });
}
