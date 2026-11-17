import 'dart:convert';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/appliers/business_applier.dart';
import 'package:amana_pos/core/sync/appliers/category_applier.dart';
import 'package:amana_pos/core/sync/appliers/product_applier.dart';
import 'package:amana_pos/core/sync/appliers/shop_applier.dart';
import 'package:amana_pos/core/sync/appliers/synced_entities_store.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/sync_appliers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/test_db.dart';

const _scope = 'u1|tenant1';

PullChange _up(String entity, String id, int? v, Map<String, dynamic> d) =>
    PullChange(
      seq: 0,
      entity: entity,
      op: 'upsert',
      id: id,
      version: v,
      data: d,
    );

PullChange _del(String entity, String id) =>
    PullChange(seq: 0, entity: entity, op: 'delete', id: id);

void main() {
  late OfflineDb odb;
  late Database db;

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
  });
  tearDown(() async => db.close());

  Future<void> run(ChangeApplier a, PullChange c) =>
      db.transaction((txn) => a.apply(txn, c));

  Future<Map<String, Object?>?> row(String t, String id) async {
    final r = await db.query(t, where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : r.first;
  }

  Map<String, dynamic> js(Map<String, Object?>? r) =>
      jsonDecode(r!['json'] as String) as Map<String, dynamic>;

  group('registration', () {
    test('buildSyncAppliers registers the four catalog appliers', () {
      final r = buildSyncAppliers();
      for (final e in ['business', 'shop', 'category', 'product']) {
        expect(r.of(e), isNotNull, reason: e);
        expect(r.of(e)!.skipWhenLocalPending, isTrue);
      }
    });
  });

  group('product', () {
    final applier = ProductApplier();
    Map<String, dynamic> p({
      String price = '12.50',
      String? cat = 'c1',
      String? hash = 'h1',
    }) => {
      'id': 'p1',
      'version': 1,
      'name': 'Tea',
      'sku': 'S1',
      'barcode': 'B1',
      'price': price,
      'cost_price': '8.00',
      'category': cat,
      'image': 'https://x/i.webp?v=abc',
      'thumbnail_url': 'https://x/t.webp?v=abc',
      'image_hash': hash,
      'is_active': true,
      'track_inventory': true,
      'min_stock_level': 2,
      'unit': 'pcs',
      'updated_at': '2026-11-16T10:00:00Z',
    };

    test('upsert inserts typed columns and legacy json', () async {
      await run(applier, _up('product', 'p1', 1, p()));
      final r = (await row('products', 'p1'))!;
      expect(r['name'], 'Tea');
      expect(r['price'], '12.50');
      expect(r['category_id'], 'c1');
      expect(r['image_url'], 'https://x/i.webp?v=abc');
      expect(r['thumbnail_url'], 'https://x/t.webp?v=abc');
      expect(r['image_hash'], 'h1');
      expect(r['version'], 1);
      final j = js(r);
      expect(j['price'], '12.50');
      expect(j['cost_price'], '8.00');
      expect(j['category'], 'c1');
      expect(j['stock_level'], 0);
    });

    test('newer version updates, older/equal is a no-op', () async {
      await run(applier, _up('product', 'p1', 2, p(price: '10.00')));
      await run(applier, _up('product', 'p1', 2, p(price: '99.00')));
      await run(applier, _up('product', 'p1', 1, p(price: '1.00')));
      expect((await row('products', 'p1'))!['price'], '10.00');
      await run(applier, _up('product', 'p1', 3, p(price: '11.00')));
      expect((await row('products', 'p1'))!['price'], '11.00');
      expect((await row('products', 'p1'))!['version'], 3);
      expect(
        await db.transaction(
          (t) => applier.localVersion(t, _up('product', 'p1', 9, p())),
        ),
        3,
      );
    });

    test(
      'derives stock_level, category_name and category product_count',
      () async {
        await run(
          CategoryApplier(scopeProvider: () => _scope),
          _up('category', 'c1', 1, {
            'id': 'c1',
            'version': 1,
            'name': 'Drinks',
          }),
        );
        await db.insert('stock', {
          'id': 's1',
          'product_id': 'p1',
          'shop_id': 'sh1',
          'quantity': 3.5,
          'json': '{}',
        });
        await db.insert('stock', {
          'id': 's2',
          'product_id': 'p1',
          'shop_id': 'sh2',
          'quantity': 1.25,
          'json': '{}',
        });
        await run(applier, _up('product', 'p1', 1, p()));
        final r = (await row('products', 'p1'))!;
        expect(r['stock_level'], 4.75);
        expect(js(r)['stock_level'], 4.75);
        expect(js(r)['category_name'], 'Drinks');
        expect(js(await row('categories', 'c1'))['product_count'], 1);
        // move category: both counts follow
        await run(
          CategoryApplier(scopeProvider: () => _scope),
          _up('category', 'c2', 1, {'id': 'c2', 'version': 1, 'name': 'Food'}),
        );
        await run(applier, _up('product', 'p1', 2, p(cat: 'c2')));
        expect(js(await row('categories', 'c1'))['product_count'], 0);
        expect(js(await row('categories', 'c2'))['product_count'], 1);
        expect(js(await row('products', 'p1'))['category_name'], 'Food');
        await run(applier, _del('product', 'p1'));
        expect(js(await row('categories', 'c2'))['product_count'], 0);
      },
    );

    test('delete removes; inactive row kept with is_active false', () async {
      await run(applier, _up('product', 'p1', 1, p()..['is_active'] = false));
      expect(js(await row('products', 'p1'))['is_active'], false);
      await run(applier, _del('product', 'p1'));
      expect(await row('products', 'p1'), isNull);
    });

    test('malformed rows are skipped without throwing', () async {
      await run(applier, _up('product', 'p1', 1, p(price: 'abc')));
      await run(applier, _up('product', 'p1', 1, p()..remove('name')));
      await run(applier, _up('product', 'p1', 1, p()..['cost_price'] = 'x'));
      await run(
        applier,
        const PullChange(seq: 0, entity: 'product', op: 'upsert', id: 'p1'),
      );
      await run(applier, _up('product', '', 1, p()));
      await run(applier, _up('product', 'p1', null, p()..remove('version')));
      expect(await db.query('products'), isEmpty);
    });

    test('empty / null image_hash stored as null-safe token', () async {
      await run(applier, _up('product', 'p1', 1, p(hash: '')));
      expect((await row('products', 'p1'))!['image_hash'], '');
      await run(applier, _up('product', 'p1', 2, p(hash: null)));
      expect((await row('products', 'p1'))!['image_hash'], isNull);
    });
  });

  group('category', () {
    final applier = CategoryApplier(scopeProvider: () => _scope);
    Map<String, dynamic> c({String name = 'Drinks', String? parent}) => {
      'id': 'c1',
      'version': 1,
      'name': name,
      'parent': parent,
      'description': 'd',
      'sort_order': 3,
      'is_active': true,
      'image': 'https://x/c.webp',
      'thumbnail_url': 'https://x/ct.webp',
      'image_hash': 'ch',
      'updated_at': '2026-11-16T10:00:00Z',
    };

    test('upsert columns, tenant from scope, image_hash', () async {
      await run(applier, _up('category', 'c1', 1, c(parent: 'c0')));
      final r = (await row('categories', 'c1'))!;
      expect(r['tenant_id'], 'tenant1');
      expect(r['parent_id'], 'c0');
      expect(r['name'], 'Drinks');
      expect(r['image_hash'], 'ch');
      expect(r['version'], 1);
      final j = js(r);
      expect(j['tenant'], 'tenant1');
      expect(j['parent'], 'c0');
      expect(j['product_count'], 0);
      expect(j['children'], isNull);
      expect(j['thumbnail_url'], 'https://x/ct.webp');
    });

    test(
      'older/equal no-op, newer updates, rename refreshes products',
      () async {
        await run(applier, _up('category', 'c1', 2, c()));
        await run(
          ProductApplier(),
          _up('product', 'p1', 1, {
            'id': 'p1',
            'version': 1,
            'name': 'T',
            'price': '1',
            'category': 'c1',
          }),
        );
        await run(applier, _up('category', 'c1', 2, c(name: 'Other')));
        await run(applier, _up('category', 'c1', 1, c(name: 'Older')));
        expect((await row('categories', 'c1'))!['name'], 'Drinks');
        await run(applier, _up('category', 'c1', 3, c(name: 'Beverages')));
        expect((await row('categories', 'c1'))!['name'], 'Beverages');
        expect(js(await row('categories', 'c1'))['product_count'], 1);
        expect(js(await row('products', 'p1'))['category_name'], 'Beverages');
      },
    );

    test('no scope and no row writes nothing; existing keeps tenant', () async {
      final noScope = CategoryApplier(scopeProvider: () => null);
      await run(noScope, _up('category', 'c1', 1, c()));
      expect(await db.query('categories'), isEmpty);
      await run(applier, _up('category', 'c1', 1, c()));
      await run(noScope, _up('category', 'c1', 2, c(name: 'N')));
      expect((await row('categories', 'c1'))!['tenant_id'], 'tenant1');
      expect((await row('categories', 'c1'))!['name'], 'N');
    });

    test(
      'version-skipped category write does not refresh product names',
      () async {
        await run(applier, _up('category', 'c1', 2, c()));
        await run(
          ProductApplier(),
          _up('product', 'p1', 1, {
            'id': 'p1',
            'version': 1,
            'name': 'T',
            'price': '1',
            'category': 'c1',
          }),
        );
        await run(applier, _up('category', 'c1', 1, c(name: 'Older')));
        expect(js(await row('products', 'p1'))['category_name'], 'Drinks');
      },
    );

    test(
      'category arriving after its products refreshes names and count',
      () async {
        await run(
          ProductApplier(),
          _up('product', 'p1', 1, {
            'id': 'p1',
            'version': 1,
            'name': 'T',
            'price': '1',
            'category': 'c1',
          }),
        );
        expect(js(await row('products', 'p1'))['category_name'], isNull);
        await run(applier, _up('category', 'c1', 1, c()));
        expect(js(await row('products', 'p1'))['category_name'], 'Drinks');
        expect(js(await row('categories', 'c1'))['product_count'], 1);
      },
    );

    test('delete, inactive kept, malformed skipped', () async {
      await run(applier, _up('category', 'c1', 1, c()..['is_active'] = false));
      expect(js(await row('categories', 'c1'))['is_active'], false);
      await run(applier, _del('category', 'c1'));
      expect(await row('categories', 'c1'), isNull);
      await run(applier, _up('category', 'c1', 1, c()..remove('name')));
      await run(applier, _up('category', '', 1, c()));
      expect(await db.query('categories'), isEmpty);
    });
  });

  group('shop', () {
    final applier = ShopApplier(scopeProvider: () => _scope);
    Map<String, dynamic> s({String name = 'Main'}) => {
      'id': 's1',
      'version': 1,
      'name': name,
      'address': 'Khartoum',
      'phone': '123',
      'is_main': true,
      'is_active': true,
      'updated_at': '2026-11-16T10:00:00Z',
    };

    test('upsert sets business_id from scope tenant; versions guard', () async {
      await run(applier, _up('shop', 's1', 2, s()));
      final r = (await row('shops', 's1'))!;
      expect(r['business_id'], 'tenant1');
      expect(r['version'], 2);
      expect(js(r)['name'], 'Main');
      expect(js(r)['business'], 'tenant1');
      await run(applier, _up('shop', 's1', 2, s(name: 'Same')));
      await run(applier, _up('shop', 's1', 1, s(name: 'Old')));
      expect(js(await row('shops', 's1'))['name'], 'Main');
      await run(applier, _up('shop', 's1', 3, s(name: 'New')));
      expect(js(await row('shops', 's1'))['name'], 'New');
    });

    test('no scope: existing row keeps business_id, no row => nothing written; '
        'delete; inactive; malformed', () async {
      final noScope = ShopApplier(scopeProvider: () => null);
      await run(noScope, _up('shop', 's1', 1, s()));
      expect(await db.query('shops'), isEmpty);
      await run(applier, _up('shop', 's1', 1, s()));
      await run(noScope, _up('shop', 's1', 2, s()..['is_active'] = false));
      expect((await row('shops', 's1'))!['business_id'], 'tenant1');
      expect(js(await row('shops', 's1'))['is_active'], false);
      await run(applier, _del('shop', 's1'));
      expect(await row('shops', 's1'), isNull);
      await run(applier, _up('shop', 's1', 1, s()..remove('name')));
      await run(applier, _up('shop', '', 1, s()));
      expect(await db.query('shops'), isEmpty);
    });
  });

  group('business', () {
    final applier = BusinessApplier();
    Map<String, dynamic> b({String name = 'Acme', String tax = '15.000'}) => {
      'id': 'b1',
      'version': 1,
      'name': name,
      'slug': 'acme',
      'business_type': 'retail',
      'currency': 'SDG',
      'timezone': 'Africa/Khartoum',
      'tax_enabled': true,
      'tax_rate': tax,
      'is_active': true,
      'updated_at': '2026-11-16T10:00:00Z',
    };
    const store = SyncedEntitiesStore();

    test(
      'writes synced_entities, never inserts the legacy businesses row',
      () async {
        await run(applier, _up('business', 'b1', 1, b()));
        expect(await db.query('businesses'), isEmpty);
        final r = await db.query('synced_entities');
        expect(r, hasLength(1));
        expect(r.first['entity'], 'business');
        expect(r.first['version'], 1);
        expect(jsonDecode(r.first['json'] as String)['currency'], 'SDG');
      },
    );

    test(
      'merges scalar keys into an existing legacy row, preserves the rest',
      () async {
        await db.insert('businesses', {
          'id': 'b1',
          'json': jsonEncode({
            'id': 'b1',
            'name': 'Old',
            'owner': 'u1',
            'shop_count': 3,
            'logo': 'l.png',
            'tax_rate': '0',
          }),
        });
        await run(applier, _up('business', 'b1', 1, b(tax: '5.000')));
        final j = js(await row('businesses', 'b1'));
        expect(j['name'], 'Acme');
        expect(j['tax_rate'], '5.000');
        expect(j['owner'], 'u1');
        expect(j['shop_count'], 3);
        expect(j['logo'], 'l.png');
        expect(j.containsKey('currency'), isFalse);
      },
    );

    test(
      'older/equal version no-op everywhere; newer wins; localVersion',
      () async {
        await db.insert('businesses', {
          'id': 'b1',
          'json': jsonEncode({'id': 'b1', 'name': 'Old'}),
        });
        await run(applier, _up('business', 'b1', 2, b()));
        await run(applier, _up('business', 'b1', 2, b(name: 'Same')));
        await run(applier, _up('business', 'b1', 1, b(name: 'Older')));
        expect(js(await row('businesses', 'b1'))['name'], 'Acme');
        await db.transaction(
          (t) async => expect(await store.localVersion(t, 'business', 'b1'), 2),
        );
        await run(applier, _up('business', 'b1', 3, b(name: 'Newer')));
        expect(js(await row('businesses', 'b1'))['name'], 'Newer');
      },
    );

    test('delete removes synced row; malformed skipped', () async {
      await run(applier, _up('business', 'b1', 1, b()));
      await run(applier, _del('business', 'b1'));
      expect(await db.query('synced_entities'), isEmpty);
      await run(applier, _up('business', 'b1', 1, b()..remove('name')));
      await run(applier, _up('business', '', 1, b()));
      expect(await db.query('synced_entities'), isEmpty);
    });
  });
}
