// Multi-device convergence property test (Task 11, extended in Phase 1
// Task 12).
//
// For every seed: N devices, each with its OWN in-memory OfflineDb, real
// LocalWriter / OutboxStore / SyncStateStore / SyncEngine, all sharing ONE
// FakeSyncServer (strict catalog, BE semantics) through forDevice views.
// Sales, stock edits and inbound receipts go through the REAL SaleService /
// StockService and the production SaleApplier / StockApplier /
// InboundApplier (wrapped by a spy that enforces "stock is re-based from
// stock_after on `applied` only, never on `duplicate`"); product renames
// and customer creates use small test appliers. Devices perform random
// offline writes, then sync in random order under
// random per-view faults (flaky, lost responses, dropped response after
// apply, device down) and simulated crashes (SyncHooks + restart on the same
// DB). Finally faults are cleared and devices sync until a fixed point, then
// the money / stock / convergence invariants are checked.
//
// Re-run one seed (prints its action log on failure):
//   flutter test test/core/sync/convergence_test.dart --dart-define=CONV_SEED=17
// Other knobs: CONV_SEEDS (count, default 60), CONV_FIRST (first seed),
// CONV_DEVICES (default 3), CONV_FAULTS / CONV_CRASHES (default true),
// CONV_MIN_ACTIONS / CONV_MAX_ACTIONS (default 20 / 60), CONV_VERBOSE.
//
// Phase 2 Task 8: every device also has a real Bootstrapper (paged, page
// size 3) run like SyncTriggers does (engine -> needsBootstrap ->
// bootstrapper -> engine once more). Two extra generator actions: a device
// "cold-starts" (its cursor, `bootstrapped`, bootstrap progress and
// completion time are wiped, local rows and outbox kept, with or without
// unsynced outbox rows) and the server answers `full_resync_required` once
// to one device. A bootstrap can be interrupted by the same faults
// (offline, flaky) and by a simulated crash at a page boundary, and must
// resume later from its stored progress.
import 'dart:convert';
import 'dart:math';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/permissions/app_permissions.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/appliers/inbound_applier.dart';
import 'package:amana_pos/core/sync/appliers/sale_applier.dart';
import 'package:amana_pos/core/sync/appliers/stock_applier.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/decimal3.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/features/inventory/data/models/requests/create_inbound_request_dto.dart';
import 'package:amana_pos/features/inventory/domain/stock_service.dart';
import 'package:amana_pos/features/pos/domain/sale_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';
import 'package:uuid/uuid.dart';

import 'support/fake_sync_server.dart';

// Default 60 seeds (~40 s) keeps `flutter test` reasonable. Full run before releases:
//   flutter test test/core/sync/convergence_test.dart --dart-define=CONV_SEEDS=200
const int kSeeds = int.fromEnvironment('CONV_SEEDS', defaultValue: 60);
const int kFirstSeed = int.fromEnvironment('CONV_FIRST', defaultValue: 0);
const int kOnlySeed = int.fromEnvironment('CONV_SEED', defaultValue: -1);
const int kDevices = int.fromEnvironment('CONV_DEVICES', defaultValue: 3);
const bool kFaults = bool.fromEnvironment('CONV_FAULTS', defaultValue: true);
const bool kCrashes = bool.fromEnvironment('CONV_CRASHES', defaultValue: true);
const int kMinActions = int.fromEnvironment(
  'CONV_MIN_ACTIONS',
  defaultValue: 20,
);
const int kMaxActions = int.fromEnvironment(
  'CONV_MAX_ACTIONS',
  defaultValue: 60,
);
const bool kVerbose = bool.fromEnvironment('CONV_VERBOSE');

/// Hard cap on fault-free rounds before declaring a device wedged.
const int kMaxFixedPointRounds = 25;
const String _scope = 'u1|t1';

// UUIDs: the strict fake (like the BE) refuses anything else.
const List<String> kProducts = [
  'f0000000-0000-4000-8000-000000000001',
  'f0000000-0000-4000-8000-000000000002',
  'f0000000-0000-4000-8000-000000000003',
  'f0000000-0000-4000-8000-000000000004',
];
const List<String> kShops = [
  'e0000000-0000-4000-8000-000000000001',
  'e0000000-0000-4000-8000-000000000002',
];
const String kVendor = 'd0000000-0000-4000-8000-000000000001';
const List<String> kPrices = ['2.50', '1.75', '0.99', '12.00'];

String _short(String id) => id.substring(id.length - 4);

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

/// Random positive decimal with up to 3 fraction digits, as a string.
String randDec(Random r, int maxWhole) {
  final milli = r.nextInt(maxWhole * 1000) + 1;
  return fmt(BigInt.from(milli) * BigInt.from(1000));
}

