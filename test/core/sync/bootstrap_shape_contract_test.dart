import 'dart:convert';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/sync_appliers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/test_db.dart';

/// Bootstrap items are the feed row's `data` only (apps/sync/pull.py
/// `bootstrap_page` -> `feed.serialize`): no `seq`, `origin_device_id`,
/// `shop_id` wrapper fields. One real-shaped item per entity, key sets
/// copied VERBATIM from the BE serializers (apps/sync/feed.py `ser_*`), is
/// pushed through EVERY registered applier exactly as the Bootstrapper will
/// wrap it. Values are realistic; keys must not drift from the BE.

const _tenant = 'b0000000-0000-4000-8000-000000000001';
const _scope = 'u0000000-0000-4000-8000-000000000009|$_tenant';
const _shop = 's0000000-0000-4000-8000-000000000002';
const _cat = 'c0000000-0000-4000-8000-000000000003';
const _prod = 'p0000000-0000-4000-8000-000000000004';
const _cust = 'k0000000-0000-4000-8000-000000000005';
const _vendor = 'v0000000-0000-4000-8000-000000000006';
const _user = 'u0000000-0000-4000-8000-000000000009';
const _sale = 'a0000000-0000-4000-8000-000000000010';
const _saleItem = 'a1000000-0000-4000-8000-000000000011';
const _ts = '2026-11-16T10:15:30.123Z';

/// Bootstrap entity order (plan, Global Constraints).
const _order = [
  'business',
  'shop',
  'category',
  'product',
  'vendor',
  'customer',
  'user',
  'subscription',
  'bankak_account',
  'stock',
  'expiry_batch',
  'sale',
  'refund',
  'inbound',
  'notification',
];

