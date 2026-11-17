import 'dart:convert';
import 'dart:typed_data';

import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/transport/http_sync_transport.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_server.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? last;
  int sent = 0;
  int status = 200;
  Object body = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    sent++;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _scope = 'u1|t1';

String _jwt(Object? userId) {
  String b64(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${b64({'alg': 'HS256'})}.${b64({'user_id': userId})}.sig';
}

void main() {
  group('DTOs', () {
    test('BootstrapManifest round trip', () {
      final j = {
        'server_time': '2026-11-16T10:00:00Z',
        'entities': ['business', 'shop'],
        'snapshot_cursor': 'snap',
      };
      final m = BootstrapManifest.fromJson(j);
      expect(m.entities, ['business', 'shop']);
      expect(m.snapshotCursor, 'snap');
      expect(m.serverTime, DateTime.utc(2026, 11, 16, 10));
      final back = BootstrapManifest.fromJson(m.toJson());
      expect(back.entities, m.entities);
      expect(back.snapshotCursor, 'snap');
    });

    test(
      'BootstrapManifest rejects missing snapshot_cursor / bad entities',
      () {
        expect(
          () => BootstrapManifest.fromJson({
            'server_time': '2026-11-16T10:00:00Z',
            'entities': <String>[],
          }),
          throwsFormatException,
        );
        expect(
          () => BootstrapManifest.fromJson({
            'server_time': '2026-11-16T10:00:00Z',
            'entities': [1],
            'snapshot_cursor': 's',
          }),
          throwsFormatException,
        );
      },
    );

    final pageJson = {
      'server_time': '2026-11-16T10:00:00Z',
      'entity': 'product',
      'snapshot_cursor': 'snap',
      'items': [
        {'id': 'p1', 'price': '10.50'},
      ],
      'has_more': true,
      'next_page_cursor': 'n1',
    };

    test('BootstrapPage round trip keeps money strings', () {
      final p = BootstrapPage.fromJson(pageJson);
      expect(p.entity, 'product');
      expect(p.items.single['price'], '10.50');
      expect(p.hasMore, isTrue);
      expect(p.nextPageCursor, 'n1');
      final back = BootstrapPage.fromJson(p.toJson());
      expect(back.items, p.items);
      expect(back.snapshotCursor, 'snap');
    });

    test('BootstrapPage rejects missing items', () {
      final j = Map<String, dynamic>.from(pageJson)..remove('items');
      expect(() => BootstrapPage.fromJson(j), throwsFormatException);
    });

    test('BootstrapPage rejects non-object item and missing entity', () {
      expect(
        () => BootstrapPage.fromJson({
          ...pageJson,
          'items': ['x'],
        }),
        throwsFormatException,
      );
      final j = Map<String, dynamic>.from(pageJson)..remove('entity');
      expect(() => BootstrapPage.fromJson(j), throwsFormatException);
    });

    test('BootstrapPage last page: no cursor', () {
      final p = BootstrapPage.fromJson({
        ...pageJson,
        'has_more': false,
        'next_page_cursor': null,
      });
      expect(p.hasMore, isFalse);
      expect(p.nextPageCursor, isNull);
    });
  });

  group('HttpSyncTransport bootstrap', () {
    late _Adapter adapter;
    late HttpSyncTransport transport;
    var session = _scope;

    setUp(() {
      adapter = _Adapter();
      session = _scope;
      transport = HttpSyncTransport.create(
        baseUrl: 'https://example.test/',
        readAccessToken: () async => _jwt('u1'),
        readTenantId: () async => 't1',
        readSessionKey: () async => session,
        adapter: adapter,
      );
    });

    test('manifest: no entity param, path and parse', () async {
      adapter.body = {
        'server_time': '2026-11-16T10:00:00Z',
        'entities': ['business'],
        'snapshot_cursor': 's',
      };
      final m = await transport.bootstrapManifest(scope: _scope);
      expect(adapter.last!.path, 'api/v1/sync/bootstrap/');
      expect(adapter.last!.queryParameters, isEmpty);
      expect(m.snapshotCursor, 's');
    });

    test(
      'page sends entity, page_cursor, limit, snapshot_cursor, sales_since',
      () async {
        adapter.body = {
          'server_time': '2026-11-16T10:00:00Z',
          'entity': 'sale',
          'snapshot_cursor': 's',
          'items': <Object>[],
          'has_more': false,
          'next_page_cursor': null,
        };
        await transport.bootstrapPage(
          entity: 'sale',
          pageCursor: 'pc',
          limit: 200,
          snapshotCursor: 's',
          salesSinceDays: 90,
          scope: _scope,
        );
        expect(adapter.last!.path, 'api/v1/sync/bootstrap/');
        expect(adapter.last!.queryParameters, {
          'entity': 'sale',
          'page_cursor': 'pc',
          'limit': 200,
          'snapshot_cursor': 's',
          'sales_since': 90,
        });
      },
    );

    test('page omits null cursors', () async {
      adapter.body = {
        'server_time': '2026-11-16T10:00:00Z',
        'entity': 'shop',
        'snapshot_cursor': 's',
        'items': <Object>[],
        'has_more': false,
      };
      await transport.bootstrapPage(entity: 'shop', scope: _scope);
      final q = adapter.last!.queryParameters;
      expect(q.containsKey('page_cursor'), isFalse);
      expect(q.containsKey('snapshot_cursor'), isFalse);
      expect(q['limit'], 500);
      expect(q['sales_since'], 90);
    });

    test('401 typed codes map like pull', () async {
      for (final c in {
        'token_expired': SyncTransportKind.tokenExpired,
        'account_disabled': SyncTransportKind.accountDisabled,
        'device_revoked': SyncTransportKind.deviceRevoked,
        'token_invalid': SyncTransportKind.unauthorized,
      }.entries) {
        adapter.status = 401;
        adapter.body = {
          'error': {'code': c.key},
        };
        await expectLater(
          transport.bootstrapPage(entity: 'shop', scope: _scope),
          throwsA(
            isA<SyncTransportException>().having(
              (e) => e.kind,
              'kind',
              c.value,
            ),
          ),
        );
        await expectLater(
          transport.bootstrapManifest(scope: _scope),
          throwsA(
            isA<SyncTransportException>().having(
              (e) => e.kind,
              'kind',
              c.value,
            ),
          ),
        );
      }
    });

    test('scope mismatch refused, nothing sent', () async {
      session = 'u2|t1';
      await expectLater(
        transport.bootstrapPage(entity: 'shop', scope: _scope),
        throwsA(
          isA<SyncTransportException>().having(
            (e) => e.kind,
            'kind',
            SyncTransportKind.scopeChanged,
          ),
        ),
      );
      await expectLater(
        transport.bootstrapManifest(scope: _scope),
        throwsA(isA<SyncTransportException>()),
      );
      expect(adapter.sent, 0);
    });

    test('malformed page (no items) -> server malformed_response', () async {
      adapter.body = {
        'server_time': '2026-11-16T10:00:00Z',
        'entity': 'shop',
        'snapshot_cursor': 's',
        'has_more': false,
      };
      await expectLater(
        transport.bootstrapPage(entity: 'shop', scope: _scope),
        throwsA(
          isA<SyncTransportException>().having(
            (e) => e.code,
            'code',
            'malformed_response',
          ),
        ),
      );
    });
  });

  group('FakeSyncServer bootstrap', () {
    late FakeSyncServer server;

    setUp(() => server = FakeSyncServer());

    Future<List<BootstrapPage>> drain(String entity, {int limit = 2}) async {
      final pages = <BootstrapPage>[];
      String? cursor;
      String? snap;
      do {
        final p = await server.bootstrapPage(
          entity: entity,
          pageCursor: cursor,
          limit: limit,
          snapshotCursor: snap,
          scope: _scope,
        );
        pages.add(p);
        snap = p.snapshotCursor;
        cursor = p.nextPageCursor;
      } while (pages.last.hasMore);
      return pages;
    }

    test('5 rows / limit 2 -> 3 pages, each row once, same snapshot', () async {
      for (final id in ['e', 'a', 'c', 'b', 'd']) {
        server.seedRow('product', {'id': id, 'version': 1, 'price': '1.00'});
      }
      final pages = await drain('product');
      expect(pages.length, 3);
      expect(pages.map((p) => p.items.length), [2, 2, 1]);
      expect(pages.map((p) => p.hasMore), [true, true, false]);
      expect(pages.last.nextPageCursor, isNull);
      expect(pages.map((p) => p.snapshotCursor).toSet().length, 1);
      final ids = pages.expand((p) => p.items).map((i) => i['id']).toList();
      expect(ids, ['a', 'b', 'c', 'd', 'e']);
    });

    test('manifest snapshot equals page snapshot and counts calls', () async {
      server.seedRow('shop', {'id': 's1', 'version': 1});
      final m = await server.bootstrapManifest(scope: _scope);
      expect(server.bootstrapManifestCalls, 1);
      final p = await server.bootstrapPage(
        entity: 'shop',
        snapshotCursor: m.snapshotCursor,
        scope: _scope,
      );
      expect(p.snapshotCursor, m.snapshotCursor);
      expect(m.entities, contains('shop'));
    });

    test(
      'row seeded between pages is not paged but pull delivers it',
      () async {
        for (final id in ['a', 'b', 'c', 'd']) {
          server.seedRow('product', {'id': id, 'version': 1});
        }
        server.onBootstrapPage = (entity, pageIndex) {
          if (pageIndex == 0) {
            server.seedRow('product', {'id': 'zz', 'version': 1});
          }
        };
        final pages = await drain('product');
        final ids = pages.expand((p) => p.items).map((i) => i['id']).toList();
        expect(ids, ['a', 'b', 'c', 'd']);
        final r = await server.pull(
          cursor: pages.first.snapshotCursor,
          scope: _scope,
        );
        expect(r.changes.map((c) => c.id), ['zz']);
      },
    );

    test(
      'rows seeded before the snapshot are not redelivered by pull',
      () async {
        server.seedRow('product', {'id': 'a', 'version': 1});
        final pages = await drain('product');
        final r = await server.pull(
          cursor: pages.first.snapshotCursor,
          scope: _scope,
        );
        expect(r.changes, isEmpty);
      },
    );

    test('fault knobs apply to bootstrap calls', () async {
      server.down = true;
      await expectLater(
        server.bootstrapManifest(scope: _scope),
        throwsA(isA<SyncTransportException>()),
      );
      server.down = false;
      server.failNextWith = 'tokenExpired';
      await expectLater(
        server.bootstrapPage(entity: 'shop', scope: _scope),
        throwsA(
          isA<SyncTransportException>().having(
            (e) => e.kind,
            'kind',
            SyncTransportKind.tokenExpired,
          ),
        ),
      );
    });
  });
}
