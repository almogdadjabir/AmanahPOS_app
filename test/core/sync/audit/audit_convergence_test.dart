import 'dart:math';

import 'package:amana_pos/core/sync/audit/checksum_audit.dart';
import 'package:amana_pos/core/sync/audit/checksum_repair.dart';
import 'package:amana_pos/core/sync/audit/local_checksum_queries.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:flutter_test/flutter_test.dart';

import '../sale_applier_test.dart' show feedSale;
import '../support/bootstrap_harness.dart';

String _id(int i) => '55555555-5555-4555-8555-${i.toString().padLeft(12, '0')}';

/// Seeded: random server sales, a random subset present locally (missing
/// rows are repairable), sometimes a synced local surplus row (not
/// repairable). The audit must end `ok` for the first and `drift` for the
/// second, and never delete a local row or throw.
void main() {
  const seeds = int.fromEnvironment('CONV_SEEDS', defaultValue: 20);

  for (var seed = 1; seed <= seeds; seed++) {
    test('audit converges (seed $seed)', () async {
      final rnd = Random(seed);
      final h = await BootHarness.create();
      addTearDown(h.dispose);
      h.server.bootstrapEntities = ['sale', 'refund', 'stock'];
      final n = rnd.nextInt(9);
      final surplus = rnd.nextBool();
      final authed = h.buildEngine().authedFor;
      final audit = ChecksumAudit(
        transport: h.transport,
        local: LocalChecksumQueries(h.odb),
        repair: ChecksumRepair(
          db: h.odb,
          transport: h.transport,
          appliers: h.registry,
          notifier: h.notifier,
          authedFor: authed,
          assertScope: () async {},
          pageSize: 1 + rnd.nextInt(3),
        ),
        state: h.state,
        notifier: h.notifier,
        authedFor: authed,
        scopeProvider: () => BootHarness.scope,
        idle: () async => true,
        capabilities: () async => {'checksum'},
        now: h.now,
      );

      for (var i = 1; i <= n; i++) {
        h.server.seedRow('sale', feedSale(id: _id(i))..['version'] = 1);
      }
      // Local copies of a random subset, through the real applier.
      for (var i = 1; i <= n; i++) {
        if (rnd.nextBool()) continue;
        final change = (await h.server.bootstrapPage(
          entity: 'sale',
          limit: 100,
          scope: BootHarness.scope,
        )).items.firstWhere((r) => r['id'] == _id(i));
        await h.db.transaction(
          (t) => h.registry
              .of('sale')!
              .apply(
                t,
                PullChange(
                  seq: 0,
                  entity: 'sale',
                  op: 'upsert',
                  id: _id(i),
                  version: 1,
                  data: change,
                ),
              ),
        );
      }
      if (surplus) {
        await h.db.insert('sales', {
          'id': _id(900),
          'shop_id': 's',
          'status': 'completed',
          'subtotal': '3.00',
          'discount': '0',
          'tax_amount': '0',
          'net_amount': '3.00',
          'occurred_at': '2026-11-16T08:05:00Z',
          'received_at': '2026-11-16T08:05:00Z',
          'sync_state': 'synced',
        });
      }
      final before = (await h.ids('sales')).toSet();

      final run = await audit.maybeRun(force: true);
      final after = (await h.ids('sales')).toSet();
      expect(after.containsAll(before), isTrue, reason: 'no row deleted');
      if (surplus) {
        expect(run, AuditRun.drift);
        expect(after, contains(_id(900)));
      } else {
        expect(run, anyOf(AuditRun.ok, AuditRun.repaired));
        expect(after.length, n);
      }
    });
  }
}
