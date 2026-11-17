import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/offline/offline_db.dart';
import '../../../core/sync/appliers/applier_support.dart';
import '../../../core/sync/catalog_support.dart';
import '../../../core/sync/images/pending_upload_store.dart';
import '../../../core/sync/local_writer.dart';
import '../../../core/sync/outbox/outbox_entry.dart';
import '../../../core/sync/outbox/outbox_store.dart';
import '../../../core/sync/sync_schema.dart';
import '../../../core/sync/sync_scope.dart';
import '../../inventory/data/local/stock_local_store.dart';
import '../../pos/data/local/sale_local_store.dart';

/// What a merge changes (or would change: [CatalogConflictService.
/// previewMerge]); shown in the confirmation dialog.
class MergeReport extends Equatable {
  const MergeReport({
    this.saleLines = 0,
    this.stockRows = 0,
    this.requeued = 0,
    this.dropped = 0,
    this.products = 0,
    this.childCategories = 0,
    this.inbound = 0,
    this.uploads = 0,
    this.targetInactive = false,
  });

  /// `sale_items` lines moved to the existing product.
  final int saleLines;

  /// Local `stock` rows of the dropped product (moved or folded).
  final int stockRows;

  /// Queued changes (sales, stock, inbound, creates) put back in the queue.
  final int requeued;

  /// Outbox rows of the dropped entity removed (its create and edits).
  final int dropped;

  /// Products moved to the existing category.
  final int products;

  /// Categories whose parent becomes the existing category.
  final int childCategories;

  /// Received-stock records rewritten.
  final int inbound;

  /// Staged images of the dropped copy, discarded (fix-wave: a merge never
  /// replaces the existing row's server image).
  final int uploads;

  /// The existing row is inactive (deleted on the server; an SKU / name
  /// clash with a deleted row). The merged sales and stock then belong to an
  /// item the POS hides (review M2): the dialog says so.
  final bool targetInactive;

  /// Queued edits of the dropped copy (its rows minus the create).
  int get droppedEdits => dropped > 1 ? dropped - 1 : 0;

  /// Rows that will point at the existing item.
  int get total =>
      saleLines + stockRows + requeued + products + childCategories + inbound;

  @override
  List<Object?> get props => [
    saleLines,
    stockRows,
    requeued,
    dropped,
    products,
    childCategories,
    inbound,
    uploads,
    targetInactive,
  ];
}

/// Thrown to roll a preview transaction back with its report.
class _Rollback implements Exception {
  const _Rollback(this.report);
  final MergeReport report;
}

/// The pending-sync screen's actions on rejected catalog rows (conflict
/// policy A, spec "Push results"):
///
/// - [mergeInto]: "Merge into existing", the ONLY place a local id is ever
///   rewritten, and only on an explicit, confirmed user action. Offered only
///   for a rejected create that carries the server's `conflict_entity_id`
///   ([canMerge]). The copy's queued edits and staged image are dropped;
///   its stock changes count on the existing row.
/// - [discardRejected]: drop a rejected (or not yet sent) catalog row. A
///   create with nothing waiting on it removes the local row, its staged
///   image, its opening stock and its outbox rows; a create other rows wait
///   on is refused (I3 / R7); an update / delete restores the row from
///   `server_json` (plus any later queued edit).
/// - [editAndRetry]: after the user edited the row in its normal form, the
///   edit is folded into the rejected row and that row is queued again.
class CatalogConflictService {
  CatalogConflictService({
    required OfflineDb db,
    required LocalWriter writer,
    required OutboxStore outbox,
    required PendingUploadStore uploads,
    String? Function()? scope,
    Future<void> Function(String stage)? debugHook,
  }) : _db = db,
       _writer = writer,
       _outbox = outbox,
       _uploads = uploads,
       _scope = scope ?? (() => SyncScope.current),
       _hook = debugHook;

  final OfflineDb _db;
  final LocalWriter _writer;
  final OutboxStore _outbox;
  final PendingUploadStore _uploads;
  final String? Function() _scope;
  final Future<void> Function(String stage)? _hook;

  static const StockLocalStore _stock = StockLocalStore();

  /// Catalog entity -> local table.
  static const Map<String, String> tableOf = {
    'product': 'products',
    'category': 'categories',
    'vendor': 'vendors',
    'customer': 'customers',
  };

