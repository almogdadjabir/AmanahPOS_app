import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/appliers/applier_support.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/images/pending_upload_store.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/sync_schema.dart';
import 'package:amana_pos/core/sync/sync_scope.dart';
import 'package:amana_pos/features/pos/data/local/sale_local_store.dart';
import 'package:amana_pos/features/sync/domain/catalog_conflict_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';

part 'pending_sync_event.dart';
part 'pending_sync_state.dart';

/// Lists the unsynced outbox rows of every scope, plus the current scope's
/// parked image uploads. Catalog rows (product / category / vendor) get the
/// conflict actions of [CatalogConflictService].
class PendingSyncBloc extends Bloc<PendingSyncEvent, PendingSyncState> {
  final OutboxStore outbox;
  final OfflineDb db;
  final String? Function() _scope;
  final DbChangeNotifier? _notifier;
  final Future<void> Function()? _syncNow;
  final CatalogConflictService? _conflicts;
  final PendingUploadStore? _uploads;
  final Future<bool> Function(String entity, String entityId)? _retryUpload;

  /// Tables a discard / retry / merge may change (badge count, stock,
  /// history, catalog lists).
  static const Set<String> changedTables = CatalogConflictService.tables;

  PendingSyncBloc({
    required this.outbox,
    required this.db,
    String? Function()? scope,
    DbChangeNotifier? notifier,
    Future<void> Function()? syncNow,
    CatalogConflictService? conflicts,
    PendingUploadStore? uploads,
    Future<bool> Function(String entity, String entityId)? retryUpload,
  }) : _scope = scope ?? (() => SyncScope.current),
       _notifier = notifier,
       _syncNow = syncNow,
       _conflicts = conflicts,
       _uploads = uploads,
       _retryUpload = retryUpload,
       super(const PendingSyncState()) {
    on<OnPendingSyncLoad>(_onLoad);
    on<OnPendingSyncRetryAll>(_onRetryAll);
    on<OnPendingSyncRetryRow>(_onRetryRow);
    on<OnPendingSyncDiscardRow>(_onDiscardRow);
    on<OnPendingSyncDiscardScope>(_onDiscardScope);
    on<OnPendingSyncSendNow>(_onSendNow);
    on<OnPendingSyncMerge>(_onMerge);
    on<OnPendingSyncEditRetry>(_onEditRetry);
    on<OnPendingSyncRetryUpload>(_onRetryUpload);
  }

  /// Read-only: what merging [row] would change (the confirmation dialog's
  /// counts). Null when the row cannot be merged or no service is wired.
  Future<MergeReport?> previewMerge(PendingSyncRow row) async {
    final c = _conflicts;
    final target = row.entry.errorEntityId;
    if (c == null || !row.canMerge || target == null) return null;
    try {
      return await c.previewMerge(
        row.entry.entityId,
        target,
        entity: row.entry.entity,
      );
    } on CatalogValidationException {
      return null;
    }
  }

