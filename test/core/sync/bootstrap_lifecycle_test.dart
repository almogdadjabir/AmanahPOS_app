// Phase 2 Task 8: lifecycle tests of the finished bootstrap machinery.
//
// Every device here is real: in-memory OfflineDb with the full schema, the
// production appliers (buildSyncAppliers), LocalWriter / OutboxStore /
// SyncStateStore / SyncEngine / Bootstrapper, SaleService / StockService,
// all sharing ONE strict FakeSyncServer through per-device views. A device
// "syncs" like SyncTriggers in the foreground app: engine -> needsBootstrap
// -> bootstrapper -> engine once more. A "relaunch" drops every in-memory
// object and rebuilds them on the same database.
import 'dart:convert';
import 'dart:math';

import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/appliers/category_applier.dart';
import 'package:amana_pos/core/sync/appliers/product_applier.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/decimal3.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_appliers.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'support/bootstrap_harness.dart';
import 'support/fake_sync_server.dart';
import 'support/test_db.dart';

const String _owner = 'u1|t1';
const String _tenant = 't1';

const List<String> kShops = [
  'e0000000-0000-4000-8000-000000000001',
  'e0000000-0000-4000-8000-000000000002',
];
const String kCategory = 'c0000000-0000-4000-8000-000000000001';
const String kVendor = 'd0000000-0000-4000-8000-000000000001';
const String kCustomer = 'b0000000-0000-4000-8000-000000000001';
final List<String> kProducts = [
  for (var i = 1; i <= 6; i++)
    'f0000000-0000-4000-8000-${'$i'.padLeft(12, '0')}',
];
const String _ts = '2026-11-16T06:00:00Z';

// ------------------------------------------------------------------ decimals

const int _scale = 6;
final BigInt _one = BigInt.from(10).pow(_scale);

BigInt dec(Object? raw) {
  var s = '${raw ?? '0'}'.trim();
  final neg = s.startsWith('-');
  if (neg || s.startsWith('+')) s = s.substring(1);
  final parts = s.split('.');
  final frac = (parts.length > 1 ? parts[1] : '').padRight(_scale, '0');
  final v =
      BigInt.parse(parts[0].isEmpty ? '0' : parts[0]) * _one +
      BigInt.parse(frac.substring(0, _scale));
  return neg ? -v : v;
}

String fmt(BigInt v) {
  final neg = v.isNegative;
  final a = v.abs();
  final whole = a ~/ _one;
  var frac = (a % _one).toString().padLeft(_scale, '0');
  frac = frac.replaceFirst(RegExp(r'0+$'), '');
  final body = frac.isEmpty ? '$whole' : '$whole.$frac';
  return neg && a != BigInt.zero ? '-$body' : body;
}

// ------------------------------------------------------------------ world

class World {
  DateTime clock = DateTime.utc(2026, 11, 16, 8);
  DateTime now() => clock;
  void advance(Duration d) => clock = clock.add(d);

  late final FakeSyncServer server = FakeSyncServer(deviceId: 'srv', now: now)
    ..strictCatalog = true
    ..capabilities = {'push', 'pull', 'bootstrap_paged'};

  /// Server stock right after seeding: `product|shop` -> quantity.
  final initialStock = <String, BigInt>{};

  Map<String, dynamic> productRow(String id, {int version = 1}) => {
    'id': id,
    'version': version,
    'shop': null,
    'category': kCategory,
    'name': 'Prod ${id.substring(id.length - 2)}',
    'description': '',
    'sku': 'SKU-$id',
    'barcode': 'BC-$id',
    'price': '2.50',
    'cost_price': '1.00',
    'image': null,
    'thumbnail_url': null,
    'image_hash': '',
    'unit': 'piece',
    'is_active': true,
    'track_inventory': true,
    'min_stock_level': 1,
    'expiry_alert_days': null,
    'updated_at': _ts,
  };