  /// `json` key set on a row whose discarded change could not be reverted
  /// (no stored server state): the next pulled version replaces the row.
  static const String staleKey = 'local_stale';

  /// Tables any action here may change (notified after the commit).
  static const Set<String> tables = {
    'products',
    'categories',
    'vendors',
    'stock',
    'inbound_transactions',
    'synced_entities',
    'premium_summary',
    kSyncedAssetsTable,
    SyncTables.pendingUploads,
    SyncTables.outbox,
    ...SaleLocalStore.tables,
  };

  /// Real columns that can hold a product / category / vendor id; every one
  /// is rewritten by a merge (`table.column`).
  static const Set<String> idColumns = {
    'products.id',
    'products.category_id',
    'categories.id',
    'categories.parent_id',
    'vendors.id',
    'customers.id',
    'sales.customer_id',
    'stock.id',
    'stock.product_id',
    'sale_items.product_id',
    'synced_assets.id',
    'pending_uploads.entity_id',
    'outbox.entity_id',
    'outbox.depends_on_entity_id',
    'outbox.depends_on_json',
    'outbox.error_entity_id',
    'outbox.failed_by_entity_id',
    'outbox.payload_json',
  };

  /// JSON columns rewritten at any depth by a merge ([CatalogSupport.
  /// replaceIdDeep]); tables missing on a device are skipped.
  static const Set<String> jsonColumns = {
    'products.json',
    'products.server_json',
    'categories.json',
    'categories.server_json',
    'vendors.json',
    'vendors.server_json',
    'stock.json',
    'sale_items.snapshot_json',
    'inbound_transactions.json',
    'synced_entities.json',
    'premium_summary.json',
    'dashboard_summary_cache.json',
    'businesses.json',
    'shops.json',
    'customers.json',
    'customers.server_json',
  };

  /// Every column a merge rewrites (the schema-grep test checks the live
  /// schema against this plus [notRewritten] and [notIdColumns]).
  static const Set<String> rewrittenColumns = {...idColumns, ...jsonColumns};

  /// Deliberately NEVER rewritten (audit): `sale_refunds.json` is the raw
  /// server feed (server ids only), `sales.warnings_json` is display
  /// history.
  static const Set<String> notRewritten = {
    'sale_refunds.json',
    'sales.warnings_json',
  };

  /// Columns whose name looks like an id column but holds no catalog id.
  static const Set<String> notIdColumns = {'sale_items.product_name'};

  /// Storage paths, not references (`pending_images/<id>/`). A merge drops
  /// the copy's staged image (row and files), so none is left naming it.
  static const Set<String> pathColumns = {
    'pending_uploads.local_path',
    'pending_uploads.thumbnail_path',
  };

  /// Hook stages of a merge (tests crash at each to prove atomicity).
  static const List<String> mergeStages = [
    'afterOutbox',
    'afterRows',
    'afterJson',
    'afterUploads',
  ];

  /// "Merge into existing" is offered for [e] only when it is a rejected
  /// catalog create that names a DIFFERENT existing row
  /// (`conflict_entity_id`). The UI keys off the field, not the entity.
  static bool canMerge(OutboxEntry e) {
    final target = e.errorEntityId?.trim() ?? '';
    return e.status == OutboxStatus.rejected &&
        e.op == 'create' &&
        tableOf.containsKey(e.entity) &&
        target.isNotEmpty &&
        target != e.entityId;
  }

  // --------------------------------------------------------------- merge

  /// What [mergeInto] would change, without changing anything (the merge
  /// runs in a transaction that is rolled back).
  Future<MergeReport> previewMerge(
    String localId,
    String serverId, {
    required String entity,
  }) async {
    final scope = _scope();
    if (scope == null) throw StateError('no signed-in scope');
    final db = await _db.database;
    MergeReport? report;
    try {
      await db.transaction((txn) async {
        final r = await _merge(
          txn,
          scope,
          entity,
          localId,
          serverId,
          files: <String>[],
          preview: true,
        );
        _rollback(r);
      });
    } on _Rollback catch (r) {
      report = r.report;
    }
    return report!;
  }

