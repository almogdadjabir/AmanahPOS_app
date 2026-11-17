import 'dart:async';
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
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:sqflite/sqflite.dart';

import 'fake_sync_server.dart';
import 'test_db.dart';

/// Wraps a transport: records every push batch, and can answer chosen
/// mutations with a scripted result WITHOUT the server applying them.
class ScenarioTransport implements SyncTransport {
  ScenarioTransport(this.inner);
  final SyncTransport inner;

  /// Size of every push batch, in call order (including failed calls).
  final batchSizes = <int>[];

  /// Every pushed mutation, in send order (repeats on retries).
  final pushed = <OutboxEntry>[];

  /// mutation_id -> result returned instead of reaching the server.
  final scripted = <String, PushResult>{};
  int pushCalls = 0;
  int pullCalls = 0;

  /// Runs right before a push/pull is sent (a session switch can happen
  /// here, like on a real network wait).
  Future<void> Function(String op)? onBeforeSend;

  /// Emulates the auth interceptor: the session key that is current at send
  /// time. A request bound to a different scope is refused.
  String? Function()? sessionKey;

  void _guard(String? scope) {
    final key = sessionKey;
    if (scope != null && key != null && key() != scope) {
      throw SyncTransportException(kind: SyncTransportKind.scopeChanged);
    }
  }

  List<String> get pushedIds => pushed.map((e) => e.mutationId).toList();

  @override
  Future<ChecksumResponse> checksum({
    required String entity,
    int sinceDays = 7,
    required String scope,
  }) => inner.checksum(entity: entity, sinceDays: sinceDays, scope: scope);

  @override
  Future<PingResponse> ping() => inner.ping();

  @override
  Future<PushResponse> push({
    required String deviceId,
    required String appVersion,
    required List<OutboxEntry> mutations,
    required String scope,
  }) async {
    await onBeforeSend?.call('push');
    _guard(scope);
    pushCalls++;
    batchSizes.add(mutations.length);
    pushed.addAll(mutations);
    final mine = mutations
        .where((m) => scripted.containsKey(m.mutationId))
        .toList();
    final rest = mutations
        .where((m) => !scripted.containsKey(m.mutationId))
        .toList();
    final r = await inner.push(
      deviceId: deviceId,
      appVersion: appVersion,
      mutations: rest,
      scope: scope,
    );
    if (mine.isEmpty) return r;
    return PushResponse(
      serverTime: r.serverTime,
      results: [...r.results, for (final m in mine) scripted[m.mutationId]!],
      nextCursor: r.nextCursor,
    );
  }

  @override
  Future<PullResponse> pull({
    String? cursor,
    int limit = 500,
    required String scope,
  }) async {
    await onBeforeSend?.call('pull');
    _guard(scope);
    pullCalls++;
    return inner.pull(cursor: cursor, limit: limit, scope: scope);
  }

  int bootstrapManifestCalls = 0;
  int bootstrapPageCalls = 0;

  @override
  Future<BootstrapManifest> bootstrapManifest({required String scope}) async {
    await onBeforeSend?.call('bootstrapManifest');
    _guard(scope);
    bootstrapManifestCalls++;
    return inner.bootstrapManifest(scope: scope);
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
    await onBeforeSend?.call('bootstrapPage');
    _guard(scope);
    bootstrapPageCalls++;
    return inner.bootstrapPage(
      entity: entity,
      pageCursor: pageCursor,
      limit: limit,
      snapshotCursor: snapshotCursor,
      salesSinceDays: salesSinceDays,
      scope: scope,
    );
  }
}

/// Applier over the scratch `widgets` table. Records the last conflict
/// `server_state` it was handed so the UI-facing storage can be asserted.
class WidgetApplier implements ChangeApplier {
  @override
  String get entity => 'product';

  @override
  Set<String> get tables => {'widgets'};

  @override
  bool get skipWhenLocalPending => true;

  final pushResults = <PushResult>[];

  @override
  Future<int?> localVersion(Transaction txn, PullChange change) async {
    final r = await txn.query(
      'widgets',
      columns: ['version'],
      where: 'id = ?',
      whereArgs: [change.id],
    );
    return r.isEmpty ? null : r.single['version'] as int?;
  }

