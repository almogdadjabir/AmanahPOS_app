import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/sync/catalog_support.dart';
import '../../../core/sync/local_writer.dart';
import '../../../core/sync/sync_schema.dart';

/// The only writer of local customer edits on the sync engine path. Each
/// call is ONE [LocalWriter.write]: the `customers` row and its outbox row
/// commit together. A created row has `version` NULL (unsent).
///
/// `loyalty_points` is server-owned: it is stored as the server sent it
/// (0 for a new local row, display only) and is NEVER put in a payload.
/// Any signed-in role may manage customers (the BE allows it; the screens
/// already gate who sees them).
class CustomerService {
  CustomerService({
    required LocalWriter writer,
    DateTime Function()? now,
    Uuid? uuid,
  }) : _writer = writer,
       _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final LocalWriter _writer;
  final DateTime Function() _now;
  final Uuid _uuid;

  static const String entity = 'customer';
  static const Set<String> tables = {'customers', SyncTables.outbox};

  /// Returns the new customer id (client UUID v4).
  Future<String> create({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    final n = name.trim();
    if (n.isEmpty) throw const CatalogValidationException('Name is required');
    final now = _now().toUtc();
    final iso = now.toIso8601String();
    final id = _uuid.v4();
    final fields = <String, dynamic>{
      'phone': ?_blankToNull(phone),
      'email': ?_blankToNull(email),
      'address': ?_blankToNull(address),
      'notes': ?_blankToNull(notes),
    };
    return _writer.write(
      tables: tables,
      body: (scope) async {
        await scope.txn.insert('customers', {
          'id': id,
          'name': n,
          'phone': fields['phone'],
          'email': fields['email'],
          'json': jsonEncode({
            'id': id,
            'name': n,
            'phone': fields['phone'],
            'email': fields['email'],
            'address': fields['address'],
            'notes': fields['notes'],
            'loyalty_points': 0,
            'is_active': true,
            'created_at': iso,
            'updated_at': iso,
          }),
          'updated_at': iso,
          'version': null,
        });
        await scope.enqueue(
          entity: entity,
          op: 'create',
          entityId: id,
          occurredAt: now,
          payload: {'id': id, 'name': n, ...fields},
        );
        return id;
      },
    );
  }

  /// Only changed fields are sent, with the row's `version` as
  /// `baseVersion` (null while the create is unsent). No change writes
  /// nothing.
  Future<void> update(
    String id, {
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    final proposed = <String, dynamic>{};
    if (name != null) {
      final n = name.trim();
      if (n.isEmpty) {
        throw const CatalogValidationException('Name is required');
      }
      proposed['name'] = n;
    }
    if (phone != null) proposed['phone'] = phone.trim();
    if (email != null) proposed['email'] = email.trim();
    if (address != null) proposed['address'] = address.trim();
    if (notes != null) proposed['notes'] = notes.trim();
    await _edit(id, proposed);
  }

  /// Deactivate / reactivate (`is_active`); the row is never deleted.
  Future<void> setActive(String id, bool active) =>
      _edit(id, {'is_active': active});

  Future<void> _edit(String id, Map<String, dynamic> proposed) async {
    final now = _now().toUtc();
    final iso = now.toIso8601String();
    await _writer.write(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        final row = await CatalogSupport.loadRow(txn, 'customers', id);
        if (row == null) {
          throw const CatalogValidationException('Customer not found');
        }
        final changed = CatalogSupport.changedFields(row.json, proposed);
        if (changed.isEmpty) return;
        final json = {...row.json, ...changed, 'updated_at': iso};
        await txn.update(
          'customers',
          {
            if (changed.containsKey('name')) 'name': changed['name'],
            if (changed.containsKey('phone')) 'phone': changed['phone'],
            if (changed.containsKey('email')) 'email': changed['email'],
            'json': jsonEncode(json),
            'updated_at': iso,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await scope.enqueue(
          entity: entity,
          op: 'update',
          entityId: id,
          occurredAt: now,
          baseVersion: row.version,
          payload: changed,
        );
      },
    );
  }

  static String? _blankToNull(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
