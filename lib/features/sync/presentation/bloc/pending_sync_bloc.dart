import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
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

  PendingSyncBloc({
    required this.outbox,
    required this.db,
    String? Function()? scope,
  }) : _scope = scope ?? (() => SyncScope.current),
       super(const PendingSyncState()) {
    on<OnPendingSyncLoad>(_onLoad);
    on<OnPendingSyncRetryAll>(_onRetryAll);
    on<OnPendingSyncRetryRow>(_onRetryRow);
    on<OnPendingSyncDiscardRow>(_onDiscardRow);
    on<OnPendingSyncDiscardScope>(_onDiscardScope);
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
  ) async {
    // Retry every rejected row of the current scope.
    final scope = _scope();
    try {
      for (final e in await outbox.rejected()) {
        if (e.scope == scope) await outbox.retryRejected(e.mutationId);
      }
      emit(
        state.copyWith(
          status: PendingSyncStatus.loaded,
          rows: await _loadRows(),
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _onRetryRow(
    OnPendingSyncRetryRow event,
    Emitter<PendingSyncState> emit,
  ) => _mutate(emit, () => outbox.retryRejected(event.mutationId));

  Future<void> _onDiscardRow(
    OnPendingSyncDiscardRow event,
    Emitter<PendingSyncState> emit,
  ) => _mutate(emit, () async {
    final rows = await outbox.listUnsynced();
    final hit = rows.where((r) => r.mutationId == event.mutationId);
    if (hit.isEmpty) return;
    final e = hit.first;
    if (e.entity == 'sale') await _markSaleRejected(e);
    await outbox.discard(e.mutationId);
  });

  Future<void> _onDiscardScope(
    OnPendingSyncDiscardScope event,
    Emitter<PendingSyncState> emit,
  ) => _mutate(emit, () async {
    // Never the signed-in session's own rows.
    if (event.scope == _scope()) return;
    for (final e in await outbox.listUnsynced()) {
      if (e.scope == event.scope && e.entity == 'sale') {
        await _markSaleRejected(e);
      }
    }
    await outbox.discardAll(scope: event.scope);
  });

  Future<void> _mutate(
    Emitter<PendingSyncState> emit,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      emit(
        state.copyWith(
          status: PendingSyncStatus.loaded,
          rows: await _loadRows(),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// A discarded sale is never deleted: the local row stays, flagged
  /// `rejected`, so history keeps showing it.
  Future<void> _markSaleRejected(OutboxEntry e) async {
    final d = await db.database;
    await const SaleLocalStore().markRejected(
      d,
      e.entityId,
      code: e.errorCode ?? 'discarded',
      message: e.errorMessage ?? 'Discarded by user',
    );
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
