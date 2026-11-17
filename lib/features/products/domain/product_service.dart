import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../common/services/image/app_image_picker.dart';
import '../../../core/permissions/app_permissions.dart';
import '../../../core/sync/appliers/applier_support.dart';
import '../../../core/sync/catalog_support.dart';
import '../../../core/sync/decimal3.dart';
import '../../../core/sync/images/pending_upload_store.dart';
import '../../../core/sync/local_writer.dart';
import '../../../core/sync/sync_schema.dart';
import '../../category/domain/category_service.dart';
import '../../inventory/domain/stock_service.dart';
import '../data/model/request/add_product_request_dto.dart';
import '../data/model/request/update_product_request_dto.dart';

/// The only writer of local product edits on the sync engine path. Each
/// call is ONE [LocalWriter.write]: product row, derived fields, outbox rows
/// and the `pending_uploads` row commit together.
///
/// A created row has `version` NULL (unsent) and the shape `ProductApplier`
/// writes (columns + full json incl. `category_name`, `stock_level`).
/// `stock_level` is never changed by create/update (only by stock writes).
/// A picked image is staged ([PendingUploadStore]), never sent here: the row
/// keeps `thumbnail_url`/`image_url` NULL and the image widget resolves the
/// pending file by entity id; the create payload carries
/// `image_pending: true`. Staged-file I/O runs BEFORE the transaction; a
/// failed write deletes the new file, a committed one deletes the replaced
/// / cancelled files.
class ProductService {
  ProductService({
    required LocalWriter writer,
    required CatalogActor Function() actor,
    required PendingUploadStore uploads,
    required CategoryService categories,
    DateTime Function()? now,
    Uuid? uuid,
  }) : _writer = writer,
       _actor = actor,
       _uploads = uploads,
       _categories = categories,
       _now = now ?? DateTime.now,
       _uuid = uuid ?? const Uuid();

  final LocalWriter _writer;
  final CatalogActor Function() _actor;
  final PendingUploadStore _uploads;
  final CategoryService _categories;
  final DateTime Function() _now;
  final Uuid _uuid;

  static const String entity = 'product';

  static const Set<String> tables = {
    'products',
    'categories',
    'stock',
    SyncTables.pendingUploads,
    SyncTables.outbox,
  };

  /// BE `Product.price`/`cost_price`: DecimalField(max_digits=12,
  /// decimal_places=2), >= 0.
  static final RegExp _money = RegExp(r'^\d{1,10}(\.\d{1,2})?$');
  static final RegExp _uint = RegExp(r'^\d{1,9}$');