// ------------------------------------------------------------------ appliers

abstract class _RowApplier implements ChangeApplier {
  _RowApplier(this.entity, this.table);

  @override
  final String entity;
  final String table;

  @override
  Set<String> get tables => {table};

  @override
  bool get skipWhenLocalPending => true;

  Map<String, Object?> rowFrom(PullChange change);

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) async {
    final r = await txn.query(
      table,
      columns: ['version'],
      where: 'id = ?',
      whereArgs: [change.id],
    );
    return r.isEmpty ? null : r.single['version'] as int?;
  }

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    if (change.op == 'delete') {
      await txn.delete(table, where: 'id = ?', whereArgs: [change.id]);
      return;
    }
    await txn.insert(table, {
      'id': change.id,
      ...rowFrom(change),
      'version': change.version,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {
    _bump(
      'push_${entity}_${result.status.name}${result.merged ? '_merged' : ''}',
    );
    if (result.status == PushStatus.rejected) return;
    await txn.update(
      table,
      {
        'version': result.version,
        if (result.merged && result.serverState != null)
          ...rowFrom(
            PullChange(
              seq: 0,
              entity: entity,
              op: 'upsert',
              id: sent.entityId,
              data: result.serverState,
            ),
          ),
      },
      where: 'id = ?',
      whereArgs: [sent.entityId],
    );
  }
}

class ProductApplier extends _RowApplier {
  ProductApplier() : super('product', 'c_products');
  @override
  Map<String, Object?> rowFrom(PullChange c) => {'name': c.data?['name']};
}

class CustomerApplier extends _RowApplier {
  CustomerApplier() : super('customer', 'c_customers');
  @override
  Map<String, Object?> rowFrom(PullChange c) => {'name': c.data?['name']};
}

/// Wraps a production applier. On every push result it checks the re-base
/// rule: `applied` -> each `stock_after` entry is now the local base;
/// `duplicate` (a replay whose stock_after is stale) -> no base changed.
class SpyApplier implements ChangeApplier {
  SpyApplier(this.inner);
  final ChangeApplier inner;

  @override
  String get entity => inner.entity;
  @override
  Set<String> get tables => inner.tables;
  @override
  bool get skipWhenLocalPending => inner.skipWhenLocalPending;
  @override
  Future<int?> localVersion(Transaction txn, PullChange change) =>
      inner.localVersion(txn, change);
  @override
  Future<void> apply(Transaction txn, PullChange change) =>
      inner.apply(txn, change);

  static Future<Map<String, String>> _bases(Transaction txn) async => {
    for (final r in await txn.query('stock'))
      '${r['product_id']}|${r['shop_id']}': '${r['base_quantity']}',
  };

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {
    _bump('push_${entity}_${result.status.name}');
    final before = await _bases(txn);
    await inner.onPushResult(txn, sent, result);
    final after = await _bases(txn);
    switch (result.status) {
      case PushStatus.applied:
        if (result.stockAfter.isNotEmpty) _bump('rebase_${entity}_applied');
        for (final a in result.stockAfter) {
          expect(
            Decimal3.parse(after['${a.productId}|${a.shopId}']!),
            Decimal3.parse(a.quantity),
            reason: 'applied ${sent.mutationId}: base not re-based',
          );
        }
      case PushStatus.duplicate:
        if (result.stockAfter.isNotEmpty) _bump('dup_with_stock_after');
        expect(
          after,
          before,
          reason: 'duplicate ${sent.mutationId} re-based stock',
        );
      case PushStatus.rejected:
      case PushStatus.retry:
        break;
    }
  }
}

// ------------------------------------------------------------------ world

/// Coverage counters across all seeds (printed at the end).
final Map<String, int> stats = {};
void _bump(String k) => stats[k] = (stats[k] ?? 0) + 1;

class World {
  World(this.seed) : rnd = Random(seed);
  final int seed;
  final Random rnd;
  final log = <String>[];
  DateTime clock = DateTime.utc(2026, 1, 1, 12);
  DateTime now() => clock;
  void advance(Duration d) => clock = clock.add(d);
  void note(String s) {
    log.add(s);
    // ignore: avoid_print
    if (kVerbose) print('[$seed] $s');
  }

  late FakeSyncServer server;
}

/// The real OfflineDb schema (onCreate), captured once from a template DB and
/// replayed as one script per device: same tables and indexes, ~10x faster
/// than running onCreate for every device of every seed.
String? _schemaDdl;

Future<String> _schema() async {
  final cached = _schemaDdl;
  if (cached != null) return cached;
  final t = await databaseFactoryFfiNoIsolate.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      singleInstance: false,
      version: OfflineDb.schemaVersion,
      onConfigure: OfflineDb.onConfigure,
      onCreate: OfflineDb.onCreate,
    ),
  );
  final rows = await t.rawQuery(
    'SELECT sql FROM sqlite_master WHERE sql IS NOT NULL '
    "AND name NOT LIKE 'sqlite_%' ORDER BY rowid",
  );
  await t.close();
  return _schemaDdl = rows.map((r) => '${r['sql']};').join('\n');
}

