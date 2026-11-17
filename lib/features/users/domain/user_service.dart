import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/appliers/user_row_support.dart';
import '../../../core/sync/catalog_support.dart';
import '../../../core/sync/local_writer.dart';
import '../../../core/sync/sync_schema.dart';
import '../../../core/sync/sync_scope.dart';

/// The only writer of local team edits. Each call is ONE
/// [LocalWriter.write]: the `synced_entities` row (entity `user`, feed
/// shape) and its outbox row commit together. A created row has `version`
/// NULL (unsent). The BE allows these to the owner only and refuses edits of
/// the owner row and of the caller's own row (refused here too).
///
/// Before a member's first local edit the row's server json is kept under
/// `_server` (see `UserConflictService`: revert / dismiss); the applier
/// drops it once the server row is adopted.
class UserService {
  UserService({
    required LocalWriter writer,
    DateTime Function()? now,
    Uuid? uuid,
  }) : _writer = writer,
       _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final LocalWriter _writer;
  final DateTime Function() _now;
  final Uuid _uuid;

  static const String entity = 'user';
  static const Set<String> tables = {'synced_entities', SyncTables.outbox};
  static const Set<String> roles = {'cashier', 'manager'};

  /// Returns the new member id (client UUID v4).
  Future<String> create({
    required String phone,
    required String fullName,
    required String role,
    String? shopId,
  }) async {
    final p = phone.trim();
    final n = fullName.trim();
    if (p.isEmpty) throw const CatalogValidationException('Phone is required');
    if (n.isEmpty) throw const CatalogValidationException('Name is required');
    if (!roles.contains(role)) {
      throw const CatalogValidationException('Invalid role');
    }
    final shop = (shopId == null || shopId.isEmpty) ? null : shopId;
    final now = _now().toUtc();
    final iso = now.toIso8601String();
    final id = _uuid.v4();
    return _writer.write(
      tables: tables,
      body: (scope) async {
        await scope.txn.insert('synced_entities', {
          'entity': entity,
          'id': id,
          'version': null,
          'json': jsonEncode({
            'id': id,
            'phone': p,
            'full_name': n,
            'role': role,
            'default_shop': shop,
            'is_active': true,
            'status': 'invited',
            'last_login_at': null,
            'created_at': iso,
          }),
          'updated_at': iso,
        });
        await scope.enqueue(
          entity: entity,
          op: 'create',
          entityId: id,
          occurredAt: now,
          payload: {
            'id': id,
            'phone': p,
            'full_name': n,
            'role': role,
            'default_shop_id': ?shop,
          },
        );
        return id;
      },
    );
  }

  /// Only changed fields are sent. Role-only -> `set_role`, shop-only ->
  /// `set_shop`, otherwise ONE `update` (an edit never conflicts with
  /// itself). An unsent-create row (version null) always uses `update`: the
  /// BE requires a base_version for set_role/set_shop. No change writes
  /// nothing.
  Future<void> update(
    String id, {
    String? fullName,
    String? role,
    String? shopId,
  }) async {
    final proposed = <String, dynamic>{};
    if (fullName != null) {
      final n = fullName.trim();
      if (n.isEmpty) throw const CatalogValidationException('Name is required');
      proposed['full_name'] = n;
    }
    if (role != null) {
      if (!roles.contains(role)) {
        throw const CatalogValidationException('Invalid role');
      }
      proposed['role'] = role;
    }
    if (shopId != null && shopId.isNotEmpty) proposed['default_shop'] = shopId;
    await _edit(
      id,
      proposed,
      opFor: (changed, version) {
        if (version != null && changed.length == 1) {
          if (changed.containsKey('role')) return 'set_role';
          if (changed.containsKey('default_shop')) return 'set_shop';
        }
        return 'update';
      },
    );
  }

  /// Deactivate (`deactivate`) / reactivate (`update is_active:true`); never
  /// version-guarded by the BE, so no base_version.
  Future<void> setActive(String id, bool active) => _edit(
    id,
    {'is_active': active},
    opFor: (_, _) => active ? 'update' : 'deactivate',
    guarded: false,
  );

  Future<void> _edit(
    String id,
    Map<String, dynamic> proposed, {
    required String Function(Map<String, dynamic> changed, int? version) opFor,
    bool guarded = true,
  }) async {
    final now = _now().toUtc();
    final iso = now.toIso8601String();
    final me = SyncScope.current?.split('|').first;
    await _writer.write(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        final row = await _load(txn, id);
        if (row == null) {
          throw const CatalogValidationException('Member not found');
        }
        if (id == me || row.json['role'] == 'owner') {
          throw const CatalogValidationException(
            'This account cannot be changed here',
          );
        }
        final changed = CatalogSupport.changedFields(row.json, proposed);
        if (changed.isEmpty) return;
        final server = row.json[kUserServerKey] ?? _without(row.json);
        final json = {...row.json, ...changed, kUserServerKey: server};
        await txn.update(
          'synced_entities',
          {'json': jsonEncode(json), 'updated_at': iso},
          where: 'entity = ? AND id = ?',
          whereArgs: [entity, id],
        );
        final op = opFor(changed, row.version);
        final payload = <String, dynamic>{
          if (op == 'deactivate')
            ...const <String, dynamic>{}
          else
            for (final e in changed.entries)
              (e.key == 'default_shop' ? 'default_shop_id' : e.key): e.value,
        };
        await scope.enqueue(
          entity: entity,
          op: op,
          entityId: id,
          occurredAt: now,
          baseVersion: guarded ? row.version : null,
          payload: payload,
        );
      },
    );
  }

  static Map<String, dynamic> _without(Map<String, dynamic> j) =>
      {...j}..remove(kUserServerKey);

  static Future<({Map<String, dynamic> json, int? version})?> _load(
    DatabaseExecutor txn,
    String id,
  ) async {
    final r = await txn.query(
      'synced_entities',
      columns: ['json', 'version'],
      where: 'entity = ? AND id = ?',
      whereArgs: [entity, id],
      limit: 1,
    );
    if (r.isEmpty) return null;
    return (
      json: jsonDecode(r.first['json'] as String) as Map<String, dynamic>,
      version: r.first['version'] as int?,
    );
  }
}
