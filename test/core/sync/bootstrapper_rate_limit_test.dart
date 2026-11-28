import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/bootstrap_harness.dart';

SyncTransportException _rateLimited(int? retryAfter) => SyncTransportException(
  kind: SyncTransportKind.server,
  httpStatus: 429,
  code: 'rate_limited',
  retryAfterSeconds: retryAfter,
);

void main() {
  late BootHarness h;
  setUp(() async => h = await BootHarness.create());
  tearDown(() async => h.dispose());

  test(
    'a 429 on a page waits Retry-After and the run still completes',
    () async {
      h.seedStandard();
      final waits = <Duration>[];
      var thrown = 0;
      h.transport.beforePage = (n, entity) async {
        if (n == 2 && thrown == 0) {
          thrown++;
          throw _rateLimited(7);
        }
      };
      final b = h.build(sleep: (d) async => waits.add(d));
      expect(await b.run(), BootstrapOutcome.completed);
      expect(waits, [const Duration(seconds: 7)]);
      expect(await h.ids('products'), ['p1', 'p2', 'p3', 'p4', 'p5']);
    },
  );

  test('no Retry-After header: backs off, never hammers', () async {
    h.seedStandard();
    final waits = <Duration>[];
    var thrown = 0;
    h.transport.beforePage = (n, entity) async {
      if (thrown < 2) {
        thrown++;
        throw _rateLimited(null);
      }
    };
    final b = h.build(sleep: (d) async => waits.add(d));
    expect(await b.run(), BootstrapOutcome.completed);
    expect(waits, hasLength(2));
    expect(waits[1], greaterThan(waits[0]));
  });

  test('a permanent 429 gives up (interrupted, resumable), bounded', () async {
    h.seedStandard();
    final waits = <Duration>[];
    h.transport.beforePage = (n, entity) async => throw _rateLimited(1);
    final b = h.build(sleep: (d) async => waits.add(d));
    expect(await b.run(), BootstrapOutcome.interrupted);
    expect(waits.length, lessThanOrEqualTo(Bootstrapper.maxRateLimitRetries));
    expect(await h.progress(), isNotNull); // resumable, nothing lost
  });
}