Future<OfflineDb> _openDb() async {
  final ddl = await _schema();
  final db = await databaseFactoryFfiNoIsolate.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      singleInstance: false,
      onConfigure: OfflineDb.onConfigure,
    ),
  );
  await db.execute(ddl);
  await db.execute('PRAGMA user_version = ${OfflineDb.schemaVersion}');
  await db.execute(
    'CREATE TABLE c_products (id TEXT PRIMARY KEY, name TEXT, version INTEGER)',
  );
  await db.execute(
    'CREATE TABLE c_customers (id TEXT PRIMARY KEY, name TEXT, '
    'version INTEGER)',
  );
  return OfflineDb.forTesting(db);
}

class Device {
  Device(this.w, this.name);
  final World w;
  final String name;

  late OfflineDb odb;
  late Database db;
  late FakeSyncServer view;
  late OutboxStore outbox;
  late SyncStateStore state;
  late LocalWriter writer;
  final notifier = DbChangeNotifier();
  final registry = ChangeApplierRegistry();
  late SyncEngine engine;
  late Bootstrapper boot;
  final engines = <SyncEngine>[];
  final boots = <Bootstrapper>[];

  /// Hook name at which the current engine crashes next (once).
  String? crashAt;
  int restarts = 0;
  int counter = 0;

  /// Every sale this device created: id -> subtotal (= BE total_amount).
  final sales = <String, String>{};
  final customers = <String>{};
  late Uuid uuid;
  late SaleService saleService;
  late StockService stockService;

  Future<void> init() async {
    odb = await _openDb();
    db = await odb.database;
    view = w.server.forDevice(name, seed: w.rnd.nextInt(1 << 30));
    // Reproducible ids per seed (sale/line/stock/inbound/device ids).
    uuid = Uuid(goptions: GlobalOptions(MathRNG(seed: w.rnd.nextInt(1 << 30))));
    await db.insert('sync_state', {
      'key': 'device_id',
      'value': uuid.v4(),
      'updated_at': w.clock.toIso8601String(),
    });
    registry
      ..register(ProductApplier())
      ..register(CustomerApplier())
      ..register(SpyApplier(StockApplier()))
      ..register(SpyApplier(SaleApplier()))
      ..register(SpyApplier(InboundApplier()));
    _rebuild();
    // Bootstrapped device: cursor + `bootstrapped` (ruling T6-b).
    await db.transaction((t) async {
      await state.setCursor(t, base64Url.encode(utf8.encode('seq:0')));
      await state.setBootstrapped(t, true);
    });
  }

  void _rebuild() {
    outbox = OutboxStore(odb, now: w.now);
    state = SyncStateStore(odb, now: w.now, scope: _scope);
    writer = LocalWriter(odb, outbox, notifier, scopeProvider: () => _scope);
    saleService = SaleService(
      writer: writer,
      state: state,
      cashierId: () => null,
      now: w.now,
      uuid: uuid,
    );
    stockService = StockService(
      writer: writer,
      actor: () => const StockActor(
        businessType: AppBusinessType.shop,
        role: AppUserRole.owner,
        shopId: null,
      ),
      now: w.now,
      uuid: uuid,
    );
    engine = SyncEngine(
      db: odb,
      transport: view,
      outbox: outbox,
      state: state,
      scopeProvider: () => _scope,
      reachability: ServerReachability(view, now: w.now),
      appliers: registry,
      notifier: notifier,
      appVersion: '1.0.0',
      backoff: Backoff(random: Random(w.rnd.nextInt(1 << 30))),
      now: w.now,
      hooks: SyncHooks(
        beforeResultWrite: (b, r) async => _maybeCrash('beforeResultWrite'),
        afterPushApplied: (b) async => _maybeCrash('afterPushApplied'),
        beforePullPageCommit: (p) async => _maybeCrash('beforePullPageCommit'),
      ),
    );
    engines.add(engine);
    boot = Bootstrapper(
      db: odb,
      transport: view,
      state: state,
      appliers: registry,
      notifier: notifier,
      scopeProvider: () => _scope,
      // Called before every page request and inside every page txn: a
      // crash here is a kill at a bootstrap page boundary / mid-page.
      assertScope: () async => _maybeCrash('bootstrapPage'),
      capabilities: () async => {...w.server.capabilities},
      authedFor: engine.authedFor,
      pageSize: 3,
      now: w.now,
      uuid: uuid,
    );
    boots.add(boot);
  }