  /// Returns the new product id (client UUID v4).
  ///
  /// [newCategoryName]: used only when `dto.category` is blank (the form's
  /// auto "General"): an active local category of that name (case
  /// insensitive) is reused, else it is created IN THE SAME WRITE
  /// (`CategoryService.createIn`) and the product depends on it.
  ///
  /// [initialQuantity] (blank = none) with [shopId]: an opening `stock.add`
  /// enqueued in the same write right after the create, depending on the
  /// new product id (`StockService.enqueueOpIn`). Must be > 0, <= 3
  /// decimals; refused for restaurants (no inventory).
  Future<String> create(
    AddProductRequestDto dto, {
    String? initialQuantity,
    String? shopId,
    String? newCategoryName,
  }) async {
    final actor = _actor();
    CatalogSupport.requireWrite(actor);
    final name = dto.name.trim();
    if (name.isEmpty) {
      throw const CatalogValidationException('Name is required');
    }
    final price = _requireMoney(dto.price, 'Price');
    final cost = _optionalMoney(dto.costPrice, 'Cost price');
    final unit = dto.unit.trim();
    if (unit.isEmpty) {
      throw const CatalogValidationException('Unit is required');
    }
    final minStock = _optionalUint(dto.minStockLevel, 'Minimum stock');
    final expiryDays = _optionalUint(dto.expiryAlertDays, 'Expiry alert days');
    final sku = _blankToNull(dto.sku);
    final barcode = _blankToNull(dto.barcode);
    final chosenCategory = _blankToNull(dto.category);
    final newCategory = chosenCategory == null
        ? _blankToNull(newCategoryName)
        : null;
    if (chosenCategory == null && newCategory == null) {
      throw const CatalogValidationException('Category is required');
    }

    ({BigInt units, String shop})? opening;
    final rawQty = initialQuantity?.trim() ?? '';
    if (rawQty.isNotEmpty) {
      if (actor.businessType == AppBusinessType.restaurant) {
        throw const CatalogValidationException(
          'Restaurants do not track inventory',
        );
      }
      final BigInt units;
      try {
        units = StockService.parseQuantity(rawQty);
      } on StockValidationException catch (e) {
        throw CatalogValidationException(e.message);
      }
      if (units <= BigInt.zero) {
        throw const CatalogValidationException(
          'Opening quantity must be greater than 0',
        );
      }
      final shop = _blankToNull(shopId);
      if (shop == null) {
        throw const CatalogValidationException('Shop is required');
      }
      opening = (units: units, shop: shop);
    }
    final openingStock = opening;

    final now = _now().toUtc();
    final id = _uuid.v4();
    final staged = await _prepareImage(dto.imageUpload, id);
    final List<String> obsolete;
    try {
      obsolete = await _writer.write<List<String>>(
        tables: tables,
        body: (scope) async {
          final txn = scope.txn;
          final catId =
              chosenCategory ??
              await _activeCategoryNamed(txn, newCategory!) ??
              await _categories.createIn(scope, name: newCategory!, now: now);
          final cat = await _requireCategory(txn, catId);
          await _checkUnique(txn, sku: sku, barcode: barcode, exceptId: null);

          final wire = AddProductRequestDto(
            name: name,
            price: price,
            category: catId,
            unit: unit,
            costPrice: cost,
            description: _blankToNull(dto.description),
            sku: sku,
            barcode: barcode,
            trackInventory: dto.trackInventory,
            minStockLevel: minStock,
            expiryAlertDays: expiryDays,
          ).toJson();
          final iso = now.toIso8601String();
          final json = <String, dynamic>{
            ...wire,
            'id': id,
            'category_name':
                cat.json['name'] ?? await _categoryName(txn, catId),
            'sku': sku,
            'barcode': barcode,
            'cost_price': cost,
            'min_stock_level': _jsonInt(minStock) ?? 0,
            'expiry_alert_days': _jsonInt(expiryDays),
            'image': null,
            'thumbnail_url': null,
            'image_hash': null,
            'is_active': true,
            'stock_level': 0.0,
            'created_at': iso,
            'updated_at': iso,
          };
          await txn.insert('products', {
            'id': id,
            'category_id': catId,
            'name': name,
            'sku': sku,
            'barcode': barcode,
            'price': price,
            'stock_level': 0.0,
            'thumbnail_url': null,
            'image_url': null,
            'image_hash': null,
            'json': jsonEncode(json),
            'updated_at': iso,
            'version': null,
          });
          await refreshCategoryProductCount(txn, catId);
          await scope.enqueue(
            entity: entity,
            op: 'create',
            entityId: id,
            occurredAt: now,
            dependsOn: [catId],
            payload: {
              ...wire,
              'id': id,
              if (staged != null) 'image_pending': true,
            },
          );
          if (openingStock != null) {
            await StockService.enqueueOpIn(
              scope,
              op: 'add',
              productId: id,
              shopId: openingStock.shop,
              delta: openingStock.units,
              reason: '',
              occurredAt: now,
              entityId: _uuid.v4(),
            );
          }
          return _stage(scope, staged);
        },
      );
    } catch (_) {
      if (staged != null) await _uploads.discard(staged);
      rethrow;
    }
    // After the commit, outside the catch: a failure here must never
    // discard the file the committed row now references.
    await _uploads.deleteFiles(obsolete);
    return id;
  }

  /// Only changed fields are sent (money compared as numbers), with the
  /// row's `version` as `baseVersion` (null while the create is unsent). A
  /// new image replaces the staged upload; an image-only change enqueues no
  /// outbox row (the uploader sends it). No change writes nothing.
  Future<void> update(String id, UpdateProductRequestDto dto) async {
    CatalogSupport.requireWrite(_actor());
    final proposed = <String, dynamic>{};
    if (dto.name != null) {
      final n = dto.name!.trim();
      if (n.isEmpty) throw const CatalogValidationException('Name is required');
      proposed['name'] = n;
    }
    if (dto.price != null) {
      proposed['price'] = _requireMoney(dto.price, 'Price');
    }
    if (dto.costPrice != null) {
      // '' clears: BE cost_price is NOT NULL with default 0, so clearing
      // sends '0'.
      proposed['cost_price'] =
          _optionalMoney(dto.costPrice, 'Cost price') ?? '0';
    }
    if (dto.category != null) {
      final c = dto.category!.trim();
      if (c.isEmpty) {
        throw const CatalogValidationException('Category is required');
      }
      proposed['category'] = c;
    }
    if (dto.unit != null) {
      final u = dto.unit!.trim();
      if (u.isEmpty) throw const CatalogValidationException('Unit is required');
      proposed['unit'] = u;
    }
    if (dto.description != null) {
      proposed['description'] = dto.description!.trim();
    }
    // '' clears: BE barcode is CharField(blank=True), not nullable.
    if (dto.barcode != null) proposed['barcode'] = dto.barcode!.trim();
    if (dto.trackInventory != null) {
      proposed['track_inventory'] = dto.trackInventory;
    }
    if (dto.minStockLevel != null) {
      proposed['min_stock_level'] =
          _optionalUint(dto.minStockLevel, 'Minimum stock') ?? '0';
    }
    if (dto.expiryAlertDays != null) {
      // '' clears: BE PositiveIntegerField(null=True); a JSON '' is not a
      // valid integer for DRF, so a cleared value is sent as null.
      proposed['expiry_alert_days'] = _optionalUint(
        dto.expiryAlertDays,
        'Expiry alert days',
      );
    }

    final now = _now().toUtc();
    final staged = await _prepareImage(dto.imageUpload, id);
    final List<String> obsolete;
    try {
      obsolete = await _writer.write<List<String>>(
        tables: tables,
        body: (scope) async {
          final txn = scope.txn;
          final row = await CatalogSupport.loadRow(txn, 'products', id);
          if (row == null || row.json['is_active'] == false) {
            throw const CatalogValidationException('Product not found');
          }
          final changed = _changed(row.json, proposed);
          if (changed.isNotEmpty) {
            await _applyUpdate(scope, id, row, changed, now);
          }
          return _stage(scope, staged);
        },
      );
    } catch (_) {
      if (staged != null) await _uploads.discard(staged);
      rethrow;
    }
    await _uploads.deleteFiles(obsolete);
  }

