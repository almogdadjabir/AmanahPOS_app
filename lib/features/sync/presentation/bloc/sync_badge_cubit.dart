import 'dart:async';

import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Header / screen badge: unsynced outbox count + engine phase. Reachability
/// comes from the engine's server ping ([SyncStatus.serverReachable]), never
/// from device Wi-Fi.
class SyncBadgeState extends Equatable {
  final int unsynced;
  final SyncStatus status;
  const SyncBadgeState({required this.unsynced, required this.status});

  @override
  List<Object?> get props => [
    unsynced,
    status.phase,
    status.block,
    status.serverReachable,
    status.rejected,
  ];
}

class SyncBadgeCubit extends Cubit<SyncBadgeState> {
  SyncBadgeCubit({
    required Stream<SyncStatus> status,
    required SyncStatus initial,
    required Future<int> Function() unsyncedCount,
    Stream<Set<String>>? tableChanges,
  }) : _unsynced = unsyncedCount,
       super(SyncBadgeState(unsynced: 0, status: initial)) {
    _sub = status.listen(_onStatus);
    // Local outbox writes (a sale, a discard / retry on the pending screen)
    // change the count without any engine status change (review M3).
    _tablesSub = tableChanges?.listen((t) {
      if (t.contains(SyncTables.outbox)) _onStatus(state.status);
    });
    _onStatus(initial);
  }

  final Future<int> Function() _unsynced;
  late final StreamSubscription<SyncStatus> _sub;
  StreamSubscription<Set<String>>? _tablesSub;

  Future<void> _onStatus(SyncStatus s) async {
    try {
      final n = await _unsynced();
      if (!isClosed) emit(SyncBadgeState(unsynced: n, status: s));
    } catch (_) {
      // Badge is best-effort.
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    await _tablesSub?.cancel();
    return super.close();
  }
}
