import 'dart:convert';
import 'dart:io';

import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/core/sync/images/pending_upload_store.dart';
import 'package:amana_pos/features/category/domain/category_service.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/products/domain/product_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../core/sync/support/test_db.dart';
import '../pos/support/sale_fixture.dart';

const _uuidRe =
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';
const kCat = 'c0000000-0000-4000-8000-000000000001';

void main() {
  late SaleFixture f;
  late CatalogActor actor;
  late Directory base;
  late PendingUploadStore uploads;
  late CategoryService categories;
  late ProductService service;

  setUp(() async {
    f = await SaleFixture.on(await openTestDb());
    base = await Directory.systemTemp.createTemp('product_service_test');
    actor = const CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.owner,
    );
    uploads = PendingUploadStore(baseDir: () async => base.path);
    categories = CategoryService(
      writer: f.writer,
      actor: () => actor,
      now: () => f.clock,
    );
    service = ProductService(
      writer: f.writer,
      actor: () => actor,
      uploads: uploads,
      categories: categories,
      now: () => f.clock,
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
    });
  });

  tearDown(() async {
    f.notifier.dispose();
    await f.db.close();
    if (base.existsSync()) await base.delete(recursive: true);
  });

  AddProductRequestDto dto({
    String name = 'Cola',
    String price = '12.50',
    String category = kCat,
    String? cost,
    String? sku,
    String? barcode,
    PickedAppImage? image,
    String? minStock,
  }) => AddProductRequestDto(
    name: name,
    price: price,
    category: category,
    unit: 'piece',
    costPrice: cost,
    sku: sku,
    barcode: barcode,
    trackInventory: true,
    minStockLevel: minStock,
    imageUpload: image,
  );

  Future<PickedAppImage> pick(List<int> bytes, [String name = 'a.jpg']) async {
    final file = File(p.join(base.path, 'picker', name));
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return PickedAppImage(file: file, path: file.path, name: name);
  }

  Future<Map<String, Object?>?> product(String id) async {
    final r = await f.db.query('products', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : r.single;
  }

  Future<Map<String, dynamic>> productJson(String id) async =>
      jsonDecode((await product(id))!['json'] as String)
          as Map<String, dynamic>;
  Future<List<Map<String, Object?>>> outbox() =>
      f.db.query('outbox', orderBy: 'seq');
  Map<String, dynamic> payloadOf(Map<String, Object?> r) =>
      jsonDecode(r['payload_json'] as String) as Map<String, dynamic>;
  List<dynamic> depsOf(Map<String, Object?> r) => r['depends_on_json'] == null
      ? const []
      : jsonDecode(r['depends_on_json'] as String) as List<dynamic>;
  List<File> stagedFiles() {
    final d = Directory(p.join(base.path, 'pending_images'));
    if (!d.existsSync()) return const [];
    return d.listSync(recursive: true).whereType<File>().toList();
  }

  Future<void> seedSynced(
    String id, {
    String? sku,
    String? barcode,
    bool active = true,
    int version = 4,
    double stockLevel = 0,
  }) => f.db.insert('products', {
    'id': id,
    'category_id': kCat,
    'name': 'Seed $id',
    'sku': sku,
    'barcode': barcode,
    'price': '5.00',
    'stock_level': stockLevel,
    'version': version,
    'json': jsonEncode({
      'id': id,
      'category': kCat,
      'name': 'Seed $id',
      'sku': sku,
      'barcode': barcode,
      'price': '5.00',
      'cost_price': '3.00',
      'unit': 'piece',
      'track_inventory': true,
      'min_stock_level': 2,
      'is_active': active,
      'stock_level': stockLevel,
    }),
  });

  test('create writes the ApplierShape row (version null) and one create '
      'row with the client id', () async {
    final id = await service.create(dto(sku: ' SKU1 ', cost: '8'));
    expect(id, matches(_uuidRe));
    final row = (await product(id))!;
    expect(row['version'], isNull);
    expect(row['name'], 'Cola');
    expect(row['price'], '12.50');
    expect(row['sku'], 'SKU1');
    expect(row['category_id'], kCat);
    expect(row['thumbnail_url'], isNull);
    expect(row['image_url'], isNull);
    final j = await productJson(id);
    expect(j['category_name'], 'Drinks');
    expect(j['is_active'], true);
    expect(j['cost_price'], '8');
    final ob = await outbox();
    expect(ob, hasLength(1));
    expect(ob.single['entity'], 'product');
    expect(ob.single['op'], 'create');
    expect(ob.single['entity_id'], id);
    final payload = payloadOf(ob.single);
    expect(payload['id'], id);
    expect(payload['price'], '12.50');
    expect(payload['category'], kCat);
    expect(payload.containsKey('image_pending'), isFalse);
    expect(depsOf(ob.single), isEmpty, reason: 'synced category');
  });

  test('create with image stages a file, writes sha256 of the bytes and '
      'image_pending true', () async {
    final bytes = List<int>.generate(3000, (i) => (i * 7) % 256);
    final picked = await pick(bytes);
    final id = await service.create(dto(image: picked));
    final payload = payloadOf((await outbox()).single);
    expect(payload['image_pending'], true);
    expect(payload.containsKey('image_upload'), isFalse);
    final up = (await uploads.get(f.db, 'product', id))!;
    expect(up.sha256, sha256.convert(bytes).toString());
    expect(up.bytes, 3000);
    expect(up.state, PendingUpload.waiting);
    expect(await File(up.localPath).readAsBytes(), bytes);
    expect(
      p.isWithin(p.join(base.path, 'pending_images', id), up.localPath),
      isTrue,
    );
    final row = (await product(id))!;
    expect(row['thumbnail_url'], isNull);
    expect(row['image_url'], isNull);
    expect(row['image_hash'], isNull);
  });

  test('second pick replaces the row and deletes the old file', () async {
    final id = await service.create(dto(image: await pick([1, 2, 3])));
    final first = (await uploads.get(f.db, 'product', id))!;
    await service.update(
      id,
      UpdateProductRequestDto(imageUpload: await pick([7, 7])),
    );
    final second = (await uploads.get(f.db, 'product', id))!;
    expect(second.localPath, isNot(first.localPath));
    expect(second.sha256, sha256.convert([7, 7]).toString());
    expect(File(first.localPath).existsSync(), isFalse);
    expect(File(second.localPath).existsSync(), isTrue);
    expect(await f.count('pending_uploads'), 1);
    expect(
      (await outbox()).length,
      1,
      reason: 'an image-only change enqueues no update row',
    );
  });

  test('delete of a never-sent create cancels the upload and removes files, '
      'leaving no outbox row behind', () async {
    final id = await service.create(dto(image: await pick([5, 5, 5])));
    final up = (await uploads.get(f.db, 'product', id))!;
    await service.delete(id);
    expect(await product(id), isNull);
    expect(await outbox(), isEmpty);
    expect(await f.count('pending_uploads'), 0);
    expect(File(up.localPath).existsSync(), isFalse);
    expect(stagedFiles(), isEmpty);
  });

  test('delete of a synced product marks it inactive, enqueues delete with '
      'baseVersion and cancels its upload', () async {
    await seedSynced('p-synced', version: 6);
    await service.update(
      'p-synced',
      UpdateProductRequestDto(imageUpload: await pick([1])),
    );
    await service.delete('p-synced');
    expect((await productJson('p-synced'))['is_active'], false);
    final del = (await outbox()).last;
    expect(del['op'], 'delete');
    expect(del['base_version'], 6);
    expect(await f.count('pending_uploads'), 0);
    expect(stagedFiles(), isEmpty);
    await expectLater(
      service.delete('p-synced'),
      throwsA(isA<CatalogValidationException>()),
    );
  });

  test('cashier refused', () async {
    actor = const CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.cashier,
    );
    await seedSynced('p1');
    await expectLater(
      service.create(dto(image: await pick([1]))),
      throwsA(isA<CatalogValidationException>()),
    );
    await expectLater(
      service.update('p1', const UpdateProductRequestDto(price: '9')),
      throwsA(isA<CatalogValidationException>()),
    );
    await expectLater(
      service.delete('p1'),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(await outbox(), isEmpty);
    expect(stagedFiles(), isEmpty);
  });

  test('price must be a decimal string', () async {
    for (final bad in [
      '',
      'abc',
      '1.234',
      '-1',
      '1e3',
      '12,5',
      '12345678901',
    ]) {
      await expectLater(
        service.create(dto(price: bad)),
        throwsA(isA<CatalogValidationException>()),
        reason: 'price "$bad"',
      );
    }
    await expectLater(
      service.create(dto(cost: '3.5.1')),
      throwsA(isA<CatalogValidationException>()),
    );
    await seedSynced('p1');
    await expectLater(
      service.update('p1', const UpdateProductRequestDto(price: 'x')),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(await outbox(), isEmpty);
    // Valid forms.
    await service.create(dto(price: '0', sku: 'a'));
    await service.create(dto(price: '10.5', sku: 'b'));
    await service.create(dto(price: ' 7.25 ', sku: 'c'));
    expect(await outbox(), hasLength(3));
  });

  test(
    'duplicate sku/barcode (including inactive local rows) refused',
    () async {
      await seedSynced('old', sku: 'S-1', barcode: '111', active: false);
      await seedSynced('live', sku: 'S-2', barcode: '222');
      final img = await pick([3, 3]);
      for (final d in [
        dto(sku: 'S-1'),
        dto(sku: ' S-2 '),
        dto(barcode: '111', image: img),
        dto(barcode: '222'),
      ]) {
        await expectLater(
          service.create(d),
          throwsA(isA<CatalogValidationException>()),
        );
      }
      await expectLater(
        service.update('live', const UpdateProductRequestDto(barcode: '111')),
        throwsA(isA<CatalogValidationException>()),
      );
      expect(await outbox(), isEmpty);
      expect(
        stagedFiles(),
        isEmpty,
        reason: 'failed write deletes the staged file',
      );
      // Its own barcode is not a duplicate.
      await service.update(
        'live',
        const UpdateProductRequestDto(barcode: '222', name: 'Renamed'),
      );
      expect(payloadOf((await outbox()).single), {'name': 'Renamed'});
    },
  );

  test('product.create depends on an open category create', () async {
    final cat = await categories.create(name: 'Snacks');
    final id = await service.create(dto(category: cat));
    final rows = await outbox();
    final create = rows.firstWhere((r) => r['entity_id'] == id);
    expect(depsOf(create), [cat]);
    expect(create['status'], 'blocked');
  });

  test('unknown or inactive category refused', () async {
    await expectLater(
      service.create(dto(category: 'nope')),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(await outbox(), isEmpty);
  });

  test('newCategoryName creates the category and the product in ONE write; '
      'an existing active one is reused', () async {
    var notifications = 0;
    final sub = f.notifier.changes.listen((_) => notifications++);
    addTearDown(sub.cancel);
    final id = await service.create(
      dto(category: ''),
      newCategoryName: 'General',
    );
    final rows = await outbox();
    expect(rows.map((r) => '${r['entity']}.${r['op']}'), [
      'category.create',
      'product.create',
    ]);
    final catId = rows.first['entity_id'] as String;
    expect(depsOf(rows.last), [catId]);
    expect((await product(id))!['category_id'], catId);
    expect(payloadOf(rows.last)['category'], catId);
    expect(notifications, 1, reason: 'one LocalWriter.write');

    await service.create(
      dto(category: '', sku: 'x'),
      newCategoryName: 'general',
    );
    final again = await outbox();
    expect(again.where((r) => r['entity'] == 'category'), hasLength(1));
    expect(payloadOf(again.last)['category'], catId);
  });

  test(
    'initial quantity enqueues a dependent stock.add in the same write',
    () async {
      final id = await service.create(
        dto(),
        initialQuantity: '4.5',
        shopId: kShop,
      );
      final rows = await outbox();
      expect(rows.map((r) => '${r['entity']}.${r['op']}'), [
        'product.create',
        'stock.add',
      ]);
      final add = rows.last;
      expect(depsOf(add), [id]);
      expect(add['status'], 'blocked');
      expect(add['entity_id'], isNot(id));
      final pl = payloadOf(add);
      expect(pl['product_id'], id);
      expect(pl['shop_id'], kShop);
      expect(pl['delta'], '4.5');
      expect(
        (await f.db.query(
          'stock',
          where: 'product_id = ?',
          whereArgs: [id],
        )).single['quantity'],
        4.5,
      );
      expect(await f.level(id), 4.5);
    },
  );

  test('initial quantity: invalid, missing shop or restaurant refused, '
      'nothing written', () async {
    for (final q in ['0', '-1', 'abc', '1.2345']) {
      await expectLater(
        service.create(dto(), initialQuantity: q, shopId: kShop),
        throwsA(isA<CatalogValidationException>()),
        reason: q,
      );
    }
    await expectLater(
      service.create(dto(), initialQuantity: '3'),
      throwsA(isA<CatalogValidationException>()),
    );
    actor = const CatalogActor(
      businessType: AppBusinessType.restaurant,
      role: AppUserRole.owner,
    );
    await expectLater(
      service.create(dto(), initialQuantity: '3', shopId: kShop),
      throwsA(isA<CatalogValidationException>()),
    );
    expect(await outbox(), isEmpty);
    expect(await f.count('products'), 2, reason: 'fixture products only');
    // Blank quantity means none.
    await service.create(dto(), initialQuantity: '  ', shopId: kShop);
    expect(await outbox(), hasLength(1));
  });

  test(
    'delete of a never-sent create that a stock.add waits on is not '
    'dropped: inactive + delete after the create, dependents untouched',
    () async {
      final id = await service.create(
        dto(),
        initialQuantity: '2',
        shopId: kShop,
      );
      await service.delete(id);
      final rows = await outbox();
      expect(rows.map((r) => '${r['entity']}.${r['op']}'), [
        'product.create',
        'stock.add',
        'product.delete',
      ]);
      expect(rows[1]['status'], 'blocked');
      expect(rows.last['base_version'], isNull);
      expect((await productJson(id))['is_active'], false);
    },
  );

  test(
    'update changing only price enqueues {price} with baseVersion',
    () async {
      await seedSynced('p1', version: 9);
      await service.update(
        'p1',
        const UpdateProductRequestDto(
          price: '6.75',
          name: 'Seed p1',
          costPrice: '3.00',
          unit: 'piece',
          trackInventory: true,
          minStockLevel: '2',
        ),
      );
      final ob = (await outbox()).single;
      expect(ob['op'], 'update');
      expect(ob['base_version'], 9);
      expect(payloadOf(ob), {'price': '6.75'});
      expect((await product('p1'))!['price'], '6.75');
      expect((await productJson('p1'))['price'], '6.75');

      // Same values again (money compared as numbers): nothing written.
      await service.update(
        'p1',
        const UpdateProductRequestDto(price: '6.75', costPrice: '3'),
      );
      expect(await outbox(), hasLength(1));
    },
  );

  test('update moving category refreshes category_name and depends on an '
      'open category create', () async {
    await seedSynced('p1');
    final cat = await categories.create(name: 'Snacks');
    await service.update('p1', UpdateProductRequestDto(category: cat));
    final up = (await outbox()).last;
    expect(payloadOf(up), {'category': cat});
    expect(depsOf(up), [cat]);
    expect((await product('p1'))!['category_id'], cat);
    expect((await productJson('p1'))['category_name'], 'Snacks');
  });

  test('stock_level untouched by create/update', () async {
    await seedSynced('p1', stockLevel: 7.5);
    await service.update('p1', const UpdateProductRequestDto(name: 'New'));
    expect(await f.level('p1'), 7.5);
    expect((await productJson('p1'))['stock_level'], 7.5);
    final id = await service.create(dto(sku: 'zz'));
    expect(await f.level(id), 0);
    expect(await f.count('stock'), 2, reason: 'fixture stock rows only');
  });

  test(
    'update clears cost, barcode and expiry in the shape the BE accepts',
    () async {
      await seedSynced('p1', barcode: '999');
      await f.db.update(
        'products',
        {
          'json': jsonEncode({
            ...await productJson('p1'),
            'expiry_alert_days': 30,
          }),
        },
        where: 'id = ?',
        whereArgs: ['p1'],
      );
      await service.update(
        'p1',
        const UpdateProductRequestDto(
          costPrice: '',
          barcode: '',
          expiryAlertDays: '',
        ),
      );
      final payload = payloadOf((await outbox()).single);
      expect(payload, {
        'cost_price': '0',
        'barcode': '',
        'expiry_alert_days': null,
      });
      final j = await productJson('p1');
      expect(j['cost_price'], '0');
      expect(j['barcode'], isNull);
      expect(j['expiry_alert_days'], isNull);
      expect((await product('p1'))!['barcode'], isNull);
    },
  );

  test('uploads are staged under the write scope', () async {
    final id = await service.create(dto(image: await pick([1, 1])));
    expect((await uploads.get(f.db, 'product', id))!.scope, kScope);
    expect(await uploads.due(f.db, scope: 'other|t9'), isEmpty);
  });
}
