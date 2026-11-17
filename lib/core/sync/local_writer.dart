import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../offline/offline_db.dart';
import 'db_change_notifier.dart';
import 'outbox/outbox_entry.dart';
import 'outbox/outbox_store.dart';
import 'sync_schema.dart';
import 'sync_scope.dart';

/// Handle passed to a [LocalWriter.write] body. Everything done through it
/// shares one SQLite transaction.
class WriteScope {
  WriteScope(this.txn, this._outbox, this._scope);

  final Transaction txn;
  final OutboxStore _outbox;
  final String? Function() _scope;

  /// The signed-in sync scope (`userId|tenantId`), or null.
  String? get scope => _scope();

  Future<OutboxEntry> enqueue({
    required String entity,
    required String op,
    required String entityId,
    required Map<String, dynamic> payload,
    List<String> dependsOn = const [],
    int? baseVersion,
    DateTime? occurredAt,
  }) {
    final scope = _scope();
    if (scope == null) {
      throw StateError('LocalWriter: no signed-in scope to enqueue under');
    }
    return _outbox.enqueue(
      txn,
      scope: scope,
      entity: entity,
      op: op,
      entityId: entityId,
      payload: payload,
      dependsOn: dependsOn,
      baseVersion: baseVersion,
      occurredAt: occurredAt,
    );
  }
}

/// The single write path: row writes and outbox enqueues commit atomically,
/// and listeners are notified only after the commit succeeds.
class LocalWriter {
  LocalWriter(
    this._db,
    this._outbox,
    this._notifier, {
    String? Function()? scopeProvider,
  }) : _scopeProvider = scopeProvider ?? (() => SyncScope.current);

  final OfflineDb _db;
  final OutboxStore _outbox;
  final DbChangeNotifier _notifier;
  final String? Function() _scopeProvider;

  static const Symbol _depthKey = #amanaLocalWriterDepth;

  /// A plain read on the database outside any write. Inside [write] use
  /// `scope.txn` instead (the raw database there deadlocks sqflite).
  Future<T> read<T>(Future<T> Function(DatabaseExecutor db) body) async {
    if (Zone.current[_depthKey] != null) {
      throw StateError('LocalWriter.read inside write; use scope.txn');
    }
    return body(await _db.database);
  }

  /// Runs [body] inside one SQLite transaction (row writes + outbox enqueues
  /// commit or roll back together), then notifies [tables] plus `outbox`.
  ///
  /// [body] may run once per call; keep it free of side effects outside
  /// `scope.txn`. Never call [write] or use the raw database inside it: that
  /// deadlocks sqflite, so nesting throws a [StateError] immediately.
  /// Listener failures after commit are reported, never rethrown.
  Future<T> write<T>({
    required Set<String> tables,
    required Future<T> Function(WriteScope scope) body,
  }) async {
    if (Zone.current[_depthKey] != null) {
      throw StateError('LocalWriter.write must not be nested; use scope.txn');
    }
    final db = await _db.database;
    final result = await Zone.current
        .fork(zoneValues: {_depthKey: 1})
        .run(
          () => db.transaction(
            (txn) => body(WriteScope(txn, _outbox, _scopeProvider)),
          ),
        );
    try {
      _notifier.notify({...tables, SyncTables.outbox});
    } catch (e, st) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'LocalWriter',
          context: ErrorDescription('while notifying listeners after commit'),
        ),
      );
    }
    return result;
  }
}
