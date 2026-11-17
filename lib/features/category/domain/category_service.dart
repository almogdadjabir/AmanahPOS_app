import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../common/services/image/app_image_picker.dart';
import '../../../core/sync/appliers/applier_support.dart';
import '../../../core/sync/catalog_support.dart';
import '../../../core/sync/images/pending_upload_store.dart';
import '../../../core/sync/local_writer.dart';
import '../../../core/sync/sync_schema.dart';
import '../data/models/requests/add_category_request_dto.dart';
import '../data/models/requests/edit_category_request_dto.dart';

/// The only writer of local category edits on the sync engine path. Each
/// call is ONE [LocalWriter.write]: row, derived fields and outbox row
/// commit together. A created row has `version` NULL (unsent) and keeps the
/// flat legacy json shape `CategoryApplier` writes.
///
/// Images (Task 7): a picked image is copied and hashed BEFORE the write
/// ([PendingUploadStore.prepare]) and staged in `pending_uploads` inside it,
/// exactly like `ProductService`; the foreground `ImageUploader` sends it
/// once the row exists on the server. A create carries
/// `image_pending: true`; an image-only edit enqueues nothing.
class CategoryService {
  CategoryService({
    required LocalWriter writer,
    required CatalogActor Function() actor,
    PendingUploadStore? uploads,
    DateTime Function()? now,
    Uuid? uuid,
  }) : _writer = writer,
       _actor = actor,
       _uploads = uploads,
       _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final LocalWriter _writer;
  final CatalogActor Function() _actor;
  final PendingUploadStore? _uploads;
  final DateTime Function() _now;
  final Uuid _uuid;

  static const String entity = 'category';

  static const Set<String> tables = {
    'categories',
    'products',
    SyncTables.pendingUploads,
    SyncTables.outbox,
  };

  /// Returns the new category id (client UUID v4). [image] is staged for
  /// upload in the same write.
  Future<String> create({
    required String name,
    String? parent,
    String? description,
    PickedAppImage? image,
  }) async {
    CatalogSupport.requireWrite(_actor());
    final n = name.trim();
    if (n.isEmpty) throw const CatalogValidationException('Name is required');
    final now = _now().toUtc();
    final id = _uuid.v4();
    final staged = await _prepareImage(image, id);
    final ({String id, List<String> obsolete}) r;
    try {
      r = await _writer.write(
        tables: tables,
        body: (scope) async {
          final created = await createIn(
            scope,
            name: n,
            parent: parent,
            description: description,
            now: now,
            id: id,
            imagePending: staged != null,
          );
          return (id: created, obsolete: await _stage(scope, staged));
        },
      );
    } catch (_) {
      if (staged != null) await _uploads!.discard(staged);
      rethrow;
    }
    await _uploads?.deleteFiles(r.obsolete);
    return r.id;
  }

  /// The body of [create] for a caller that already holds a [WriteScope]
  /// (`LocalWriter.write` cannot nest; e.g. `ProductService` creating the
  /// auto "General" category in the product's own write). Validates name,
  /// parent and duplicates, inserts the row and enqueues the create. The
  /// caller checks the actor and includes [tables] in its write.
  Future<String> createIn(
    WriteScope scope, {
    required String name,
    String? parent,
    String? description,
    required DateTime now,
    String? id,
    bool imagePending = false,
  }) async {
    final n = name.trim();
    if (n.isEmpty) throw const CatalogValidationException('Name is required');
    final desc = _blankToNull(description);
    final parentId = _blankToNull(parent);
    final newId = id ?? _uuid.v4();
    final txn = scope.txn;
    final sc = scope.scope;
    if (sc == null) throw StateError('no signed-in scope');
    final tenant = tenantOfScope(sc);
    if (parentId != null) {
      final p = await CatalogSupport.loadRow(txn, 'categories', parentId);
      if (p == null || p.json['is_active'] == false) {
        throw const CatalogValidationException('Parent category not found');
      }
    }
    await _checkDuplicateName(scope, n, exceptId: null);
    final dto = AddCategoryRequestDto(name: n, description: desc);
    final iso = now.toIso8601String();
    await txn.insert('categories', {
      'id': newId,
      'tenant_id': tenant,
      'parent_id': parentId,
      'name': n,
      'json': jsonEncode({
        'id': newId,
        'tenant': tenant,
        'parent': parentId,
        'name': n,
        'description': desc,
        'image': null,
        'thumbnail_url': null,
        'is_active': true,
        'sort_order': 0,
        'product_count': 0,
        'children': null,
        'created_at': iso,
        'updated_at': iso,
      }),
      'updated_at': iso,
      'version': null,
    });
    await scope.enqueue(
      entity: 'category',
      op: 'create',
      entityId: newId,
      occurredAt: now,
      dependsOn: [?parentId],
      payload: {
        ...dto.toJson(),
        'parent': ?parentId,
        'id': newId,
        if (imagePending) 'image_pending': true,
      },
    );
    return newId;
  }

  /// Only changed fields are sent, with the row's `version` as `baseVersion`
  /// (null while the create is unsent). A rename also refreshes
  /// `category_name` of its products. No change writes nothing. A new
  /// [image] is staged (replacing an earlier unsent pick) and needs no
  /// outbox row.
  Future<void> update(
    String id,
    EditCategoryRequestDto dto, {
    PickedAppImage? image,
  }) async {
    CatalogSupport.requireWrite(_actor());
    final now = _now().toUtc();
    final staged = await _prepareImage(image, id);
    final List<String> obsolete;
    try {
      obsolete = await _writer.write<List<String>>(
        tables: tables,
        body: (scope) async {
          final row = await CatalogSupport.loadRow(scope.txn, 'categories', id);
          if (row == null || row.json['is_active'] == false) {
            throw const CatalogValidationException('Category not found');
          }
          await _applyUpdate(scope, id, dto, now);
          return _stage(scope, staged);
        },
      );
    } catch (_) {
      if (staged != null) await _uploads!.discard(staged);
      rethrow;
    }
    await _uploads?.deleteFiles(obsolete);
  }

