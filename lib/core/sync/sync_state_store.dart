import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../offline/offline_db.dart';
import 'sync_schema.dart';

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
  static const _kDeviceRegistration = 'device_registration';
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

  /// Clears sync progress (this scope's cursor and deferred pull, plus skew,
  /// last sync, capabilities). Another scope's keys, the device id and the
  /// runner lock are deliberately kept.
  Future<void> clear() async {
    final db = await _db.database;
    await db.delete(
      SyncTables.syncState,
      where: 'key IN (?, ?, ?, ?, ?)',
      whereArgs: [
        _k(_kCursor),
        _kClockSkew,
        _kLastSyncedAt,
        _kCapabilities,
        _k(_kDeferredPull),
      ],
    );
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