  /// BE-shaped catalog: 2 shops, 1 category, 6 products, 1 vendor, 1
  /// customer, stock for every product x shop.
  void seedCatalog() {
    for (final (i, s) in kShops.indexed) {
      server.seedRow('shop', {
        'id': s,
        'version': 1,
        'name': 'Shop ${i + 1}',
        'address': '',
        'phone': '',
        'is_main': i == 0,
        'is_active': true,
        'updated_at': _ts,
      });
    }
    server.seedRow('category', {
      'id': kCategory,
      'version': 1,
      'parent': null,
      'name': 'Drinks',
      'description': '',
      'image': null,
      'thumbnail_url': null,
      'image_hash': '',
      'sort_order': 0,
      'is_active': true,
      'updated_at': _ts,
    });
    for (final p in kProducts) {
      server.seedRow('product', productRow(p));
    }
    server.seedRow('vendor', {
      'id': kVendor,
      'version': 1,
      'name': 'Delta Supplies',
      'phone': '',
      'email': '',
      'address': '',
      'notes': '',
      'is_active': true,
      'updated_at': _ts,
    });
    server.seedRow('customer', {
      'id': kCustomer,
      'version': 1,
      'name': 'Amna',
      'phone': '',
      'email': '',
      'address': '',
      'notes': '',
      'loyalty_points': 0,
      'is_active': true,
      'updated_at': _ts,
    });
    var q = 40;
    for (final p in kProducts) {
      for (final s in kShops) {
        q += 7;
        final quantity = '$q.250';
        server.seedStock(p, s, quantity);
        initialStock['$p|$s'] = dec(quantity);
      }
    }
  }
}

// ------------------------------------------------------------------ device

class Dev {
  Dev(this.w, this.name, {this.pageSize = 2, this.scope = _owner});
  final World w;
  final String name;
  final int pageSize;

  /// Signed-in `userId|tenantId`; change it and [launch] to switch user.
  String scope;

  late OfflineDb odb;
  late Database db;
  late FakeSyncServer view;
  late BootTransport transport;
  final notifier = DbChangeNotifier();
  late ChangeApplierRegistry registry;
  late OutboxStore outbox;
  late SyncStateStore state;
  late LocalWriter writer;
  late SyncEngine engine;
  late Bootstrapper boot;
  late SaleService sales;
  late StockService stock;
  final _engines = <SyncEngine>[];
  final _boots = <Bootstrapper>[];
  int launches = 0;
  BootstrapOutcome? lastBoot;

  /// Sales this device created.
  final saleIds = <String>{};

  Future<void> init() async {
    odb = await openTestDb();
    db = await odb.database;
    view = w.server.forDevice(
      name,
      seed: name.codeUnits.fold(7, (a, b) => a + b),
    );
    transport = BootTransport(view);
    launch();
  }

  /// (Re)launch: every in-memory object is new, the database is the same.
  void launch() {
    launches++;
    registry = buildSyncAppliers(scopeProvider: () => scope);
    outbox = OutboxStore(odb, now: w.now);
    state = SyncStateStore(odb, now: w.now, scope: scope);
    writer = LocalWriter(odb, outbox, notifier, scopeProvider: () => scope);
    engine = SyncEngine(
      db: odb,
      transport: transport,
      outbox: outbox,
      state: state,
      scopeProvider: () => scope,
      reachability: ServerReachability(transport, now: w.now),
      appliers: registry,
      notifier: notifier,
      appVersion: '1.0.0',
      backoff: Backoff(random: Random(launches)),
      now: w.now,
    );
    _engines.add(engine);
    boot = Bootstrapper(
      db: odb,
      transport: transport,
      state: state,
      appliers: registry,
      notifier: notifier,
      scopeProvider: () => scope,
      assertScope: () async {},
      capabilities: () async => {...w.server.capabilities},
      authedFor: engine.authedFor,
      pageSize: pageSize,
      now: w.now,
    );
    _boots.add(boot);
    sales = SaleService(
      writer: writer,
      state: state,
      cashierId: () => null,
      now: w.now,
    );
    stock = StockService(
      writer: writer,
      actor: () => const StockActor(
        businessType: AppBusinessType.shop,
        role: AppUserRole.owner,
        shopId: null,
      ),
      now: w.now,
    );
  }

  Future<void> dispose() async {
    for (final b in _boots) {
      await b.dispose();
    }
    for (final e in _engines) {
      await e.dispose();
    }
    notifier.dispose();
    await db.close();
  }

