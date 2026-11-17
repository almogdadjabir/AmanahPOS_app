import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:amana_pos/core/offline/offline_db.dart';
import 'package:amana_pos/core/sync/bootstrap/bootstrapper.dart';
import 'package:amana_pos/core/sync/change_applier.dart';
import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/db_change_notifier.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/outbox/outbox_store.dart';
import 'package:amana_pos/core/sync/reachability.dart';
import 'package:amana_pos/core/sync/sync_appliers.dart';
import 'package:amana_pos/core/sync/sync_engine.dart';
import 'package:amana_pos/core/sync/sync_state_store.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:sqflite/sqflite.dart';

import 'fake_sync_server.dart';
import 'test_db.dart';

/// Transport wrapper for bootstrap tests: records requests, enforces the
/// live session like the auth interceptor, and lets a test fail/alter a
/// request before it is sent or after its response arrived.
class BootTransport implements SyncTransport {
  BootTransport(this.inner);
  final FakeSyncServer inner;

  String? Function()? sessionKey;

  int manifestCalls = 0;

  /// (entity, pageCursor, limit) of every page request that reached here.
  final pageRequests = <(String, String?, int)>[];

  /// Runs before a page is sent (1-based page call count). May throw.
  FutureOr<void> Function(int call, String entity)? beforePage;

  /// Runs after a page response arrived (1-based). May throw (lost
  /// response) or return a replacement page.
  BootstrapPage? Function(int call, BootstrapPage page)? afterPage;

  void _guard(String scope) {
    final key = sessionKey;
    if (key != null && key() != scope) {
      throw SyncTransportException(kind: SyncTransportKind.scopeChanged);
    }
  }

  List<String> get requestedEntities {
    final out = <String>[];
    for (final (e, _, _) in pageRequests) {
      if (out.isEmpty || out.last != e) out.add(e);
    }
    return out;
  }

  @override
  Future<PingResponse> ping() => inner.ping();

  @override
  Future<PushResponse> push({
    required String deviceId,
    required String appVersion,
    required List<OutboxEntry> mutations,
    required String scope,
  }) {
    _guard(scope);
    return inner.push(
      deviceId: deviceId,
      appVersion: appVersion,
      mutations: mutations,
      scope: scope,
    );
  }

  @override
  Future<PullResponse> pull({
    String? cursor,
    int limit = 500,
    required String scope,
  }) {
    _guard(scope);
    return inner.pull(cursor: cursor, limit: limit, scope: scope);
  }

  @override
  Future<BootstrapManifest> bootstrapManifest({required String scope}) async {
    _guard(scope);
    final m = await inner.bootstrapManifest(scope: scope);
    manifestCalls++;
    return m;
  }

  @override
  Future<BootstrapPage> bootstrapPage({
    required String entity,
    String? pageCursor,
    int limit = 500,
    String? snapshotCursor,
    int salesSinceDays = 90,
    required String scope,
  }) async {
    _guard(scope);
    final n = pageRequests.length + 1;
    pageRequests.add((entity, pageCursor, limit));
    await beforePage?.call(n, entity);
    final page = await inner.bootstrapPage(
      entity: entity,
      pageCursor: pageCursor,
      limit: limit,
      snapshotCursor: snapshotCursor,
      salesSinceDays: salesSinceDays,
      scope: scope,
    );
    return afterPage?.call(n, page) ?? page;
  }
}

/// Wraps a real applier; throws while [throwOn] holds the id.
class ThrowingApplier implements ChangeApplier {
  ThrowingApplier(this.inner);
  final ChangeApplier inner;
  final throwOn = <String>{};
  Object Function() error = () => StateError('applier boom');

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
  Future<void> apply(Transaction txn, PullChange change) async {
    await inner.apply(txn, change);
    if (throwOn.contains(change.id)) throw error();
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) => inner.onPushResult(txn, sent, result);
}

/// Wraps a real applier and records which transaction every apply ran in
/// (identity), so a test can count the transactions a bootstrap used.
class TxnCountingApplier implements ChangeApplier {
  TxnCountingApplier(this.inner);
  final ChangeApplier inner;

