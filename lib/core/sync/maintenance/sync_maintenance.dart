import 'dart:developer' as developer;

import '../outbox/outbox_store.dart';
import '../sync_state_store.dart';

/// Housekeeping that runs after a completed foreground sync: prunes `done`
/// outbox rows (never open, blocked or rejected ones) at most once per
/// [interval]. Never throws.
class SyncMaintenance {
  SyncMaintenance({
    required OutboxStore outbox,
    required SyncStateStore state,
    required String? Function() scopeProvider,
    DateTime Function()? now,
  }) : _outbox = outbox,
       _state = state,
       _scopeProvider = scopeProvider,
       _now = now ?? DateTime.now;

  static const Duration interval = Duration(hours: 24);
  static const Duration keepDone = Duration(days: 7);

  final OutboxStore _outbox;
  final SyncStateStore _state;
  final String? Function() _scopeProvider;
  final DateTime Function() _now;

  /// Rows pruned; 0 when skipped.
  Future<int> maybeRun() async {
    try {
      final scope = _scopeProvider();
      if (scope == null) return 0;
      final store = _state.forScope(scope);
      final now = _now().toUtc();
      final last = await store.lastPruneAt();
      // A last run in the future (clock moved back) must not starve pruning.
      if (last != null &&
          !now.isBefore(last) &&
          now.difference(last) < interval) {
        return 0;
      }
      final n = await _outbox.pruneDone(keep: keepDone);
      await store.setLastPruneAt(now);
      return n;
    } catch (e, st) {
      developer.log(
        'maintenance prune failed',
        name: 'SyncMaintenance',
        error: e,
        stackTrace: st,
      );
      return 0;
    }
  }
}