  void _maybeCrash(String where) {
    if (crashAt == where) {
      crashAt = null;
      throw CrashSimulation(where);
    }
  }

  /// Process restart on the same DB.
  void restart() {
    restarts++;
    _rebuild();
  }

  Future<void> dispose() async {
    for (final e in engines) {
      await e.dispose();
    }
    for (final b in boots) {
      await b.dispose();
    }
    notifier.dispose();
    await db.close();
  }

  // ---------------------------------------------------------- local writes

  Future<OutboxEntry> rename(String p, String name) => writer.write(
    tables: {'c_products'},
    body: (scope) async {
      final r = await scope.txn.query(
        'c_products',
        where: 'id = ?',
        whereArgs: [p],
      );
      final base = r.isEmpty ? null : r.single['version'] as int?;
      await scope.txn.update(
        'c_products',
        {'name': name},
        where: 'id = ?',
        whereArgs: [p],
      );
      return scope.enqueue(
        entity: 'product',
        op: 'update',
        entityId: p,
        payload: {'name': name},
        baseVersion: base,
        occurredAt: w.clock,
      );
    },
  );

  Future<OutboxEntry> createCustomer(String id, String name) => writer.write(
    tables: {'c_customers'},
    body: (scope) async {
      await scope.txn.insert('c_customers', {
        'id': id,
        'name': name,
        'version': null,
      });
      return scope.enqueue(
        entity: 'customer',
        op: 'create',
        entityId: id,
        payload: {'name': name},
        occurredAt: w.clock,
      );
    },
  );

  /// One random offline action.
  Future<void> randomAction() async {
    final r = w.rnd;
    final k = r.nextInt(100);
    counter++;
    if (k < 35) {
      final p = kProducts[r.nextInt(kProducts.length)];
      final s = kShops[r.nextInt(kShops.length)];
      final d = randDec(r, 20);
      final op = const ['add', 'remove', 'adjust'][r.nextInt(3)];
      final delta = op == 'adjust' && r.nextBool() ? '-$d' : d;
      w.note('$name stock.$op ${_short(p)}:${_short(s)} $delta');
      await switch (op) {
        'add' => stockService.add(productId: p, shopId: s, delta: delta),
        'remove' => stockService.remove(productId: p, shopId: s, delta: delta),
        _ => stockService.adjust(productId: p, shopId: s, delta: delta),
      };
    } else if (k < 65) {
      final shop = kShops[r.nextInt(kShops.length)];
      final n = r.nextInt(3) + 1;
      final lines = <SaleDraftLine>[
        for (var i = 0; i < n; i++)
          SaleDraftLine.product(
            productId: kProducts[r.nextInt(kProducts.length)],
            productName: 'P',
            quantity: randDec(r, 5),
            unitPrice: kPrices[r.nextInt(kPrices.length)],
          ),
        if (r.nextInt(4) == 0)
          const SaleDraftLine.custom(name: 'Keypad', unitPrice: '4.20'),
      ];
      final cust = customers.isNotEmpty && r.nextInt(3) == 0
          ? customers.elementAt(r.nextInt(customers.length))
          : null;
      final sale = await saleService.createSale(
        SaleDraft(
          shopId: shop,
          paymentMethod: r.nextBool() ? 'cash' : 'card',
          lines: lines,
          customerId: cust,
        ),
      );
      sales[sale.id] = sale.subtotal;
      w.note(
        '$name sale ${_short(sale.id)} ${_short(shop)} '
        'total=${sale.subtotal} cust=$cust '
        '${lines.map((l) => '${l.isCustom ? 'custom' : _short(l.productId!)}x${l.quantity}').join(',')}',
      );
    } else if (k < 72) {
      final shop = kShops[r.nextInt(kShops.length)];
      final p = kProducts[r.nextInt(kProducts.length)];
      final q = randDec(r, 30);
      w.note('$name inbound ${_short(p)}:${_short(shop)} +$q');
      await stockService.receiveInbound(
        CreateInboundRequestDto(
          shopId: shop,
          reference: '$name-PO-$counter',
          vendorId: kVendor,
          items: [CreateInboundItemRequestDto(productId: p, quantity: q)],
        ),
      );
    } else if (k < 88) {
      final p = kProducts[r.nextInt(kProducts.length)];
      final nm = '$name-n$counter';
      w.note('$name rename ${_short(p)} -> $nm');
      await rename(p, nm);
    } else {
      final id = uuid.v4();
      customers.add(id);
      w.note('$name customer ${_short(id)}');
      await createCustomer(id, 'Cust $id');
    }
  }

