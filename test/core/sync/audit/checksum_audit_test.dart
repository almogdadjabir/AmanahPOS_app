import 'package:amana_pos/core/sync/audit/checksum_audit.dart';
import 'package:amana_pos/core/sync/audit/checksum_repair.dart';
import 'package:amana_pos/core/sync/audit/local_checksum_queries.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sale_applier_test.dart' show feedSale;
import '../support/bootstrap_harness.dart';

String _id(int i) => '55555555-5555-4555-8555-${i.toString().padLeft(12, '0')}';

void main() {
  late BootHarness h;
  late ChecksumAudit audit;
  var parityCalls = 0;
  var parityThrows = false;
  var idle = true;
  var caps = {'checksum'};
  String? scope = BootHarness.scope;

  setUp(() async {
    h = await BootHarness.create();
    h.server.bootstrapEntities = ['sale', 'refund', 'stock'];
    idle = true;
    caps = {'checksum'};
    scope = BootHarness.scope;
    final authed = h.buildEngine().authedFor;
    audit = ChecksumAudit(
      transport: h.transport,
      local: LocalChecksumQueries(h.odb),
      repair: ChecksumRepair(
        db: h.odb,
        transport: h.transport,
        appliers: h.registry,
        notifier: h.notifier,
        authedFor: authed,
        assertScope: () async {},
      ),
      state: h.state,
      notifier: h.notifier,
      authedFor: authed,
      scopeProvider: () => scope,
      idle: () async => idle,
      capabilities: () async => caps,
      now: h.now,
      debugParity: () async {
        parityCalls++;
        if (parityThrows) throw StateError('parity boom');
      },
    );
    parityCalls = 0;
    parityThrows = false;
  });
  tearDown(() async => h.dispose());

  void serverSale(int i, {String received = '2026-11-16T08:05:00Z'}) {
    h.server.seedRow(
      'sale',
      feedSale(id: _id(i))
        ..['received_at'] = received
        ..['created_at'] = received,
    );
  }

  Future<void> localSale(
    int i, {
    String sync = 'synced',
    String received = '2026-11-16T08:05:00Z',
    String net = '7.50',
  }) => h.db.insert('sales', {
    'id': _id(i),
    'shop_id': 's',
    'status': 'completed',
    'subtotal': net,
    'discount': '0',
    'tax_amount': '0',
    'net_amount': net,
    'occurred_at': received,
    'received_at': received,
    'sync_state': sync,
  });

  Future<void> syncedBoth(int n) async {
    for (var i = 1; i <= n; i++) {
      serverSale(i);
      await localSale(i);
    }
  }

  test(
    'match -> ok, state ok, throttled second call, force bypasses',
    () async {
      await syncedBoth(2);
      expect(await audit.maybeRun(), AuditRun.ok);
      final st = h.state.forScope(BootHarness.scope);
      expect((await st.auditState())!.status, 'ok');
      final calls = h.server.checksumCalls;
      expect(await audit.maybeRun(), AuditRun.skipped);
      expect(h.server.checksumCalls, calls);
      expect(await audit.maybeRun(force: true), AuditRun.ok);
    },
  );

  test('pending and rejected local rows never cause a mismatch (1)', () async {
    await syncedBoth(2);
    await localSale(90, sync: 'pending', net: '999.00');
    await localSale(91, sync: 'rejected', net: '888.00');
    expect(await audit.maybeRun(), AuditRun.ok);
  });

  test('a synced row at the window edge is inconclusive (2)', () async {
    await syncedBoth(1);
    // cutoff = 2026-11-09T12:00; row 2 min after it, on both sides.
    serverSale(5, received: '2026-11-09T12:02:00Z');
    await localSale(5, received: '2026-11-09T12:02:00Z');
    final repairBefore = h.transport.pageRequests.length;
    expect(await audit.maybeRun(), AuditRun.inconclusive);
    expect(h.transport.pageRequests.length, repairBefore);
    // No ok/drift state was written (the retry back-off only moves the
    // throttle).
    expect(await h.state.forScope(BootHarness.scope).auditState(), isNull);
  });

  test('server moving during the audit is inconclusive (3)', () async {
    await syncedBoth(1);
    h.transport.beforePage = null;
    var n = 0;
    h.server.onChecksum = () {
      if (++n == 2) serverSale(77, received: '2026-11-16T09:00:00Z');
    };
    expect(await audit.maybeRun(), AuditRun.inconclusive);
  });

  test('server has an extra sale -> repaired', () async {
    await syncedBoth(2);
    serverSale(3);
    expect(await audit.maybeRun(), AuditRun.repaired);
    expect(await h.ids('sales'), [_id(1), _id(2), _id(3)]);
    expect(
      (await h.state.forScope(BootHarness.scope).auditState())!.status,
      'ok',
    );
  });

  test('local surplus synced sale -> drift, row kept (4)', () async {
    await syncedBoth(2);
    await localSale(9); // synced locally, absent on the server
    expect(await audit.maybeRun(), AuditRun.drift);
    final s = (await h.state.forScope(BootHarness.scope).auditState())!;
    expect(s.isDrift, isTrue);
    expect(s.detail['sale']['localCount'], 3);
    expect(s.detail['sale']['serverCount'], 2);
    expect(await h.ids('sales'), contains(_id(9)));
  });

  test('not idle, no capability, no scope -> skipped', () async {
    await syncedBoth(1);
    idle = false;
    expect(await audit.maybeRun(), AuditRun.skipped);
    idle = true;
    caps = {};
    expect(await audit.maybeRun(), AuditRun.skipped);
    caps = {'checksum'};
    scope = null;
    expect(await audit.maybeRun(), AuditRun.skipped);
    expect(await h.state.forScope(BootHarness.scope).auditState(), isNull);
  });

  test('transport error -> skipped, no state written', () async {
    await syncedBoth(1);
    h.server.down = true;
    expect(await audit.maybeRun(), AuditRun.skipped);
    expect(await h.state.forScope(BootHarness.scope).auditState(), isNull);
  });

  test('scope switched during the run writes nothing (5)', () async {
    await syncedBoth(1);
    h.server.onChecksum = () => scope = 'other|t1';
    expect(await audit.maybeRun(), AuditRun.skipped);
    expect(await h.state.forScope(BootHarness.scope).auditState(), isNull);
  });

  test('debug parity runs on match and never breaks the audit', () async {
    await syncedBoth(1);
    expect(await audit.maybeRun(), AuditRun.ok);
    expect(parityCalls, 1);
    parityThrows = true;
    expect(await audit.maybeRun(force: true), AuditRun.ok);
    expect(parityCalls, 2);
  });

  test('FINAL: a null server sum is not a mismatch', () async {
    await syncedBoth(1);
    h.server.nullSums = true;
    expect(await audit.maybeRun(), AuditRun.ok);
  });

  test(
    'FINAL: inconclusive / failed attempts back off 15 min, not 6 h',
    () async {
      await syncedBoth(1);
      serverSale(5, received: '2026-11-09T12:02:00Z'); // edge -> inconclusive
      await localSale(5, received: '2026-11-09T12:02:00Z');
      expect(await audit.maybeRun(), AuditRun.inconclusive);
      final calls = h.server.checksumCalls;
      expect(await audit.maybeRun(), AuditRun.skipped); // inside 15 min
      expect(h.server.checksumCalls, calls);
      h.advance(const Duration(minutes: 16));
      expect(await audit.maybeRun(), isNot(AuditRun.skipped)); // retried
      expect(h.server.checksumCalls, greaterThan(calls));
    },
  );
}
