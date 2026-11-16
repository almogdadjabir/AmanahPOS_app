import 'dart:async';

import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_sync_server.dart';

class _CountingTransport implements SyncTransport {
  _CountingTransport(this.inner);
  final SyncTransport inner;
  int pings = 0;

  @override
  Future<PingResponse> ping() {
    pings++;
    return inner.ping();
  }

  @override
  Future<PushResponse> push({
    required String deviceId,
    required String appVersion,
    required List<OutboxEntry> mutations,
  }) => inner.push(
    deviceId: deviceId,
    appVersion: appVersion,
    mutations: mutations,
  );

  @override
  Future<PullResponse> pull({String? cursor, int limit = 500}) =>
      inner.pull(cursor: cursor, limit: limit);
}

void main() {
  late DateTime clock;
  late FakeSyncServer server;
  late _CountingTransport transport;

  setUp(() {
    clock = DateTime.utc(2026, 1, 1, 12);
    server = FakeSyncServer(deviceId: 'd1', now: () => clock);
    transport = _CountingTransport(server);
  });

  ServerReachability make() => ServerReachability(transport, now: () => clock);

  test('caches within ttl, force bypasses, expires after ttl', () async {
    final r = make();
    expect(await r.check(), isNotNull);
    expect(await r.check(), isNotNull);
    expect(transport.pings, 1);
    await r.check(force: true);
    expect(transport.pings, 2);
    clock = clock.add(const Duration(seconds: 16));
    await r.check();
    expect(transport.pings, 3);
  });

  test('failure flips isReachable immediately and emits once', () async {
    final r = make();
    await r.check();
    expect(r.isReachable, isTrue);
    final events = <bool>[];
    final sub = r.changes.listen(events.add);
    r.reportFailure();
    r.reportFailure();
    await Future<void>.delayed(Duration.zero);
    expect(r.isReachable, isFalse);
    expect(events, [false]);
    r.reportSuccess();
    await Future<void>.delayed(Duration.zero);
    expect(events, [false, true]);
    await sub.cancel();
  });

  test('transport exception means unreachable, never rethrown', () async {
    server.down = true;
    final r = make();
    expect(await r.check(), isNull);
    expect(r.isReachable, isFalse);
    expect(r.lastPing, isNull);
  });

  test('cached unreachable result is also cached within ttl', () async {
    server.down = true;
    final r = make();
    await r.check();
    await r.check();
    expect(transport.pings, 1);
  });

  test('skew with device clock 3h behind server', () async {
    server.clockSkew = const Duration(hours: 3);
    final r = make();
    await r.check();
    expect(r.clockSkew, const Duration(hours: 3));
    expect(r.lastPing, isNotNull);
  });

  test('skew uses round trip midpoint', () async {
    // Server time equals device time at response end; request started 10s
    // earlier so midpoint is 5s before server time => skew +5s.
    var calls = 0;
    final t = _SlowTransport(() {
      clock = clock.add(const Duration(seconds: 10));
      return PingResponse(ok: true, serverTime: clock);
    });
    final r = ServerReachability(
      t,
      now: () {
        calls++;
        return clock;
      },
    );
    await r.check();
    expect(r.clockSkew, const Duration(seconds: 5));
    expect(calls, greaterThanOrEqualTo(2));
  });

  test('any exception from ping means unreachable and recovers', () async {
    for (final err in <Object>[StateError('x'), TimeoutException('t')]) {
      var fail = true;
      final t = _SlowTransport(() {
        if (fail) throw err;
        return PingResponse(ok: true, serverTime: clock);
      });
      final r = ServerReachability(t, now: () => clock);
      expect(await r.check(), isNull);
      expect(r.isReachable, isFalse);
      fail = false;
      expect(await r.check(force: true), isNotNull);
      expect(r.isReachable, isTrue);
    }
  });

  test('concurrent checks share one ping; next check pings again', () async {
    final r = make();
    final res = await Future.wait([r.check(), r.check(), r.check()]);
    expect(transport.pings, 1);
    expect(res.every((e) => e != null), isTrue);
    server.down = true;
    await r.check(force: true);
    expect(transport.pings, 2);
    server.down = false;
    expect(await r.check(force: true), isNotNull);
    expect(transport.pings, 3);
  });

  test('ping with ok false is unreachable', () async {
    final t = _SlowTransport(() => PingResponse(ok: false, serverTime: clock));
    final r = ServerReachability(t, now: () => clock);
    expect(await r.check(), isNull);
    expect(r.isReachable, isFalse);
  });

  test('dispose closes changes and is idempotent', () async {
    final r = make();
    var done = false;
    r.changes.listen((_) {}, onDone: () => done = true);
    await r.dispose();
    await r.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(done, isTrue);
    r.reportFailure();
    await r.check(force: true);
  });
}

class _SlowTransport implements SyncTransport {
  _SlowTransport(this.onPing);
  final PingResponse Function() onPing;

  @override
  Future<PingResponse> ping() async => onPing();

  @override
  Future<PushResponse> push({
    required String deviceId,
    required String appVersion,
    required List<OutboxEntry> mutations,
  }) => throw UnimplementedError();

  @override
  Future<PullResponse> pull({String? cursor, int limit = 500}) =>
      throw UnimplementedError();
}