  /// One foreground sync as SyncTriggers runs it.
  Future<SyncOutcome> sync() async {
    lastBoot = null;
    var o = await engine.syncNow();
    if (o == SyncOutcome.needsBootstrap) {
      final b = lastBoot = await boot.run();
      if (b == BootstrapOutcome.completed || b == BootstrapOutcome.notNeeded) {
        o = await engine.syncNow();
      }
    }
    return o;
  }

  /// Syncs (fault-free) until the outbox is drained, nothing is deferred
  /// and the cursor is at the server head.
  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      w.advance(const Duration(hours: 2)); // past row backoff and leases
      expect(await sync(), SyncOutcome.completed, reason: '$name settle');
      if ((await notDone()).isEmpty &&
          await state.deferredPullJson(db) == null &&
          await atHead()) {
        return;
      }
    }
    fail('$name did not settle');
  }

  Future<bool> atHead() async {
    final c = await state.cursor();
    if (c == null) return false;
    return int.parse(utf8.decode(base64Url.decode(c)).substring(4)) ==
        w.server.headSeq;
  }

  Future<List<Map<String, Object?>>> notDone() =>
      db.query('outbox', where: "status != 'done'", orderBy: 'seq');

  // ---------------------------------------------------------- local writes

  Future<String> sell(
    String shop,
    List<(String, String)> lines, {
    String? customer,
  }) async {
    final sale = await sales.createSale(
      SaleDraft(
        shopId: shop,
        paymentMethod: 'cash',
        customerId: customer,
        lines: [
          for (final (p, q) in lines)
            SaleDraftLine.product(
              productId: p,
              productName: 'P',
              quantity: q,
              unitPrice: '2.50',
            ),
        ],
      ),
    );
    saleIds.add(sale.id);
    return sale.id;
  }

  Future<String?> localQuantity(String p, String s) async {
    final r = await db.query(
      'stock',
      where: 'product_id = ? AND shop_id = ?',
      whereArgs: [p, s],
    );
    return r.isEmpty ? null : '${r.single['base_quantity']}';
  }

  Future<double?> displayed(String p, String s) async {
    final r = await db.query(
      'stock',
      where: 'product_id = ? AND shop_id = ?',
      whereArgs: [p, s],
    );
    return r.isEmpty ? null : (r.single['quantity'] as num).toDouble();
  }
}

// ------------------------------------------------------------------ checks

/// Server stock implied by the seed plus every mutation the devices ever
/// enqueued (the outbox is never pruned in these tests), decimal-exact.
Future<Map<String, BigInt>> expectedStock(World w, List<Dev> devices) async {
  final expected = {...w.initialStock};
  void add(String k, BigInt d) =>
      expected[k] = (expected[k] ?? BigInt.zero) + d;
  for (final d in devices) {
    for (final row in await d.db.query('outbox', orderBy: 'seq')) {
      final e = OutboxEntry.fromRow(row);
      final p = e.payload;
      switch (e.entity) {
        case 'stock':
          final d = dec(p['delta']);
          add(
            '${p['product_id']}|${p['shop_id']}',
            e.op == 'remove' ? -d.abs() : d,
          );
        case 'inbound':
          for (final it in p['items'] as List) {
            add('${it['product_id']}|${p['shop_id']}', dec(it['quantity']));
          }
        case 'sale':
          for (final it in p['items'] as List) {
            if (it['custom'] == true) continue;
            add('${it['product_id']}|${p['shop']}', -dec(it['quantity']));
          }
      }
    }
  }
  return expected;
}

