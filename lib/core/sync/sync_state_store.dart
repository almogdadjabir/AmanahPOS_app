import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../offline/offline_db.dart';
import 'sync_schema.dart';

/// Result of the last checksum self-audit of one scope: `ok`, or `drift`
/// (a repair did not make local totals match the server).
class AuditState {
  const AuditState({
    required this.status,
    required this.at,
    this.detail = const {},
  });

  static const String ok = 'ok';
  static const String drift = 'drift';

  final String status;
  final DateTime at;

  /// `{entity: {localCount, serverCount, localSum, serverSum}}` for support.
  final Map<String, dynamic> detail;

  bool get isDrift => status == drift;

  Map<String, dynamic> toJson() => {
    'status': status,
    'at': at.toUtc().toIso8601String(),
    'detail': detail,
  };

  static AuditState? tryFromJson(Object? raw) {
    try {
      if (raw is! String) return null;
      final j = jsonDecode(raw);
      if (j is! Map) return null;
      final status = j['status'];
      final at = DateTime.tryParse('${j['at']}');
      if (status is! String || at == null) return null;
      final d = j['detail'];
      return AuditState(
        status: status,
        at: at.toUtc(),
        detail: d is Map ? Map<String, dynamic>.from(d) : const {},
      );
    } catch (_) {
      return null;
    }
  }
}

/// Resumable first-setup (bootstrap) progress of one scope. One JSON value
/// under `bootstrap_progress|<scope>`, written in the same transaction as the
/// page's rows.
class BootstrapProgress {
  const BootstrapProgress({
    required this.snapshotCursor,
    required this.entities,
    required this.done,
    required this.startedAt,
    this.pageCursor,
  });

  /// Cursor from the manifest; becomes the pull cursor at the end.
  final String snapshotCursor;

  /// Ordered entities of the manifest.
  final List<String> entities;

  /// Entities fully downloaded.
  final List<String> done;

  /// Keyset cursor inside the current (first not-done) entity.
  final String? pageCursor;

  final DateTime startedAt;

  Map<String, dynamic> toJson() => {
    'snapshot_cursor': snapshotCursor,
    'entities': entities,
    'done': done,
    'page_cursor': pageCursor,
    'started_at': startedAt.toUtc().toIso8601String(),
  };

  /// Null when [j] is not a well-formed progress record.
  static BootstrapProgress? tryFromJson(Object? j) {
    if (j is! Map) return null;
    final snap = j['snapshot_cursor'];
    final ents = j['entities'];
    final done = j['done'];
    final started = DateTime.tryParse('${j['started_at']}');
    final page = j['page_cursor'];
    if (snap is! String ||
        ents is! List ||
        done is! List ||
        started == null ||
        (page != null && page is! String)) {
      return null;
    }
    if (ents.any((e) => e is! String) || done.any((e) => e is! String)) {
      return null;
    }
    return BootstrapProgress(
      snapshotCursor: snap,
      entities: List<String>.from(ents),
      done: List<String>.from(done),
      pageCursor: page as String?,
      startedAt: started.toUtc(),
    );
  }

  factory BootstrapProgress.fromJson(Map<String, dynamic> j) =>
      tryFromJson(j) ?? (throw FormatException('Bad BootstrapProgress: $j'));
}

/// Key/value sync bookkeeping persisted in the `sync_state` table.
class SyncStateStore {
  SyncStateStore(
    this._db, {
    DateTime Function()? now,
    Uuid? uuid,
    String? scope,
  }) : _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid(),
       _scope = scope;

  final OfflineDb _db;
  final String? _scope;

  /// A view of the same table whose cursor, deferred pull and repair flag
  /// live under [scope] (`userId|tenantId`). `device_id` and `sync_lock`
  /// stay global.
  SyncStateStore forScope(String scope) =>
      SyncStateStore(_db, now: _now, uuid: _uuid, scope: scope);

  /// Scoped key. An unscoped store must never touch per-session progress.
  String _k(String base) {
    final scope = _scope;
    if (scope == null) {
      throw StateError(
        'SyncStateStore: "$base" needs forScope(userId|tenantId)',
      );
    }
    return '$base|$scope';
  }

  final DateTime Function() _now;
  final Uuid _uuid;