  // ---------------------------------------------------------- sync

  void clearFaults() {
    view
      ..down = false
      ..flakyRate = 0
      ..lostResponseRate = 0
      ..dropResponseAfterApply = 0
      ..fullResyncOnce = false;
    crashAt = null;
  }

  /// Cold start: this scope's setup state is gone (cursor, `bootstrapped`,
  /// progress, completion time), like after the logout/business-switch
  /// reset; local rows and the outbox (unsynced work) are kept.
  Future<void> coldStart() async {
    final pending = (await notDone()).length;
    _bump(pending > 0 ? 'coldstart_with_pending' : 'coldstart_clean');
    w.note('$name COLD START (pending outbox=$pending)');
    await db.transaction(SyncStateStore.resetSetupOfAllScopes);
  }

  void randomFaults() {
    final r = w.rnd;
    clearFaults();
    if (!kFaults) return;
    if (r.nextInt(10) == 0) view.down = true;
    if (r.nextBool()) view.flakyRate = r.nextDouble() * 0.5;
    if (r.nextBool()) view.lostResponseRate = r.nextDouble() * 0.5;
    if (r.nextInt(4) == 0) view.dropResponseAfterApply = 1;
    if (r.nextInt(8) == 0) {
      view.fullResyncOnce = true;
      _bump('fault_full_resync_once');
    }
    if (kCrashes && r.nextInt(4) == 0) {
      crashAt = const [
        'beforeResultWrite',
        'afterPushApplied',
        'beforePullPageCommit',
        'bootstrapPage',
      ][r.nextInt(4)];
    }
  }

  String get faultString =>
      '${view.down ? 'down ' : ''}'
      'flaky=${view.flakyRate.toStringAsFixed(2)} '
      'lost=${view.lostResponseRate.toStringAsFixed(2)} '
      'drop=${view.dropResponseAfterApply} '
      '${view.fullResyncOnce ? 'resync ' : ''}crash=$crashAt';

  /// Runs one sync; a simulated crash restarts the "process" on the same DB
  /// after the lock / claim leases expired.
  Future<SyncOutcome?> sync() async {
    final faults = faultString;
    try {
      var o = await engine.syncNow();
      if (o == SyncOutcome.needsBootstrap) {
        // What SyncTriggers does in the foreground app.
        if (await state.bootstrapProgress(db) != null) {
          _bump('bootstrap_resume');
        }
        final guarded = await _pendingRows();
        final b = await boot.run();
        _bump('bootstrap_${b.name}');
        // Review focus 4: a bootstrap never overwrites a row that has an
        // unsynced outbox edit (it is deferred to a later pull instead).
        expect(
          await _pendingRows(keys: guarded.keys),
          guarded,
          reason: '$name bootstrap overwrote a locally pending row',
        );
        if (guarded.isNotEmpty) _bump('bootstrap_guarded_pending_rows');
        w.note('$name bootstrap [$faults] -> ${b.name}');
        if (b == BootstrapOutcome.completed ||
            b == BootstrapOutcome.notNeeded) {
          o = await engine.syncNow();
        }
      }
      _bump('sync_${o.name}');
      if (await deferred() != null) _bump('deferred_pull_left_after_sync');
      w.note('$name sync [$faults] -> ${o.name} ${engine.current}');
      return o;
    } on CrashSimulation catch (c) {
      _bump('crash_${c.where}');
      w.note('$name sync [$faults] -> CRASH ${c.where}; restart');
      w.advance(const Duration(minutes: 10));
      restart();
      return null;
    }
  }

  // ---------------------------------------------------------- observation

  static const _pendingTables = {
    'product': 'c_products',
    'customer': 'c_customers',
    'sale': 'sales',
  };

  /// Local rows of entities that have a not-done outbox row (or of [keys]).
  Future<Map<String, String>> _pendingRows({Iterable<String>? keys}) async {
    final want =
        keys?.toList() ??
        [
          for (final o in await notDone())
            if (_pendingTables.containsKey(o['entity']))
              '${o['entity']}/${o['entity_id']}',
        ];
    final out = <String, String>{};
    for (final k in want) {
      final i = k.indexOf('/');
      final rows = await db.query(
        _pendingTables[k.substring(0, i)]!,
        where: 'id = ?',
        whereArgs: [k.substring(i + 1)],
      );
      out[k] = jsonEncode(rows);
    }
    return out;
  }

  Future<List<Map<String, Object?>>> notDone() =>
      db.query('outbox', where: "status != 'done'", orderBy: 'seq');

