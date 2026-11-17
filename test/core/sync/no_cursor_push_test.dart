import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/engine_harness.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';

void main() {
  late EngineHarness h;

  setUp(() async {
    h = await EngineHarness.create();
    await h.state.clear(); // never bootstrapped: no cursor
  });
  tearDown(() => h.dispose());

  Future<List<String>> statuses() async => [
    for (final r in await h.db.query('outbox', orderBy: 'seq'))
      r['status']! as String,
  ];

  test('no cursor: pushes all pending, skips pull, needsBootstrap', () async {
    await h.createWidget('w1');
    await h.createWidget('w2');
    await h.createWidget('w3');
    final engine = h.build();
    expect(await engine.syncNow(), SyncOutcome.needsBootstrap);
    expect(await statuses(), ['done', 'done', 'done']);
    expect(h.transport.pushCalls, greaterThan(0));
    expect(h.transport.pullCalls, 0);
    expect(h.server.applied.length, 3);
    expect(await h.state.cursor(), isNull);
  });

  test('no cursor + server down: rows stay pending, backoff', () async {
    await h.createWidget('w1');
    h.server.down = true;
    final engine = h.build();
    expect(await engine.syncNow(), SyncOutcome.backoff);
    expect(await statuses(), ['pending']);
    expect(h.transport.pullCalls, 0);
  });

  test('no cursor + unauthorized push still blocks with needsLogin', () async {
    await h.createWidget('w1');
    h.transport.onBeforeSend = (op) async {
      if (op == 'push') {
        throw SyncTransportException(kind: SyncTransportKind.tokenExpired);
      }
    };
    final engine = h.build(refreshToken: () async => RefreshOutcome.rejected);
    expect(await engine.syncNow(), SyncOutcome.blocked);
    expect(engine.current.needsLogin, isTrue);
    expect(await statuses(), ['pending']);
    expect(h.transport.pullCalls, 0);
  });

  test('no cursor: scope switch mid-push still aborts the run', () async {
    await h.createWidget('w1');
    h.transport.onBeforeSend = (op) async {
      if (op == 'push') h.liveScope = 'u2|t1';
    };
    final engine = h.build();
    final out = await engine.syncNow();
    expect(out, isNot(SyncOutcome.completed));
    expect(h.transport.pullCalls, 0);
  });

  test('no cursor: cancel stops before pushing', () async {
    await h.createWidget('w1');
    final engine = h.build();
    h.transport.onBeforeSend = (op) async => engine.cancel();
    expect(await engine.syncNow(), SyncOutcome.cancelled);
    expect(h.transport.pullCalls, 0);
  });

  // Ruling T11-a: another user of the SAME tenant is bootstrapped (the gate
  // lets this user sell), but this scope has no cursor/flag of its own: its
  // outbox is pushed, nothing is pulled, the engine asks for its bootstrap.
  test('second user of a bootstrapped tenant: pushes, never pulls without '
      'its own bootstrap', () async {
    final first = h.state.forScope('u1|t1');
    await h.db.transaction((t) async {
      await first.setCursor(t, '1');
      await first.setBootstrapped(t, true);
    });
    expect(await h.state.isTenantBootstrapped('t1'), isTrue);
    h.activeScope = 'u2|t1';
    await h.createWidget('w1');
    final engine = h.build();
    expect(await engine.syncNow(), SyncOutcome.needsBootstrap);
    expect(await statuses(), ['done']);
    expect(h.transport.pullCalls, 0);
    expect(await h.state.forScope('u2|t1').cursor(), isNull);
  });
}