  /// "Edit and retry": the entity's last outbox seq (taken before its edit
  /// form opens) and its local `json` (null when the row is gone).
  Future<({int seq, Map<String, dynamic>? json})?> editTarget(
    PendingSyncRow row,
  ) async {
    final c = _conflicts;
    if (c == null || !row.canEditRetry) return null;
    final e = row.entry;
    return (
      seq: await c.lastSeqOf(e.entity, e.entityId),
      json: await c.localRow(e.entity, e.entityId),
    );
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
          failedUploads: await _loadFailedUploads(),
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
    final d = await db.database;
    for (final e in await outbox.rejected()) {
      if (e.scope != scope) continue;
      // Never sent silently without its product / vendor: that row needs
      // its own confirmed retry (see PendingSyncRow.missingDependency).
      if ((await CatalogSupport.goneDependencies(d, e)).isNotEmpty) continue;
      await outbox.retryRejected(e.mutationId);
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
    // Catalog rows: the local row is dropped (create) or restored from its
    // last server state (update / delete), never left diverged. Decided by
    // the stored row's entity, not by the (possibly stale) list.
    final c = _conflicts;
    final found = await (await db.database).query(
      SyncTables.outbox,
      columns: ['entity'],
      where: 'mutation_id = ?',
      whereArgs: [event.mutationId],
      limit: 1,
    );
    final catalog =
        found.isNotEmpty &&
        CatalogConflictService.tableOf.containsKey(found.first['entity']);
    final outcome = c != null && catalog
        ? await c.discardRejected(event.mutationId)
        : await outbox.discard(event.mutationId, currentScope: _scope());
    switch (outcome) {
      case DiscardOutcome.sending:
        return PendingSyncFailure.discardSending;
      case DiscardOutcome.alreadySynced:
        return PendingSyncFailure.discardAlreadySynced;
      case DiscardOutcome.otherScope:
        return PendingSyncFailure.discardOtherScope;
      case DiscardOutcome.hasDependents:
        return PendingSyncFailure.discardHasDependents;
      case DiscardOutcome.mayBeOnServer:
        return PendingSyncFailure.discardMayBeOnServer;
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

  Future<void> _onMerge(
    OnPendingSyncMerge event,
    Emitter<PendingSyncState> emit,
  ) => _mutate(emit, () async {
    final row = state.rows
        .where((r) => r.entry.mutationId == event.mutationId)
        .firstOrNull;
    final c = _conflicts;
    final target = row?.entry.errorEntityId;
    if (c == null || row == null || !row.canMerge || target == null) {
      return PendingSyncFailure.mergeRefused;
    }
    try {
      await c.mergeInto(row.entry.entityId, target, entity: row.entry.entity);
    } on CatalogValidationException {
      return PendingSyncFailure.mergeRefused;
    }
    // M4: when the existing row was not local yet, the copy stands in under
    // its id until the pull brings the server state: sync now.
    _kickSync();
    return null;
  });

  Future<void> _onEditRetry(
    OnPendingSyncEditRetry event,
    Emitter<PendingSyncState> emit,
  ) => _mutate(emit, () async {
    final c = _conflicts;
    if (c == null) return null;
    final ok = await c.editAndRetry(
      event.mutationId,
      editedAfterSeq: event.editedAfterSeq,
    );
    return ok ? null : PendingSyncFailure.editNotSaved;
  });

  /// The uploader notifies `pending_uploads`; the sync triggers start an
  /// upload run from that notification (review M1).
  Future<void> _onRetryUpload(
    OnPendingSyncRetryUpload event,
    Emitter<PendingSyncState> emit,
  ) => _mutate(emit, () async {
    await _retryUpload?.call(event.entity, event.entityId);
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

  /// Starts the app's sync-now without waiting for it (best effort).
  void _kickSync() {
    final f = _syncNow;
    if (f == null) return;
    f().catchError((Object _) {});
  }

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
      final uploads = await _loadFailedUploads();
      emit(
        failure == null
            ? state.copyWith(
                status: PendingSyncStatus.loaded,
                rows: rows,
                failedUploads: uploads,
                clearError: true,
              )
            : state.withFailure(
                failure,
                message,
                rows: rows,
                failedUploads: uploads,
              ),
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

  Future<List<PendingUploadRow>> _loadFailedUploads() async {
    final store = _uploads;
    final scope = _scope();
    if (store == null || scope == null) return const [];
    final d = await db.database;
    final out = <PendingUploadRow>[];
    for (final u in await store.all(d, scope: scope)) {
      if (u.state != PendingUpload.failed) continue;
      out.add(
        PendingUploadRow(
          entity: u.entity,
          entityId: u.entityId,
          label: await _catalogName(d, u.entity, u.entityId) ?? '',
          error: u.lastError,
        ),
      );
    }
    return out;
  }

  /// `name` of a local product / category / vendor (vendors keep it in
  /// `json`), or null.
  static Future<String?> _catalogName(
    DatabaseExecutor d,
    String entity,
    String? id,
  ) async {
    final table = CatalogConflictService.tableOf[entity];
    if (table == null || id == null) return null;
    final r = await d.query(
      table,
      columns: ['json'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (r.isEmpty) return null;
    final name = decodeJsonMap(r.first['json'])['name'];
    return name is String && name.isNotEmpty ? name : null;
  }

  /// Whether the local catalog row carries [CatalogConflictService.
  /// staleKey].
  static Future<bool> _isStale(
    DatabaseExecutor d,
    String entity,
    String id,
  ) async {
    final table = CatalogConflictService.tableOf[entity];
    if (table == null) return false;
    final r = await d.query(
      table,
      columns: ['json'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return r.isNotEmpty &&
        decodeJsonMap(r.first['json'])[CatalogConflictService.staleKey] ==
            true;
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
      String? conflictLabel;
      var dependents = 0;
      var stale = false;
      final own = scope != null && e.scope == scope;
      if (CatalogConflictService.tableOf.containsKey(e.entity)) {
        label =
            await _catalogName(d, e.entity, e.entityId) ??
            (e.payload['name'] as String?) ??
            '';
        conflictLabel = await _catalogName(d, e.entity, e.errorEntityId);
        final c = _conflicts;
        if (own && e.op == 'create' && c != null) {
          dependents = await c.dependentsOfCreate(e.entity, e.entityId);
        }
        stale = await _isStale(d, e.entity, e.entityId);
      }
      final missing =
          own &&
          e.status == OutboxStatus.rejected &&
          (await CatalogSupport.goneDependencies(d, e)).isNotEmpty;
      PendingSyncRow? behind;
      if (resolveParent && e.status == OutboxStatus.blocked) {
        // The first dependency whose create is still listed.
        OutboxEntry? parent;
        for (final d in e.dependsOn) {
          parent = byKey['${e.scope}|$d'];
          if (parent != null) break;
        }
        if (parent != null) behind = await build(parent, resolveParent: false);
      }
      return PendingSyncRow(
        entry: e,
        label: label,
        total: total,
        otherScope: scope != null && e.scope != scope,
        waitsBehind: behind,
        conflictLabel: conflictLabel,
        dependents: dependents,
        missingDependency: missing,
        stale: stale,
      );
    }

    return [for (final e in entries) await build(e)];
  }
}