  Future<bool> atHead() async {
    final c = await state.cursor();
    final seq = c == null
        ? -1
        : int.parse(utf8.decode(base64Url.decode(c)).substring(4));
    return seq == w.server.headSeq;
  }

  Future<String?> deferred() => state.deferredPullJson(db);
}

// ------------------------------------------------------------------ scenario

Future<void> runSeed(int seed) async {
  final w = World(seed);
  w.server = FakeSyncServer(deviceId: 'seed', seed: seed, now: w.now);
  final devices = [for (var i = 1; i <= kDevices; i++) Device(w, 'd$i')];
  try {
    await _scenario(w, devices);
  } catch (e) {
    // ignore: avoid_print
    print(
      '\n==== CONVERGENCE FAILURE seed=$seed ====\n'
      'Re-run: flutter test test/core/sync/convergence_test.dart '
      '--dart-define=CONV_SEED=$seed\n'
      '${w.log.length > 400 ? '... (${w.log.length - 400} earlier lines)\n' : ''}'
      '${w.log.skip(max(0, w.log.length - 400)).join('\n')}\n'
      '==== end seed=$seed ====\n',
    );
    rethrow;
  } finally {
    for (final d in devices) {
      await d.dispose();
    }
  }
}

Future<void> _scenario(World w, List<Device> devices) async {
  final r = w.rnd;
  final server = w.server
    ..strictCatalog = true
    ..capabilities = {'push', 'pull', 'bootstrap_paged'}
    ..seedVendor(kVendor);

  // ---- seed the server: products + initial stock ----
  final initial = <String, BigInt>{};
  var seedSeq = 0;
  final seedMutations = <OutboxEntry>[];
  for (final p in kProducts) {
    seedMutations.add(
      OutboxEntry(
        seq: ++seedSeq,
        mutationId: 'seed-$p',
        entity: 'product',
        op: 'create',
        entityId: p,
        occurredAt: w.clock,
        payload: {'name': 'Product $p'},
      ),
    );
    for (final s in kShops) {
      final q = randDec(r, 100);
      initial['$p|$s'] = dec(q);
      seedMutations.add(
        OutboxEntry(
          seq: ++seedSeq,
          mutationId: 'seed-$p-$s',
          entity: 'stock',
          op: 'adjust',
          entityId: '$p:$s',
          occurredAt: w.clock,
          payload: {'product_id': p, 'shop_id': s, 'delta': q},
        ),
      );
    }
  }
  final seedResp = await server.push(
    deviceId: 'seed',
    appVersion: '1.0.0',
    mutations: seedMutations,
    scope: 'u1|t1',
  );
  expect(seedResp.results.every((x) => x.status == PushStatus.applied), isTrue);
  final seedFeed = server.feed.length;

  // ---- bootstrap every device (fault-free) ----
  for (final d in devices) {
    await d.init();
    expect(await d.engine.syncNow(), SyncOutcome.completed);
  }
  w.note('bootstrapped ${devices.length} devices, head=${server.headSeq}');

  // ---- offline actions: a part now, the rest during the sync rounds ----
  final budget = {
    for (final d in devices)
      d: kMinActions + r.nextInt(kMaxActions - kMinActions + 1),
  };
  for (final d in devices) {
    final now = r.nextInt(budget[d]! + 1);
    for (var i = 0; i < now; i++) {
      await d.randomAction();
    }
    budget[d] = budget[d]! - now;
  }

  // ---- faulty sync rounds, random device order ----
  final rounds = 3 + r.nextInt(6);
  for (var round = 0; round < rounds; round++) {
    w.note('-- round $round');
    final order = [...devices]..shuffle(r);
    for (final d in order) {
      // Interleave remaining offline actions.
      final left = budget[d]!;
      if (left > 0) {
        final n = round == rounds - 1 ? left : r.nextInt(left + 1);
        for (var i = 0; i < n; i++) {
          await d.randomAction();
        }
        budget[d] = left - n;
      }
      if (r.nextInt(10) == 0) await d.coldStart();
      if (r.nextInt(4) == 0) continue; // this device stays offline
      d.randomFaults();
      await d.sync();
      if (r.nextInt(3) == 0) {
        // A second attempt shortly after (rows usually still backing off).
        d.randomFaults();
        await d.sync();
      }
    }
    w.advance(Duration(minutes: r.nextInt(90)));
  }
  for (final d in devices) {
    expect(budget[d], 0);
  }

  // ---- fault-free rounds until a fixed point ----
  for (final d in devices) {
    d.clearFaults();
  }
  var fixed = false;
  for (var round = 0; round < kMaxFixedPointRounds && !fixed; round++) {
    w.note('-- final round $round');
    for (final d in devices) {
      // Past every per-row backoff (maxRowDelay is 1 h) and every lease.
      w.advance(const Duration(hours: 2));
      final o = await d.sync();
      expect(o, SyncOutcome.completed, reason: '${d.name} fault-free sync');
    }
    fixed = true;
    for (final d in devices) {
      if ((await d.notDone()).isNotEmpty ||
          !await d.atHead() ||
          await d.deferred() != null) {
        fixed = false;
      }
    }
  }

  // (f) no device wedged.
  for (final d in devices) {
    expect(
      await d.notDone(),
      isEmpty,
      reason: '(e)/(f) ${d.name} outbox not drained',
    );
    expect(
      await d.atHead(),
      isTrue,
      reason: '(f) ${d.name} cursor not at head',
    );
    expect(await d.deferred(), isNull, reason: '(f) ${d.name} deferred left');
    expect(d.engine.current.phase, SyncPhase.idle, reason: '(f) ${d.name}');
  }
  expect(fixed, isTrue, reason: '(f) no fixed point within cap');

  await _assertInvariants(w, devices, initial, seedFeed);
}