  /// Rewrites every reference to the local [localId] of [entity] to the
  /// existing server row [serverId] (all tables of the Phase 3 audit, open
  /// outbox payloads and dependencies, the staged image) and drops the
  /// rejected create, in ONE `LocalWriter.write`. Throws
  /// [CatalogValidationException] (nothing changed) unless a rejected
  /// create of [localId] names [serverId] as its `conflict_entity_id`.
  Future<MergeReport> mergeInto(
    String localId,
    String serverId, {
    required String entity,
  }) async {
    final files = <String>[];
    final report = await _writer.write<MergeReport>(
      tables: tables,
      body: (s) async {
        final scope = s.scope;
        if (scope == null) throw StateError('no signed-in scope');
        return _merge(
          s.txn,
          scope,
          entity,
          localId,
          serverId,
          files: files,
          preview: false,
        );
      },
    );
    await _uploads.deleteFiles(files);
    return report;
  }

  /// `void`, not `Never`: flow analysis must not treat the preview's
  /// transaction as never completing.
  static void _rollback(MergeReport r) => throw _Rollback(r);

  Future<void> _stage(String stage, bool preview) async {
    if (!preview) await _hook?.call(stage);
  }

  Future<MergeReport> _merge(
    Transaction txn,
    String scope,
    String entity,
    String localId,
    String serverId, {
    required List<String> files,
    required bool preview,
  }) async {
    final table = tableOf[entity];
    if (table == null) {
      throw CatalogValidationException('Cannot merge a $entity');
    }
    if (localId == serverId || serverId.trim().isEmpty) {
      throw const CatalogValidationException('Nothing to merge');
    }
    final own = await txn.query(
      SyncTables.outbox,
      where: 'entity = ? AND entity_id = ? AND scope = ?',
      whereArgs: [entity, localId, scope],
    );
    final ok = own.any(
      (r) =>
          r['op'] == 'create' &&
          r['status'] == 'rejected' &&
          r['error_entity_id'] == serverId,
    );
    if (!ok) throw const CatalogValidationException('Nothing to merge');
    if (own.any((r) => r['status'] == 'inflight' || r['lease_until'] != null)) {
      throw const CatalogValidationException('Being sent, try again');
    }

    // 1. Outbox: drop the local entity's rows, rewrite the rest.
    final dropped = await txn.delete(
      SyncTables.outbox,
      where: 'entity = ? AND entity_id = ? AND scope = ?',
      whereArgs: [entity, localId, scope],
    );
    final rekey = await _outbox.rekeyForMerge(
      txn,
      localId,
      serverId,
      scope: scope,
    );
    await _stage('afterOutbox', preview);

    // 2. Real columns.
    final serverRow = await txn.query(
      table,
      columns: ['id', 'json'],
      where: 'id = ?',
      whereArgs: [serverId],
      limit: 1,
    );
    final targetInactive =
        serverRow.isNotEmpty &&
        decodeJsonMap(serverRow.first['json'])['is_active'] == false;
    String? oldCategory;
    if (entity == 'product') {
      final r = await txn.query(
        'products',
        columns: ['category_id'],
        where: 'id = ?',
        whereArgs: [localId],
        limit: 1,
      );
      oldCategory = r.isEmpty ? null : r.first['category_id'] as String?;
    }
    if (serverRow.isNotEmpty) {
      await txn.delete(table, where: 'id = ?', whereArgs: [localId]);
    } else {
      // Not pulled yet: the local row stands in under the server id; with
      // no version, the pulled server state replaces it.
      await txn.update(
        table,
        {'id': serverId, 'version': null, 'server_json': null},
        where: 'id = ?',
        whereArgs: [localId],
      );
    }
    var saleLines = 0, stockRows = 0, products = 0, children = 0;
    final shops = <String>{};
    switch (entity) {
      case 'product':
        saleLines = await txn.update(
          'sale_items',
          {'product_id': serverId},
          where: 'product_id = ?',
          whereArgs: [localId],
        );
        final rows = await txn.query(
          'stock',
          columns: ['id', 'shop_id'],
          where: 'product_id = ?',
          whereArgs: [localId],
        );
        stockRows = rows.length;
        for (final r in rows) {
          final shop = r['shop_id'] as String;
          shops.add(shop);
          final taken = await txn.query(
            'stock',
            columns: ['id'],
            where: 'product_id = ? AND shop_id = ?',
            whereArgs: [serverId, shop],
            limit: 1,
          );
          if (taken.isNotEmpty) {
            // Never synced: its base is a local 0; the deltas now count
            // on the existing row (recomputed below).
            await txn.delete('stock', where: 'id = ?', whereArgs: [r['id']]);
          } else {
            final id = r['id'] as String;
            await txn.update(
              'stock',
              {
                'product_id': serverId,
                if (id == '$localId-$shop') 'id': '$serverId-$shop',
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }
      case 'customer':
        // Sales of the never-synced copy now belong to the existing one.
        saleLines = await txn.update(
          'sales',
          {'customer_id': serverId},
          where: 'customer_id = ?',
          whereArgs: [localId],
        );
      case 'category':
        products = await txn.update(
          'products',
          {'category_id': serverId},
          where: 'category_id = ?',
          whereArgs: [localId],
        );
        children = await txn.update(
          'categories',
          {'parent_id': serverId},
          where: 'parent_id = ?',
          whereArgs: [localId],
        );
    }
    // A never-synced id has no served image; drop its registrations.
    final assets = await txn.query(
      kSyncedAssetsTable,
      columns: ['local_path'],
      where: 'type = ? AND id = ?',
      whereArgs: [entity, localId],
    );
    for (final a in assets) {
      if (a['local_path'] is String) files.add(a['local_path'] as String);
    }
    await unregisterAssets(txn, entity, localId);
    await _stage('afterRows', preview);

    // 3. JSON blobs, any depth.
    var inbound = 0;
    for (final key in jsonColumns) {
      final dot = key.indexOf('.');
      final n = await _rewriteJson(
        txn,
        key.substring(0, dot),
        key.substring(dot + 1),
        localId,
        serverId,
      );
      if (key == 'inbound_transactions.json') inbound = n;
    }
    await _stage('afterJson', preview);

    // 4. Staged image of the copy: dropped (fix-wave ruling). It must
    // never replace the existing row's server image; the existing row keeps
    // its own (and any image staged for it stays queued).
    var uploads = 0;
    if (await _uploads.get(txn, entity, localId) != null) {
      files.addAll(await _uploads.cancel(txn, entity, localId));
      uploads = 1;
    }
    await _stage('afterUploads', preview);

    // 5. Derived values.
    final pairs = <(String, String)>{
      for (final shop in shops) (serverId, shop),
      for (final e in rekey.requeued)
        ...StockLocalStore.affectedByOutboxRow(e.entity, e.op, e.payload),
    };
    for (final (product, shop) in pairs) {
      await _stock.recompute(
        txn,
        product,
        shop,
        createIfMissing: product == serverId,
      );
    }
    switch (entity) {
      case 'product':
        final r = await txn.query(
          'products',
          columns: ['category_id'],
          where: 'id = ?',
          whereArgs: [serverId],
          limit: 1,
        );
        await refreshCategoryProductCount(txn, oldCategory);
        if (r.isNotEmpty) {
          await refreshCategoryProductCount(
            txn,
            r.first['category_id'] as String?,
          );
        }
      case 'category':
        final r = await txn.query(
          'categories',
          columns: ['name'],
          where: 'id = ?',
          whereArgs: [serverId],
          limit: 1,
        );
        await refreshProductsCategoryName(
          txn,
          serverId,
          r.isEmpty ? null : r.first['name'] as String?,
        );
        await refreshCategoryProductCount(txn, serverId);
    }

    return MergeReport(
      saleLines: saleLines,
      stockRows: stockRows,
      requeued: rekey.requeued.length,
      dropped: dropped,
      products: products,
      childCategories: children,
      inbound: inbound,
      uploads: uploads,
      targetInactive: targetInactive,
    );
  }

  /// Rewrites [from] -> [to] inside `table.column` (JSON); returns the rows
  /// changed. A table missing on this device is skipped.
  Future<int> _rewriteJson(
    Transaction txn,
    String table,
    String column,
    String from,
    String to,
  ) async {
    final exists = await txn.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      [table],
    );
    if (exists.isEmpty) return 0;
    final rows = await txn.rawQuery(
      'SELECT rowid AS rid, $column AS v FROM $table '
      "WHERE $column LIKE ? ESCAPE '\\'",
      ['%${_likeEscape(from)}%'],
    );
    var n = 0;
    for (final r in rows) {
      final raw = r['v'];
      if (raw is! String) continue;
      Object? decoded;
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        continue;
      }
      final next = jsonEncode(CatalogSupport.replaceIdDeep(decoded, from, to));
      if (next == raw) continue;
      await txn.update(
        table,
        {column: next},
        where: 'rowid = ?',
        whereArgs: [r['rid']],
      );
      n++;
    }
    return n;
  }

  static String _likeEscape(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  // ------------------------------------------------------------- discard

  static const String _discardable =
      "status IN ('pending','blocked','rejected') AND lease_until IS NULL";

  /// Discards one catalog outbox row (rejected, or not sent yet). In ONE
  /// write:
  /// - a `create`: every open row of the entity is removed, its dependents
  ///   (sales, stock, child rows) are failed and stay failed, and the local
  ///   row, its stock rows, image registrations and staged image go (files
  ///   after the commit);
  /// - an `update` / `delete`: the row is removed and the local row is
  ///   restored from `server_json` with the entity's later queued edits on
  ///   top. With no stored server state the row is kept and marked
  ///   [staleKey].
  ///
  /// Refuses a row being sent ([DiscardOutcome.sending]), another scope's
  /// row and an already confirmed one, like [OutboxStore.discard].
  Future<DiscardOutcome> discardRejected(String mutationId) async {
    final files = <String>[];
    final out = await _writer.write<DiscardOutcome>(
      tables: tables,
      body: (s) async {
        final txn = s.txn;
        final rows = await txn.query(
          SyncTables.outbox,
          where: 'mutation_id = ?',
          whereArgs: [mutationId],
          limit: 1,
        );
        if (rows.isEmpty) return DiscardOutcome.notFound;
        final e = OutboxEntry.fromRow(rows.first);
        // M6: no signed-in scope = no single-row discard at all.
        final scope = s.scope;
        if (scope == null || e.scope != scope) return DiscardOutcome.otherScope;
        if (e.status == OutboxStatus.done) return DiscardOutcome.alreadySynced;
        if (!tableOf.containsKey(e.entity)) {
          throw ArgumentError('Not a catalog row: ${e.entity}');
        }
        if (e.op == 'create') {
          final createSeq = await _openCreateSeq(
            txn,
            e.entity,
            e.entityId,
            e.scope,
          );
          // I3 / R7: never strand what waits on this create.
          if (await _dependentsOfCreate(
                txn,
                e.entity,
                e.entityId,
                scope: e.scope,
                createSeq: createSeq,
              ) >
              0) {
            return DiscardOutcome.hasDependents;
          }
          final all = await txn.query(
            SyncTables.outbox,
            where:
                "entity = ? AND entity_id = ? AND scope = ? "
                "AND status != 'done'",
            whereArgs: [e.entity, e.entityId, e.scope],
          );
          final stuck = await txn.query(
            SyncTables.outbox,
            columns: ['seq'],
            where:
                "entity = ? AND entity_id = ? AND scope = ? "
                "AND status != 'done' AND NOT ($_discardable)",
            whereArgs: [e.entity, e.entityId, e.scope],
          );
          if (stuck.isNotEmpty || all.isEmpty) return DiscardOutcome.sending;
          // M8: claimed and not answered by the server (a rejected create
          // was answered: the server holds nothing).
          if (all.any(
            (r) =>
                r['op'] == 'create' &&
                r['status'] != 'rejected' &&
                r['claimed_at'] != null,
          )) {
            return DiscardOutcome.mayBeOnServer;
          }
          await txn.delete(
            SyncTables.outbox,
            where:
                "entity = ? AND entity_id = ? AND scope = ? "
                "AND status != 'done'",
            whereArgs: [e.entity, e.entityId, e.scope],
          );
          // The opening stock written with a product create is part of it.
          final opening = await _openingStockOf(
            txn,
            e.entityId,
            scope: e.scope,
            createSeq: createSeq,
          );
          if (opening != null) {
            await txn.delete(
              SyncTables.outbox,
              where: 'seq = ?',
              whereArgs: [opening],
            );
          }
          await _outbox.failDependents(txn, e.entityId, scope: e.scope);
          await _dropLocalRow(txn, e.entity, e.entityId, files);
        } else {
          final n = await txn.delete(
            SyncTables.outbox,
            where: 'mutation_id = ? AND $_discardable',
            whereArgs: [mutationId],
          );
          if (n != 1) return DiscardOutcome.sending;
          await _restore(txn, e);
        }
        return DiscardOutcome.discarded;
      },
    );
    await _uploads.deleteFiles(files);
    return out;
  }

  /// How many things wait on the open create of [entityId] ([entity]) in
  /// the current scope: outbox rows of other entities that list it in
  /// `depends_on` (any open status, including rows already failed
  /// `dependency_failed` by its rejection, which a merge or a retry would
  /// revive), plus, for a category, local products and child categories
  /// that point at it without such a row. The opening stock written with a
  /// product create is part of the create and is not counted. 0 when there
  /// is no open create. Drives whether "Discard" is offered (I3).
  Future<int> dependentsOfCreate(String entity, String entityId) async {
    final scope = _scope();
    if (scope == null) return 0;
    final db = await _db.database;
    final createSeq = await _openCreateSeq(db, entity, entityId, scope);
    if (createSeq == null) return 0;
    return _dependentsOfCreate(
      db,
      entity,
      entityId,
      scope: scope,
      createSeq: createSeq,
    );
  }

  static Future<int?> _openCreateSeq(
    DatabaseExecutor txn,
    String entity,
    String entityId,
    String scope,
  ) async {
    final r = await txn.query(
      SyncTables.outbox,
      columns: ['seq'],
      where:
          "entity = ? AND entity_id = ? AND scope = ? AND op = 'create' "
          "AND status != 'done'",
      whereArgs: [entity, entityId, scope],
      orderBy: 'seq ASC',
      limit: 1,
    );
    return r.isEmpty ? null : r.first['seq'] as int?;
  }

  /// `seq` of the opening `stock.add` [ProductService.create] enqueued in
  /// the same write right after the create (seq + 1, depending on it).
  static Future<int?> _openingStockOf(
    DatabaseExecutor txn,
    String productId, {
    required String scope,
    required int? createSeq,
  }) async {
    if (createSeq == null) return null;
    final r = await txn.query(
      SyncTables.outbox,
      columns: ['seq', 'depends_on_json', 'payload_json'],
      where:
          "seq = ? AND scope = ? AND entity = 'stock' AND op = 'add' "
          "AND status != 'done'",
      whereArgs: [createSeq + 1, scope],
      limit: 1,
    );
    if (r.isEmpty) return null;
    final deps = OutboxEntry.decodeDependsOn(r.first['depends_on_json']);
    final payload = decodeJsonMap(r.first['payload_json']);
    return deps.contains(productId) && payload['product_id'] == productId
        ? r.first['seq'] as int?
        : null;
  }

  Future<int> _dependentsOfCreate(
    DatabaseExecutor txn,
    String entity,
    String entityId, {
    required String scope,
    required int? createSeq,
  }) async {
    final opening = entity == 'product'
        ? await _openingStockOf(
            txn,
            entityId,
            scope: scope,
            createSeq: createSeq,
          )
        : null;
    final rows = await txn.rawQuery(
      'SELECT seq, entity_id, depends_on_json FROM ${SyncTables.outbox} '
      "WHERE scope = ? AND status != 'done' AND entity_id != ? "
      "AND depends_on_json LIKE ? ESCAPE '\\'",
      [scope, entityId, '%${_likeEscape(jsonEncode(entityId))}%'],
    );
    final waiting = <String>{};
    var n = 0;
    for (final r in rows) {
      if (r['seq'] == opening) continue;
      if (!OutboxEntry.decodeDependsOn(
        r['depends_on_json'],
      ).contains(entityId)) {
        continue;
      }
      n++;
      waiting.add(r['entity_id'] as String);
    }
    if (entity == 'category') {
      for (final (table, column) in const [
        ('products', 'category_id'),
        ('categories', 'parent_id'),
      ]) {
        final local = await txn.query(
          table,
          columns: ['id', 'json'],
          where: '$column = ?',
          whereArgs: [entityId],
        );
        for (final l in local) {
          if (waiting.contains(l['id'])) continue;
          if (decodeJsonMap(l['json'])['is_active'] == false) continue;
          n++;
        }
      }
    }
    return n;
  }

  Future<void> _dropLocalRow(
    Transaction txn,
    String entity,
    String id,
    List<String> files,
  ) async {
    final table = tableOf[entity]!;
    String? category;
    if (entity == 'product') {
      final r = await txn.query(
        'products',
        columns: ['category_id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      category = r.isEmpty ? null : r.first['category_id'] as String?;
      await txn.delete('stock', where: 'product_id = ?', whereArgs: [id]);
    }
    await txn.delete(table, where: 'id = ?', whereArgs: [id]);
    if (entity != 'vendor' && entity != 'customer') {
      await unregisterAssets(txn, entity, id);
      files.addAll(await _uploads.cancel(txn, entity, id));
    }
    await refreshCategoryProductCount(txn, category);
  }

  /// Restores the local row of [discarded]'s entity from `server_json`,
  /// then re-applies the entity's remaining open rows (oldest first).
  Future<void> _restore(Transaction txn, OutboxEntry discarded) async {
    final table = tableOf[discarded.entity]!;
    final id = discarded.entityId;
    final rows = await txn.query(
      table,
      columns: ['json', 'server_json'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final current = decodeJsonMap(rows.first['json']);
    final server = decodeJsonMap(rows.first['server_json']);
    if (server.isEmpty) {
      current[staleKey] = true;
      await txn.update(
        table,
        {'json': jsonEncode(current)},
        where: 'id = ?',
        whereArgs: [id],
      );
      return;
    }
    final version = server.remove('version');
    if (table == 'categories') server.remove('image_hash');
    final oldCategory = current['category'] as String?;
    final next = <String, dynamic>{...current, ...server, 'id': id}
      ..remove(staleKey);
    // A field only the discarded change set has no server value: cleared.
    for (final k in discarded.payload.keys) {
      if (!kNonFieldPayloadKeys.contains(k) && !server.containsKey(k)) {
        next[k] = null;
      }
    }
    final later = await txn.query(
      SyncTables.outbox,
      where: "entity = ? AND entity_id = ? AND scope = ? AND status != 'done'",
      whereArgs: [discarded.entity, id, discarded.scope],
      orderBy: 'seq ASC',
    );
    for (final r in later.map(OutboxEntry.fromRow)) {
      if (r.op == 'delete') {
        next['is_active'] = false;
        continue;
      }
      for (final e in r.payload.entries) {
        if (!kNonFieldPayloadKeys.contains(e.key)) next[e.key] = e.value;
      }
    }
    final category = next['category'] as String?;
    if (table == 'products' && category != null) {
      final c = await txn.query(
        'categories',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [category],
        limit: 1,
      );
      if (c.isNotEmpty) next['category_name'] = c.first['name'];
    }
    await txn.update(
      table,
      {
        'json': jsonEncode(next),
        if (version is int) 'version': version,
        ...catalogColumnsOf(table, next),
        if (table == 'products' && !next.containsKey('barcode'))
          'barcode': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (table == 'products' && category != oldCategory) {
      await refreshCategoryProductCount(txn, oldCategory);
      await refreshCategoryProductCount(txn, category);
    }
    if (table == 'categories') {
      await refreshProductsCategoryName(txn, id, next['name'] as String?);
    }
  }

  // ------------------------------------------------------ edit and retry

  /// Highest outbox `seq` of the entity (0 when none): taken before the
  /// edit form opens, so [editAndRetry] can tell whether the user saved.
  Future<int> lastSeqOf(String entity, String entityId) async {
    final db = await _db.database;
    final scope = _scope();
    final r = await db.rawQuery(
      'SELECT MAX(seq) AS s FROM ${SyncTables.outbox} '
      'WHERE entity = ? AND entity_id = ?'
      '${scope == null ? '' : ' AND scope = ?'}',
      [entity, entityId, ?scope],
    );
    return (r.first['s'] as int?) ?? 0;
  }

  /// The local row's `json` (null when gone), to open its edit form.
  Future<Map<String, dynamic>?> localRow(String entity, String id) async {
    final table = tableOf[entity];
    if (table == null) return null;
    final db = await _db.database;
    final r = await db.query(
      table,
      columns: ['json'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return r.isEmpty ? null : decodeJsonMap(r.first['json']);
  }

  /// "Edit and retry": the user has edited the row in its normal form,
  /// which queued `update` rows behind the rejected row. Their fields are
  /// folded into the rejected row (later wins, dependencies merged), they
  /// are removed, and the rejected row goes back to the queue together with
  /// the rows it failed ([OutboxStore.retryRejectedIn]). With
  /// [editedAfterSeq] (see [lastSeqOf]) nothing happens unless an edit was
  /// saved after it. Returns whether the row was queued again.
  Future<bool> editAndRetry(String mutationId, {int? editedAfterSeq}) =>
      _writer.write<bool>(
        tables: tables,
        body: (s) async {
          final txn = s.txn;
          final rows = await txn.query(
            SyncTables.outbox,
            where: "mutation_id = ? AND status = 'rejected'",
            whereArgs: [mutationId],
            limit: 1,
          );
          if (rows.isEmpty) return false;
          final r = OutboxEntry.fromRow(rows.first);
          if (s.scope != null && r.scope != s.scope) return false;
          if (!tableOf.containsKey(r.entity)) return false;
          final later = (await txn.query(
            SyncTables.outbox,
            where:
                "entity = ? AND entity_id = ? AND scope = ? AND seq > ? "
                "AND op = 'update' AND $_discardable",
            whereArgs: [r.entity, r.entityId, r.scope, r.seq],
            orderBy: 'seq ASC',
          )).map(OutboxEntry.fromRow).toList();
          // M5 / T8-9 concern 4: a rejected UPDATE does not hold later
          // edits (ruling I2), so the engine may have claimed or sent the
          // user's edit already. That edit was saved: its fields supersede
          // the rejected values, which must never be resent over it.
          final sent = r.op == 'update'
              ? (await txn.query(
                  SyncTables.outbox,
                  where:
                      "entity = ? AND entity_id = ? AND scope = ? AND seq > ? "
                      "AND op = 'update' AND NOT ($_discardable)",
                  whereArgs: [
                    r.entity,
                    r.entityId,
                    r.scope,
                    editedAfterSeq ?? r.seq,
                  ],
                  orderBy: 'seq ASC',
                )).map(OutboxEntry.fromRow).toList()
              : const <OutboxEntry>[];
          if (editedAfterSeq != null &&
              !later.any((l) => (l.seq ?? 0) > editedAfterSeq) &&
              sent.isEmpty) {
            return false;
          }
          final payload = <String, dynamic>{...r.payload};
          final deps = <String>{...r.dependsOn};
          for (final x in sent) {
            for (final k in x.payload.keys) {
              if (!kNonFieldPayloadKeys.contains(k)) payload.remove(k);
            }
          }
          for (final l in later) {
            payload.addAll(l.payload);
            deps.addAll(l.dependsOn);
          }
          if (r.op == 'update' &&
              payload.keys.every(kNonFieldPayloadKeys.contains)) {
            // Every rejected field was replaced by the sent edit: nothing
            // is left to retry.
            await txn.delete(
              SyncTables.outbox,
              where: 'seq = ?',
              whereArgs: [r.seq],
            );
            for (final l in later) {
              await txn.delete(
                SyncTables.outbox,
                where: 'seq = ?',
                whereArgs: [l.seq],
              );
            }
            return true;
          }
          final open = await _outbox.openCreateIds(txn, deps, scope: r.scope);
          final keep = [
            for (final d in deps)
              if (open.contains(d)) d,
          ];
          await txn.update(
            SyncTables.outbox,
            {
              'payload_json': jsonEncode(payload),
              'depends_on_json': keep.isEmpty ? null : jsonEncode(keep),
            },
            where: 'seq = ?',
            whereArgs: [r.seq],
          );
          for (final l in later) {
            await txn.delete(
              SyncTables.outbox,
              where: 'seq = ?',
              whereArgs: [l.seq],
            );
          }
          return _outbox.retryRejectedIn(txn, mutationId);
        },
      );
}