  static const _kDeviceId = 'device_id';
  static const _kCursor = 'cursor';
  static const _kClockSkew = 'clock_skew_ms';
  static const _kLastSyncedAt = 'last_synced_at';
  static const _kCapabilities = 'capabilities';
  static const _kLock = 'sync_lock';
  static const _kRepairNeeded = 'repair_needed';
  static const _kDeferredPull = 'deferred_pull';
  static const _kBootstrapProgress = 'bootstrap_progress';
  static const _kBootstrapped = 'bootstrapped';
  static const _kBootstrapCompletedAt = 'bootstrap_completed_at';
  static const _kDeviceRegistration = 'device_registration';
  static const _kAuditLastAt = 'audit_last_at';
  static const _kAuditState = 'audit_state';
  static const _kLocalReceiptCounter = 'local_receipt_counter';

  Future<String?> _get(DatabaseExecutor e, String key) async {
    final rows = await e.query(
      SyncTables.syncState,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> _put(DatabaseExecutor e, String key, String value) {
    return e.insert(SyncTables.syncState, {
      'key': key,
      'value': value,
      'updated_at': _now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> deviceId() async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final existing = await _get(txn, _kDeviceId);
      if (existing != null && existing.isNotEmpty) return existing;
      final id = _uuid.v4();
      await _put(txn, _kDeviceId, id);
      return id;
    });
  }

  /// Increments and returns this device's local receipt counter (global,
  /// survives logout and [clear]). Call inside the transaction that writes
  /// the sale so a rolled-back sale never consumes a number.
  Future<int> nextLocalReceiptCounter(DatabaseExecutor txn) async {
    final current = int.tryParse(await _get(txn, _kLocalReceiptCounter) ?? '');
    final next = (current ?? 0) + 1;
    await _put(txn, _kLocalReceiptCounter, '$next');
    return next;
  }

  Future<String?> cursor() async => _get(await _db.database, _k(_kCursor));

  /// [cursor] read through [e] (inside a page transaction).
  Future<String?> cursorIn(DatabaseExecutor e) => _get(e, _k(_kCursor));

  Future<void> setCursor(DatabaseExecutor txn, String cursor) =>
      _put(txn, _k(_kCursor), cursor);

  Future<Duration?> clockSkew() async {
    final v = await _get(await _db.database, _kClockSkew);
    final ms = v == null ? null : int.tryParse(v);
    return ms == null ? null : Duration(milliseconds: ms);
  }

  Future<void> setClockSkew(Duration d) async =>
      _put(await _db.database, _kClockSkew, d.inMilliseconds.toString());

  Future<DateTime?> lastSyncedAt() async {
    final v = await _get(await _db.database, _kLastSyncedAt);
    return v == null ? null : DateTime.tryParse(v)?.toUtc();
  }

  Future<void> setLastSyncedAt(DateTime t) async =>
      _put(await _db.database, _kLastSyncedAt, t.toUtc().toIso8601String());

  Future<Set<String>> capabilities() async {
    final v = await _get(await _db.database, _kCapabilities);
    if (v == null || v.isEmpty) return {};
    return v.split(',').where((e) => e.isNotEmpty).toSet();
  }

  Future<void> setCapabilities(Set<String> caps) async {
    final sorted = caps.toList()..sort();
    await _put(await _db.database, _kCapabilities, sorted.join(','));
  }

  /// Clears sync progress (this scope's cursor, deferred pull and bootstrap
  /// progress, plus skew, last sync, capabilities). Another scope's keys, the
  /// device id, the runner lock and this scope's `bootstrapped` flag are
  /// deliberately kept (a reset cursor must never put a set-up device back
  /// on the blocking first-setup screen).
  Future<void> clear() async {
    final db = await _db.database;
    await db.delete(
      SyncTables.syncState,
      where: 'key IN (?, ?, ?, ?, ?, ?, ?, ?)',
      whereArgs: [
        _k(_kAuditLastAt),
        _k(_kAuditState),
        _k(_kCursor),
        _kClockSkew,
        _kLastSyncedAt,
        _kCapabilities,
        _k(_kDeferredPull),
        _k(_kBootstrapProgress),
      ],
    );
  }

  // ---- bootstrap (first setup) ----

  /// Progress of an interrupted bootstrap of this scope, or null (none, or
  /// an unreadable record: the bootstrapper then starts over).
  Future<BootstrapProgress?> bootstrapProgress(DatabaseExecutor e) async {
    final raw = await _get(e, _k(_kBootstrapProgress));
    if (raw == null) return null;
    try {
      return BootstrapProgress.tryFromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  /// Writes (or with null removes) the progress inside [txn].
  Future<void> setBootstrapProgress(
    DatabaseExecutor txn,
    BootstrapProgress? p,
  ) async {
    if (p == null) {
      await txn.delete(
        SyncTables.syncState,
        where: 'key = ?',
        whereArgs: [_k(_kBootstrapProgress)],
      );
    } else {
      await _put(txn, _k(_kBootstrapProgress), jsonEncode(p.toJson()));
    }
  }

  /// True once this scope's first setup committed its final transaction.
  /// Never touched by [clear].
  Future<bool> isBootstrapped() async =>
      await _get(await _db.database, _k(_kBootstrapped)) == '1';

  Future<void> setBootstrapped(DatabaseExecutor txn, bool v) async {
    if (v) {
      await _put(txn, _k(_kBootstrapped), '1');
    } else {
      await txn.delete(
        SyncTables.syncState,
        where: 'key = ?',
        whereArgs: [_k(_kBootstrapped)],
      );
    }
  }

  /// Ruling T11-a: true when ANY scope (`userId|tenantId`) of [tenantId] on
  /// this device has its `bootstrapped` flag. The catalog tables are per
  /// device and shared by the tenant's users, so this is the first-setup
  /// UI gate; it never replaces the scope's own flag/cursor (the engine
  /// still bootstraps a cursor-less scope before pulling). Keys are parsed
  /// exactly (no LIKE wildcards: `_`/`%` in ids must not match). Works on
  /// an unscoped store.
  Future<bool> isTenantBootstrapped(String tenantId) async {
    if (tenantId.isEmpty) return false;
    const prefix = '$_kBootstrapped|';
    final db = await _db.database;
    final rows = await db.query(
      SyncTables.syncState,
      columns: ['key'],
      where: 'substr(key, 1, ?) = ? AND value = ?',
      whereArgs: [prefix.length, prefix, '1'],
    );
    for (final r in rows) {
      final key = r['key'] as String?;
      if (key == null || !key.startsWith(prefix)) continue;
      final parts = key.substring(prefix.length).split('|');
      if (parts.length != 2 || parts[0].isEmpty) continue;
      if (parts[1] == tenantId) return true;
    }
    return false;
  }

  /// When this scope's last bootstrap committed its final transaction
  /// (written in that transaction). Survives [clear]: the engine uses it to
  /// refuse a `full_resync_required` loop right after a bootstrap.
  Future<DateTime?> bootstrapCompletedAt() async {
    final v = await _get(await _db.database, _k(_kBootstrapCompletedAt));
    return v == null ? null : DateTime.tryParse(v)?.toUtc();
  }

  Future<void> setBootstrapCompletedAt(DatabaseExecutor txn, DateTime t) =>
      _put(txn, _k(_kBootstrapCompletedAt), t.toUtc().toIso8601String());

  /// Ruling T1-d: the local table wipe (logout / business switch) removes
  /// the rows every scope's setup produced, so it must drop every scope's
  /// cursor, `bootstrapped` flag, bootstrap progress and completion time
  /// TOGETHER, inside the wipe's own transaction (else a re-login finds a
  /// cursor over an empty catalog and never bootstraps). Deferred pulled
  /// changes, the outbox, the device id, the lock and the receipt counter
  /// are kept: they protect unsynced work.
  static Future<void> resetSetupOfAllScopes(DatabaseExecutor txn) => txn.delete(
    SyncTables.syncState,
    where: 'key LIKE ? OR key LIKE ? OR key LIKE ? OR key LIKE ?',
    whereArgs: [
      '$_kCursor|%',
      '$_kBootstrapped|%',
      '$_kBootstrapProgress|%',
      '$_kBootstrapCompletedAt|%',
    ],
  );

  // ---- checksum self-audit (Phase 6) ----

  Future<DateTime?> lastAuditAt() async {
    final v = await _get(await _db.database, _k(_kAuditLastAt));
    return v == null ? null : DateTime.tryParse(v)?.toUtc();
  }

  Future<void> setLastAuditAt(DateTime t) async =>
      _put(await _db.database, _k(_kAuditLastAt), t.toUtc().toIso8601String());

  Future<AuditState?> auditState() async =>
      AuditState.tryFromJson(await _get(await _db.database, _k(_kAuditState)));

  /// Null removes the record.
  Future<void> setAuditState(AuditState? s) async {
    final db = await _db.database;
    if (s == null) {
      await db.delete(
        SyncTables.syncState,
        where: 'key = ?',
        whereArgs: [_k(_kAuditState)],
      );
      return;
    }
    await _put(db, _k(_kAuditState), jsonEncode(s.toJson()));
  }

  // ---- device registration (best-effort, see SyncDeviceRegistrar) ----

  /// Signature of the last successful `POST sync/devices/` (user, tenant,
  /// app version, FCM token). Kept across [clear] like the device id; a
  /// different signature means "register again".
  Future<String?> deviceRegistration() async =>
      _get(await _db.database, _kDeviceRegistration);

  Future<void> setDeviceRegistration(String signature) async =>
      _put(await _db.database, _kDeviceRegistration, signature);

  // ---- repair flag: a push result could not be applied locally ----

  /// Sets the flag; pass [txn] to write it inside an open transaction.
  Future<void> setRepairNeeded([DatabaseExecutor? txn]) async =>
      _put(txn ?? await _db.database, _k(_kRepairNeeded), '1');

  Future<bool> repairNeeded() async =>
      await _get(await _db.database, _k(_kRepairNeeded)) == '1';

  Future<void> clearRepairNeeded() async {
    final db = await _db.database;
    await db.delete(
      SyncTables.syncState,
      where: 'key = ?',
      whereArgs: [_k(_kRepairNeeded)],
    );
  }

  // ---- pulled changes deferred because a local edit was still pending ----

  /// Raw JSON (map of "entity|id" -> change JSON) or null. Read inside the
  /// pull page transaction.
  Future<String?> deferredPullJson(DatabaseExecutor txn) =>
      _get(txn, _k(_kDeferredPull));

  Future<void> setDeferredPullJson(DatabaseExecutor txn, String? json) async {
    if (json == null) {
      await txn.delete(
        SyncTables.syncState,
        where: 'key = ?',
        whereArgs: [_k(_kDeferredPull)],
      );
    } else {
      await _put(txn, _k(_kDeferredPull), json);
    }
  }

  // ---- runner lock: value = "<holder>|<expiry ISO UTC>" ----

  ({String holder, DateTime expiry})? _parseLock(String? v) {
    if (v == null) return null;
    final i = v.lastIndexOf('|');
    if (i < 0) return null;
    final expiry = DateTime.tryParse(v.substring(i + 1));
    if (expiry == null) return null;
    return (holder: v.substring(0, i), expiry: expiry.toUtc());
  }

  String _encodeLock(String holder, Duration ttl) =>
      '$holder|${_now().toUtc().add(ttl).toIso8601String()}';

  /// Slack for small clock steps (NTP): within it a future expiry is still
  /// honoured, so a second runner cannot steal a live lock.
  static const Duration clockSlack = Duration(minutes: 1);

  /// An expiry later than now + [ttl] + [clockSlack] cannot have been written
  /// by a correct clock (the clock moved backwards): treat it as expired so a
  /// wrong clock never wedges sync.
  bool _expired(DateTime expiry, Duration ttl) {
    final now = _now().toUtc();
    return !expiry.isAfter(now) || expiry.isAfter(now.add(ttl + clockSlack));
  }

  Future<bool> acquireLock(String holder, Duration ttl) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final cur = _parseLock(await _get(txn, _kLock));
      final free =
          cur == null || cur.holder == holder || _expired(cur.expiry, ttl);
      if (!free) return false;
      await _put(txn, _kLock, _encodeLock(holder, ttl));
      return true;
    });
  }

  Future<bool> renewLock(String holder, Duration ttl) async {
    final db = await _db.database;
    return db.transaction((txn) async {
      final cur = _parseLock(await _get(txn, _kLock));
      if (cur == null || cur.holder != holder || _expired(cur.expiry, ttl)) {
        return false;
      }
      await _put(txn, _kLock, _encodeLock(holder, ttl));
      return true;
    });
  }

  Future<void> releaseLock(String holder) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final cur = _parseLock(await _get(txn, _kLock));
      if (cur != null && cur.holder == holder) {
        await txn.delete(
          SyncTables.syncState,
          where: 'key = ?',
          whereArgs: [_kLock],
        );
      }
    });
  }
}