  /// Items applied per transaction, in first-use order.
  final perTxn = Map<Transaction, int>.identity();

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
  Future<void> apply(Transaction txn, PullChange change) {
    perTxn[txn] = (perTxn[txn] ?? 0) + 1;
    return inner.apply(txn, change);
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) => inner.onPushResult(txn, sent, result);
}

/// One device with a real in-memory DB, the real applier registry and a
/// FakeSyncServer that advertises `bootstrap_paged`.
class BootHarness {
  BootHarness._();

  static const String scope = 'u1|t1';

  String? activeScope = scope;
  String? liveScope;

  /// Scope a bootstrap run started under (what `assertScope` compares to).
  String runScope = scope;

  late OfflineDb odb;
  late Database db;
  late FakeSyncServer server;
  late BootTransport transport;
  late SyncStateStore state;
  late ChangeApplierRegistry registry;
  final notifier = DbChangeNotifier();
  final notified = <String>{};
  final _boots = <Bootstrapper>[];
  final _engines = <SyncEngine>[];
  SyncEngine? engine;

  /// Throws from `assertScope` at the [assertKillAt]-th call (1-based
  /// across the harness lifetime), like a kill at that point.
  int assertCalls = 0;
  int? assertKillAt;

  int refreshCalls = 0;
  RefreshOutcome refreshOutcome = RefreshOutcome.refreshed;
  void Function()? onRefresh;

  DateTime clock = DateTime.utc(2026, 11, 16, 12);
  DateTime now() => clock;
  void advance(Duration d) => clock = clock.add(d);

  static Future<BootHarness> create({
    ChangeApplierRegistry Function(BootHarness h)? registry,
  }) async {
    final h = BootHarness._();
    h.odb = await openTestDb();
    h.db = await h.odb.database;
    h.server = FakeSyncServer(now: h.now);
    h.server.capabilities = {'push', 'pull', 'bootstrap_paged'};
    h.server.bootstrapEntities = ['category', 'product', 'customer'];
    h.transport = BootTransport(h.server);
    h.transport.sessionKey = () => h.liveScope ?? h.activeScope;
    h.state = SyncStateStore(h.odb, now: h.now);
    h.registry =
        registry?.call(h) ??
        buildSyncAppliers(scopeProvider: () => h.activeScope);
    h.notifier.changes.listen(h.notified.addAll);
    return h;
  }

  SyncStateStore get scoped => state.forScope(scope);

  SyncEngine buildEngine() {
    final e = SyncEngine(
      db: odb,
      transport: transport,
      outbox: OutboxStore(odb, now: now),
      state: state,
      scopeProvider: () => activeScope,
      readSessionKey: () async => liveScope ?? activeScope,
      reachability: ServerReachability(transport, now: now),
      appliers: registry,
      notifier: notifier,
      appVersion: '1.0.0',
      backoff: Backoff(random: Random(1)),
      now: now,
      refreshToken: () async {
        refreshCalls++;
        onRefresh?.call();
        return refreshOutcome;
      },
    );
    _engines.add(e);
    engine = e;
    return e;
  }