  /// Records [staged] under the write's sync scope; returns the files of
  /// the replaced upload (deleted after the commit).
  Future<List<String>> _stage(WriteScope scope, StagedImage? staged) async {
    if (staged == null) return const <String>[];
    final sc = scope.scope;
    if (sc == null) throw StateError('no signed-in scope');
    return (await _uploads.stage(scope.txn, staged, scope: sc)).obsoleteFiles;
  }

  Future<void> _applyUpdate(
    WriteScope scope,
    String id,
    ({Map<String, dynamic> json, int? version}) row,
    Map<String, dynamic> changed,
    DateTime now,
  ) async {
    final txn = scope.txn;
    final oldCategory = row.json['category'] as String?;
    final newCategory = changed['category'] as String?;
    String? newCategoryName;
    if (newCategory != null) {
      final cat = await _requireCategory(txn, newCategory);
      newCategoryName = cat.json['name'] as String?;
    }
    if (changed.containsKey('barcode')) {
      await _checkUnique(
        txn,
        sku: null,
        barcode: _blankToNull(changed['barcode'] as String?),
        exceptId: id,
      );
    }
    final iso = now.toIso8601String();
    final json = <String, dynamic>{
      ...row.json,
      ...changed,
      if (changed.containsKey('min_stock_level'))
        'min_stock_level': _jsonInt(changed['min_stock_level'] as String?) ?? 0,
      if (changed.containsKey('expiry_alert_days'))
        'expiry_alert_days': _jsonInt(changed['expiry_alert_days'] as String?),
      if (changed.containsKey('barcode'))
        'barcode': _blankToNull(changed['barcode'] as String?),
      if (newCategory != null) 'category_name': newCategoryName,
      'updated_at': iso,
    };
    await txn.update(
      'products',
      {
        if (changed.containsKey('name')) 'name': changed['name'],
        if (changed.containsKey('price')) 'price': changed['price'],
        if (changed.containsKey('barcode')) 'barcode': json['barcode'],
        'category_id': ?newCategory,
        'json': jsonEncode(json),
        'updated_at': iso,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (newCategory != null && newCategory != oldCategory) {
      await refreshCategoryProductCount(txn, newCategory);
      await refreshCategoryProductCount(txn, oldCategory);
    }
    await scope.enqueue(
      entity: entity,
      op: 'update',
      entityId: id,
      occurredAt: now,
      baseVersion: row.version,
      dependsOn: [?newCategory],
      payload: changed,
    );
  }

  /// Cancels any staged upload (files removed after commit). A never-sent
  /// create with no waiting row is dropped with its outbox rows, local stock
  /// rows and row (R7); otherwise the row is marked inactive and a `delete`
  /// is enqueued (after any open create; waiting rows, e.g. the opening
  /// `stock.add`, are never failed by a local delete).
  Future<void> delete(String id) async {
    CatalogSupport.requireWrite(_actor());
    final now = _now().toUtc();
    final files = await _writer.write<List<String>>(
      tables: tables,
      body: (scope) async {
        final txn = scope.txn;
        final sc = scope.scope;
        if (sc == null) throw StateError('no signed-in scope');
        final row = await CatalogSupport.loadRow(txn, 'products', id);
        if (row == null || row.json['is_active'] == false) {
          throw const CatalogValidationException('Product not found');
        }
        final files = await _uploads.cancel(txn, entity, id);
        if (await CatalogSupport.dropNeverSentCreate(
          txn,
          entity,
          id,
          scope: sc,
        )) {
          await txn.delete('products', where: 'id = ?', whereArgs: [id]);
          // Nothing waits on the product, so no stock row carries a pending
          // delta; any row is a local base-0 placeholder.
          await txn.delete('stock', where: 'product_id = ?', whereArgs: [id]);
          await unregisterAssets(txn, entity, id);
          await refreshCategoryProductCount(
            txn,
            row.json['category'] as String?,
          );
          return files;
        }
        final iso = now.toIso8601String();
        await txn.update(
          'products',
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
          entity: entity,
          op: 'delete',
          entityId: id,
          occurredAt: now,
          baseVersion: row.version,
          payload: const {},
        );
        return files;
      },
    );
    await _uploads.deleteFiles(files);
  }

  Future<StagedImage?> _prepareImage(PickedAppImage? picked, String id) async {
    if (picked == null) return null;
    try {
      return await _uploads.prepare(
        entity: entity,
        entityId: id,
        source: picked.file,
      );
    } on Exception catch (_) {
      throw const CatalogValidationException('The picked image is unreadable');
    }
  }

  Future<({Map<String, dynamic> json, int? version})> _requireCategory(
    DatabaseExecutor txn,
    String id,
  ) async {
    final c = await CatalogSupport.loadRow(txn, 'categories', id);
    if (c == null || c.json['is_active'] == false) {
      throw const CatalogValidationException('Category not found');
    }
    return c;
  }

  Future<String?> _categoryName(DatabaseExecutor txn, String id) async {
    final r = await txn.query(
      'categories',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return r.isEmpty ? null : r.first['name'] as String?;
  }

  Future<String?> _activeCategoryNamed(
    DatabaseExecutor txn,
    String name,
  ) async {
    final rows = await txn.query('categories', columns: ['id', 'name', 'json']);
    final lower = name.trim().toLowerCase();
    for (final r in rows) {
      if (decodeJsonMap(r['json'])['is_active'] == false) continue;
      if (((r['name'] as String?) ?? '').trim().toLowerCase() == lower) {
        return r['id'] as String;
      }
    }
    return null;
  }

  /// BE `_unique_conflict`: sku and barcode are unique per tenant across ALL
  /// products (active or not), exact match. Best effort locally.
  Future<void> _checkUnique(
    DatabaseExecutor txn, {
    required String? sku,
    required String? barcode,
    required String? exceptId,
  }) async {
    for (final (col, value, label) in [
      ('sku', sku, 'SKU'),
      ('barcode', barcode, 'barcode'),
    ]) {
      if (value == null) continue;
      final rows = await txn.query(
        'products',
        columns: ['id'],
        where: exceptId == null
            ? 'TRIM($col) = ?'
            : 'TRIM($col) = ? AND id != ?',
        whereArgs: [value, ?exceptId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        throw CatalogValidationException(
          'Another product already uses this $label',
        );
      }
    }
  }

  /// Fields of [proposed] that differ from [current]: money and integers
  /// compared as numbers, strings trimmed (null == '').
  static Map<String, dynamic> _changed(
    Map<String, dynamic> current,
    Map<String, dynamic> proposed,
  ) {
    const money = {'price', 'cost_price'};
    const ints = {'min_stock_level', 'expiry_alert_days'};
    final out = <String, dynamic>{};
    proposed.forEach((k, v) {
      final cur = current[k];
      bool same;
      if (money.contains(k)) {
        same = Decimal3.tryParse(cur) == Decimal3.tryParse(v);
      } else if (ints.contains(k)) {
        same = _jsonInt('${cur ?? ''}') == _jsonInt('${v ?? ''}');
      } else if (v is bool) {
        same = cur == v;
      } else {
        same = CatalogSupport.changedFields({k: cur}, {k: v}).isEmpty;
      }
      if (!same) out[k] = v;
    });
    return out;
  }

  static String _requireMoney(String? raw, String label) {
    final s = raw?.trim() ?? '';
    if (!_money.hasMatch(s)) {
      throw CatalogValidationException(
        '$label must be a number with at most 2 decimals',
      );
    }
    return s;
  }

  static String? _optionalMoney(String? raw, String label) {
    final s = raw?.trim() ?? '';
    return s.isEmpty ? null : _requireMoney(s, label);
  }

  static String? _optionalUint(String? raw, String label) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return null;
    // Forms send "5" or "5.0" for a whole number.
    final m = RegExp(r'^(\d+)(?:\.0*)?$').firstMatch(s);
    if (m == null || !_uint.hasMatch(m.group(1)!)) {
      throw CatalogValidationException('$label must be a whole number');
    }
    return m.group(1);
  }

  static int? _jsonInt(String? s) {
    final t = s?.trim() ?? '';
    if (t.isEmpty) return null;
    return int.tryParse(t) ?? num.tryParse(t)?.toInt();
  }

  static String? _blankToNull(String? s) {
    final t = s?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}
