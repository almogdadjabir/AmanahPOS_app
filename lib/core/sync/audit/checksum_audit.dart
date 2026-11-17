import 'dart:developer' as developer;

import '../contract/sync_contract.dart';
import '../db_change_notifier.dart';
import '../decimal3.dart';
import '../sync_engine.dart' show AuthedCall;
import '../sync_schema.dart';
import '../sync_state_store.dart';
import '../transport/sync_transport.dart';
import 'checksum_repair.dart';
import 'local_checksum_queries.dart';

enum AuditVerdict { match, inconclusive, mismatch }

enum AuditRun { skipped, ok, repaired, drift, inconclusive }

/// Self-audit of the synced sale / refund / stock rows against the server's
/// `sync/checksum`. On a mismatch it runs ONE targeted [ChecksumRepair] and
/// re-checks once; if the totals still differ the owner is told (state
/// `drift`). It never deletes rows and never loops.
class ChecksumAudit {
  ChecksumAudit({
    required SyncTransport transport,
    required LocalChecksumQueries local,
    required ChecksumRepair repair,
    required SyncStateStore state,
    required DbChangeNotifier notifier,
    required AuthedCall Function(String scope) authedFor,
    required String? Function() scopeProvider,
    required Future<bool> Function() idle,
    required Future<Set<String>> Function() capabilities,
    DateTime Function()? now,
    Future<void> Function()? debugParity,
  }) : _transport = transport,
       _local = local,
       _repair = repair,
       _state = state,
       _notifier = notifier,
       _authedFor = authedFor,
       _scopeProvider = scopeProvider,
       _idle = idle,
       _capabilities = capabilities,
       _now = now ?? DateTime.now,
       _debugParity = debugParity;

  static const Duration minInterval = Duration(hours: 6);

  /// An inconclusive or failed attempt retries after this, not after
  /// [minInterval] (and never on every sync).
  static const Duration retryInterval = Duration(minutes: 15);
  static const int windowDays = 7;
  static const String capability = 'checksum';

  final SyncTransport _transport;
  final LocalChecksumQueries _local;
  final ChecksumRepair _repair;
  final SyncStateStore _state;
  final DbChangeNotifier _notifier;
  final AuthedCall Function(String scope) _authedFor;
  final String? Function() _scopeProvider;
  final Future<bool> Function() _idle;
  final Future<Set<String>> Function() _capabilities;
  final DateTime Function() _now;
  final Future<void> Function()? _debugParity;

  bool _running = false;

  /// Last pass's per-entity differences (for the drift detail).
  Map<String, dynamic> _lastDetail = {};

  /// Throttled, precondition-checked run. Never throws.
  Future<AuditRun> maybeRun({bool force = false}) async {
    if (_running) return AuditRun.skipped;
    _running = true;
    try {
      final scope = _scopeProvider();
      if (scope == null || scope.isEmpty) return AuditRun.skipped;
      final st = _state.forScope(scope);
      if (!force) {
        final last = await st.lastAuditAt();
        if (last != null && _now().toUtc().difference(last) < minInterval) {
          return AuditRun.skipped;
        }
      }
      if (!(await _capabilities()).contains(capability)) {
        return AuditRun.skipped;
      }
      if (!await _idle()) return AuditRun.skipped;

      var v = await verdict(scope);
      var repaired = false;
      if (v == AuditVerdict.mismatch) {
        await _repair.repair(scope: scope, salesSinceDays: windowDays);
        repaired = true;
        v = await verdict(scope);
      }
      if (_scopeProvider() != scope) return AuditRun.skipped; // switched
      final now = _now().toUtc();
      switch (v) {
        case AuditVerdict.inconclusive:
          await _backOff(st); // no state change
          return AuditRun.inconclusive;
        case AuditVerdict.match:
          await st.setAuditState(AuditState(status: AuditState.ok, at: now));
          await st.setLastAuditAt(now);
          _notifier.notify({SyncTables.syncState});
          await _runParity();
          return repaired ? AuditRun.repaired : AuditRun.ok;
        case AuditVerdict.mismatch:
          await st.setAuditState(
            AuditState(status: AuditState.drift, at: now, detail: _lastDetail),
          );
          await st.setLastAuditAt(now);
          _notifier.notify({SyncTables.syncState});
          return AuditRun.drift;
      }
    } catch (e, stack) {
      developer.log(
        'checksum audit failed',
        name: 'ChecksumAudit',
        error: e,
        stackTrace: stack,
      );
      final scope = _scopeProvider();
      if (scope != null && scope.isNotEmpty) {
        try {
          await _backOff(_state.forScope(scope));
        } catch (_) {}
      }
      return AuditRun.skipped;
    } finally {
      _running = false;
    }
  }

  /// Makes the throttle expire [retryInterval] from now.
  Future<void> _backOff(SyncStateStore st) =>
      st.setLastAuditAt(_now().toUtc().subtract(minInterval - retryInterval));

  Future<void> _runParity() async {
    final p = _debugParity;
    if (p == null) return;
    try {
      await p();
    } catch (e, st) {
      developer.log(
        'dashboard parity failed',
        name: 'ChecksumAudit',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// One pass over sale, refund and stock.
  Future<AuditVerdict> verdict(String scope) async {
    final authed = _authedFor(scope);
    final cutoff = _now().toUtc().subtract(const Duration(days: windowDays));
    var mismatch = false;
    var inconclusive = false;
    final detail = <String, dynamic>{};

    Future<ChecksumResponse> server(String entity) => authed(
      () => _transport.checksum(
        entity: entity,
        sinceDays: windowDays,
        scope: scope,
      ),
    );

    for (final entity in const ['sale', 'refund', 'stock']) {
      final before = await server(entity);
      final LocalChecksum mine = switch (entity) {
        'sale' => await _local.sales(cutoff: cutoff),
        'refund' => await _local.refunds(cutoff: cutoff),
        _ => await _local.stock(),
      };
      final after = await server(entity);
      if (after.maxSeq != before.maxSeq) {
        inconclusive = true; // the server moved during the audit
        continue;
      }
      if (mine.nearEdge) {
        inconclusive = true;
        continue;
      }
      final diff = _differs(entity, mine, after);
      if (diff) {
        mismatch = true;
        detail[entity] = {
          'localCount': mine.count,
          'serverCount': after.count,
          'localSum': mine.sumTotal,
          'serverSum': after.sumTotal,
        };
      }
    }
    _lastDetail = detail;
    if (mismatch) return AuditVerdict.mismatch;
    return inconclusive ? AuditVerdict.inconclusive : AuditVerdict.match;
  }

  /// Stock compares the sum only: local `stock` may hold zero rows the server
  /// never created.
  bool _differs(String entity, LocalChecksum l, ChecksumResponse s) {
    if (entity != 'stock' && l.count != s.count) return true;
    // A sum the server did not send (or that does not parse) cannot prove
    // drift; the count (and the other sum) still can.
    bool sumDiffers(String? mine, String? theirs) {
      final a = _num(mine);
      final b = _num(theirs);
      return a != null && b != null && a != b;
    }

    if (sumDiffers(l.sumTotal, s.sumTotal)) return true;
    if (entity == 'sale' && sumDiffers(l.sumRevenue, s.sumRevenue)) {
      return true;
    }
    return false;
  }

  static BigInt? _num(String? v) => v == null ? null : Decimal3.tryParse(v);
}
