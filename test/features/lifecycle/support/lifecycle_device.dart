import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/catalog_support.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/images/image_uploader.dart';
import 'package:amana_pos/core/sync/images/pending_upload_store.dart';
import 'package:amana_pos/core/sync/decimal3.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_appliers.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/core/time/business_day.dart';
import 'package:amana_pos/features/category/domain/category_service.dart';
import 'package:amana_pos/features/dashboard/data/local/local_dashboard_queries.dart';
import 'package:amana_pos/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:amana_pos/features/inventory/data/local/stock_local_store.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/inventory/domain/vendor_service.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:amana_pos/features/products/domain/product_service.dart';
import 'package:amana_pos/features/sync/domain/catalog_conflict_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/sync/support/fake_sync_server.dart';

const kScope = 'u1|t1';
const kBiz = '99999999-9999-4999-8999-999999999999';
const kShop = '11111111-1111-4111-8111-111111111111';
const kTz = 'Africa/Khartoum';

/// Catalog shared by the server and every device's bootstrap.
class CatalogItem {
  const CatalogItem(this.id, this.name, this.price, this.base);
  final String id;
  final String name;
  final String price;

  /// Server stock at bootstrap.
  final String base;
}

const kCatalog = [
  CatalogItem('22222222-2222-4222-8222-000000000001', 'Tea', '2.50', '40'),
  CatalogItem('22222222-2222-4222-8222-000000000002', 'Sugar', '1.75', '12.5'),
  CatalogItem('22222222-2222-4222-8222-000000000003', 'Rice', '3.10', '3'),
  CatalogItem('22222222-2222-4222-8222-000000000004', 'Oil', '9.99', '0'),
];

/// A shared, mutable clock: device, engine and server all read it.
class Clock {
  Clock(this.t);
  DateTime t;
  DateTime now() => t;
  void advance(Duration d) => t = t.add(d);
}

/// One device running the REAL app stack on a real SQLite FILE: OfflineDb
/// schema, LocalWriter, OutboxStore, SyncStateStore, SyncEngine with the
/// production appliers, SaleService, StockService and the local dashboard.
/// [reopen] closes the file and rebuilds everything like a process relaunch.
class LifecycleDevice {
  LifecycleDevice._(this.name, this.path, this.deviceId, this.view, this.clock);

  final String name;
  final String path;
  final String deviceId;
  final FakeSyncServer view;
  final Clock clock;

  late OfflineDb odb;
  late Database db;
  late DbChangeNotifier notifier;
  late OutboxStore outbox;
  late SyncStateStore state;
  late LocalWriter writer;
  late SyncEngine engine;
  late SaleService sales;
  late StockService stock;
  late LocalDashboardQueries dashboard;

  // Phase 3 catalog stack (owner): services, staged images, the
  // foreground image uploader and the pending-sync conflict actions.
  late PendingUploadStore uploads;
  late CategoryService categories;
  late ProductService products;
  late VendorService vendors;
  late ImageUploader uploader;
  late CatalogConflictService conflicts;
  final _engines = <SyncEngine>[];
  int relaunches = 0;

  /// Engine hook name at which the current engine crashes next (once).
  String? crashAt;

  /// SaleService stage ('beforeCommit' / 'afterCommit') at which the next
  /// sale write crashes (once).
  String? saleCrashAt;

  static Future<LifecycleDevice> create({
    required String name,
    required Directory dir,
    required String deviceId,
    required FakeSyncServer view,
    required Clock clock,
  }) async {
    sqfliteFfiInit();
    final d = LifecycleDevice._(
      name,
      '${dir.path}/$name.db',
      deviceId,
      view,
      clock,
    );
    await d._open();
    await d.db.insert('sync_state', {
      'key': 'device_id',
      'value': deviceId,
      'updated_at': clock.now().toIso8601String(),
    });
    await d._bootstrap();
    return d;
  }

