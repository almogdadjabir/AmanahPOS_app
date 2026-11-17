import 'dart:convert';
import 'dart:io';

import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/core/sync/images/pending_upload_store.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/features/category/domain/category_service.dart';
import 'package:amana_pos/features/inventory/data/local/stock_local_store.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_vendor_request_dto.dart';
import 'package:amana_pos/features/inventory/domain/vendor_service.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/domain/product_service.dart';
import 'package:amana_pos/features/sync/domain/catalog_conflict_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

const kCat = 'c0000000-0000-4000-8000-000000000001';
const kServerProduct = 'aaaaaaaa-0000-4000-8000-000000000001';
const kServerCat = 'aaaaaaaa-0000-4000-8000-000000000002';
const kServerVendor = 'aaaaaaaa-0000-4000-8000-000000000003';

void main() {
  late SaleFixture f;
  late Directory base;
  late PendingUploadStore uploads;
  late CategoryService categories;
  late ProductService products;
  late VendorService vendors;
  late CatalogConflictService service;
  String? failAt;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    base = await Directory.systemTemp.createTemp('catalog_conflict_test');
    uploads = PendingUploadStore(baseDir: () async => base.path);
    const actor = CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.owner,
    );
    categories = CategoryService(
      writer: f.writer,
      actor: () => actor,
      uploads: uploads,
      now: () => f.clock,
    );
    products = ProductService(
      writer: f.writer,
      actor: () => actor,
      uploads: uploads,
      categories: categories,
      now: () => f.clock,
    );
    vendors = VendorService(
      writer: f.writer,
      actor: () => actor,
      now: () => f.clock,
    );
    failAt = null;
    service = CatalogConflictService(
      db: f.odb,
      writer: f.writer,
      outbox: f.outbox,
      uploads: uploads,
      scope: () => f.scope,
      debugHook: (stage) async {
        if (stage == failAt) throw StateError('crash at $stage');
      },
    );
    await f.db.insert('categories', {
      'id': kCat,
      'tenant_id': 't1',
      'name': 'Drinks',
      'version': 2,
      'json': jsonEncode({
        'id': kCat,
        'name': 'Drinks',
        'is_active': true,
        'product_count': 0,
      }),
      'server_json': jsonEncode({
        'id': kCat,
        'name': 'Drinks',
        'is_active': true,
        'version': 2,
      }),
    });
  });

  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
    if (base.existsSync()) await base.delete(recursive: true);
  });

  // ------------------------------------------------------------- helpers

  Future<PickedAppImage> pick(List<int> bytes) async {
    final file = File(p.join(base.path, 'picker', 'a.jpg'));
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return PickedAppImage(file: file, path: file.path, name: 'a.jpg');
  }

  Future<List<Map<String, Object?>>> outbox() =>
      f.db.query('outbox', orderBy: 'seq');

  Future<Map<String, Object?>> rowOf(String entity, String id, String op) async =>
      (await f.db.query(
        'outbox',
        where: 'entity = ? AND entity_id = ? AND op = ?',
        whereArgs: [entity, id, op],
      )).single;

  /// What the engine does for a rejected create (SyncEngine._writeResult).
  Future<void> reject(
    String entity,
    String id, {
    String op = 'create',
    String code = 'conflict_unique',
    String? conflictId,
  }) async {
    final row = await rowOf(entity, id, op);
    await f.db.transaction((txn) async {
      await f.outbox.applyResult(
        txn,
        row['mutation_id'] as String,
        status: OutboxStatus.rejected,
        code: code,
        message: 'already exists',
        errorEntityId: conflictId,
      );
      if (op == 'create') {
        await f.outbox.failDependents(txn, id, scope: kScope);
      }
    });
  }

  Future<void> rawEnqueue({
    required String entity,
    required String op,
    required String entityId,
    required Map<String, dynamic> payload,
    List<String> dependsOn = const [],
  }) => f.db.transaction(
    (txn) => f.outbox.enqueue(
      txn,
      entity: entity,
      op: op,
      entityId: entityId,
      payload: payload,
      dependsOn: dependsOn,
      scope: kScope,
    ),
  );

  /// Every TEXT cell of every table (minus [skip] `table.column`) that
  /// contains [needle].
  Future<List<String>> cellsContaining(
    String needle, {
    Set<String> skip = const {},
  }) async {
    final hits = <String>[];
    final tables = await f.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%'",
    );
    for (final t in tables) {
      final name = t['name'] as String;
      for (final c in await f.db.rawQuery('PRAGMA table_info($name)')) {
        final col = c['name'] as String;
        if (skip.contains('$name.$col')) continue;
        final n = await f.db.rawQuery(
          'SELECT COUNT(*) AS n FROM $name WHERE CAST($col AS TEXT) LIKE ?',
          ['%$needle%'],
        );
        if ((n.first['n'] as int) > 0) hits.add('$name.$col');
      }
    }
    return hits;
  }

  /// The whole database as text (atomicity snapshot).
  Future<String> dump() async {
    final out = StringBuffer();
    final tables = await f.db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    );
    for (final t in tables) {
      final name = t['name'] as String;
      final rows = await f.db.rawQuery('SELECT * FROM $name ORDER BY rowid');
      out.writeln('$name ${jsonEncode(rows)}');
    }
    return out.toString();
  }

  Future<void> seedServerProduct({String sku = 'SKU-1'}) async {
    final data = {
      'id': kServerProduct,
      'name': 'Cola (server)',
      'price': '9.00',
      'sku': sku,
      'category': kCat,
      'is_active': true,
    };
    await f.db.insert('products', {
      'id': kServerProduct,
      'name': 'Cola (server)',
      'sku': sku,
      'price': '9.00',
      'category_id': kCat,
      'stock_level': 0.0,
      'version': 3,
      'json': jsonEncode({...data, 'category_name': 'Drinks'}),
      'server_json': jsonEncode({...data, 'version': 3}),
    });
    await const StockLocalStore().setBase(f.db, kServerProduct, kShop, '10');
  }

  /// A local product P (opening stock 5, staged image), sold (2), received
  /// (1, raw inbound), plus every audit place that can name a product id.
  /// Its create is then rejected `conflict_unique` naming the server
  /// product; one more stock row is queued AFTER the rejection (blocked).
  Future<String> seedConflictingProduct() async {
    final pid = await products.create(
      AddProductRequestDto(
        name: 'Cola',
        price: '10.00',
        category: kCat,
        unit: 'piece',
        sku: 'SKU-1',
        trackInventory: true,
        imageUpload: await pick([1, 2, 3]),
      ),
      initialQuantity: '5',
      shopId: kShop,
    );
    await seedServerProduct();
    await f.service().createSale(
      SaleDraft(
        shopId: kShop,
        paymentMethod: 'cash',
        lines: [
          SaleDraftLine.product(
            productId: pid,
            productName: 'Cola',
            quantity: '2',
            unitPrice: '10.00',
            snapshot: {'id': pid, 'name': 'Cola', 'category': kCat},
          ),
        ],
      ),
    );
    await f.db.insert('inbound_transactions', {
      'id': 'in-1',
      'shop_id': kShop,
      'json': jsonEncode({
        'id': 'in-1',
        'vendor_id': 'v-1',
        'items': [
          {'product': pid, 'quantity': '1'},
        ],
      }),
    });
    await rawEnqueue(
      entity: 'inbound',
      op: 'create',
      entityId: 'in-1',
      payload: {
        'client_inbound_id': 'in-1',
        'vendor_id': 'v-1',
        'shop_id': kShop,
        'items': [
          {'product_id': pid, 'quantity': '1'},
        ],
      },
      dependsOn: [pid],
    );
    await f.db.insert('synced_assets', {
      'type': 'product',
      'id': pid,
      'variant': 'thumb',
      'url': 'https://x/$pid.webp',
      'state': 'pending',
      'attempts': 0,
    });
    await f.db.insert('synced_entities', {
      'entity': 'expiry_batch',
      'id': 'eb-1',
      'version': 1,
      'json': jsonEncode({'id': 'eb-1', 'product': pid}),
    });
    // Whitelisted: deliberately never rewritten.
    final saleId = (await f.db.query('sales')).single['id'] as String;
    await f.db.update(
      'sales',
      {
        'warnings_json': jsonEncode([
          {'code': 'low_stock', 'product': pid},
        ]),
      },
      where: 'id = ?',
      whereArgs: [saleId],
    );
    await f.db.insert('sale_refunds', {
      'id': 'rf-1',
      'sale_id': saleId,
      'shop_id': kShop,
      'total': '1',
      'occurred_at': '2026-11-16T10:00:00Z',
      'json': jsonEncode({
        'items': [
          {'product': pid},
        ],
      }),
    });
    await reject('product', pid, conflictId: kServerProduct);
    // Queued after the rejection: blocked behind the rejected create (M2).
    await rawEnqueue(
      entity: 'stock',
      op: 'add',
      entityId: 'st-late',
      payload: {
        'product_id': pid,
        'shop_id': kShop,
        'delta': '1',
        'reason': '',
      },
      dependsOn: [pid],
    );
    // The legacy single-dependency column (unused since v14) still counts.
    await f.db.update(
      'outbox',
      {'depends_on_entity_id': pid},
      where: 'entity_id = ?',
      whereArgs: ['st-late'],
    );
    await const StockLocalStore().recompute(f.db, pid, kShop);
    return pid;
  }

  // ------------------------------------------------------------- merge

  group('mergeInto', () {
    test('merge rewrites product id in stock, sale_items, inbound lines, '
        'outbox payloads, depends_on, pending_uploads and leaves no row '
        'with the old id', () async {
      final pid = await seedConflictingProduct();
      final staged = (await uploads.get(f.db, 'product', pid))!;
      expect(File(staged.localPath).existsSync(), isTrue);

      final report = await service.mergeInto(
        pid,
        kServerProduct,
        entity: 'product',
      );

      // Review Focus 5: nothing outside the whitelist names the old id.
      expect(
        await cellsContaining(
          pid,
          skip: {
            ...CatalogConflictService.notRewritten,
            ...CatalogConflictService.pathColumns,
          },
        ),
        isEmpty,
      );
      // ...and the whitelist kept it on purpose. The copy's staged image
      // (row and file) is gone, so no storage path names it either.
      expect(await cellsContaining(pid), {
        'sales.warnings_json',
        'sale_refunds.json',
      });

      expect(await f.db.query('products', where: 'id = ?', whereArgs: [pid]),
          isEmpty);
      final line = (await f.db.query('sale_items')).single;
      expect(line['product_id'], kServerProduct);
      expect(
        (jsonDecode(line['snapshot_json'] as String) as Map)['id'],
        kServerProduct,
      );
      // 10 (server) + 5 (opening) - 2 (sale) + 1 (inbound) + 1 (late add).
      final stock = (await f.db.query(
        'stock',
        where: 'product_id = ?',
        whereArgs: [kServerProduct],
      )).single;
      expect(stock['base_quantity'], '10');
      expect(stock['quantity'], 15.0);
      // Fix-wave: the copy's staged image never replaces the existing
      // product's server image; it is dropped with its file.
      expect(await uploads.get(f.db, 'product', kServerProduct), isNull);
      expect(await uploads.get(f.db, 'product', pid), isNull);
      expect(File(staged.localPath).existsSync(), isFalse);
      expect(report.targetInactive, isFalse);

      // Every waiting row goes back to the queue, now naming the server id.
      final rows = await outbox();
      expect(rows.where((r) => r['entity'] == 'product'), isEmpty);
      for (final r in rows) {
        expect(r['status'], 'pending', reason: '${r['entity']}.${r['op']}');
        expect(r['depends_on_json'], isNull);
        expect(r['error_code'], isNull);
      }
      expect(rows.length, 4); // stock.add, sale.create, inbound, late add
      expect(report.saleLines, 1);
      expect(report.dropped, 1);
      expect(report.requeued, 4);
      expect(report.uploads, 1);
      expect(report.total, greaterThan(0));
    });

    test('preview reports the same counts and changes nothing', () async {
      final pid = await seedConflictingProduct();
      final before = await dump();
      final preview = await service.previewMerge(
        pid,
        kServerProduct,
        entity: 'product',
      );
      expect(await dump(), before);
      final report = await service.mergeInto(
        pid,
        kServerProduct,
        entity: 'product',
      );
      expect(preview, report);
    });

    test('merge keeps an image already staged for the EXISTING product and '
        'drops only the copy\'s', () async {
      final pid = await seedConflictingProduct();
      final copy = (await uploads.get(f.db, 'product', pid))!;
      await products.update(
        kServerProduct,
        UpdateProductRequestDto(imageUpload: await pick([7, 8, 9])),
      );
      final own = (await uploads.get(f.db, 'product', kServerProduct))!;
      await service.mergeInto(pid, kServerProduct, entity: 'product');
      final after = (await uploads.get(f.db, 'product', kServerProduct))!;
      expect(after.sha256, own.sha256);
      expect(File(after.localPath).existsSync(), isTrue);
      expect(File(copy.localPath).existsSync(), isFalse);
    });

    test('M2: merging into an INACTIVE existing row is reported', () async {
      final pid = await seedConflictingProduct();
      final row = (await f.db.query(
        'products',
        where: 'id = ?',
        whereArgs: [kServerProduct],
      )).single;
      final j = jsonDecode(row['json'] as String) as Map;
      await f.db.update(
        'products',
        {'json': jsonEncode({...j, 'is_active': false})},
        where: 'id = ?',
        whereArgs: [kServerProduct],
      );
      final preview = await service.previewMerge(
        pid,
        kServerProduct,
        entity: 'product',
      );
      expect(preview.targetInactive, isTrue);
      expect(preview.droppedEdits, 0);
    });

    test('merge is atomic (a failure mid-way changes nothing)', () async {
      final pid = await seedConflictingProduct();
      final staged = (await uploads.get(f.db, 'product', pid))!;
      final before = await dump();
      for (final stage in CatalogConflictService.mergeStages) {
        failAt = stage;
        await expectLater(
          service.mergeInto(pid, kServerProduct, entity: 'product'),
          throwsStateError,
          reason: stage,
        );
        expect(await dump(), before, reason: 'after a crash at $stage');
        expect(File(staged.localPath).existsSync(), isTrue);
      }
      failAt = null;
      await service.mergeInto(pid, kServerProduct, entity: 'product');
      expect(await dump(), isNot(before));
    });

    test('merge is refused without conflict_entity_id (and for another '
        'server id)', () async {
      final pid = await seedConflictingProduct();
      final before = await dump();
      await f.db.update(
        'outbox',
        {'error_entity_id': null},
        where: "entity = 'product' AND entity_id = ?",
        whereArgs: [pid],
      );
      final noConflict = await dump();
      await expectLater(
        service.mergeInto(pid, kServerProduct, entity: 'product'),
        throwsA(isA<CatalogValidationException>()),
      );
      expect(await dump(), noConflict);
      expect(
        CatalogConflictService.canMerge(
          OutboxEntry.fromRow(await rowOf('product', pid, 'create')),
        ),
        isFalse,
      );
      // Restore the conflict id: a DIFFERENT target is still refused.
      await f.db.update(
        'outbox',
        {'error_entity_id': kServerProduct},
        where: "entity = 'product' AND entity_id = ?",
        whereArgs: [pid],
      );
      expect(await dump(), before);
      expect(
        CatalogConflictService.canMerge(
          OutboxEntry.fromRow(await rowOf('product', pid, 'create')),
        ),
        isTrue,
      );
      await expectLater(
        service.mergeInto(pid, kServerCat, entity: 'product'),
        throwsA(isA<CatalogValidationException>()),
      );
      expect(await dump(), before);
    });

    test('merge when the server product is not local yet: the local row '
        'takes the server id until the pull brings the server state',
        () async {
      final pid = await products.create(
        const AddProductRequestDto(
          name: 'Cola',
          price: '10.00',
          category: kCat,
          unit: 'piece',
          sku: 'SKU-9',
          trackInventory: true,
        ),
        initialQuantity: '2',
        shopId: kShop,
      );
      await reject('product', pid, conflictId: kServerProduct);
      await service.mergeInto(pid, kServerProduct, entity: 'product');
      final row = (await f.db.query(
        'products',
        where: 'id = ?',
        whereArgs: [kServerProduct],
      )).single;
      expect(row['version'], isNull);
      expect(row['server_json'], isNull);
      expect(
        (jsonDecode(row['json'] as String) as Map)['id'],
        kServerProduct,
      );
      expect(await cellsContaining(pid), isEmpty);
      final stockRow = (await f.db.query(
        'stock',
        where: 'product_id = ?',
        whereArgs: [kServerProduct],
      )).single;
      expect(stockRow['quantity'], 2.0);
      expect(stockRow['id'], '$kServerProduct-$kShop');
    });

    test('category merge rewrites products, child categories and waiting '
        'creates', () async {
      final cid = await categories.create(name: 'Snacks');
      final child = await categories.create(name: 'Chips', parent: cid);
      final pid = await products.create(
        AddProductRequestDto(
          name: 'Crisps',
          price: '3.00',
          category: cid,
          unit: 'piece',
          trackInventory: false,
        ),
      );
      await f.db.insert('categories', {
        'id': kServerCat,
        'tenant_id': 't1',
        'name': 'Snacks',
        'version': 5,
        'json': jsonEncode({
          'id': kServerCat,
          'name': 'Snacks',
          'is_active': true,
          'product_count': 0,
        }),
      });
      await reject('category', cid, conflictId: kServerCat);
      // The cascade failed the product and the child category.
      expect((await rowOf('product', pid, 'create'))['status'], 'rejected');
      expect((await rowOf('category', child, 'create'))['status'], 'rejected');

      final report = await service.mergeInto(
        cid,
        kServerCat,
        entity: 'category',
      );

      expect(await cellsContaining(cid), isEmpty);
      final product = (await f.db.query(
        'products',
        where: 'id = ?',
        whereArgs: [pid],
      )).single;
      expect(product['category_id'], kServerCat);
      final pj = jsonDecode(product['json'] as String) as Map;
      expect(pj['category'], kServerCat);
      expect(pj['category_name'], 'Snacks');
      final chips = (await f.db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [child],
      )).single;
      expect(chips['parent_id'], kServerCat);
      final create = await rowOf('product', pid, 'create');
      expect(create['status'], 'pending');
      expect(
        (jsonDecode(create['payload_json'] as String) as Map)['category'],
        kServerCat,
      );
      expect((await rowOf('category', child, 'create'))['status'], 'pending');
      final serverCat = (await f.db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [kServerCat],
      )).single;
      expect(
        (jsonDecode(serverCat['json'] as String) as Map)['product_count'],
        1,
      );
      expect(report.products, 1);
      expect(report.childCategories, 1);
    });

    test('vendor merge rewrites inbound vendor ids', () async {
      final vid = await vendors.create(
        const CreateVendorRequestDto(name: 'Nile Foods'),
      );
      await f.db.insert('vendors', {
        'id': kServerVendor,
        'version': 2,
        'json': jsonEncode({
          'id': kServerVendor,
          'name': 'Nile Foods',
          'is_active': true,
        }),
      });
      await f.db.insert('inbound_transactions', {
        'id': 'in-2',
        'shop_id': kShop,
        'json': jsonEncode({'id': 'in-2', 'vendor_id': vid, 'items': []}),
      });
      await rawEnqueue(
        entity: 'inbound',
        op: 'create',
        entityId: 'in-2',
        payload: {
          'client_inbound_id': 'in-2',
          'vendor_id': vid,
          'shop_id': kShop,
          'items': [
            {'product_id': kP1, 'quantity': '1'},
          ],
        },
        dependsOn: [vid],
      );
      await reject('vendor', vid, conflictId: kServerVendor);
      final report = await service.mergeInto(
        vid,
        kServerVendor,
        entity: 'vendor',
      );
      expect(await cellsContaining(vid), isEmpty);
      final inbound = await rowOf('inbound', 'in-2', 'create');
      expect(inbound['status'], 'pending');
      expect(
        (jsonDecode(inbound['payload_json'] as String) as Map)['vendor_id'],
        kServerVendor,
      );
      expect(await f.db.query('vendors', where: 'id = ?', whereArgs: [vid]),
          isEmpty);
      expect(report.inbound, 1);
      expect(report.requeued, 1);
    });

    test('schema grep: every id / json column is rewritten by a merge or '
        'deliberately whitelisted', () async {
      final idLike = RegExp(r'(product|category|vendor|parent|entity_id|json)');
      final covered = {
        ...CatalogConflictService.rewrittenColumns,
        ...CatalogConflictService.notRewritten,
        ...CatalogConflictService.notIdColumns,
      };
      final missing = <String>[];
      final tables = await f.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%'",
      );
      for (final t in tables) {
        final name = t['name'] as String;
        for (final c in await f.db.rawQuery('PRAGMA table_info($name)')) {
          final col = c['name'] as String;
          final key = '$name.$col';
          final isCatalogPk =
              col == 'id' &&
              const {'products', 'categories', 'vendors', 'stock'}
                  .contains(name);
          if ((idLike.hasMatch(col) || isCatalogPk) &&
              !covered.contains(key)) {
            missing.add(key);
          }
        }
      }
      expect(missing, isEmpty,
          reason: 'add new id columns to CatalogConflictService');
      expect(CatalogConflictService.notRewritten, {
        'sale_refunds.json',
        'sales.warnings_json',
      });
    });
  });

  // ------------------------------------------------------------- discard

  group('discardRejected', () {
    test('discard rejected create removes row/outbox/files', () async {
      final pid = await products.create(
        AddProductRequestDto(
          name: 'Cola',
          price: '10.00',
          category: kCat,
          unit: 'piece',
          sku: 'SKU-2',
          trackInventory: true,
          imageUpload: await pick([4, 5, 6]),
        ),
        initialQuantity: '5',
        shopId: kShop,
      );
      await products.update(pid, const UpdateProductRequestDto(name: 'Cola 2'));
      final staged = (await uploads.get(f.db, 'product', pid))!;
      await reject('product', pid, code: 'limit_exceeded');
      final create = await rowOf('product', pid, 'create');

      final out = await service.discardRejected(
        create['mutation_id'] as String,
      );

      expect(out, DiscardOutcome.discarded);
      expect(
        await f.db.query('products', where: 'id = ?', whereArgs: [pid]),
        isEmpty,
      );
      expect(
        await f.db.query('stock', where: 'product_id = ?', whereArgs: [pid]),
        isEmpty,
      );
      expect(
        await f.db.query(
          'outbox',
          where: "entity = 'product' AND entity_id = ?",
          whereArgs: [pid],
        ),
        isEmpty,
      );
      expect(await uploads.get(f.db, 'product', pid), isNull);
      expect(File(staged.localPath).existsSync(), isFalse);
      // Its opening stock is part of the create: gone with it, not left
      // behind as a failed row.
      expect(await outbox(), isEmpty);
    });

    test('I3 / R7: a create with a sale waiting on it is NOT discarded '
        '(nothing changes); merge or edit and retry instead', () async {
      final pid = await products.create(
        const AddProductRequestDto(
          name: 'Cola',
          price: '10.00',
          category: kCat,
          unit: 'piece',
          trackInventory: true,
        ),
        initialQuantity: '5',
        shopId: kShop,
      );
      await f.service().createSale(
        SaleDraft(
          shopId: kShop,
          paymentMethod: 'cash',
          lines: [
            SaleDraftLine.product(
              productId: pid,
              productName: 'Cola',
              quantity: '1',
              unitPrice: '10.00',
            ),
          ],
        ),
      );
      await reject('product', pid, code: 'limit_exceeded');
      final create = await rowOf('product', pid, 'create');
      expect(
        await service.dependentsOfCreate('product', pid),
        1,
        reason: 'the sale; the opening stock is part of the create',
      );
      final before = await dump();
      expect(
        await service.discardRejected(create['mutation_id'] as String),
        DiscardOutcome.hasDependents,
      );
      expect(await dump(), before);
    });

    test('I3: a PENDING (never rejected) create with a blocked dependent is '
        'not discarded either', () async {
      final cid = await categories.create(name: 'Snacks');
      final pid = await products.create(
        AddProductRequestDto(
          name: 'Crisps',
          price: '3.00',
          category: cid,
          unit: 'piece',
          trackInventory: false,
        ),
      );
      expect((await rowOf('product', pid, 'create'))['status'], 'blocked');
      final create = await rowOf('category', cid, 'create');
      expect(
        await service.discardRejected(create['mutation_id'] as String),
        DiscardOutcome.hasDependents,
      );
      expect(await f.db.query('categories', where: 'id = ?', whereArgs: [cid]),
          hasLength(1));
      expect((await rowOf('product', pid, 'create'))['status'], 'blocked');
    });

    test('I3 scenario B: a rejected category create whose local products are '
        'still there is not discarded', () async {
      final cid = await categories.create(name: 'General');
      final pid = await products.create(
        AddProductRequestDto(
          name: 'Crisps',
          price: '3.00',
          category: cid,
          unit: 'piece',
          trackInventory: false,
        ),
      );
      await reject('category', cid, conflictId: kServerCat);
      expect((await rowOf('product', pid, 'create'))['status'], 'rejected');
      expect(await service.dependentsOfCreate('category', cid), 1);
      final create = await rowOf('category', cid, 'create');
      expect(
        await service.discardRejected(create['mutation_id'] as String),
        DiscardOutcome.hasDependents,
      );
      // Once the product is discarded, the category can go.
      final pc = await rowOf('product', pid, 'create');
      expect(
        await service.discardRejected(pc['mutation_id'] as String),
        DiscardOutcome.discarded,
      );
      expect(await service.dependentsOfCreate('category', cid), 0);
      expect(
        await service.discardRejected(create['mutation_id'] as String),
        DiscardOutcome.discarded,
      );
      expect(await outbox(), isEmpty);
    });

    test('M8: a create that may already be on the server (claimed, answer '
        'not seen) is not discarded', () async {
      final vid = await vendors.create(
        const CreateVendorRequestDto(name: 'Nile Foods'),
      );
      final create = await rowOf('vendor', vid, 'create');
      await f.db.update(
        'outbox',
        {'claimed_at': '2026-11-16T09:00:00Z', 'attempts': 1},
        where: 'mutation_id = ?',
        whereArgs: [create['mutation_id']],
      );
      expect(
        await service.discardRejected(create['mutation_id'] as String),
        DiscardOutcome.mayBeOnServer,
      );
      expect(await f.db.query('vendors', where: 'id = ?', whereArgs: [vid]),
          hasLength(1));
    });

    test('a create with no dependents (never sent) is still discarded', () async {
      final vid = await vendors.create(
        const CreateVendorRequestDto(name: 'Nile Foods'),
      );
      final create = await rowOf('vendor', vid, 'create');
      expect(
        await service.discardRejected(create['mutation_id'] as String),
        DiscardOutcome.discarded,
      );
      expect(await outbox(), isEmpty);
      expect(await f.db.query('vendors', where: 'id = ?', whereArgs: [vid]),
          isEmpty);
    });

    test('discard rejected update restores server_json', () async {
      await seedServerProduct();
      await products.update(
        kServerProduct,
        const UpdateProductRequestDto(price: '12.00', barcode: '777'),
      );
      await reject(
        'product',
        kServerProduct,
        op: 'update',
        code: 'validation_error',
      );
      final update = await rowOf('product', kServerProduct, 'update');
      final out = await service.discardRejected(
        update['mutation_id'] as String,
      );
      expect(out, DiscardOutcome.discarded);
      final row = (await f.db.query(
        'products',
        where: 'id = ?',
        whereArgs: [kServerProduct],
      )).single;
      expect(row['price'], '9.00');
      expect(row['barcode'], isNull);
      expect(row['version'], 3);
      final json = jsonDecode(row['json'] as String) as Map;
      expect(json['price'], '9.00');
      expect(json.containsKey('barcode') ? json['barcode'] : null, isNull);
      expect(json['category_name'], 'Drinks');
      expect(await outbox(), isEmpty);
    });

    test('discard of a rejected update keeps a later queued edit on top',
        () async {
      await seedServerProduct();
      await products.update(
        kServerProduct,
        const UpdateProductRequestDto(price: '12.00'),
      );
      await reject(
        'product',
        kServerProduct,
        op: 'update',
        code: 'validation_error',
      );
      await products.update(
        kServerProduct,
        const UpdateProductRequestDto(name: 'Cola Zero'),
      );
      final rejected = (await outbox()).firstWhere(
        (r) => r['status'] == 'rejected',
      );
      await service.discardRejected(rejected['mutation_id'] as String);
      final row = (await f.db.query(
        'products',
        where: 'id = ?',
        whereArgs: [kServerProduct],
      )).single;
      expect(row['price'], '9.00');
      expect(row['name'], 'Cola Zero');
      expect((await outbox()).single['status'], 'pending');
    });

    test('discard of a rejected delete brings the row back', () async {
      await seedServerProduct();
      await products.delete(kServerProduct);
      await reject(
        'product',
        kServerProduct,
        op: 'delete',
        code: 'forbidden',
      );
      final del = await rowOf('product', kServerProduct, 'delete');
      await service.discardRejected(del['mutation_id'] as String);
      final row = (await f.db.query(
        'products',
        where: 'id = ?',
        whereArgs: [kServerProduct],
      )).single;
      expect((jsonDecode(row['json'] as String) as Map)['is_active'], isTrue);
    });

    test('discard of a rejected update with no server state marks the row '
        'stale and keeps it', () async {
      final vid = await vendors.create(
        const CreateVendorRequestDto(name: 'Nile Foods'),
      );
      // Pretend the create went through without a stored server state.
      await f.db.update(
        'outbox',
        {'status': 'done'},
        where: 'entity_id = ?',
        whereArgs: [vid],
      );
      await f.db.rawUpdate(
        'UPDATE vendors SET version = 1 WHERE id = ?',
        [vid],
      );
      await rawEnqueue(
        entity: 'vendor',
        op: 'update',
        entityId: vid,
        payload: {'name': 'Nile'},
      );
      await reject('vendor', vid, op: 'update', code: 'validation_error');
      final upd = await rowOf('vendor', vid, 'update');
      await service.discardRejected(upd['mutation_id'] as String);
      final row = (await f.db.query(
        'vendors',
        where: 'id = ?',
        whereArgs: [vid],
      )).single;
      final json = jsonDecode(row['json'] as String) as Map;
      expect(json[CatalogConflictService.staleKey], isTrue);
      expect(json['name'], 'Nile Foods');
    });

    test('M6: with no signed-in scope nothing is discarded; lastSeqOf only '
        'counts the current scope', () async {
      final vid = await vendors.create(
        const CreateVendorRequestDto(name: 'Nile Foods'),
      );
      final create = await rowOf('vendor', vid, 'create');
      final seq = await service.lastSeqOf('vendor', vid);
      expect(seq, create['seq']);
      f.scope = 'u2|t2';
      expect(await service.lastSeqOf('vendor', vid), 0);
      f.scope = null;
      expect(
        await service.discardRejected(create['mutation_id'] as String),
        DiscardOutcome.otherScope,
      );
      expect(await outbox(), hasLength(1));
    });

    test('a row being sent is not discarded', () async {
      await seedServerProduct();
      await products.update(
        kServerProduct,
        const UpdateProductRequestDto(price: '12.00'),
      );
      final row = await rowOf('product', kServerProduct, 'update');
      await f.db.update(
        'outbox',
        {'status': 'inflight', 'lease_until': '2099-01-01T00:00:00Z'},
        where: 'mutation_id = ?',
        whereArgs: [row['mutation_id']],
      );
      expect(
        await service.discardRejected(row['mutation_id'] as String),
        DiscardOutcome.sending,
      );
      expect((await outbox()).single['status'], 'inflight');
    });
  });

  // ------------------------------------------------------- edit and retry

  group('editAndRetry', () {
    test('M5 / T8-9 concern 4: the user\'s edit was already sent on its own; '
        'it counts as saved and the old rejected price is never resent',
        () async {
      await seedServerProduct();
      await products.update(
        kServerProduct,
        const UpdateProductRequestDto(price: '12.00'),
      );
      await reject(
        'product',
        kServerProduct,
        op: 'update',
        code: 'validation_error',
      );
      final rejected = await rowOf('product', kServerProduct, 'update');
      final mid = rejected['mutation_id'] as String;
      final since = await service.lastSeqOf('product', kServerProduct);
      await products.update(
        kServerProduct,
        const UpdateProductRequestDto(price: '14.00'),
      );
      // The engine sent the new edit within the debounce: it is done.
      await f.db.update(
        'outbox',
        {'status': 'done'},
        where: "entity_id = ? AND seq > ?",
        whereArgs: [kServerProduct, since],
      );
      expect(await service.editAndRetry(mid, editedAfterSeq: since), isTrue);
      final open = await f.db.query(
        'outbox',
        where: "entity_id = ? AND status != 'done'",
        whereArgs: [kServerProduct],
      );
      expect(open, isEmpty, reason: 'nothing left to resend the old 12.00');
    });

    test('M5: fields the sent edit did not cover are still retried', () async {
      await seedServerProduct();
      await products.update(
        kServerProduct,
        const UpdateProductRequestDto(price: '12.00', name: 'Cola Max'),
      );
      await reject(
        'product',
        kServerProduct,
        op: 'update',
        code: 'validation_error',
      );
      final mid =
          (await rowOf('product', kServerProduct, 'update'))['mutation_id']
              as String;
      final since = await service.lastSeqOf('product', kServerProduct);
      await products.update(
        kServerProduct,
        const UpdateProductRequestDto(price: '14.00'),
      );
      await f.db.update(
        'outbox',
        {'status': 'inflight', 'lease_until': '2099-01-01T00:00:00Z'},
        where: "entity_id = ? AND seq > ?",
        whereArgs: [kServerProduct, since],
      );
      expect(await service.editAndRetry(mid, editedAfterSeq: since), isTrue);
      final r = OutboxEntry.fromRow(
        (await f.db.query(
          'outbox',
          where: 'mutation_id = ?',
          whereArgs: [mid],
        )).single,
      );
      expect(r.status, OutboxStatus.pending);
      expect(r.payload.containsKey('price'), isFalse);
      expect(r.payload['name'], 'Cola Max');
    });

    test('folds the edit made after the rejection into the create and '
        'requeues it with its dependents', () async {
      final pid = await products.create(
        const AddProductRequestDto(
          name: 'Cola',
          price: '10.00',
          category: kCat,
          unit: 'piece',
          barcode: '111',
          trackInventory: true,
        ),
        initialQuantity: '5',
        shopId: kShop,
      );
      await reject('product', pid, conflictId: kServerProduct);
      final create = await rowOf('product', pid, 'create');
      final mid = create['mutation_id'] as String;
      final since = await service.lastSeqOf('product', pid);

      // Closed the form without saving: nothing happens.
      expect(await service.editAndRetry(mid, editedAfterSeq: since), isFalse);
      expect((await rowOf('product', pid, 'create'))['status'], 'rejected');

      await products.update(pid, const UpdateProductRequestDto(barcode: '222'));
      expect(await service.editAndRetry(mid, editedAfterSeq: since), isTrue);

      final rows = await outbox();
      expect(rows.where((r) => r['op'] == 'update'), isEmpty);
      final c = await rowOf('product', pid, 'create');
      expect(c['status'], 'pending');
      expect(c['error_entity_id'], isNull);
      expect(
        (jsonDecode(c['payload_json'] as String) as Map)['barcode'],
        '222',
      );
      // The opening stock add waits behind the create again.
      expect(
        rows.firstWhere((r) => r['entity'] == 'stock')['status'],
        'blocked',
      );
    });
  });
}