/// Keys exactly as `ser_<entity>` emits them.
final Map<String, Map<String, dynamic>> _items = {
  // ser_business
  'business': {
    'id': _tenant,
    'version': 3,
    'name': 'Nile Grocery',
    'slug': 'nile-grocery',
    'business_type': 'retail',
    'address': 'Khartoum',
    'phone': '+249900000000',
    'email': '',
    'currency': 'SDG',
    'timezone': 'Africa/Khartoum',
    'tax_enabled': true,
    'tax_name': 'VAT',
    'tax_rate': '17.00',
    'tax_inclusive': false,
    'is_active': true,
    'updated_at': _ts,
  },
  // ser_shop
  'shop': {
    'id': _shop,
    'version': 2,
    'name': 'Main shop',
    'address': 'Souq Arabi',
    'phone': '+249911111111',
    'is_main': true,
    'is_active': true,
    'updated_at': _ts,
  },
  // ser_category
  'category': {
    'id': _cat,
    'version': 1,
    'parent': null,
    'name': 'Drinks',
    'description': '',
    'image': 'https://cdn.example/c.webp?v=abcdef012345',
    'thumbnail_url': 'https://cdn.example/c_t.webp?v=abcdef012345',
    'image_hash': 'abcdef0123456789',
    'sort_order': 0,
    'is_active': true,
    'updated_at': _ts,
  },
  // ser_product
  'product': {
    'id': _prod,
    'version': 5,
    'shop': null,
    'category': _cat,
    'name': 'Pepsi 330ml',
    'description': '',
    'sku': 'PEP-330',
    'barcode': '6223000000001',
    'price': '1500.00',
    'cost_price': '1100.00',
    'image': null,
    'thumbnail_url': null,
    'image_hash': '',
    'unit': 'piece',
    'is_active': true,
    'track_inventory': true,
    'min_stock_level': 10,
    'expiry_alert_days': null,
    'updated_at': _ts,
  },
  // ser_vendor
  'vendor': {
    'id': _vendor,
    'version': 1,
    'name': 'Delta Supplies',
    'phone': '+249922222222',
    'email': '',
    'address': '',
    'notes': '',
    'is_active': true,
    'updated_at': _ts,
  },
  // ser_customer
  'customer': {
    'id': _cust,
    'version': 1,
    'name': 'Amna',
    'phone': '+249933333333',
    'email': '',
    'address': '',
    'notes': '',
    'loyalty_points': 12,
    'is_active': true,
    'updated_at': _ts,
  },
  // ser_user
  'user': {
    'id': _user,
    'version': 4,
    'phone': '+249944444444',
    'full_name': 'Omer Ali',
    'role': 'owner',
    'default_shop': _shop,
    'is_active': true,
    'status': 'active',
    'last_login_at': _ts,
    'created_at': _ts,
  },
  // ser_subscription (no version)
  'subscription': {
    'id': 'sub00000-0000-4000-8000-000000000012',
    'start_date': '2026-11-01',
    'end_date': '2026-12-01',
    'is_active': true,
    'is_expired': false,
    'days_remaining': 15,
    'plan': {
      'id': 'pl000000-0000-4000-8000-000000000013',
      'name': 'Pro',
      'price': '0.00',
      'currency': 'SDG',
      'max_shops': 3,
      'max_products': 1000,
      'max_users': 5,
      'duration_days': 30,
      'features': <String, dynamic>{'premium': true},
      'is_free': false,
    },
  },
  // ser_bankak (no version)
  'bankak_account': {
    'id': 'bk000000-0000-4000-8000-000000000014',
    'account_number': '1234567',
    'account_name': 'Nile Grocery',
    'is_default': true,
    'is_active': true,
  },
  // ser_stock (no version)
  'stock': {
    'id': 'st000000-0000-4000-8000-000000000015',
    'product_id': _prod,
    'shop_id': _shop,
    'quantity': '7.000',
    'updated_at': _ts,
  },
  // ser_expiry_batch (no version)
  'expiry_batch': {
    'id': 'eb000000-0000-4000-8000-000000000016',
    'product': _prod,
    'shop': _shop,
    'quantity': '4.000',
    'expiry_date': '2027-01-31',
    'batch_number': 'B-77',
    'updated_at': _ts,
  },
  // ser_sale (no version), nested payments + items
  'sale': {
    'id': _sale,
    'shop': _shop,
    'cashier': _user,
    'customer': _cust,
    'receipt_number': 'R-0001',
    'local_receipt_number': 'L-0001',
    'client_sale_id': _sale,
    'device_id': 'd0000000-0000-4000-8000-000000000017',
    'total_amount': '3000.00',
    'discount_amount': '0.00',
    'tax_amount': '0.00',
    'tax_rate': '0.00',
    'tax_inclusive': false,
    'tax_name': '',
    'net_amount': '3000.00',
    'payment_method': 'cash',
    'bankak_account_snapshot': null,
    'status': 'partial_refund',
    'notes': '',
    'occurred_at': _ts,
    'received_at': _ts,
    'occurred_at_suspect': false,
    'created_at': _ts,
    'updated_at': _ts,
    'refunded_amount': '1500.00',
    'payments': [
      {'method': 'cash', 'amount': '3000.00'},
    ],
    'items': [
      {
        'id': _saleItem,
        'product': _prod,
        'product_name': 'Pepsi 330ml',
        'is_custom': false,
        'note': '',
        'quantity': '2.000',
        'unit_price': '1500.00',
        'unit_cost': '1100.00',
        'discount': '0.00',
        'subtotal': '3000.00',
        'returned_quantity': '1.000',
      },
    ],
  },
  // ser_refund (no version)
  'refund': {
    'id': 'rf000000-0000-4000-8000-000000000018',
    'sale': _sale,
    'shop': _shop,
    'reference': 'RF-0001',
    'total': '1500.00',
    'method': 'cash',
    'notes': '',
    'refunded_by': _user,
    'occurred_at': _ts,
    'created_at': _ts,
    'items': [
      {'sale_item': _saleItem, 'quantity': '1.000', 'amount': '1500.00'},
    ],
  },
  // ser_inbound (no version)
  'inbound': {
    'id': 'in000000-0000-4000-8000-000000000019',
    'shop': _shop,
    'vendor': _vendor,
    'reference': 'IN-0001',
    'notes': '',
    'created_by': _user,
    'created_at': _ts,
    'items': [
      {
        'product': _prod,
        'quantity': '12.000',
        'unit_cost': '1100.00',
        'expiry_date': '2027-01-31',
        'batch_number': 'B-77',
      },
    ],
  },
  // ser_notification (no version)
  'notification': {
    'id': 'nt000000-0000-4000-8000-000000000020',
    'title': 'Low stock',
    'body': 'Pepsi 330ml is low',
    'notification_type': 'low_stock',
    'is_read': false,
    'data': <String, dynamic>{'product_id': _prod},
    'created_at': _ts,
  },
};

/// The synthetic change the Bootstrapper builds (design section 2).
PullChange _wrap(String entity, Map<String, dynamic> item) => PullChange(
  seq: 0,
  entity: entity,
  op: 'upsert',
  id: item['id'] as String,
  version: item['version'] as int?,
  data: item,
  originDeviceId: null,
  shopId: null,
);