  Future<void> _open() async {
    final raw = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        singleInstance: false,
        version: OfflineDb.schemaVersion,
        onConfigure: OfflineDb.onConfigure,
        onCreate: OfflineDb.onCreate,
        onUpgrade: OfflineDb.onUpgrade,
      ),
    );
    odb = OfflineDb.forTesting(raw);
    db = raw;
    notifier = DbChangeNotifier();
    outbox = OutboxStore(odb, now: clock.now);
    state = SyncStateStore(odb, now: clock.now, scope: kScope);
    writer = LocalWriter(odb, outbox, notifier, scopeProvider: () => kScope);
    sales = SaleService(
      writer: writer,
      state: state,
      cashierId: () => null,
      now: clock.now,
      debugHook: (stage) async {
        if (saleCrashAt == stage) {
          saleCrashAt = null;
          throw CrashSimulation('sale $stage');
        }
      },
    );
    stock = StockService(
      writer: writer,
      actor: () => const StockActor(
        businessType: AppBusinessType.shop,
        role: AppUserRole.owner,
        shopId: kShop,
      ),
      now: clock.now,
    );
    dashboard = LocalDashboardQueries(
      db: odb,
      notifier: notifier,
      now: clock.now,
      tenantId: () => kBiz,
    );
    engine = SyncEngine(
      db: odb,
      transport: view,
      outbox: outbox,
      state: state,
      scopeProvider: () => kScope,
      readSessionKey: () async => kScope,
      reachability: ServerReachability(view, now: clock.now),
      // The signed-in scope, as in the app (CategoryApplier needs its
      // tenant to write a pulled category).
      appliers: buildSyncAppliers(scopeProvider: () => kScope),
      notifier: notifier,
      appVersion: '1.0.0',
      backoff: Backoff(random: Random(name.hashCode)),
      now: clock.now,
      hooks: SyncHooks(
        beforeResultWrite: (b, r) async => _maybeCrash('beforeResultWrite'),
        afterPushApplied: (b) async => _maybeCrash('afterPushApplied'),
        beforePullPageCommit: (p) async => _maybeCrash('beforePullPageCommit'),
      ),
    );
    _engines.add(engine);
    const owner = CatalogActor(
      businessType: AppBusinessType.shop,
      role: AppUserRole.owner,
    );
    uploads = PendingUploadStore(baseDir: () async => '$path.files');
    categories = CategoryService(
      writer: writer,
      actor: () => owner,
      uploads: uploads,
      now: clock.now,
    );
    products = ProductService(
      writer: writer,
      actor: () => owner,
      uploads: uploads,
      categories: categories,
      now: clock.now,
    );
    vendors = VendorService(writer: writer, actor: () => owner, now: clock.now);
    uploader = ImageUploader(
      db: odb,
      store: uploads,
      transport: view,
      notifier: notifier,
      scopeProvider: () => kScope,
      authedFor: engine.authedFor,
      now: clock.now,
    );
    conflicts = CatalogConflictService(
      db: odb,
      writer: writer,
      outbox: outbox,
      uploads: uploads,
      scope: () => kScope,
    );
  }

  void _maybeCrash(String where) {
    if (crashAt == where) {
      crashAt = null;
      throw CrashSimulation(where);
    }
  }

  /// What the legacy bootstrap leaves on the device: catalog, shop, server
  /// stock as base, and the pull cursor at the server head.
  Future<void> _bootstrap() async {
    await db.insert('shops', {
      'id': kShop,
      'business_id': kBiz,
      'json': jsonEncode({'id': kShop}),
    });
    for (final c in kCatalog) {
      await db.insert('products', {
        'id': c.id,
        'name': c.name,
        'stock_level': 0.0,
        'json': jsonEncode({'id': c.id, 'name': c.name, 'price': c.price}),
      });
      await const StockLocalStore().setBase(db, c.id, kShop, c.base);
    }
    // Bootstrapped device: cursor + `bootstrapped` (ruling T6-b).
    await db.transaction((t) async {
      await state.setCursor(
        t,
        base64Url.encode(utf8.encode('seq:${view.headSeq}')),
      );
      await state.setBootstrapped(t, true);
    });
  }

  /// Process killed and relaunched: in-memory state dropped, file reopened.
  Future<void> reopen() async {
    relaunches++;
    for (final e in _engines) {
      await e.dispose();
    }
    _engines.clear();
    notifier.dispose();
    await db.close();
    await _open();
  }

  Future<void> dispose() async {
    for (final e in _engines) {
      await e.dispose();
    }
    notifier.dispose();
    await db.close();
  }

  /// One sync attempt; a simulated crash relaunches the process after the
  /// lock / claim leases expired. Returns null on a crash.
  Future<SyncOutcome?> sync() async {
    try {
      return await engine.syncNow();
    } on CrashSimulation {
      clock.advance(const Duration(minutes: 10));
      await reopen();
      return null;
    }
  }

  // ------------------------------------------------------------ observation

  Future<List<Map<String, Object?>>> notDone() =>
      db.query('outbox', where: "status != 'done'", orderBy: 'seq');

  Future<int> rejectedCount() async => Sqflite.firstIntValue(
    await db.rawQuery("SELECT COUNT(*) FROM outbox WHERE status = 'rejected'"),
  )!;

  Future<bool> atHead() async {
    final c = await state.cursor();
    if (c == null) return false;
    final seq = int.parse(utf8.decode(base64Url.decode(c)).substring(4));
    return seq == view.headSeq;
  }

  /// Displayed stock, exactly: base + this device's open deltas, plus a
  /// check that the REAL column agrees with it.
  Future<BigInt> displayedUnits(String productId) async {
    final units = await const StockLocalStore().currentUnits(
      db,
      productId,
      kShop,
    );
    final row = (await db.query(
      'stock',
      where: 'product_id = ? AND shop_id = ?',
      whereArgs: [productId, kShop],
    )).single;
    final shown = (row['quantity'] as num).toDouble();
    if (shown != Decimal3.toDouble(units)) {
      throw StateError('$name stock.quantity $shown != exact $units');
    }
    return units;
  }

  Future<BigInt> baseUnits(String productId) async {
    final row = (await db.query(
      'stock',
      where: 'product_id = ? AND shop_id = ?',
      whereArgs: [productId, kShop],
    )).single;
    return Decimal3.parse(row['base_quantity'] as String);
  }

  /// id -> subtotal (= BE total_amount) of every local sale.
  Future<Map<String, String>> localSales() async => {
    for (final r in await db.query('sales'))
      r['id'] as String: r['subtotal'] as String,
  };

  /// First value of the live "today" dashboard stream (what Home renders).
  Future<DashboardSummary> todayDashboard() => dashboard
      .watchToday(shopId: kShop, timezone: kTz, businessId: kBiz)
      .first;

  Future<DashboardSummary> dayDashboard(BusinessDay day) => dashboard
      .watchDay(day: day, shopId: kShop, timezone: kTz, businessId: kBiz)
      .first;
}

// ------------------------------------------------------------------ money

/// Exact cents of a decimal string (at most 2 decimals).
BigInt cents(String v) {
  final s = v.trim();
  final neg = s.startsWith('-');
  final body = neg ? s.substring(1) : s;
  final parts = body.split('.');
  final frac = (parts.length > 1 ? parts[1] : '').padRight(2, '0');
  if (frac.length > 2) throw FormatException('more than 2 decimals: $v');
  final c =
      BigInt.parse(parts[0].isEmpty ? '0' : parts[0]) * BigInt.from(100) +
      BigInt.parse(frac);
  return neg ? -c : c;
}

/// Dashboard amounts are doubles of exact cents: back to exact cents.
BigInt dashCents(double v) => BigInt.from((v * 100).round());

/// Server-side Σ total_amount (exact cents) of sales reported on [day].
BigInt serverTotalFor(FakeSyncServer server, BusinessDay day) {
  var sum = BigInt.zero;
  for (final s in (server.tables['sale'] ?? const {}).values) {
    final at = DateTime.parse(s['created_at'] as String);
    if (BusinessDay.of(at, kTz) == day && s['status'] == 'completed') {
      sum += cents(s['total_amount'] as String);
    }
  }
  return sum;
}
