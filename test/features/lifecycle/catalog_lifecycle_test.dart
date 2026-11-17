// Phase 3 lifecycle (Task 9) on the REAL stack: an owner's offline day of
// catalog work on device A (category, product with image and opening
// stock, vendor; sell the new product, edit its price, delete a vendor),
// then reconnect: everything lands, the server holds one image, the sale
// line names the product, stock is exact, and a second device pulls all of
// it. Then a SKU collision between two devices ends `rejected
// conflict_unique` with "Merge into existing" available; the merge
// converges both devices and the server.
import 'dart:convert';
import 'dart:io';

import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:amana_pos/core/sync/decimal3.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_vendor_request_dto.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/products/data/model/request/add_product_request_dto.dart';
import 'package:amana_pos/features/products/data/model/request/update_product_request_dto.dart';
import 'package:amana_pos/features/sync/domain/catalog_conflict_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/sync/support/fake_sync_server.dart';
import 'support/lifecycle_device.dart';

const _oldVendor = 'cccccccc-0000-4000-8000-000000000001';

void main() {
  late Directory dir;
  late Clock clock;
  late FakeSyncServer server;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('catalog_lifecycle');
    clock = Clock(DateTime.utc(2026, 11, 17, 8));
    server = FakeSyncServer(deviceId: 'srv', now: clock.now)
      ..strictCatalog = true
      ..seedVendor(_oldVendor);
    server.tables['vendor']![_oldVendor]!
      ..['name'] = 'Old Supplier'
      ..['is_active'] = true;
    for (final c in kCatalog) {
      server
        ..seedProduct(c.id, name: c.name, price: c.price)
        ..seedStock(c.id, kShop, c.base);
    }
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  Future<LifecycleDevice> device(String name, String id) async {
    final d = await LifecycleDevice.create(
      name: name,
      dir: dir,
      deviceId: id,
      view: server.forDevice(id),
      clock: clock,
    );
    // What the bootstrap leaves for the seeded vendor.
    await d.db.insert('vendors', {
      'id': _oldVendor,
      'version': 1,
      'json': jsonEncode({
        'id': _oldVendor,
        'name': 'Old Supplier',
        'is_active': true,
      }),
      'server_json': jsonEncode({
        'id': _oldVendor,
        'name': 'Old Supplier',
        'is_active': true,
        'version': 1,
      }),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    addTearDown(d.dispose);
    return d;
  }

  /// Syncs (and runs the foreground uploader) until nothing is left to send.
  Future<void> settle(LifecycleDevice d) async {
    for (var i = 0; i < 8; i++) {
      clock.advance(const Duration(seconds: 30));
      await d.sync();
      await d.uploader.run();
      final open = await d.db.rawQuery(
        "SELECT COUNT(*) AS c FROM outbox WHERE status IN "
        "('pending','blocked','inflight')",
      );
      final waiting = await d.db.query('pending_uploads');
      if ((open.first['c'] as int) == 0 && waiting.isEmpty) break;
    }
    await d.sync(); // pull the uploader's own feed rows
  }

  Future<PickedAppImage> picture(List<int> bytes) async {
    final f = File('${dir.path}/pick_${bytes.length}.jpg');
    await f.writeAsBytes(bytes);
    return PickedAppImage(file: f, path: f.path, name: 'pick.jpg');
  }

  Future<Map<String, dynamic>> localJson(
    LifecycleDevice d,
    String table,
    String id,
  ) async {
    final r = await d.db.query(table, where: 'id = ?', whereArgs: [id]);
    return jsonDecode(r.single['json'] as String) as Map<String, dynamic>;
  }

  SaleDraft sell(String productId, String name, String qty, String price) =>
      SaleDraft(
        shopId: kShop,
        paymentMethod: 'cash',
        lines: [
          SaleDraftLine.product(
            productId: productId,
            productName: name,
            quantity: qty,
            unitPrice: price,
            snapshot: {'id': productId, 'name': name},
          ),
        ],
      );

  test('an offline day of catalog work lands exactly and reaches a second '
      'device', () async {
    final a = await device('a', 'aaaa0000-0000-4000-8000-00000000000a');
    final b = await device('b', 'bbbb0000-0000-4000-8000-00000000000b');

    // ---- device A, offline all day ----
    a.view.down = true;
    final bytes = List<int>.generate(512, (i) => (i * 7) % 256);
    final sha = sha256.convert(bytes).toString();
    final cat = await a.categories.create(name: 'Snacks');
    final vendor = await a.vendors.create(
      const CreateVendorRequestDto(name: 'Nile Foods'),
    );
    final pid = await a.products.create(
      AddProductRequestDto(
        name: 'Crisps',
        price: '3.50',
        category: cat,
        unit: 'piece',
        sku: 'CR-1',
        trackInventory: true,
        imageUpload: await picture(bytes),
      ),
      initialQuantity: '10',
      shopId: kShop,
    );
    final sale = await a.sales.createSale(sell(pid, 'Crisps', '2', '3.50'));
    await a.products.update(pid, const UpdateProductRequestDto(price: '4.00'));
    await a.vendors.delete(_oldVendor);
    await a.sync(); // offline: nothing moves
    expect(server.tables['product']!.containsKey(pid), isFalse);
    expect(await a.displayedUnits(pid), Decimal3.parse('8'));

    // ---- reconnect ----
    a.view.down = false;
    await settle(a);

    expect(await a.notDone(), isEmpty);
    expect(await a.db.query('pending_uploads'), isEmpty);
    final sp = server.tables['product']![pid]!;
    expect(sp['price'], '4.00');
    expect(sp['category'], cat);
    expect(sp['sku'], 'CR-1');
    expect(sp['image_hash'], sha);
    expect(server.imageStores, 1, reason: 'exactly one server image');
    expect(server.tables['category']![cat]!['name'], 'Snacks');
    expect(server.tables['vendor']![vendor]!['name'], 'Nile Foods');
    expect(server.tables['vendor']![_oldVendor]!['is_active'], isFalse);
    final serverSale = server.tables['sale']![sale.id]!;
    expect(
      [for (final it in serverSale['items'] as List) (it as Map)['product']],
      [pid],
    );
    expect(server.stockQuantity(pid, kShop), '8');
    expect(await a.displayedUnits(pid), Decimal3.parse('8'));
    final aRow = (await a.db.query(
      'products',
      where: 'id = ?',
      whereArgs: [pid],
    )).single;
    expect(aRow['image_hash'], sha);
    expect(aRow['price'], '4.00');

    // ---- device B pulls all of it ----
    await settle(b);
    final bp = await localJson(b, 'products', pid);
    expect(bp['price'], '4.00');
    expect(bp['category'], cat);
    expect(bp['image_hash'], sha);
    expect((await localJson(b, 'categories', cat))['name'], 'Snacks');
    expect((await localJson(b, 'vendors', vendor))['name'], 'Nile Foods');
    final old = await b.db.query(
      'vendors',
      where: 'id = ?',
      whereArgs: [_oldVendor],
    );
    expect(
      old.isEmpty ||
          (jsonDecode(old.single['json'] as String) as Map)['is_active'] ==
              false,
      isTrue,
      reason: 'the deleted vendor is gone or inactive on B',
    );
    expect(await b.displayedUnits(pid), Decimal3.parse('8'));
    expect((await b.localSales()).keys, contains(sale.id));
  });

  test('the same SKU on two devices: rejected conflict_unique with Merge '
      'available, merge then converges', () async {
    final a = await device('a', 'aaaa0000-0000-4000-8000-00000000000a');
    final b = await device('b', 'bbbb0000-0000-4000-8000-00000000000b');

    // A creates and syncs first.
    final catA = await a.categories.create(name: 'Drinks');
    final juiceA = await a.products.create(
      AddProductRequestDto(
        name: 'Juice',
        price: '2.00',
        category: catA,
        unit: 'piece',
        sku: 'DUP-1',
        trackInventory: true,
      ),
      initialQuantity: '5',
      shopId: kShop,
    );
    await settle(a);
    expect(await a.notDone(), isEmpty);

    // B, offline before ever pulling A's product, creates the same SKU,
    // with opening stock, and sells it.
    b.view.down = true;
    final catB = await b.categories.create(name: 'Beverages');
    final juiceB = await b.products.create(
      AddProductRequestDto(
        name: 'Orange juice',
        price: '2.25',
        category: catB,
        unit: 'piece',
        sku: 'DUP-1',
        trackInventory: true,
      ),
      initialQuantity: '3',
      shopId: kShop,
    );
    final sale = await b.sales.createSale(
      sell(juiceB, 'Orange juice', '1', '2.25'),
    );
    b.view.down = false;
    await settle(b);

    // Rejected, nothing rewritten automatically (policy A).
    final create = OutboxEntry.fromRow(
      (await b.db.query(
        'outbox',
        where: "entity = 'product' AND entity_id = ? AND op = 'create'",
        whereArgs: [juiceB],
      )).single,
    );
    expect(create.status, OutboxStatus.rejected);
    expect(create.errorCode, 'conflict_unique');
    expect(create.errorEntityId, juiceA);
    expect(CatalogConflictService.canMerge(create), isTrue);
    expect(
      server.tables['sale']?.containsKey(sale.id) ?? false,
      isFalse,
      reason: 'the sale waits: it would land with product = NULL',
    );
    // B already pulled A's product.
    expect(
      await b.db.query('products', where: 'id = ?', whereArgs: [juiceA]),
      hasLength(1),
    );

    // The user merges (confirmed); the counts match the preview.
    final preview = await b.conflicts.previewMerge(
      juiceB,
      juiceA,
      entity: 'product',
    );
    final report = await b.conflicts.mergeInto(
      juiceB,
      juiceA,
      entity: 'product',
    );
    expect(report, preview);
    expect(report.saleLines, 1);
    await settle(b);
    await settle(a);

    expect(await b.notDone(), isEmpty);
    final serverSale = server.tables['sale']![sale.id]!;
    expect(
      [for (final it in serverSale['items'] as List) (it as Map)['product']],
      [juiceA],
    );
    // 5 (A opening) + 3 (B opening, now on A's product) - 1 (B's sale).
    expect(server.stockQuantity(juiceA, kShop), '7');
    expect(server.tables['product']!.containsKey(juiceB), isFalse);
    for (final d in [a, b]) {
      expect(await d.displayedUnits(juiceA), Decimal3.parse('7'));
      expect(
        await d.db.query('products', where: 'id = ?', whereArgs: [juiceB]),
        isEmpty,
      );
    }
    // B's own category was created and stays (no conflict on it).
    expect(server.tables['category']!.containsKey(catB), isTrue);
  });
}
