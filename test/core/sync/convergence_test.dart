// Multi-device convergence property test (Task 11).
//
// For every seed: N devices, each with its OWN in-memory OfflineDb, real
// LocalWriter / OutboxStore / SyncStateStore / SyncEngine and its own
// appliers writing local tables, all sharing ONE FakeSyncServer through
// forDevice views. Devices perform random offline writes (stock deltas,
// sales, product renames, customer creates), then sync in random order under
// random per-view faults (flaky, lost responses, dropped response after
// apply, device down) and simulated crashes (SyncHooks + restart on the same
// DB). Finally faults are cleared and devices sync until a fixed point, then
// the money / stock / convergence invariants are checked.
//
// Re-run one seed (prints its action log on failure):
//   flutter test test/core/sync/convergence_test.dart --dart-define=CONV_SEED=17
// Other knobs: CONV_SEEDS (count, default 200), CONV_FIRST (first seed),
// CONV_DEVICES (default 3), CONV_FAULTS / CONV_CRASHES (default true),
// CONV_MIN_ACTIONS / CONV_MAX_ACTIONS (default 20 / 60), CONV_VERBOSE.
import 'dart:convert';
import 'dart:math';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/local_writer.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'support/fake_sync_server.dart';

// Default 60 seeds (~17 s) keeps `flutter test` fast. Full run before releases:
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

const List<String> kProducts = ['P1', 'P2', 'P3', 'P4'];
const List<String> kShops = ['S1', 'S2'];

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

class SaleApplier extends _RowApplier {
  SaleApplier(this.stock) : super('sale', 'c_sales');
  final StockApplier stock;

  @override
  Map<String, Object?> rowFrom(PullChange c) => {
    'shop_id': c.data?['shop_id'],
    'total': c.data?['total'],
    'status': c.data?['status'],
    'customer_id': c.data?['customer_id'],
  };

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
      {'version': result.version, 'status': 'done'},
      where: 'id = ?',
      whereArgs: [sent.entityId],
    );
    await stock.rebase(txn, result);
  }
}

/// Local stock = server base (pulled) + this device's pending deltas (derived
/// from the outbox). Base is always refreshed from pulls, even while local
/// deltas are pending.
class StockApplier implements ChangeApplier {
  @override
  String get entity => 'stock';

  @override
  Set<String> get tables => {'c_stock'};