/// Invariant (g): after bootstrap + pull a device's sales, money and stock
/// equal the server's truth (only [shops] are visible to it).
Future<void> expectMatchesServer(
  Dev d, {
  Set<String>? shops,
  bool checkOutbox = true,
}) async {
  final server = d.w.server;
  final visible = shops ?? kShops.toSet();
  if (checkOutbox) {
    expect(await d.notDone(), isEmpty, reason: '${d.name} outbox drained');
  }
  expect(await d.state.isBootstrapped(), isTrue, reason: d.name);
  expect(await d.state.bootstrapProgress(d.db), isNull, reason: d.name);
  expect(await d.state.deferredPullJson(d.db), isNull, reason: d.name);

  // Sales: same ids, each synced with the server's money and receipt; no
  // sale lost or duplicated; Σ net equal.
  final serverSales = {
    for (final e in (server.tables['sale'] ?? {}).entries)
      if (visible.contains(e.value['shop'])) e.key: e.value,
  };
  final local = {for (final r in await d.db.query('sales')) r['id']: r};
  expect(local.keys.toSet(), serverSales.keys.toSet(), reason: '${d.name} ids');
  var serverNet = BigInt.zero;
  var localNet = BigInt.zero;
  for (final ss in serverSales.values) {
    final ls = local[ss['id']]!;
    serverNet += dec(ss['net_amount']);
    localNet += dec(ls['net_amount']);
    expect(
      [
        dec(ls['subtotal']),
        dec(ls['net_amount']),
        ls['shop_id'],
        ls['receipt_number'],
        ls['sync_state'],
      ],
      [
        dec(ss['total_amount']),
        dec(ss['net_amount']),
        ss['shop'],
        ss['receipt_number'],
        'synced',
      ],
      reason: '${d.name} sale ${ss['id']}',
    );
    expect(
      (await d.db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [ss['id']],
      )).length,
      (ss['items'] as List).length,
      reason: '${d.name} sale ${ss['id']} lines',
    );
  }
  expect(fmt(localNet), fmt(serverNet), reason: '${d.name} Σ net');
  final feedSales = server.feed.where((c) => c.entity == 'sale').toList();
  expect(
    feedSales.map((c) => c.id).toSet().length,
    feedSales.length,
    reason: 'a sale was applied twice on the server',
  );

  // Stock: one row per visible (product, shop); base == displayed == server.
  final rows = await d.db.query('stock');
  expect(rows.length, kProducts.length * visible.length, reason: d.name);
  for (final r in rows) {
    final p = r['product_id'] as String;
    final s = r['shop_id'] as String;
    expect(visible, contains(s), reason: '${d.name} invisible shop stock');
    final q = dec(server.stockQuantity(p, s));
    expect(dec(r['base_quantity']), q, reason: '${d.name} base $p|$s');
    expect(
      (r['quantity'] as num).toDouble(),
      Decimal3.toDouble(Decimal3.parse(fmt(q))),
      reason: '${d.name} displayed $p|$s',
    );
    expect(r['id'], server.stockLevelId(p, s), reason: '${d.name} stock id');
  }

  // Catalog.
  final products = {
    for (final r in await d.db.query('products')) r['id']: r['version'],
  };
  expect(products, {
    for (final r in server.tables['product']!.values) r['id']: r['version'],
  }, reason: '${d.name} products');
}

Future<void> expectStockArithmetic(World w, List<Dev> devices) async {
  final expected = await expectedStock(w, devices);
  for (final p in kProducts) {
    for (final s in kShops) {
      expect(
        dec(w.server.stockQuantity(p, s)),
        expected['$p|$s'],
        reason: 'server stock $p|$s != seed + Σ deltas',
      );
    }
  }
}

