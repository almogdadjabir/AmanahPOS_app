import 'dart:convert';

import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> pushJson() => {
    'server_time': '2026-11-16T10:00:02Z',
    'next_cursor': 'c1',
    'results': [
      {
        'mutation_id': 'm1',
        'status': 'applied',
        'entity_id': 'e1',
        'version': 8,
        'server_seq': 123456,
        'warnings': ['negative_stock'],
        'stock_after': [
          {'product_id': 'p1', 'shop_id': 's1', 'quantity': '-2.500'},
        ],
      },
      {'mutation_id': 'm2', 'status': 'duplicate'},
      {
        'mutation_id': 'm3',
        'status': 'rejected',
        'code': 'conflict_version',
        'message': 'stale',
        'server_state': {'id': 'e3', 'version': 9},
      },
      {'mutation_id': 'm4', 'status': 'retry', 'code': 'server_busy'},
    ],
  };

  test('PushResponse parses all four statuses and extras', () {
    final r = PushResponse.fromJson(pushJson());
    expect(r.serverTime, DateTime.utc(2026, 11, 16, 10, 0, 2));
    expect(r.nextCursor, 'c1');
    expect(r.results.map((e) => e.status), PushStatus.values);
    final a = r.results[0];
    expect(a.version, 8);
    expect(a.serverSeq, 123456);
    expect(a.warnings, ['negative_stock']);
    expect(a.stockAfter.single.quantity, '-2.500');
    expect(a.stockAfter.single.productId, 'p1');
    expect(a.stockAfter.single.shopId, 's1');
    expect(r.results[1].warnings, isEmpty);
    expect(r.results[1].stockAfter, isEmpty);
    expect(r.results[2].serverState, {'id': 'e3', 'version': 9});
    expect(r.results[2].code, 'conflict_version');
    expect(r.results[3].code, 'server_busy');
  });

  test('PushResponse round-trips through toJson', () {
    final r = PushResponse.fromJson(pushJson());
    final again = PushResponse.fromJson(
      jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>,
    );
    expect(jsonEncode(again.toJson()), jsonEncode(r.toJson()));
  });

  test('unknown status throws FormatException', () {
    expect(
      () => PushResult.fromJson({'mutation_id': 'x', 'status': 'weird'}),
      throwsFormatException,
    );
  });

  test('PingResponse without capabilities -> empty set', () {
    final p = PingResponse.fromJson({
      'ok': true,
      'server_time': '2026-11-16T10:00:00Z',
    });
    expect(p.capabilities, isEmpty);
    expect(p.maintenance, false);
    expect(p.retryAfterSeconds, isNull);
  });

  test('PingResponse full + round trip', () {
    final p = PingResponse.fromJson({
      'ok': true,
      'server_time': '2026-11-16T10:00:00Z',
      'min_app_version': '1.2.0',
      'latest_app_version': '1.4.0',
      'maintenance': true,
      'retry_after': 30,
      'capabilities': ['sync_push', 'sync_pull'],
    });
    expect(p.minAppVersion, '1.2.0');
    expect(p.retryAfterSeconds, 30);
    expect(p.capabilities, {'sync_push', 'sync_pull'});
    final again = PingResponse.fromJson(p.toJson());
    expect(again.capabilities, p.capabilities);
    expect(again.maintenance, true);
  });

  test('PullResponse full_resync_required and changes', () {
    final r = PullResponse.fromJson({
      'server_time': '2026-11-16T10:00:00Z',
      'changes': [
        {
          'seq': 1001,
          'entity': 'product',
          'op': 'upsert',
          'id': 'u1',
          'version': 8,
          'data': {'name': 'x'},
          'origin_device_id': 'd1',
        },
        {'seq': 1002, 'entity': 'category', 'op': 'delete', 'id': 'u2'},
      ],
      'next_cursor': 'n',
      'has_more': true,
      'full_resync_required': true,
    });
    expect(r.fullResyncRequired, true);
    expect(r.hasMore, true);
    expect(r.changes[0].originDeviceId, 'd1');
    expect(r.changes[1].data, isNull);
    final again = PullResponse.fromJson(
      jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>,
    );
    expect(again.changes.length, 2);
    expect(again.nextCursor, 'n');
  });

  test('PullResponse flags default to false', () {
    final r = PullResponse.fromJson({
      'server_time': '2026-11-16T10:00:00Z',
      'changes': [],
      'next_cursor': 'n',
    });
    expect(r.hasMore, false);
    expect(r.fullResyncRequired, false);
  });

  test('buildPushRequestJson uses wire keys', () {
    final e = OutboxEntry(
      seq: 12,
      mutationId: 'm1',
      entity: 'product',
      op: 'update',
      entityId: 'e1',
      baseVersion: 7,
      occurredAt: DateTime.utc(2026, 11, 16, 9, 41, 12),
      payload: {'name': 'شاي'},
    );
    final j = buildPushRequestJson(
      deviceId: 'dev',
      appVersion: '1.4.0',
      clientTime: DateTime.utc(2026, 11, 16, 10),
      mutations: [e],
    );
    expect(j['device_id'], 'dev');
    expect(j['app_version'], '1.4.0');
    expect(j['client_time'], '2026-11-16T10:00:00.000Z');
    final m = (j['mutations'] as List).single as Map;
    expect(m, {
      'mutation_id': 'm1',
      'seq': 12,
      'entity': 'product',
      'op': 'update',
      'entity_id': 'e1',
      'base_version': 7,
      'occurred_at': '2026-11-16T09:41:12.000Z',
      'payload': {'name': 'شاي'},
    });
  });

  test('SyncTransportException toString carries kind', () {
    final e = SyncTransportException(
      kind: SyncTransportKind.server,
      httpStatus: 503,
    );
    expect(e.toString(), contains('server'));
  });

  group('PushResult extended keys', () {
    test('applied with receipt_number', () {
      final r = PushResult.fromJson({
        'mutation_id': 'm',
        'status': 'applied',
        'receipt_number': 'R-1',
        'occurred_at_suspect': true,
        'refund_reference': 'ref',
        'refund_total': 12.5,
        'invite_sent': true,
      });
      expect(r.receiptNumber, 'R-1');
      expect(r.occurredAtSuspect, true);
      expect(r.refundReference, 'ref');
      expect(r.refundTotal, '12.5');
      expect(r.inviteSent, true);
      expect(r.merged, false);
      expect(r.dependsOn, isEmpty);
    });
    test('conflict_unique with conflict_entity_id + server_state', () {
      final r = PushResult.fromJson({
        'mutation_id': 'm',
        'status': 'rejected',
        'code': 'conflict_unique',
        'conflict_entity_id': 'c1',
        'server_state': {'id': 'c1'},
      });
      expect(r.conflictEntityId, 'c1');
      expect(r.serverState, {'id': 'c1'});
    });
    test('dependency_failed with depends_on', () {
      final r = PushResult.fromJson({
        'mutation_id': 'm',
        'status': 'rejected',
        'code': 'dependency_failed',
        'depends_on': ['a', 'b'],
      });
      expect(r.dependsOn, ['a', 'b']);
    });
    test('validation_error with errors map', () {
      final r = PushResult.fromJson({
        'mutation_id': 'm',
        'status': 'rejected',
        'code': 'validation_error',
        'errors': {
          'name': ['required'],
        },
      });
      expect(r.errors, {
        'name': ['required'],
      });
    });
    test('merged true and unknown extra preserved, round trip', () {
      final src = {
        'mutation_id': 'm',
        'status': 'applied',
        'merged': true,
        'future_key': {'a': 1},
      };
      final r = PushResult.fromJson(src);
      expect(r.merged, true);
      expect(r.extra, {
        'future_key': {'a': 1},
      });
      final back = PushResult.fromJson(
        jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>,
      );
      expect(back.merged, true);
      expect(back.extra, {
        'future_key': {'a': 1},
      });
      expect(back.toJson()['future_key'], {'a': 1});
    });
    test('malformed typed fields -> FormatException', () {
      for (final bad in [
        {'merged': 'yes'},
        {'receipt_number': 5},
        {'depends_on': 'x'},
        {
          'depends_on': [1],
        },
        {'errors': []},
        {'invite_sent': 'y'},
        {'refund_total': true},
        {'occurred_at_suspect': 1},
        {'conflict_entity_id': 3},
      ]) {
        expect(
          () => PushResult.fromJson({
            'mutation_id': 'm',
            'status': 'applied',
            ...bad,
          }),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });
    test('PullChange shop_id', () {
      final c = PullChange.fromJson({
        'seq': 1,
        'entity': 'stock',
        'op': 'upsert',
        'id': 'i',
        'shop_id': 's',
      });
      expect(c.shopId, 's');
      expect(c.toJson()['shop_id'], 's');
    });
  });

  group('malformed input -> FormatException', () {
    const t = '2026-11-16T10:00:00Z';
    test('missing mutation_id', () {
      expect(
        () => PushResult.fromJson({'status': 'applied'}),
        throwsFormatException,
      );
    });
    test('results not a list', () {
      expect(
        () => PushResponse.fromJson({'server_time': t, 'results': 'x'}),
        throwsFormatException,
      );
    });
    test('result element not an object', () {
      expect(
        () => PushResponse.fromJson({
          'server_time': t,
          'results': [1],
        }),
        throwsFormatException,
      );
    });
    test('PullChange missing seq / entity', () {
      expect(
        () => PullChange.fromJson({'entity': 'a', 'op': 'upsert', 'id': 'i'}),
        throwsFormatException,
      );
      expect(
        () => PullChange.fromJson({'seq': 1, 'op': 'upsert', 'id': 'i'}),
        throwsFormatException,
      );
    });
    test('PullResponse missing next_cursor', () {
      expect(
        () => PullResponse.fromJson({'server_time': t, 'changes': []}),
        throwsFormatException,
      );
    });
    test('PingResponse missing server_time', () {
      expect(() => PingResponse.fromJson({'ok': true}), throwsFormatException);
    });
    test('StockAfter quantity null / wrong type / number', () {
      expect(
        () => StockAfter.fromJson({
          'product_id': 'p',
          'shop_id': 's',
          'quantity': null,
        }),
        throwsFormatException,
      );
      expect(
        () => StockAfter.fromJson({
          'product_id': 'p',
          'shop_id': 's',
          'quantity': true,
        }),
        throwsFormatException,
      );
      expect(
        () => StockAfter.fromJson({'product_id': 'p', 'shop_id': 's'}),
        throwsFormatException,
      );
      expect(
        StockAfter.fromJson({
          'product_id': 'p',
          'shop_id': 's',
          'quantity': 3,
        }).quantity,
        '3',
      );
    });
    test('bad date string', () {
      expect(
        () => PingResponse.fromJson({'ok': true, 'server_time': 'nope'}),
        throwsFormatException,
      );
    });
    test('wrong-typed optional field', () {
      expect(
        () => PushResult.fromJson({
          'mutation_id': 'm',
          'status': 'applied',
          'version': 'x',
        }),
        throwsFormatException,
      );
    });
  });

  test('SyncTransportKind has exactly the 9 values', () {
    expect(SyncTransportKind.values.map((e) => e.name).toList(), [
      'network',
      'timeout',
      'server',
      'unauthorized',
      'tokenExpired',
      'accountDisabled',
      'deviceRevoked',
      'tooLarge',
      'maintenance',
    ]);
  });

  test('SyncTransport.pull default limit is 500', () async {
    final tr = _Spy();
    await tr.pull();
    expect(tr.lastLimit, 500);
  });
}

class _Spy implements SyncTransport {
  int? lastLimit;
  @override
  Future<PingResponse> ping() => throw UnimplementedError();
  @override
  Future<PushResponse> push({
    required String deviceId,
    required String appVersion,
    required List<OutboxEntry> mutations,
  }) => throw UnimplementedError();
  @override
  Future<PullResponse> pull({String? cursor, int limit = 500}) async {
    lastLimit = limit;
    return PullResponse(
      serverTime: DateTime.utc(2026),
      changes: const [],
      nextCursor: 'c',
    );
  }
}