/// Where each entity's row must land.
Future<bool> _exists(DatabaseExecutor db, String entity, String id) async {
  Future<bool> inTable(String t) async =>
      (await db.query(t, where: 'id = ?', whereArgs: [id])).isNotEmpty;
  switch (entity) {
    case 'shop':
      return inTable('shops');
    case 'category':
      return inTable('categories');
    case 'product':
      return inTable('products');
    case 'vendor':
      return inTable('vendors');
    case 'customer':
      return inTable('customers');
    case 'stock':
      return inTable('stock');
    case 'sale':
      return inTable('sales');
    case 'refund':
      return inTable('sale_refunds');
    case 'inbound':
      return inTable('inbound_transactions');
    default: // business, user, subscription, bankak_account, expiry_batch,
      // notification
      return (await db.query(
        'synced_entities',
        where: 'entity = ? AND id = ?',
        whereArgs: [entity, id],
      )).isNotEmpty;
  }
}

void main() {
  late OfflineDb odb;
  late Database db;
  late ChangeApplierRegistry registry;

  setUp(() async {
    odb = await openTestDb();
    db = await odb.database;
    registry = buildSyncAppliers(scopeProvider: () => _scope);
  });
  tearDown(() async => db.close());

  Future<void> applyAll(Iterable<String> entities) async {
    for (final e in entities) {
      final a = registry.of(e);
      expect(a, isNotNull, reason: 'no applier for $e');
      // One page transaction per entity, like the Bootstrapper.
      await db.transaction((txn) => a!.apply(txn, _wrap(e, _items[e]!)));
    }
  }

  test('every registered applier has a contract item and vice versa', () {
    expect(
      registry.all
          .map((a) => a.entity)
          .where((e) => !pushOnlyEntities.contains(e))
          .toSet(),
      _items.keys.toSet(),
    );
    expect(_order.toSet(), _items.keys.toSet());
  });

  test('bootstrap-shaped items in entity order land in their tables', () async {
    await applyAll(_order);
    for (final e in _order) {
      expect(
        await _exists(db, e, _items[e]!['id'] as String),
        isTrue,
        reason: '$e row missing',
      );
    }
    // Nested sale lines/payments came through without the wrapper.
    expect(
      await db.query('sale_items', where: 'sale_id = ?', whereArgs: [_sale]),
      hasLength(1),
    );
    expect(
      await db.query('sale_payments', where: 'sale_id = ?', whereArgs: [_sale]),
      hasLength(1),
    );
    // shop_id taken from the row itself (no wrapper shopId).
    final st = await db.query(
      'stock',
      where: 'product_id = ?',
      whereArgs: [_prod],
    );
    expect(st.single['shop_id'], _shop);
    final sale = await db.query('sales', where: 'id = ?', whereArgs: [_sale]);
    expect(sale.single['shop_id'], _shop);
    // Status comes from the pulled sale row, never from the refund.
    expect(sale.single['status'], 'partial_refund');
    final inb = await db.query(
      'inbound_transactions',
      where: 'id = ?',
      whereArgs: [_items['inbound']!['id']],
    );
    expect(inb.single['shop_id'], _shop);
    final rf = await db.query('sale_refunds');
    expect(rf.single['shop_id'], _shop);
    expect(rf.single['sale_id'], _sale);
  });

  test('stock and inbound rows carry the names their readers show', () async {
    await applyAll(_order);
    final st = await db.query(
      'stock',
      where: 'product_id = ?',
      whereArgs: [_prod],
    );
    final sj = jsonDecode(st.single['json'] as String) as Map;
    expect(sj['product_name'], 'Pepsi 330ml');
    expect(sj['product_sku'], 'PEP-330');
    expect(sj['shop_name'], 'Main shop');
    // 7 <= min_stock_level 10 and > 0.
    expect(sj['is_low_stock'], isTrue);

    final inb = await db.query(
      'inbound_transactions',
      where: 'id = ?',
      whereArgs: [_items['inbound']!['id']],
    );
    final ij = jsonDecode(inb.single['json'] as String) as Map;
    expect(ij['vendor_id'], _vendor);
    expect(ij['vendor_name'], 'Delta Supplies');
    expect(ij['shop_name'], 'Main shop');
    expect(ij['created_by_name'], 'Omer Ali');
    expect((ij['items'] as List).single['product_name'], 'Pepsi 330ml');
  });

  test('reverse order (children before parents) never throws', () async {
    await applyAll(_order.reversed);
    for (final e in [
      'stock',
      'sale',
      'refund',
      'inbound',
      'expiry_batch',
      'product',
    ]) {
      expect(
        await _exists(db, e, _items[e]!['id'] as String),
        isTrue,
        reason: '$e row missing',
      );
    }
  });

  test('replaying the same page is idempotent', () async {
    await applyAll(_order);
    await applyAll(_order);
    for (final t in [
      'shops',
      'products',
      'stock',
      'sales',
      'sale_items',
      'sale_refunds',
      'inbound_transactions',
    ]) {
      expect(
        (await db.rawQuery('SELECT COUNT(*) AS n FROM $t')).single['n'],
        1,
        reason: t,
      );
    }
  });
}