  Bootstrapper build({
    int pageSize = 2,
    AuthedCall Function(String scope)? authedFor,
    int maxPagesPerEntity = Bootstrapper.defaultMaxPagesPerEntity,
    Set<String>? capabilities,
  }) {
    final b = Bootstrapper(
      db: odb,
      transport: transport,
      state: state,
      appliers: registry,
      notifier: notifier,
      scopeProvider: () => activeScope,
      assertScope: () async {
        assertCalls++;
        if (assertKillAt != null && assertCalls == assertKillAt) {
          throw CrashSimulation('assertScope #$assertCalls');
        }
        if ((liveScope ?? activeScope) != runScope) {
          throw SyncTransportException(kind: SyncTransportKind.scopeChanged);
        }
      },
      capabilities: () async => capabilities ?? {...server.capabilities},
      authedFor: authedFor ?? (engine ?? buildEngine()).authedFor,
      maxPagesPerEntity: maxPagesPerEntity,
      pageSize: pageSize,
      now: now,
    );
    _boots.add(b);
    return b;
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

  // ---------------------------------------------------------- seeding

  void seedCategory(String id, {int version = 1, String? name}) =>
      server.seedRow('category', {
        'id': id,
        'version': version,
        'name': name ?? 'Cat $id',
        'parent': null,
        'is_active': true,
        'updated_at': '2026-11-16T10:00:00Z',
      });

  Map<String, dynamic> productRow(
    String id, {
    int version = 1,
    String? name,
    String price = '1.50',
    String category = 'c1',
  }) => {
    'id': id,
    'version': version,
    'name': name ?? 'Prod $id',
    'sku': 'S-$id',
    'barcode': 'B-$id',
    'price': price,
    'cost_price': '1.00',
    'category': category,
    'image': null,
    'thumbnail_url': null,
    'image_hash': '',
    'is_active': true,
    'track_inventory': true,
    'min_stock_level': 0,
    'unit': 'pcs',
    'updated_at': '2026-11-16T10:00:00Z',
  };

  void seedProduct(String id, {int version = 1, String? name}) =>
      server.seedRow('product', productRow(id, version: version, name: name));

  void seedCustomer(String id, {int version = 1}) =>
      server.seedRow('customer', {
        'id': id,
        'version': version,
        'name': 'Cust $id',
        'phone': null,
        'email': null,
        'loyalty_points': 0,
        'is_active': true,
        'updated_at': '2026-11-16T10:00:00Z',
      });

  /// 3 categories (2 pages of 2), 5 products (3 pages), 2 customers (1).
  void seedStandard() {
    for (final c in ['c1', 'c2', 'c3']) {
      seedCategory(c);
    }
    for (final p in ['p1', 'p2', 'p3', 'p4', 'p5']) {
      seedProduct(p);
    }
    for (final c in ['k1', 'k2']) {
      seedCustomer(c);
    }
  }

  /// Local product row written directly through the real applier.
  Future<void> localProduct(String id, {int version = 1, String? name}) async {
    final applier = registry.of('product')!;
    await db.transaction(
      (t) => applier.apply(
        t,
        PullChange(
          seq: 0,
          entity: 'product',
          op: 'upsert',
          id: id,
          version: version,
          data: productRow(id, version: version, name: name),
        ),
      ),
    );
  }

  Future<void> pendingOutbox(String entity, String id) async {
    await db.insert('outbox', {
      'mutation_id': 'm-$entity-$id',
      'entity': entity,
      'op': 'update',
      'entity_id': id,
      'occurred_at': clock.toIso8601String(),
      'payload_json': jsonEncode({'name': 'local'}),
      'status': 'pending',
      'created_at': clock.toIso8601String(),
      'scope': scope,
    });
  }

  // ---------------------------------------------------------- observation

  Future<List<String>> ids(String table) async => [
    for (final r in await db.query(table, columns: ['id'], orderBy: 'id'))
      r['id'] as String,
  ];

  Future<Map<String, Object?>?> row(String table, String id) async {
    final r = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : r.first;
  }

  Future<BootstrapProgress?> progress([String s = scope]) =>
      state.forScope(s).bootstrapProgress(db);

  Future<String?> deferredJson([String s = scope]) =>
      state.forScope(s).deferredPullJson(db);

  /// Everything a bootstrap writes, for identity comparisons.
  Future<String> dump() async {
    final out = <String, Object?>{};
    for (final t in ['categories', 'products', 'customers']) {
      out[t] = await db.query(t, orderBy: 'id');
    }
    out['sync_state'] = [
      for (final r in await db.query(
        'sync_state',
        columns: ['key', 'value'],
        orderBy: 'key',
      ))
        // The lock and the completion wall-clock time are not data.
        if (r['key'] != 'sync_lock' &&
            !(r['key'] as String).startsWith('bootstrap_completed_at|'))
          r,
    ];
    return jsonEncode(out);
  }
}
