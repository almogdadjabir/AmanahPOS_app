import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/sync/catalog_support.dart';
import '../../../core/sync/local_writer.dart';
import '../../../core/sync/sync_schema.dart';
import '../data/models/requests/create_vendor_request_dto.dart';
import '../data/models/requests/update_vendor_request_dto.dart';
import '../data/models/responses/vendor_response_dto.dart';

/// The only writer of local vendor edits on the sync engine path (one
/// [LocalWriter.write] per call). A created row has `version` NULL and the
/// legacy `VendorData` json shape. Vendor names are not unique.
class VendorService {
  VendorService({
    required LocalWriter writer,
    required CatalogActor Function() actor,
    DateTime Function()? now,
    Uuid? uuid,
  }) : _writer = writer,
       _actor = actor,
       _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final LocalWriter _writer;
  final CatalogActor Function() _actor;
  final DateTime Function() _now;
  final Uuid _uuid;

  static const Set<String> tables = {'vendors', SyncTables.outbox};

  /// Returns the new vendor id (client UUID v4).
  Future<String> create(CreateVendorRequestDto request) async {
    CatalogSupport.requireWrite(_actor());
    if (request.name.trim().isEmpty) {
      throw const CatalogValidationException('Name is required');
    }
    final payload = request.toJson();
    final now = _now().toUtc();
    final id = _uuid.v4();
    return _writer.write<String>(
      tables: tables,
      body: (scope) async {
        final iso = now.toIso8601String();
        await scope.txn.insert('vendors', {
          'id': id,
          'json': jsonEncode({
            ...VendorData(
              id: id,
              name: payload['name'] as String,
              phone: payload['phone'] as String?,
              email: payload['email'] as String?,
              address: payload['address'] as String?,
              notes: payload['notes'] as String?,
              isActive: true,
            ).toJson(),
            'created_at': iso,
            'updated_at': iso,
          }),
          'updated_at': iso,
          'version': null,
        });
        await scope.enqueue(
          entity: 'vendor',
          op: 'create',
          entityId: id,
          occurredAt: now,
          payload: {...payload, 'id': id},
        );
        return id;
      },
    );
  }

  /// Only changed fields are sent, with the row's `version` as `baseVersion`.
  /// No change writes nothing.
  Future<void> update(String id, UpdateVendorRequestDto dto) async {
    CatalogSupport.requireWrite(_actor());
    final now = _now().toUtc();
    await _writer.write<void>(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        final row = await CatalogSupport.loadRow(txn, 'vendors', id);
        // An inactive vendor can only be reactivated.
        if (row == null ||
            (row.json['is_active'] == false && dto.isActive != true)) {
          throw const CatalogValidationException('Vendor not found');
        }
        final changed = CatalogSupport.changedFields(row.json, dto.toJson());
        if (changed.isEmpty) return;
        final iso = now.toIso8601String();
        await txn.update(
          'vendors',
          {
            'json': jsonEncode({...row.json, ...changed, 'updated_at': iso}),
            'updated_at': iso,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await scope.enqueue(
          entity: 'vendor',
          op: 'update',
          entityId: id,
          occurredAt: now,
          baseVersion: row.version,
          payload: changed,
        );
      },
    );
  }

  /// A never-sent create with no waiting row (e.g. an inbound receipt) is
  /// dropped with its outbox rows (R7); otherwise the vendor is marked
  /// inactive and a `delete` is enqueued after any open create.
  Future<void> delete(String id) async {
    CatalogSupport.requireWrite(_actor());
    final now = _now().toUtc();
    await _writer.write<void>(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        final sc = scope.scope;
        if (sc == null) throw StateError('no signed-in scope');
        final row = await CatalogSupport.loadRow(txn, 'vendors', id);
        if (row == null || row.json['is_active'] == false) {
          throw const CatalogValidationException('Vendor not found');
        }
        if (await CatalogSupport.dropNeverSentCreate(
          txn,
          'vendor',
          id,
          scope: sc,
        )) {
          await txn.delete('vendors', where: 'id = ?', whereArgs: [id]);
          return;
        }
        final iso = now.toIso8601String();
        await txn.update(
          'vendors',
          {
            'json': jsonEncode({
              ...row.json,
              'is_active': false,
              'updated_at': iso,
            }),
            'updated_at': iso,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
        await scope.enqueue(
          entity: 'vendor',
          op: 'delete',
          entityId: id,
          occurredAt: now,
          baseVersion: row.version,
          payload: const {},
        );
      },
    );
  }
}
