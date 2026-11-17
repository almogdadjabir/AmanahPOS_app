import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/features/pos/data/local/sale_local_store.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pending_sync_event.dart';
part 'pending_sync_state.dart';

/// Lists the unsynced outbox rows of every scope.
class PendingSyncBloc extends Bloc<PendingSyncEvent, PendingSyncState> {
  final OutboxStore outbox;
  final OfflineDb db;
  final String? Function() _scope;
  final DbChangeNotifier? _notifier;
  final Future<void> Function()? _syncNow;

  /// Tables a discard / retry may change (badge count, stock, history).
  static const Set<String> changedTables = {
    SyncTables.outbox,
    ...SaleLocalStore.tables,
    'stock',
    'products',
  };

  PendingSyncBloc({
    required this.outbox,
    required this.db,
    String? Function()? scope,
    DbChangeNotifier? notifier,
    Future<void> Function()? syncNow,
  }) : _scope = scope ?? (() => SyncScope.current),
       _notifier = notifier,
       _syncNow = syncNow,
       super(const PendingSyncState()) {
    on<OnPendingSyncLoad>(_onLoad);
    on<OnPendingSyncRetryAll>(_onRetryAll);
    on<OnPendingSyncRetryRow>(_onRetryRow);
    on<OnPendingSyncDiscardRow>(_onDiscardRow);
    on<OnPendingSyncDiscardScope>(_onDiscardScope);
    on<OnPendingSyncSendNow>(_onSendNow);
  }

  Future<void> _onLoad(
    OnPendingSyncLoad event,
    Emitter<PendingSyncState> emit,
  ) async {
    emit(state.copyWith(status: PendingSyncStatus.loading, clearError: true));
    try {
      emit(
        state.copyWith(
          status: PendingSyncStatus.loaded,
          rows: await _loadRows(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PendingSyncStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRetryAll(
    OnPendingSyncRetryAll event,
    Emitter<PendingSyncState> emit,
  ) => _mutate(emit, () async {
    // Retry every rejected row of the current scope.
    final scope = _scope();
    for (final e in await outbox.rejected()) {
      if (e.scope == scope) await outbox.retryRejected(e.mutationId);
    }
    return null;
  });

  Future<void> _onRetryRow(
    OnPendingSyncRetryRow event,
    Emitter<PendingSyncState> emit,
  ) => _mutate(emit, () async {
    await outbox.retryRejected(event.mutationId);
    return null;
  });

  /// The store re-checks the row inside its own transaction (review I1): a
  /// row the engine claimed after the list loaded is refused, never dropped.
  Future<void> _onDiscardRow(
    OnPendingSyncDiscardRow event,
    Emitter<PendingSyncState> emit,
  ) => _mutate(emit, () async {
    switch (await outbox.discard(event.mutationId, currentScope: _scope())) {
      case DiscardOutcome.sending:
        return PendingSyncFailure.discardSending;
      case DiscardOutcome.alreadySynced:
        return PendingSyncFailure.discardAlreadySynced;
      case DiscardOutcome.otherScope:
        return PendingSyncFailure.discardOtherScope;
      case DiscardOutcome.discarded:
      case DiscardOutcome.notFound:
        return null;
    }
  });

  /// "Send now" from the discard sheet: the app's existing sync-now. A row
  /// the server already has comes back `duplicate` (sale synced, row done).
  Future<void> _onSendNow(
    OnPendingSyncSendNow event,
    Emitter<PendingSyncState> emit,
  ) => _mutate(emit, () async {
    await _syncNow?.call();
    return null;
  });

  Future<void> _onDiscardScope(
    OnPendingSyncDiscardScope event,
    Emitter<PendingSyncState> emit,
  ) => _mutate(emit, () async {
    // Never the signed-in session's own rows.
    if (event.scope == _scope()) return null;
    await outbox.discardAll(scope: event.scope);
    return null;
  });

  /// Runs [action], notifies live readers (badge, stock, history) and
  /// reloads the list. A thrown error or a refusal returned by [action] is
  /// published as a [PendingSyncState.failure] (the screen shows it).
  Future<void> _mutate(
    Emitter<PendingSyncState> emit,
    Future<PendingSyncFailure?> Function() action,
  ) async {
    PendingSyncFailure? failure;
    String? message;
    try {
      failure = await action();
    } catch (e) {
      failure = PendingSyncFailure.actionFailed;
      message = e.toString();
    }
    _notifier?.notify(changedTables);
    try {
      final rows = await _loadRows();
      emit(
        failure == null
            ? state.copyWith(
                status: PendingSyncStatus.loaded,
                rows: rows,
                clearError: true,
              )
            : state.withFailure(failure, message, rows: rows),
      );
    } catch (e) {
      emit(
        state.withFailure(
          failure ?? PendingSyncFailure.actionFailed,
          message ?? e.toString(),
        ),
      );
    }
  }

  Future<List<PendingSyncRow>> _loadRows() async {
    final entries = await outbox.listUnsynced();
    final d = await db.database;
    final scope = _scope();
    final byKey = <String, OutboxEntry>{};
    for (final e in entries) {
      if (e.op == 'create') byKey['${e.scope}|${e.entityId}'] = e;
    }

    Future<PendingSyncRow> build(
      OutboxEntry e, {
      bool resolveParent = true,
    }) async {
      var label = '';
      String? total;
      if (e.entity == 'sale') {
        final r = await d.query(
          SaleLocalStore.sales,
          columns: ['receipt_number', 'local_receipt_number', 'net_amount'],
          where: 'id = ?',
          whereArgs: [e.entityId],
          limit: 1,
        );
        if (r.isNotEmpty) {
          label =
              (r.first['receipt_number'] as String?) ??
              (r.first['local_receipt_number'] as String?) ??
              '';
          total = r.first['net_amount'] as String?;
        }
        if (label.isEmpty) {
          label = (e.payload['local_receipt_number'] as String?) ?? '';
        }
      } else if (e.entity == 'stock') {
        final pid = e.payload['product_id'] as String?;
        if (pid != null) {
          final r = await d.query(
            'products',
            columns: ['name'],
            where: 'id = ?',
            whereArgs: [pid],
            limit: 1,
          );
          label = (r.isNotEmpty ? r.first['name'] as String? : null) ?? pid;
        }
      }
      PendingSyncRow? behind;
      if (resolveParent && e.status == OutboxStatus.blocked) {
        final parent = byKey['${e.scope}|${e.dependsOnEntityId}'];
        if (parent != null) behind = await build(parent, resolveParent: false);
      }
      return PendingSyncRow(
        entry: e,
        label: label,
        total: total,
        otherScope: scope != null && e.scope != scope,
        waitsBehind: behind,
      );
    }

    return [for (final e in entries) await build(e)];
  }
}