Future<void> _assertInvariants(
  World w,
  List<Device> devices,
  Map<String, BigInt> initial,
  int seedFeed,
) async {
  final server = w.server;

  // Every mutation any device ever enqueued (outbox rows are never pruned
  // here), in a global ledger.
  final all = <OutboxEntry>[];
  for (final d in devices) {
    final rows = await d.db.query('outbox', orderBy: 'seq');
    all.addAll(rows.map(OutboxEntry.fromRow));
  }

  // (e) everything done, nothing rejected.
  for (final e in all) {
    expect(
      e.status,
      OutboxStatus.done,
      reason: '(e) ${e.entity}/${e.entityId} ${e.mutationId} ${e.errorCode}',
    );
  }

  // (d) every mutation applied on the server exactly once.
  final ids = all.map((e) => e.mutationId).toList();
  expect(ids.toSet().length, ids.length, reason: '(d) duplicate mutation_id');
  var expectedEmits = 0;
  for (final e in all) {
    final res = server.applied[e.mutationId];
    expect(res, isNotNull, reason: '(d) ${e.mutationId} never applied');
    expect(res!.status, PushStatus.applied, reason: '(d) ${e.mutationId}');
    final items = (e.payload['items'] as List?) ?? const [];
    expectedEmits += switch (e.entity) {
      // the sale row + one stock movement per tracked product line
      'sale' => 1 + items.where((it) => (it as Map)['custom'] != true).length,
      'inbound' => 1 + items.length,
      _ => 1,
    };
  }
  expect(
    server.feed.length - seedFeed,
    expectedEmits,
    reason: '(d) feed length: a mutation was applied twice or lost',
  );
  final saleEmits = <String, int>{};
  for (final c in server.feed.where((c) => c.entity == 'sale')) {
    saleEmits[c.id] = (saleEmits[c.id] ?? 0) + 1;
  }
  expect(
    saleEmits.values.every((n) => n == 1),
    isTrue,
    reason: '(d) a sale was emitted twice',
  );

  // (a) stock: server == initial + every signed effect (stock add / remove /
  // adjust, inbound lines, sale product lines), decimal-exact.
  final expected = {...initial};
  void add(String k, BigInt d) =>
      expected[k] = (expected[k] ?? BigInt.zero) + d;
  for (final e in all) {
    final p = e.payload;
    switch (e.entity) {
      case 'stock':
        final k = '${p['product_id']}|${p['shop_id']}';
        final d = dec(p['delta']);
        add(k, switch (e.op) {
          'remove' => -d.abs(),
          _ => d,
        });
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
  for (final p in kProducts) {
    for (final s in kShops) {
      expect(
        dec(server.stockQuantity(p, s)),
        expected['$p|$s'],
        reason: '(a) server stock $p|$s',
      );
    }
  }

  // (b) sales: each created sale exists exactly once on the server; Σ
  // total_amount == Σ the devices' own subtotals.
  final serverSales = server.tables['sale'] ?? {};
  final deviceSales = <String, String>{};
  for (final d in devices) {
    for (final en in d.sales.entries) {
      expect(deviceSales.containsKey(en.key), isFalse);
      deviceSales[en.key] = en.value;
    }
  }
  expect(
    serverSales.keys.toSet(),
    deviceSales.keys.toSet(),
    reason: '(b) sale ids',
  );
  var serverTotal = BigInt.zero;
  for (final s in serverSales.values) {
    serverTotal += dec(s['total_amount']);
    expect(
      dec(s['total_amount']),
      dec(deviceSales[s['id']]),
      reason: '(b) sale ${s['id']} total',
    );
  }
  var deviceTotal = BigInt.zero;
  for (final t in deviceSales.values) {
    deviceTotal += dec(t);
  }
  expect(fmt(serverTotal), fmt(deviceTotal), reason: '(b) sale totals');
  var serverNet = BigInt.zero;
  for (final s in serverSales.values) {
    serverNet += dec(s['net_amount']);
  }

  // (c) each device's local tables == server.
  final serverProducts = server.tables['product'] ?? {};
  final serverCustomers = server.tables['customer'] ?? {};
  for (final d in devices) {
    final prods = {
      for (final row in await d.db.query('c_products')) row['id']: row,
    };
    expect(prods.keys.toSet(), serverProducts.keys.toSet(), reason: d.name);
    for (final sp in serverProducts.values) {
      final lp = prods[sp['id']]!;
      expect(
        [lp['name'], lp['version']],
        [sp['name'], sp['version']],
        reason: '(c) ${d.name} product ${sp['id']}',
      );
    }
    final custs = {
      for (final row in await d.db.query('c_customers')) row['id']: row,
    };
    expect(custs.keys.toSet(), serverCustomers.keys.toSet(), reason: d.name);
    for (final sc in serverCustomers.values) {
      final lc = custs[sc['id']]!;
      expect(
        [lc['name'], lc['version']],
        [sc['name'], sc['version']],
        reason: '(c) ${d.name} customer ${sc['id']}',
      );
    }
    // Real `sales` table (own sales synced + other devices' pulled).
    final sales = {for (final row in await d.db.query('sales')) row['id']: row};
    expect(sales.keys.toSet(), serverSales.keys.toSet(), reason: d.name);
    for (final ss in serverSales.values) {
      final ls = sales[ss['id']]!;
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
        reason: '(c) ${d.name} sale ${ss['id']}',
      );
      expect(
        (await d.db.query(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [ss['id']],
        )).length,
        (ss['items'] as List).length,
        reason: '(c) ${d.name} sale ${ss['id']} lines',
      );
    }
    // (g) money after any bootstrap + pull: Σ local net == Σ server net.
    var localNet = BigInt.zero;
    for (final ls in sales.values) {
      localNet += dec(ls['net_amount']);
    }
    expect(fmt(localNet), fmt(serverNet), reason: '(g) ${d.name} Σ net');
    // Bootstrap state settled.
    expect(await d.state.isBootstrapped(), isTrue, reason: d.name);
    expect(await d.state.bootstrapProgress(d.db), isNull, reason: d.name);
    // Real `stock` table: base == displayed == server (nothing pending).
    for (final row in await d.db.query('stock')) {
      final p = row['product_id'] as String;
      final s = row['shop_id'] as String;
      final server = dec(w.server.stockQuantity(p, s));
      expect(
        dec(row['base_quantity']),
        server,
        reason: '(c) ${d.name} base $p|$s',
      );
      expect(
        (row['quantity'] as num).toDouble(),
        Decimal3.toDouble(Decimal3.parse(fmt(server))),
        reason: '(c) ${d.name} displayed $p|$s',
      );
      expect(
        row['id'],
        w.server.stockLevelId(p, s),
        reason: '(c) ${d.name} stock row adopts the StockLevel id',
      );
    }
    expect(
      (await d.db.query('stock')).length,
      kProducts.length * kShops.length,
      reason: '(c) ${d.name} stock rows',
    );
  }
}

void main() {
  final seeds = kOnlySeed >= 0
      ? [kOnlySeed]
      : [for (var s = kFirstSeed; s < kFirstSeed + kSeeds; s++) s];
  final sw = Stopwatch();
  FlutterExceptionHandler? prevOnError;
  setUpAll(() {
    sw.start();
    // The engine's resync loop guard reports loudly by design; count it
    // instead of printing it. Anything else still goes to the handler.
    prevOnError = FlutterError.onError;
    FlutterError.onError = (d) {
      if ('${d.exception}'.contains('full_resync_required within')) {
        _bump('resync_loop_guard');
      } else {
        prevOnError?.call(d);
      }
    };
  });
  tearDownAll(() {
    FlutterError.onError = prevOnError;
    // ignore: avoid_print
    print(
      'convergence: ${seeds.length} seeds x $kDevices devices in '
      '${sw.elapsedMilliseconds} ms\n'
      'coverage: ${(stats.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key}=${e.value}').join(', ')}',
    );
  });
  group('multi-device convergence', () {
    for (final seed in seeds) {
      test('seed $seed', () => runSeed(seed));
    }
  });
}