  @override
  Future<void> apply(Transaction txn, PullChange change) async {
    if (change.op == 'delete') {
      await txn.delete('widgets', where: 'id = ?', whereArgs: [change.id]);
      return;
    }
    await txn.insert('widgets', {
      'id': change.id,
      'name': change.data?['name'],
      'version': change.version,
      'conflict': null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> onPushResult(
    Transaction txn,
    OutboxEntry sent,
    PushResult result,
  ) async {
    pushResults.add(result);
    if (result.status == PushStatus.rejected) {
      await txn.update(
        'widgets',
        {
          'conflict': jsonEncode({
            'code': result.code,
            'message': result.message,
            'server_state': result.serverState,
          }),
        },
        where: 'id = ?',
        whereArgs: [sent.entityId],
      );
      return;
    }
    await txn.update(
      'widgets',
      {
        'version': result.version,
        if (result.merged && result.serverState != null)
          'name': result.serverState!['name'],
        if (result.merged && result.serverState != null)
          'conflict': jsonEncode({
            'merged': true,
            'server_state': result.serverState,
          }),
      },
      where: 'id = ?',
      whereArgs: [sent.entityId],
    );
  }
}

/// One simulated device: real OfflineDb (in-memory), real LocalWriter and
/// outbox, FakeSyncServer and a fake clock. [restart] builds a NEW
/// engine/state/outbox on the SAME database, like a process restart.
class EngineHarness {
  EngineHarness._();

  static const String scope = 'u1|t1';

  /// Scope the engine and writer act under; null = nobody signed in.
  String? activeScope = scope;

  /// What the live auth session says; null = same as [activeScope]. Setting
  /// it differently models the delayed `SyncScope.current`.
  String? liveScope;

  /// Runs on every live session read of the engine (1-based call count).
  void Function(int n)? onSessionRead;
  int sessionReads = 0;

  late OfflineDb odb;
  late Database db;
  late FakeSyncServer server;
  late ScenarioTransport transport;
  late OutboxStore outbox;
  late SyncStateStore state;
  late LocalWriter writer;
  final notifier = DbChangeNotifier();
  final applier = WidgetApplier();
  final registry = ChangeApplierRegistry();
  final _engines = <SyncEngine>[];
  SyncEngine? engine;

  DateTime clock = DateTime.utc(2026, 1, 1, 12);
  DateTime now() => clock;
  void advance(Duration d) => clock = clock.add(d);

  static final seedCursor = base64Url.encode(utf8.encode('seq:0'));

  static Future<EngineHarness> create() async {
    final h = EngineHarness._();
    h.odb = await openTestDb();
    h.db = await h.odb.database;
    await h.db.execute(
      'CREATE TABLE widgets (id TEXT PRIMARY KEY, name TEXT, '
      'version INTEGER, conflict TEXT)',
    );
    h.server = FakeSyncServer(now: h.now);
    h.transport = ScenarioTransport(h.server);
    h.registry.register(h.applier);
    h.transport.sessionKey = () => h.liveScope ?? h.activeScope;
    h._rebuildStores();
    // Bootstrapped device: a cursor at the start of the feed and the
    // scope's `bootstrapped` flag (set by the final bootstrap transaction).
    await h.db.transaction((t) async {
      await h.state.setCursor(t, seedCursor);
      await h.state.setBootstrapped(t, true);
    });
    return h;
  }

  void _rebuildStores() {
    outbox = OutboxStore(odb, now: now);
    state = SyncStateStore(odb, now: now, scope: scope);
    writer = LocalWriter(
      odb,
      outbox,
      notifier,
      scopeProvider: () => activeScope,
    );
  }

  SyncEngine build({
    SyncHooks? hooks,
    int pullPageSize = SyncEngine.defaultPullPageSize,
    int backoffSeed = 1,
    Future<RefreshOutcome> Function()? refreshToken,
  }) {
    final e = SyncEngine(
      db: odb,
      transport: transport,
      outbox: outbox,
      state: state,
      scopeProvider: () => activeScope,
      readSessionKey: () async {
        onSessionRead?.call(++sessionReads);
        return liveScope ?? activeScope;
      },
      reachability: ServerReachability(transport, now: now),
      appliers: registry,
      notifier: notifier,
      appVersion: '1.0.0',
      backoff: Backoff(random: Random(backoffSeed)),
      now: now,
      hooks: hooks,
      refreshToken: refreshToken,
      pullPageSize: pullPageSize,
    );
    _engines.add(e);
    engine = e;
    return e;
  }

  /// Simulated process restart: everything in memory is dropped and rebuilt
  /// on the same database.
  SyncEngine restart({
    SyncHooks? hooks,
    int pullPageSize = SyncEngine.defaultPullPageSize,
  }) {
    _rebuildStores();
    return build(hooks: hooks, pullPageSize: pullPageSize);
  }

  Future<void> dispose() async {
    for (final e in _engines) {
      await e.dispose();
    }
    notifier.dispose();
    await db.close();
  }

  // ---------------------------------------------------------- local writes

  Future<OutboxEntry> createWidget(
    String id, {
    String? name,
    DateTime? occurredAt,
    String entity = 'product',
    String op = 'create',
    int? baseVersion,
    List<String> dependsOn = const [],
    Map<String, dynamic>? payload,
  }) {
    return writer.write(
      tables: {'widgets'},
      body: (scope) async {
        if (entity == 'product') {
          await scope.txn.insert('widgets', {
            'id': id,
            'name': name ?? 'W $id',
            'version': null,
            'conflict': null,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return scope.enqueue(
          entity: entity,
          op: op,
          entityId: id,
          payload: payload ?? {'name': name ?? 'W $id'},
          baseVersion: baseVersion,
          dependsOn: dependsOn,
          occurredAt: occurredAt,
        );
      },
    );
  }

  /// Another device pushes a create straight to the server.
  Future<PushResult> otherDevice(String id, {String? name}) async {
    final r = await server
        .forDevice('dev-2')
        .push(
          deviceId: 'dev-2',
          appVersion: '1.0.0',
          mutations: [
            OutboxEntry(
              seq: server.headSeq + 1,
              mutationId: 'other-$id-${server.headSeq}',
              entity: 'product',
              op: 'create',
              entityId: id,
              occurredAt: clock,
              payload: {'name': name ?? 'Other $id'},
            ),
          ],
          scope: 'u1|t1',
        );
    return r.results.single;
  }

  // ---------------------------------------------------------- observation

  Future<Map<String, Object?>> outboxRow(String mutationId) async =>
      (await db.query(
        'outbox',
        where: 'mutation_id = ?',
        whereArgs: [mutationId],
      )).single;

  Future<int> countStatus(String s) async => Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM outbox WHERE status = ?', [s]),
  )!;

  Future<int> outboxTotal() async =>
      Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM outbox'))!;

  Future<List<Map<String, Object?>>> widgets() =>
      db.query('widgets', orderBy: 'id');

  Future<Map<String, Object?>> widget(String id) async =>
      (await db.query('widgets', where: 'id = ?', whereArgs: [id])).single;

  int get serverProductCount => server.tables['product']?.length ?? 0;
}