void main() {
  late World w;
  final devs = <Dev>[];

  setUp(() {
    w = World();
    devs.clear();
  });
  tearDown(() async {
    for (final d in devs) {
      await d.dispose();
    }
  });

  Future<Dev> device(
    String name, {
    int pageSize = 2,
    String scope = _owner,
  }) async {
    final d = Dev(w, name, pageSize: pageSize, scope: scope);
    await d.init();
    devs.add(d);
    return d;
  }

  test('(a) journey: first login -> bootstrap cut offline at ~90% -> '
      'relaunch resumes from stored progress -> done -> offline day of '
      'sales -> reconnect converges with the server', () async {
    w.seedCatalog();
    final other = await device('w', pageSize: 500);
    expect(await other.sync(), SyncOutcome.completed);
    // History on the server before the first login.
    await other.sell(kShops[0], [(kProducts[0], '1.5'), (kProducts[1], '2')]);
    await other.sell(kShops[1], [(kProducts[2], '3')]);
    await other.settle();

    final d = await device('d');
    // A full run on a throwaway twin tells how many page requests a
    // complete bootstrap of this data needs.
    final twin = await device('twin');
    expect(await twin.sync(), SyncOutcome.completed);
    final total = twin.transport.pageRequests.length;
    expect(total, greaterThan(15));
    final cut = (total * 0.9).floor();

    var otherWrote = false;
    d.transport.beforePage = (n, entity) async {
      if (entity == 'product' && !otherWrote) {
        // After the snapshot: bootstrap pages never carry it, pull must.
        otherWrote = true;
        await other.sell(kShops[0], [(kProducts[0], '4')]);
        await other.settle();
      }
      if (n == cut) d.view.down = true; // network gone at ~90%
    };

    // First login: cut offline.
    expect(await d.sync(), SyncOutcome.needsBootstrap);
    expect(d.lastBoot, BootstrapOutcome.interrupted);
    expect(d.boot.current.offline, isTrue);
    final progress = (await d.state.bootstrapProgress(d.db))!;
    expect(progress.done, isNotEmpty);
    expect(await d.state.isBootstrapped(), isFalse);
    expect(await d.state.cursor(), isNull);
    final failed = d.transport.pageRequests.last;
    expect(d.transport.pageRequests, hasLength(cut));

    // Relaunch while still offline: nothing moves, nothing is lost.
    d.transport.beforePage = null;
    d.launch();
    w.advance(const Duration(minutes: 5));
    expect(await d.sync(), SyncOutcome.backoff);
    expect(await d.state.bootstrapProgress(d.db), isNotNull);
    expect(await d.state.isBootstrapped(), isFalse);

    // Back online: the NEW bootstrapper resumes at the stored page.
    d.view.down = false;
    w.advance(const Duration(minutes: 5));
    expect(await d.sync(), SyncOutcome.completed);
    expect(d.lastBoot, BootstrapOutcome.completed);
    expect(d.launches, 2);
    expect(d.transport.manifestCalls, 1, reason: 'ONE snapshot');
    final reqs = d.transport.pageRequests;
    expect(reqs[cut], failed, reason: 'resumes at the failed page');
    expect(
      {for (final r in reqs) '${r.$1}|${r.$2}'}.length,
      reqs.length - 1,
      reason: 'only the failed page is requested twice',
    );
    expect(reqs.length - 1, total, reason: 'nothing skipped');
    expect(otherWrote, isTrue);
    await d.settle();
    await expectMatchesServer(d);

    // An offline day: customer-less sales and stock deltas, never pushed.
    d.view.down = true;
    final before = await d.displayed(kProducts[0], kShops[0]);
    for (var i = 0; i < 5; i++) {
      w.advance(const Duration(hours: 1));
      await d.sell(kShops[0], [(kProducts[0], '1'), (kProducts[3], '0.5')]);
      expect(await d.sync(), SyncOutcome.backoff);
    }
    await d.stock.adjust(
      productId: kProducts[1],
      shopId: kShops[0],
      delta: '-1.5',
    );
    await d.stock.add(productId: kProducts[2], shopId: kShops[1], delta: '10');
    expect(await d.notDone(), hasLength(7));
    expect(
      await d.displayed(kProducts[0], kShops[0]),
      closeTo(before! - 5, 1e-9),
      reason: 'displayed = base + pending',
    );
    expect(
      (await d.db.query('sales', where: "sync_state = 'pending'")).length,
      5,
    );
    // The other device keeps selling online meanwhile.
    await other.sell(kShops[0], [(kProducts[0], '2')]);
    await other.settle();

    // Reconnect.
    d.view.down = false;
    await d.settle();
    await other.settle();
    for (final x in [d, other]) {
      await expectMatchesServer(x);
    }
    await expectStockArithmetic(w, [d, other, twin]);
    expect(w.server.tables['sale']!.keys.toSet(), {
      ...d.saleIds,
      ...other.saleIds,
    });
  });

  test('(b) device B bootstraps while device A keeps selling and adjusting '
      'stock between pages: both converge, stock == seed + Σ deltas, no sale '
      'lost or duplicated', () async {
    w.seedCatalog();
    final a = await device('a', pageSize: 500);
    expect(await a.sync(), SyncOutcome.completed);
    final b = await device('b', pageSize: 2);
    final r = Random(8);
    var writes = 0;
    Future<void> aWrites() async {
      final p = kProducts[r.nextInt(kProducts.length)];
      final s = kShops[r.nextInt(kShops.length)];
      switch (r.nextInt(4)) {
        case 0:
          await a.stock.adjust(productId: p, shopId: s, delta: '-0.75');
        case 1:
          await a.stock.receiveInbound(
            CreateInboundRequestDto(
              shopId: s,
              reference: 'PO-${writes + 1}',
              vendorId: kVendor,
              items: [CreateInboundItemRequestDto(productId: p, quantity: '6')],
            ),
          );
        default:
          await a.sell(s, [(p, '1.25'), (kProducts[0], '1')]);
      }
      writes++;
      w.advance(const Duration(minutes: 1));
      expect(await a.sync(), SyncOutcome.completed);
    }

    b.transport.beforePage = (n, entity) => aWrites();
    expect(await b.sync(), SyncOutcome.completed);
    expect(b.lastBoot, BootstrapOutcome.completed);
    expect(writes, b.transport.pageRequests.length);
    expect(writes, greaterThan(15));
    b.transport.beforePage = null;

    // B sells too, then both settle.
    await b.sell(kShops[1], [(kProducts[5], '2')]);
    await b.settle();
    await a.settle();
    await b.settle();
    for (final x in [a, b]) {
      await expectMatchesServer(x);
    }
    await expectStockArithmetic(w, [a, b]);
    expect(w.server.tables['sale']!.keys.toSet(), {...a.saleIds, ...b.saleIds});
  });

  test(
    '(c) cashier scope: the manifest lacks vendor/inbound and serves only '
    'its shop; only listed entities are requested and only its shop lands',
    () async {
      w.seedCatalog();
      // The owner leaves history in both shops (sales, inbound).
      final owner = await device('owner', pageSize: 500);
      expect(await owner.sync(), SyncOutcome.completed);
      await owner.sell(kShops[0], [(kProducts[0], '1')]);
      await owner.sell(kShops[1], [(kProducts[1], '2')]);
      for (final s in kShops) {
        await owner.stock.receiveInbound(
          CreateInboundRequestDto(
            shopId: s,
            reference: 'PO-$s',
            vendorId: kVendor,
            items: [
              CreateInboundItemRequestDto(
                productId: kProducts[2],
                quantity: '3',
              ),
            ],
          ),
        );
      }
      await owner.settle();

      final listed = [
        for (final e in Bootstrapper.entityOrder)
          if (e != 'vendor' && e != 'inbound') e,
      ];
      w.server
        ..bootstrapEntities = listed
        ..bootstrapShops = {kShops[0]};
      final cashier = await device('cashier', scope: 'u2|$_tenant');
      expect(await cashier.sync(), SyncOutcome.completed);
      expect(cashier.lastBoot, BootstrapOutcome.completed);

      final requested = cashier.transport.requestedEntities;
      expect(requested, isNot(contains('vendor')));
      expect(requested, isNot(contains('inbound')));
      expect(requested.every(listed.contains), isTrue);
      expect(requested, [
        for (final e in Bootstrapper.entityOrder)
          if (listed.contains(e)) e,
      ], reason: 'client order, each entity once');
      expect(
        [for (final r in await cashier.db.query('shops')) r['id']],
        [kShops[0]],
      );
      expect(await cashier.db.query('vendors'), isEmpty);
      expect(await cashier.db.query('inbound_transactions'), isEmpty);
      await expectMatchesServer(cashier, shops: {kShops[0]});
    },
  );

  test(
    '(e) tombstone: a product deleted via pull and returned INACTIVE by a '
    'later bootstrap comes back inactive (hidden from POS), never active',
    () async {
      w.seedCatalog();
      final d = await device('d', pageSize: 3);
      expect(await d.sync(), SyncOutcome.completed);
      final px = kProducts[4];
      expect(
        await d.db.query('products', where: 'id = ?', whereArgs: [px]),
        hasLength(1),
      );

      // Server: the product is deleted (feed `delete`, version 2) ...
      final res = await w.server
          .forDevice('admin')
          .push(
            deviceId: 'admin',
            appVersion: '1.0.0',
            mutations: [
              OutboxEntry(
                seq: 1,
                mutationId: 'del-$px',
                entity: 'product',
                op: 'delete',
                entityId: px,
                occurredAt: w.clock,
                payload: const {},
              ),
            ],
            scope: _owner,
          );
      expect(res.results.single.status, PushStatus.applied);
      expect(res.results.single.version, 2);
      // ... but the BE keeps the soft-deleted row, which a bootstrap serves.
      w.server.tables['product']![px] = {
        ...w.productRow(px, version: 2),
        'is_active': false,
      };

      await d.settle();
      expect(
        await d.db.query('products', where: 'id = ?', whereArgs: [px]),
        isEmpty,
        reason: 'the pulled delete removed it',
      );

      // Later the server asks for a full resync: a new bootstrap.
      w.advance(const Duration(minutes: 30));
      d.view.fullResyncOnce = true;
      expect(await d.sync(), SyncOutcome.completed);
      expect(d.lastBoot, BootstrapOutcome.completed);
      expect(d.transport.manifestCalls, 2);

      final row = (await d.db.query(
        'products',
        where: 'id = ?',
        whereArgs: [px],
      )).single;
      expect(row['version'], 2);
      final listed = await OfflineLocalCache(d.odb).getProducts();
      final p = listed.singleWhere((x) => x.id == px);
      expect(p.isActive, isFalse, reason: 'never resurfaces active');
      expect(listed.where((x) => x.isActive != false), hasLength(5));

      // Stable: further syncs keep it inactive.
      await d.settle();
      expect(
        (await OfflineLocalCache(
          d.odb,
        ).getProducts()).singleWhere((x) => x.id == px).isActive,
        isFalse,
      );
      await expectMatchesServer(d);
    },
  );

  test('Task 7 M4: another user of the same device bootstraps while user A '
      'has a pushed-but-unanswered sale; the row is shown synced in B '
      'session, A then gets `duplicate` and everything converges', () async {
    w.seedCatalog();
    final d = await device('d', pageSize: 4);
    expect(await d.sync(), SyncOutcome.completed);
    final sale = await d.sell(kShops[0], [(kProducts[0], '2')]);
    d.view.dropResponseAfterApply = 1; // applied, response lost
    expect(await d.sync(), isNot(SyncOutcome.completed));
    expect(w.server.tables['sale']!.containsKey(sale), isTrue);
    expect((await d.notDone()).single['entity_id'], sale);

    // User B (same tenant) signs in on the same device: own scope, no
    // pending outbox of its own, so the bootstrap writes the server row.
    d.scope = 'u2|$_tenant';
    d.launch();
    expect(await d.sync(), SyncOutcome.completed);
    final row = (await d.db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [sale],
    )).single;
    expect(row['sync_state'], 'synced', reason: 'actual (M4) behavior');
    expect((await d.notDone()).single['entity_id'], sale);

    // User A back: the replay answers duplicate; local == server.
    d.scope = _owner;
    d.launch();
    w.advance(const Duration(hours: 2));
    await d.settle();
    await expectMatchesServer(d);
    await expectStockArithmetic(w, [d]);
  });

  test('(f) perf: 20k products bootstrap in 40 pages of 500, ONE '
      'transaction per page', () async {
    final products = TxnCountingApplier(ProductApplier());
    final h = await BootHarness.create(
      registry: (h) => ChangeApplierRegistry()
        ..register(CategoryApplier(scopeProvider: () => h.activeScope))
        ..register(products),
    );
    addTearDown(h.dispose);
    h.server.bootstrapEntities = ['category', 'product'];
    h.seedCategory('c1');
    // Straight into the server table (no feed rows): the fake's snapshot
    // filter stays O(1) per row.
    final table = h.server.tables.putIfAbsent('product', () => {});
    for (var i = 0; i < 20000; i++) {
      final id = 'p${'$i'.padLeft(6, '0')}';
      table[id] = h.productRow(id);
    }

    final sw = Stopwatch()..start();
    expect(await h.build(pageSize: 500).run(), BootstrapOutcome.completed);
    sw.stop();
    // ignore: avoid_print
    print('20k products bootstrap: ${sw.elapsedMilliseconds} ms');

    final pages = h.transport.pageRequests.where((r) => r.$1 == 'product');
    expect(pages, hasLength(40));
    expect(pages.every((r) => r.$3 == 500), isTrue);
    expect(products.perTxn, hasLength(40), reason: 'one txn per page');
    expect(products.perTxn.values.every((n) => n == 500), isTrue);
    expect(
      Sqflite.firstIntValue(
        await h.db.rawQuery('SELECT COUNT(*) FROM products'),
      ),
      20000,
    );
    expect(await h.scoped.isBootstrapped(), isTrue);
    expect(sw.elapsed, lessThan(const Duration(seconds: 90)));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