  @override
  bool get skipWhenLocalPending => false;

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) async => null;

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    final d = change.data!;
    await txn.insert('c_stock', {
      'product_id': d['product_id'],
      'shop_id': d['shop_id'],
      'base': d['quantity'],
      'version': change.version,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Re-base from `stock_after` only for a FRESH `applied` result: a
  /// `duplicate` replays the stored (possibly stale) stock_after.
  Future<void> rebase(Transaction txn, PushResult r) async {
    if (r.status != PushStatus.applied) return;
    for (final a in r.stockAfter) {
      final n = await txn.update(
        'c_stock',
        {'base': a.quantity},
        where: 'product_id = ? AND shop_id = ?',
        whereArgs: [a.productId, a.shopId],
      );
      if (n == 0) {
        await txn.insert('c_stock', {
          'product_id': a.productId,
          'shop_id': a.shopId,
          'base': a.quantity,
          'version': null,
        });
      }
    }
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) => rebase(txn, result);
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
  await db.execute(
    'CREATE TABLE c_sales (id TEXT PRIMARY KEY, shop_id TEXT, total TEXT, '
    'status TEXT, customer_id TEXT, version INTEGER)',
  );
  await db.execute(
    'CREATE TABLE c_stock (product_id TEXT, shop_id TEXT, base TEXT, '
    'version INTEGER, PRIMARY KEY (product_id, shop_id))',
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
  final engines = <SyncEngine>[];

  /// Hook name at which the current engine crashes next (once).
  String? crashAt;
  int restarts = 0;
  int counter = 0;

  /// Every sale this device created: id -> total.
  final sales = <String, String>{};
  final customers = <String>{};

  Future<void> init() async {
    odb = await _openDb();
    db = await odb.database;
    view = w.server.forDevice(name, seed: w.rnd.nextInt(1 << 30));
    final stock = StockApplier();
    registry
      ..register(ProductApplier())
      ..register(CustomerApplier())
      ..register(stock)
      ..register(SaleApplier(stock));
    _rebuild();
    await db.transaction(
      (t) => state.setCursor(t, base64Url.encode(utf8.encode('seq:0'))),
    );
  }

  void _rebuild() {
    outbox = OutboxStore(odb, now: w.now);
    state = SyncStateStore(odb, now: w.now);
    writer = LocalWriter(odb, outbox, notifier);
    engine = SyncEngine(
      db: odb,
      transport: view,
      outbox: outbox,
      state: state,
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
    notifier.dispose();
    await db.close();
  }

  // ---------------------------------------------------------- local writes

  Future<OutboxEntry> stockDelta(String p, String s, String delta) =>
      writer.write(
        tables: {'c_stock'},
        body: (scope) => scope.enqueue(
          entity: 'stock',
          op: 'adjust',
          entityId: '$p:$s',
          payload: {'product_id': p, 'shop_id': s, 'delta': delta},
          occurredAt: w.clock,
        ),
      );

  Future<OutboxEntry> sale(
    String id,
    String shop,
    List<(String, String)> lines,
    String total,
    String? customer,
  ) => writer.write(
    tables: {'c_sales'},
    body: (scope) async {
      await scope.txn.insert('c_sales', {
        'id': id,
        'shop_id': shop,
        'total': total,
        'status': 'local',
        'customer_id': customer,
        'version': null,
      });
      return scope.enqueue(
        entity: 'sale',
        op: 'create',
        entityId: id,
        payload: {
          'shop_id': shop,
          'total': total,
          'items': [
            for (final (p, q) in lines) {'product_id': p, 'quantity': q},
          ],
          'customer_id': ?customer,
        },
        dependsOnEntityId: customer,
        occurredAt: w.clock,
      );
    },
  );

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
    if (k < 40) {
      final p = kProducts[r.nextInt(kProducts.length)];
      final s = kShops[r.nextInt(kShops.length)];
      final d = randDec(r, 20);
      final delta = r.nextBool() ? d : '-$d';
      w.note('$name stock $p:$s $delta');
      await stockDelta(p, s, delta);
    } else if (k < 70) {
      final id = '$name-s$counter';
      final shop = kShops[r.nextInt(kShops.length)];
      final n = r.nextInt(3) + 1;
      final lines = <(String, String)>[
        for (var i = 0; i < n; i++)
          (kProducts[r.nextInt(kProducts.length)], randDec(r, 5)),
      ];
      final total = randDec(r, 500);
      final cust = customers.isNotEmpty && r.nextInt(3) == 0
          ? customers.elementAt(r.nextInt(customers.length))
          : null;
      sales[id] = total;
      w.note('$name sale $id $shop total=$total cust=$cust $lines');
      await sale(id, shop, lines, total, cust);
    } else if (k < 88) {
      final p = kProducts[r.nextInt(kProducts.length)];
      final nm = '$name-n$counter';
      w.note('$name rename $p -> $nm');
      await rename(p, nm);
    } else {
      final id = '$name-c$counter';
      customers.add(id);
      w.note('$name customer $id');
      await createCustomer(id, 'Cust $id');
    }
  }

  // ---------------------------------------------------------- sync

  void clearFaults() {
    view
      ..down = false
      ..flakyRate = 0
      ..lostResponseRate = 0
      ..dropResponseAfterApply = 0;
    crashAt = null;
  }

  void randomFaults() {
    final r = w.rnd;
    clearFaults();
    if (!kFaults) return;
    if (r.nextInt(10) == 0) view.down = true;
    if (r.nextBool()) view.flakyRate = r.nextDouble() * 0.5;
    if (r.nextBool()) view.lostResponseRate = r.nextDouble() * 0.5;
    if (r.nextInt(4) == 0) view.dropResponseAfterApply = 1;
    if (kCrashes && r.nextInt(4) == 0) {
      crashAt = const [
        'beforeResultWrite',
        'afterPushApplied',
        'beforePullPageCommit',
      ][r.nextInt(3)];
    }
  }

  String get faultString =>
      '${view.down ? 'down ' : ''}'
      'flaky=${view.flakyRate.toStringAsFixed(2)} '
      'lost=${view.lostResponseRate.toStringAsFixed(2)} '
      'drop=${view.dropResponseAfterApply} crash=$crashAt';

  /// Runs one sync; a simulated crash restarts the "process" on the same DB
  /// after the lock / claim leases expired.
  Future<SyncOutcome?> sync() async {
    final faults = faultString;
    try {
      final o = await engine.syncNow();
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
  final server = w.server;

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
    expectedEmits += switch (e.entity) {
      'sale' => (e.payload['items'] as List).length + 1,
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

  // (a) stock: server == initial + every delta (stock adjusts and sale
  // lines), decimal-exact.
  final expected = {...initial};
  for (final e in all) {
    if (e.entity == 'stock') {
      final k = '${e.payload['product_id']}|${e.payload['shop_id']}';
      expected[k] = (expected[k] ?? BigInt.zero) + dec(e.payload['delta']);
    } else if (e.entity == 'sale') {
      final shop = e.payload['shop_id'];
      for (final it in e.payload['items'] as List) {
        final k = '${it['product_id']}|$shop';
        expected[k] = (expected[k] ?? BigInt.zero) - dec(it['quantity']);
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

  // (b) sales: each created sale exists exactly once on the server; totals
  // add up to the devices' totals.
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
    serverTotal += dec(s['total']);
  }
  var deviceTotal = BigInt.zero;
  for (final t in deviceSales.values) {
    deviceTotal += dec(t);
  }
  expect(fmt(serverTotal), fmt(deviceTotal), reason: '(b) sale totals');

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
    final sales = {
      for (final row in await d.db.query('c_sales')) row['id']: row,
    };
    expect(sales.keys.toSet(), serverSales.keys.toSet(), reason: d.name);
    for (final ss in serverSales.values) {
      final ls = sales[ss['id']]!;
      expect(
        [ls['total'], ls['status'], ls['shop_id'], ls['version']],
        [ss['total'], ss['status'], ss['shop_id'], ss['version']],
        reason: '(c) ${d.name} sale ${ss['id']}',
      );
    }
    // Local stock = base + pending deltas (none pending at the fixed point).
    final pendingDelta = <String, BigInt>{};
    for (final row in await d.notDone()) {
      final e = OutboxEntry.fromRow(row);
      if (e.entity == 'stock') {
        final k = '${e.payload['product_id']}|${e.payload['shop_id']}';
        pendingDelta[k] =
            (pendingDelta[k] ?? BigInt.zero) + dec(e.payload['delta']);
      }
    }
    for (final row in await d.db.query('c_stock')) {
      final k = '${row['product_id']}|${row['shop_id']}';
      final local = dec(row['base']) + (pendingDelta[k] ?? BigInt.zero);
      expect(
        fmt(local),
        server.stockQuantity(
          row['product_id'] as String,
          row['shop_id'] as String,
        ),
        reason: '(c) ${d.name} stock $k',
      );
    }
    expect(
      (await d.db.query('c_stock')).length,
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
  setUpAll(sw.start);
  tearDownAll(() {
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