  /// The field part of [update] (row already checked active).
  Future<void> _applyUpdate(
    WriteScope scope,
    String id,
    EditCategoryRequestDto dto,
    DateTime now,
  ) async {
    final txn = scope.txn;
    final row = (await CatalogSupport.loadRow(txn, 'categories', id))!;
    final proposed = <String, dynamic>{};
    if (dto.name != null) {
      final n = dto.name!.trim();
      if (n.isEmpty) {
        throw const CatalogValidationException('Name is required');
      }
      proposed['name'] = n;
    }
    if (dto.description != null) {
      proposed['description'] = dto.description!.trim();
    }
    final changed = CatalogSupport.changedFields(row.json, proposed);
    if (changed.isEmpty) return;
    if (changed.containsKey('name')) {
      await _checkDuplicateName(scope, changed['name'] as String, exceptId: id);
    }
    final iso = now.toIso8601String();
    final json = {...row.json, ...changed, 'updated_at': iso};
    await txn.update(
      'categories',
      {
        if (changed.containsKey('name')) 'name': changed['name'],
        'json': jsonEncode(json),
        'updated_at': iso,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (changed.containsKey('name')) {
      await refreshProductsCategoryName(txn, id, changed['name'] as String);
    }
    await scope.enqueue(
      entity: entity,
      op: 'update',
      entityId: id,
      occurredAt: now,
      baseVersion: row.version,
      payload: changed,
    );
  }

  /// Records [staged] under the write's sync scope; returns the files of
  /// the replaced upload (deleted after the commit).
  Future<List<String>> _stage(WriteScope scope, StagedImage? staged) async {
    if (staged == null) return const <String>[];
    final sc = scope.scope;
    if (sc == null) throw StateError('no signed-in scope');
    return (await _uploads!.stage(scope.txn, staged, scope: sc)).obsoleteFiles;
  }

  /// Copies and hashes [picked] (file I/O, outside any transaction).
  Future<StagedImage?> _prepareImage(PickedAppImage? picked, String id) async {
    if (picked == null) return null;
    final uploads = _uploads;
    if (uploads == null) {
      throw StateError('CategoryService has no PendingUploadStore');
    }
    try {
      return await uploads.prepare(
        entity: entity,
        entityId: id,
        source: picked.file,
      );
    } on Exception catch (_) {
      throw const CatalogValidationException('The picked image is unreadable');
    }
  }

  /// Refused while the category has active products or active children. A
  /// never-sent create with no waiting row is dropped with its outbox rows
  /// (R7); otherwise the row is marked inactive and a `delete` is enqueued
  /// (after any open create, so waiting rows unblock normally).
  Future<void> delete(String id) async {
    CatalogSupport.requireWrite(_actor());
    final now = _now().toUtc();
    final files = await _writer.write<List<String>>(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        final sc = scope.scope;
        if (sc == null) throw StateError('no signed-in scope');
        final row = await CatalogSupport.loadRow(txn, 'categories', id);
        if (row == null || row.json['is_active'] == false) {
          throw const CatalogValidationException('Category not found');
        }
        final products = await txn.query(
          'products',
          columns: ['json'],
          where: 'category_id = ?',
          whereArgs: [id],
        );
        if (products.any(
          (p) => decodeJsonMap(p['json'])['is_active'] != false,
        )) {
          throw const CatalogValidationException(
            'Category has products; move or delete them first',
          );
        }
        final children = await txn.query(
          'categories',
          columns: ['json'],
          where: 'parent_id = ?',
          whereArgs: [id],
        );
        if (children.any(
          (c) => decodeJsonMap(c['json'])['is_active'] != false,
        )) {
          throw const CatalogValidationException(
            'Category has sub-categories; delete them first',
          );
        }
        // A staged image of a deleted category is never sent.
        final files = await _uploads?.cancel(txn, entity, id) ?? const [];
        if (await CatalogSupport.dropNeverSentCreate(
          txn,
          'category',
          id,
          scope: sc,
        )) {
          await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
          await unregisterAssets(txn, 'category', id);
          return files;
        }
        final iso = now.toIso8601String();
        await txn.update(
          'categories',
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
          entity: 'category',
          op: 'delete',
          entityId: id,
          occurredAt: now,
          baseVersion: row.version,
          payload: const {},
        );
        return files;
      },
    );
    await _uploads?.deleteFiles(files);
  }

  /// Best effort against local active rows of the tenant (the server stays
  /// authoritative).
  Future<void> _checkDuplicateName(
    WriteScope scope,
    String name, {
    required String? exceptId,
  }) async {
    final rows = await scope.txn.query(
      'categories',
      columns: ['id', 'name', 'json'],
    );
    final lower = name.toLowerCase();
    for (final r in rows) {
      if (r['id'] == exceptId) continue;
      if (decodeJsonMap(r['json'])['is_active'] == false) continue;
      if (((r['name'] as String?) ?? '').trim().toLowerCase() == lower) {
        throw const CatalogValidationException(
          'A category with this name already exists',
        );
      }
    }
  }

  static String? _blankToNull(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}
