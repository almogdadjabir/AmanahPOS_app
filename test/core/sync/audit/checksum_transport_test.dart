import 'dart:convert';
import 'dart:typed_data';

import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/transport/http_sync_transport.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_sync_server.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? last;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode({
        'entity': 'sale',
        'count': 3,
        'sum_total': '150.00',
        'sum_revenue': '100.00',
        'max_seq': '42',
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

void main() {
  test('fromJson parses strings, int max_seq and null sums', () {
    final r = ChecksumResponse.fromJson({
      'entity': 'sale',
      'count': 3,
      'sum_total': '150.00',
      'sum_revenue': '100.00',
      'max_seq': '42',
    });
    expect(r.count, 3);
    expect(r.sumTotal, '150.00');
    expect(r.sumRevenue, '100.00');
    expect(r.maxSeq, 42);
    final p = ChecksumResponse.fromJson({
      'entity': 'product',
      'count': 2,
      'sum_total': null,
      'max_seq': 7,
    });
    expect(p.sumTotal, isNull);
    expect(p.maxSeq, 7);
  });

  test('HttpSyncTransport.checksum sends entity and since', () async {
    final a = _Adapter();
    final t = HttpSyncTransport(
      Dio(BaseOptions(baseUrl: 'https://example.test/'))..httpClientAdapter = a,
    );
    final r = await t.checksum(entity: 'sale', sinceDays: 7, scope: 'u|t');
    expect(r.count, 3);
    expect(a.last!.method, 'GET');
    expect(a.last!.path, 'api/v1/sync/checksum/');
    expect(a.last!.queryParameters, {'entity': 'sale', 'since': 7});
  });

  test('fake server totals follow BE rules', () async {
    final s = FakeSyncServer();
    final now = DateTime.now().toUtc();
    void sale(String id, String status, String net, DateTime at) =>
        s.seedRow('sale', {
          'id': id,
          'status': status,
          'net_amount': net,
          'created_at': at.toIso8601String(),
        });
    sale('a', 'completed', '100.00', now);
    sale('b', 'cancelled', '50.00', now);
    sale('c', 'completed', '9.00', now.subtract(const Duration(days: 30)));
    final r = await s.checksum(entity: 'sale', sinceDays: 7, scope: 'x');
    expect(r.count, 2);
    expect(r.sumTotal, '150.00');
    expect(r.sumRevenue, '100.00');
    expect(s.checksumCalls, 1);
  });
}
