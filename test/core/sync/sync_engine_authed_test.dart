import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/bootstrap_harness.dart';

SyncTransportException _expired() =>
    SyncTransportException(kind: SyncTransportKind.tokenExpired);

/// Pull transport that fails the first [failures] pulls with token expiry.
class _FlakyPull extends BootTransport {
  _FlakyPull(super.inner, this.failures);
  int failures;
  int pulls = 0;

  @override
  Future<PullResponse> pull({
    String? cursor,
    int limit = 500,
    required String scope,
  }) {
    pulls++;
    if (failures > 0) {
      failures--;
      throw _expired();
    }
    return super.pull(cursor: cursor, limit: limit, scope: scope);
  }
}

/// Pull script: call 1 and 3 fail with token expiry; call 2 succeeds with
/// has_more so a third call follows inside the same syncNow.
class _ScriptedPull extends BootTransport {
  _ScriptedPull(super.inner);
  int pulls = 0;

  @override
  Future<PullResponse> pull({
    String? cursor,
    int limit = 500,
    required String scope,
  }) async {
    pulls++;
    if (pulls == 1 || pulls == 3) throw _expired();
    return PullResponse(
      serverTime: DateTime.utc(2026, 11, 16, 12),
      changes: const [],
      nextCursor: 'c$pulls',
      hasMore: true,
    );
  }
}

void main() {
  late BootHarness h;

  setUp(() async {
    h = await BootHarness.create();
  });

  group('authedFor shares one refresh budget with _authed', () {
    test('authedFor: one token_expired refreshes once and succeeds', () async {
      final engine = h.buildEngine();
      final call = engine.authedFor(BootHarness.scope);
      var n = 0;
      final r = await call(() async {
        if (n++ == 0) throw _expired();
        return 'ok';
      });
      expect(r, 'ok');
      expect(h.refreshCalls, 1);
    });

    test('authedFor: a second 401 in a row does not refresh again', () async {
      final engine = h.buildEngine();
      final call = engine.authedFor(BootHarness.scope);
      var n = 0;
      await expectLater(
        call<String>(() async {
          n++;
          throw _expired();
        }),
        throwsA(isA<SyncTransportException>()),
      );
      expect(n, 2); // original + one retry
      expect(h.refreshCalls, 1);
    });

    test(
      'authedFor: refresh landing on another session -> scopeChanged',
      () async {
        final engine = h.buildEngine();
        final call = engine.authedFor(BootHarness.scope);
        h.onRefresh = () => h.liveScope = 'other|t';
        var n = 0;
        await expectLater(
          call<String>(() async {
            if (n++ == 0) throw _expired();
            return 'ok';
          }),
          throwsA(
            isA<SyncTransportException>().having(
              (e) => e.kind,
              'kind',
              SyncTransportKind.scopeChanged,
            ),
          ),
        );
        expect(n, 1); // never retried against the wrong session
      },
    );

    test('authedFor: rejected refresh -> SyncBlockedException', () async {
      final engine = h.buildEngine();
      h.refreshOutcome = RefreshOutcome.rejected;
      final call = engine.authedFor(BootHarness.scope);
      await expectLater(
        call<String>(() async => throw _expired()),
        throwsA(isA<SyncBlockedException>()),
      );
    });

    Future<void> primed(BootHarness x) async {
      await x.db.transaction((t) async {
        await x.scoped.setCursor(t, 'c0');
        await x.scoped.setBootstrapped(t, true);
      });
    }

    test('authed (engine budget): once per syncNow, then no more', () async {
      final flaky = _FlakyPull(h.server, 1);
      h.transport = flaky;
      await primed(h);
      final engine = h.buildEngine();
      await engine.syncNow();
      expect(h.refreshCalls, 1);
      expect(flaky.pulls, greaterThanOrEqualTo(2));

      // Two failures in one syncNow: only one refresh is allowed.
      final h2 = await BootHarness.create();
      final flaky2 = _FlakyPull(h2.server, 5);
      h2.transport = flaky2;
      await primed(h2);
      final e2 = h2.buildEngine();
      await e2.syncNow();
      expect(h2.refreshCalls, 1);
    });

    test(
      'authedFor: budget is restored by a success (second refresh)',
      () async {
        final engine = h.buildEngine();
        final call = engine.authedFor(BootHarness.scope);
        var n = 0;
        expect(
          await call(() async {
            if (n++ == 0) throw _expired();
            return 'a';
          }),
          'a',
        );
        expect(h.refreshCalls, 1);
        n = 0;
        expect(
          await call(() async {
            if (n++ == 0) throw _expired();
            return 'b';
          }),
          'b',
        );
        expect(h.refreshCalls, 2);
      },
    );

    test('authed (engine): no restore on success within one syncNow', () async {
      final scripted = _ScriptedPull(h.server);
      h.transport = scripted;
      await h.db.transaction((t) async {
        await h.scoped.setCursor(t, 'c0');
        await h.scoped.setBootstrapped(t, true);
      });
      final engine = h.buildEngine();
      await engine.syncNow();
      expect(scripted.pulls, 3); // 401, ok, 401 (not retried)
      expect(h.refreshCalls, 1);
    });
  });
}
