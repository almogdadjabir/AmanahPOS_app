// In-memory stand-in for the real backend (docs/BE_GAPS.md sections 2-6, 10).
//
// Payload conventions the fake relies on (the real DTOs may carry more):
//  * dependency detection (the wire has no depends_on field): a mutation is
//    rejected `dependency_failed` when any of these reference an entity id
//    whose *create* was rejected earlier: `payload['depends_on']` (String or
//    List<String>), `payload['product_id']`, `payload['category_id']`,
//    `payload['sale_id']`, `payload['items'][i]['product_id']`, or the
//    mutation's own `entity_id` on a non-create op.
//  * dependency_failed mirrors BE services._apply_one: within ONE push, any
//    rejected mutation's entity_id is "failed"; a later mutation (seq order)
//    whose BE `dependencies()` name a failed id is rejected
//    `dependency_failed` with `depends_on`. Nothing carries over between
//    pushes (the BE has no cross-batch memory either).
//  * catalog (category/product/vendor, BE handlers.catalog_*): create keeps
//    the client id (an existing id -> `conflict_unique` naming itself);
//    tenant uniqueness (product sku/barcode incl. inactive rows, category
//    name per parent, vendor name case-insensitive) -> `conflict_unique` +
//    `conflict_entity_id` + `errors`; update with a stale base_version is
//    applied and answers `merged` + `server_state`; delete = is_active false
//    + a `delete` change row (tombstone; the row stays, bootstrap serves it
//    inactive); update of a tombstoned row -> `entity_deleted`; a second
//    delete is `applied` (idempotent). Knobs: [productLimit]
//    (`limit_exceeded`), per-view [role] `cashier` (`forbidden` outside the
//    BE CASHIER_ALLOWED set). Payloads are not validated (legacy tests send
//    partial rows). Customer/shop/others stay generic upserts.
//  * `putImage` (ImageUploadTransport): BE image PUT, idempotent by sha256;
//    sets `image_hash` = sha256 of the uploaded bytes.
//  * stock ops (`stock` entity, BE `stock_op`): `product_id`, `shop_id`,
//    `delta` (decimal string); add needs delta > 0, remove applies
//    -|delta|, adjust is signed; `count` uses `counted_quantity`;
//    `transfer` uses `product_id`, `from_shop`, `to_shop`, `quantity`.
//    Result entity_id is the product id; `stock_after` lists the levels
//    (3-decimal strings, "0" for a level that does not exist).
//  * stock feed rows are `ser_stock` (`id` = StockLevel UUID, product_id,
//    shop_id, quantity, updated_at), version 0 (StockLevel is unversioned).
//  * `sale.create` mirrors BE `sale_create` + `create_sale(accept_always)`:
//    OfflineSaleInputSerializer validation (items >= 1, quantity <= 3
//    decimals and >= 0.001, prices <= 2 decimals), total = sum(price * qty
//    - line discount), tax from the payload snapshot (half-up cents), net,
//    `payments` must sum to net within 0.01 else `validation_error`,
//    `items[].id` kept (reused id -> forbidden), stock decremented for
//    tracked product lines only (custom lines never), negative stock
//    accepted with `negative_stock`, `occurred_at` more than 7 days after
//    server time -> `occurred_at_suspect` (created_at = server time),
//    receipt `REC-YYYYMMDD-XXXXXXXX`. A sale id already known answers
//    `applied` with no stock_after. Feed/table rows are `ser_sale` shaped
//    (shop, customer, total_amount, net_amount, payments, items[].product,
//    ...), version 0 (Sale is unversioned); push results carry no version.
//    `sale.refund` (BE shape): `sale_id`, `reference`, `items:
//    [{sale_item_id, quantity}]`, `method`, `reason`, `occurred_at`. `sale.cancel`: entity_id is the sale.
//  * `inbound.create` mirrors BE `inbound_create` (stock increment,
//    `stock_after`, `ser_inbound` feed row, reference unique).
//  * [strictCatalog] (off by default for legacy tests): UUID ids, unknown
//    products/vendors rejected `not_found` for stock/inbound, unknown sale
//    product -> `product_missing` and no stock movement. Off, an unknown
//    product behaves like a tracked one.
//  * merge semantic (BE_GAPS 10): an update with a stale `base_version` still
//    applies and the result carries `merged: true` plus the final
//    `server_state` (warnings stay free of 'merged').
//  * `conflict_unique` results carry the conflicting row as `server_state`
//    (its `id` is the conflicting row id).
//  * push `next_cursor` is the server head. Engines must NOT adopt it as the
//    pull cursor: it can skip other devices' changes made before it.
//  * replaying a mutation_id: previously applied -> `duplicate`; previously
//    rejected -> re-evaluated (BE deviation 6; deterministic, so usually the
//    same rejection). [applied] keeps the LAST result of every mutation.
//  * fault knobs (down, failNextWith, latency, flakyRate, lostResponseRate,
//    dropResponseAfterApply, clockSkew) are PER VIEW; minAppVersion,
//    fullResyncRequired and capabilities are shared server state.
//  * Other entities (user, notification, ...) are generic upserts.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/transport/image_upload_transport.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';
import 'package:crypto/crypto.dart' as crypto;

const _scale = 6;
final BigInt _one = BigInt.from(10).pow(_scale);

BigInt _parseDec(Object? raw) {
  var s = '${raw ?? '0'}'.trim();
  if (!RegExp(r'^[+-]?(\d+(\.\d*)?|\.\d+)$').hasMatch(s)) {
    throw FormatException('Bad decimal: $raw');
  }
  final neg = s.startsWith('-');
  if (neg || s.startsWith('+')) s = s.substring(1);
  final parts = s.split('.');
  final frac = (parts.length > 1 ? parts[1] : '').padRight(_scale, '0');
  final v =
      BigInt.parse(parts[0].isEmpty ? '0' : parts[0]) * _one +
      BigInt.parse(frac.substring(0, _scale));
  return neg ? -v : v;
}

String _fmtDec(BigInt v) {
  final neg = v.isNegative;
  final a = v.abs();
  final whole = a ~/ _one;
  var frac = (a % _one).toString().padLeft(_scale, '0');
  frac = frac.replaceFirst(RegExp(r'0+$'), '');
  final body = frac.isEmpty ? '$whole' : '$whole.$frac';
  return neg && a != BigInt.zero ? '-$body' : body;
}

class _Core {
  final tables = <String, Map<String, Map<String, dynamic>>>{};
  final feed = <PullChange>[];
  final applied = <String, PushResult>{};
  final stock = <String, BigInt>{};
  final stockIds = <String, String>{};
  final saleItemIds = <String>{};
  final tombstones = <String, int>{};
  final refunded = <String, BigInt>{}; // sale|sale_item -> refunded qty
  final refundRefs = <String, String>{}; // sale|reference -> total
  int seq = 0;
  int receiptCounter = 0;
  bool strictCatalog = false;
  int? productLimit;
  int imageStores = 0;

  String? minAppVersion;
  bool fullResyncRequired = false;
  Set<String> capabilities = {};

  int bootstrapManifestCalls = 0;
  int bootstrapPageCalls = 0;
  final bootstrapServed = <String, int>{}; // entity -> pages served in a run
  Set<String>? bootstrapShops; // cashier scope: only these shops' rows
  List<String> bootstrapEntities = [
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
}

class FakeSyncServer implements SyncTransport, ImageUploadTransport {
  FakeSyncServer({
    String deviceId = 'device-1',
    int seed = 42,
    DateTime Function()? now,
  }) : this._(_Core(), deviceId, Random(seed), now ?? DateTime.now);

  FakeSyncServer._(this._c, this.deviceId, this.random, this.now);

  final _Core _c;
  final String deviceId;
  final DateTime Function() now;

  /// A view over the same data acting as another device. Fault knobs and
  /// clockSkew are independent per view.
  FakeSyncServer forDevice(String id, {int seed = 7}) =>
      FakeSyncServer._(_c, id, Random(seed), now);

  // ---- per-view fault knobs ----
  Duration latency = Duration.zero;
  bool down = false;
  int dropResponseAfterApply = 0;
  double flakyRate = 0;
  double lostResponseRate = 0;
  final Random random;
  String? failNextWith;
  Duration clockSkew = Duration.zero;

  /// Role of the user this view pushes as: `cashier` gets `forbidden` for
  /// every mutation outside the BE CASHIER_ALLOWED set and for image PUTs.
  String role = 'owner';

  /// The next N image PUTs store the image, then lose the response.
  int dropImageResponseAfterApply = 0;
  int imagePutCalls = 0;

  /// The next pull that reaches this view answers `full_resync_required`
  /// (once; the flag clears itself), like a cursor older than the BE's
  /// `pruned_through`.
  bool fullResyncOnce = false;

  DateTime get _serverTime => now().add(clockSkew).toUtc();

  // ---- observable state ----
  Map<String, Map<String, Map<String, dynamic>>> get tables => _c.tables;
  List<PullChange> get feed => _c.feed;
  Map<String, PushResult> get applied => _c.applied;

  /// Images actually stored by [putImage] (an idempotent replay is not).
  int get imageStores => _c.imageStores;

  /// Plan limit on active products (`limit_exceeded`); null = unlimited.
  int? get productLimit => _c.productLimit;
  set productLimit(int? v) => _c.productLimit = v;
  int get headSeq => _c.seq;

  /// Every StockLevel: `product|shop` -> quantity.
  Map<String, String> get stockLevels => {
    for (final e in _c.stock.entries) e.key: _fmtDec(e.value),
  };
  String stockQuantity(String productId, String shopId) =>
      _fmtDec(_c.stock['$productId|$shopId'] ?? BigInt.zero);

  // ---- shared server-level knobs ----
  String? get minAppVersion => _c.minAppVersion;
  set minAppVersion(String? v) => _c.minAppVersion = v;
  bool get fullResyncRequired => _c.fullResyncRequired;
  set fullResyncRequired(bool v) => _c.fullResyncRequired = v;
  Set<String> get capabilities => _c.capabilities;
  set capabilities(Set<String> v) => _c.capabilities = v;

  Future<void> _gate() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    final f = failNextWith;
    if (f != null) {
      failNextWith = null;
      final kind = SyncTransportKind.values.firstWhere(
        (k) => k.name == f,
        orElse: () => SyncTransportKind.server,
      );
      throw SyncTransportException(kind: kind, code: f);
    }
    if (down) {
      throw SyncTransportException(kind: SyncTransportKind.network);
    }
    if (flakyRate > 0 && random.nextDouble() < flakyRate) {
      throw SyncTransportException(
        kind: random.nextBool()
            ? SyncTransportKind.timeout
            : SyncTransportKind.network,
      );
    }
  }

  @override
  Future<PingResponse> ping() async {
    await _gate();
    return PingResponse(
      ok: true,
      serverTime: _serverTime,
      minAppVersion: _c.minAppVersion,
      capabilities: {..._c.capabilities},
    );
  }

  String _cursor(int seq) => base64Url.encode(utf8.encode('seq:$seq'));

  int _decode(String? cursor) {
    if (cursor == null || cursor.isEmpty) return 0;
    final s = utf8.decode(base64Url.decode(cursor));
    if (!s.startsWith('seq:')) throw FormatException('Bad cursor: $cursor');
    return int.parse(s.substring(4));
  }

  @override
  Future<PullResponse> pull({
    String? cursor,
    int limit = 500,
    required String scope,
  }) async {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit', 'must be > 0');
    await _gate();
    if (_c.fullResyncRequired || fullResyncOnce) {
      fullResyncOnce = false;
      return PullResponse(
        serverTime: _serverTime,
        changes: const [],
        nextCursor: _cursor(_c.seq),
        fullResyncRequired: true,
      );
    }
    final after = _decode(cursor);
    final newer = _c.feed.where((c) => c.seq > after).toList();
    final page = newer.take(limit).toList();
    return PullResponse(
      serverTime: _serverTime,
      changes: page,
      nextCursor: _cursor(page.isEmpty ? after : page.last.seq),
      hasMore: newer.length > page.length,
    );
  }

  // ---------------------------------------------------------- bootstrap

  /// Entities the manifest lists (cashier tests can drop vendor/inbound).
  List<String> get bootstrapEntities => _c.bootstrapEntities;
  set bootstrapEntities(List<String> v) => _c.bootstrapEntities = v;

  /// Cashier scope: when set, bootstrap pages serve only these shops and
  /// the rows of these shops (`shop` / `shop_id`; rows without a shop are
  /// served). Pull is not filtered.
  Set<String>? get bootstrapShops => _c.bootstrapShops;
  set bootstrapShops(Set<String>? v) => _c.bootstrapShops = v;

  int get bootstrapManifestCalls => _c.bootstrapManifestCalls;
  int get bootstrapPageCalls => _c.bootstrapPageCalls;

  /// Runs after a bootstrap page is built (so rows written here are NOT in
  /// that page nor any later page of the same snapshot). [pageIndex] is the
  /// 0-based index of the page just served for [entity].
  void Function(String entity, int pageIndex)? onBootstrapPage;

  /// Feed-shaped server row: stored in the entity table and emitted to the
  /// feed (so a row seeded after a snapshot is delivered by `pull`).
  void seedRow(String entity, Map<String, dynamic> row) {
    final id = row['id'] as String;
    final data = Map<String, dynamic>.from(row);
    final v = (data['version'] as int?) ?? 1;
    data['version'] = v;
    _c.tables.putIfAbsent(entity, () => {})[id] = data;
    _emit(entity, 'upsert', id, v, data, 'seed');
  }

  int _lastSeq(String entity, String id) {
    for (var i = _c.feed.length - 1; i >= 0; i--) {
      final c = _c.feed[i];
      if (c.entity == entity && c.id == id) return c.seq;
    }
    return 0;
  }

  Map<String, Map<String, dynamic>> _bootstrapRows(String entity) {
    final shops = _c.bootstrapShops;
    final all = _allBootstrapRows(entity);
    if (shops == null) return all;
    bool visible(Map<String, dynamic> r) {
      if (entity == 'shop') return shops.contains(r['id']);
      final s = r['shop'] ?? r['shop_id'];
      return s == null || shops.contains(s);
    }

    return {
      for (final e in all.entries)
        if (visible(e.value)) e.key: e.value,
    };
  }

  Map<String, Map<String, dynamic>> _allBootstrapRows(String entity) {
    if (entity == 'stock') {
      return {
        for (final e in _c.stock.entries)
          _c.stockIds[e.key]!: {
            'id': _c.stockIds[e.key],
            'product_id': e.key.split('|')[0],
            'shop_id': e.key.split('|')[1],
            'quantity': _fixed(e.value, 3),
            'updated_at': _iso(_serverTime),
          },
      };
    }
    return _c.tables[entity] ?? const {};
  }

  @override
  Future<BootstrapManifest> bootstrapManifest({required String scope}) async {
    await _gate();
    _c.bootstrapManifestCalls++;
    _c.bootstrapServed.clear();
    return BootstrapManifest(
      serverTime: _serverTime,
      entities: [..._c.bootstrapEntities],
      snapshotCursor: _cursor(_c.seq),
    );
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
    if (limit <= 0) throw ArgumentError.value(limit, 'limit', 'must be > 0');
    await _gate();
    _c.bootstrapPageCalls++;
    final snapshot = snapshotCursor ?? _cursor(_c.seq);
    final snapSeq = _decode(snapshot);
    final after = (pageCursor == null || pageCursor.isEmpty)
        ? null
        : utf8.decode(base64Url.decode(pageCursor));
    final rows = _bootstrapRows(entity);
    final ids = rows.keys.where((id) {
      if (after != null && id.compareTo(after) <= 0) return false;
      // Written after the snapshot: `pull(snapshot)` delivers it instead.
      return _lastSeq(entity, id) <= snapSeq;
    }).toList()..sort();
    final page = ids.take(limit).toList();
    final more = ids.length > page.length;
    final index = after == null ? 0 : (_c.bootstrapServed[entity] ?? 0);
    _c.bootstrapServed[entity] = index + 1;
    final result = BootstrapPage(
      serverTime: _serverTime,
      entity: entity,
      snapshotCursor: snapshot,
      items: [for (final id in page) Map<String, dynamic>.from(rows[id]!)],
      hasMore: more,
      nextPageCursor: more ? base64Url.encode(utf8.encode(page.last)) : null,
    );
    onBootstrapPage?.call(entity, index);
    return result;
  }

  @override
  Future<PushResponse> push({
    required String deviceId,
    required String appVersion,
    required List<OutboxEntry> mutations,
    required String scope,
  }) async {
    await _gate();
    final order = List.generate(mutations.length, (i) => i)
      ..sort((a, b) {
        final c = (mutations[a].seq ?? 0).compareTo(mutations[b].seq ?? 0);
        return c != 0 ? c : a.compareTo(b);
      });
    final results = <PushResult>[];
    final failed = <String>{}; // BE failed_ids: this push only
    for (final i in order) {
      results.add(_applyOne(mutations[i], deviceId, failed));
    }
    if (dropResponseAfterApply > 0) {
      dropResponseAfterApply--;
      throw SyncTransportException(kind: SyncTransportKind.timeout);
    }
    if (lostResponseRate > 0 && random.nextDouble() < lostResponseRate) {
      throw SyncTransportException(kind: SyncTransportKind.timeout);
    }
    return PushResponse(
      serverTime: _serverTime,
      results: results,
      nextCursor: _cursor(_c.seq),
    );
  }

  // ---------------------------------------------------------------- apply

  PushResult _applyOne(OutboxEntry e, String device, Set<String> failed) {
    final stored = _c.applied[e.mutationId];
    if (stored != null && stored.status == PushStatus.applied) {
      return PushResult(
        mutationId: stored.mutationId,
        status: PushStatus.duplicate,
        entityId: stored.entityId,
        version: stored.version,
        serverSeq: stored.serverSeq,
        code: stored.code,
        message: stored.message,
        serverState: stored.serverState,
        warnings: stored.warnings,
        stockAfter: stored.stockAfter,
        merged: stored.merged,
        receiptNumber: stored.receiptNumber,
        conflictEntityId: stored.conflictEntityId,
        dependsOn: stored.dependsOn,
        errors: stored.errors,
        inviteSent: stored.inviteSent,
        refundReference: stored.refundReference,
        refundTotal: stored.refundTotal,
        occurredAtSuspect: stored.occurredAtSuspect,
        extra: stored.extra,
      );
    }
    // Never applied (or rejected before: re-evaluated, BE deviation 6).
    PushResult result;
    try {
      result = _dispatch(e, device, failed);
    } catch (err) {
      result = _reject(e, 'validation_error', 'Malformed payload: $err');
    }
    if (result.status == PushStatus.rejected) failed.add(e.entityId);
    if (result.status != PushStatus.retry) {
      _c.applied[e.mutationId] = result;
    }
    return result;
  }

  PushResult _reject(
    OutboxEntry e,
    String code,
    String msg, {
    Map<String, dynamic>? state,
    PushStatus status = PushStatus.rejected,
    String? conflictEntityId,
    List<String> dependsOn = const [],
    Map<String, dynamic>? errors,
  }) => PushResult(
    mutationId: e.mutationId,
    status: status,
    entityId: e.entityId,
    code: code,
    message: msg,
    serverState: state,
    conflictEntityId: conflictEntityId,
    dependsOn: dependsOn,
    errors: errors,
  );

  /// BE `handlers.dependencies(m)`: entity ids this mutation needs.
  static List<String> _deps(OutboxEntry e) {
    final p = e.payload;
    String? s(Object? v) => v is String && v.isNotEmpty ? v : null;
    final deps = <String?>[];
    if (e.op == 'update' || e.op == 'delete') deps.add(e.entityId);
    final items = p['items'] is List ? p['items'] as List : const [];
    Iterable<String?> itemProducts() =>
        items.map((it) => it is Map ? s(it['product_id']) : null);
    if (e.entity == 'sale' && e.op == 'create') {
      deps
        ..addAll(itemProducts())
        ..add(s(p['customer']))
        ..add(s(p['shop']));
    } else if (e.entity == 'sale') {
      deps.add(s(p['sale_id']) ?? e.entityId);
    } else if (e.entity == 'stock') {
      for (final k in const ['product_id', 'shop_id', 'from_shop', 'to_shop']) {
        deps.add(s(p[k]));
      }
    } else if (e.entity == 'inbound') {
      deps
        ..addAll(itemProducts())
        ..add(s(p['vendor_id']))
        ..add(s(p['shop_id']));
    } else if (e.entity == 'user' && e.op == 'create') {
      deps.add(s(p['default_shop_id']));
    } else if (e.entity == 'product') {
      deps.add(s(p['category']));
    }
    return deps.whereType<String>().toList();
  }

  /// BE handlers.CASHIER_ALLOWED.
  static const _cashierAllowed = {
    'sale.create',
    'sale.refund',
    'sale.cancel',
    'customer.create',
    'customer.update',
    'stock.add',
    'stock.remove',
    'stock.adjust',
    'notification.mark_read',
    'notification.mark_all_read',
  };

  PushResult _dispatch(OutboxEntry e, String device, Set<String> failed) {
    if (role == 'cashier' && !_cashierAllowed.contains('${e.entity}.${e.op}')) {
      return _reject(
        e,
        'forbidden',
        'You do not have permission for this action.',
      );
    }
    for (final d in _deps(e)) {
      if (failed.contains(d)) {
        return _reject(
          e,
          'dependency_failed',
          'A mutation this one depends on was rejected.',
          dependsOn: [d],
        );
      }
    }
    switch (e.entity) {
      case 'stock':
        return _stockOp(e, device);
      case 'sale':
        return _saleOp(e, device);
      case 'inbound' when e.op == 'create':
        return _inboundCreate(e, device);
      case 'category' || 'product' || 'vendor':
        return _catalogOp(e, device);
      default:
        return _rowOp(e, device);
    }
  }

  int _emit(
    String entity,
    String op,
    String id,
    int? version,
    Map<String, dynamic>? data,
    String device,
  ) {
    final seq = ++_c.seq;
    _c.feed.add(
      PullChange(
        seq: seq,
        entity: entity,
        op: op,
        id: id,
        version: version,
        data: data == null ? null : Map<String, dynamic>.from(data),
        originDeviceId: device,
      ),
    );
    return seq;
  }

  PushResult _rowOp(OutboxEntry e, String device) {
    final table = _c.tables.putIfAbsent(e.entity, () => {});
    final key = '${e.entity}/${e.entityId}';
    final existing = table[e.entityId];
    if (e.op == 'delete') {
      if (existing == null) {
        return _c.tombstones.containsKey(key)
            ? _reject(e, 'entity_deleted', 'Already deleted')
            : _reject(e, 'not_found', 'Unknown ${e.entity}');
      }
      final v = (existing['version'] as int) + 1;
      table.remove(e.entityId);
      _c.tombstones[key] = v;
      final s = _emit(e.entity, 'delete', e.entityId, v, null, device);
      return PushResult(
        mutationId: e.mutationId,
        status: PushStatus.applied,
        entityId: e.entityId,
        version: v,
        serverSeq: s,
      );
    }
    if (e.op == 'update' && existing == null) {
      return _c.tombstones.containsKey(key)
          ? _reject(e, 'entity_deleted', 'Row was deleted')
          : _reject(e, 'not_found', 'Unknown ${e.entity}');
    }
    final stale =
        e.op == 'update' &&
        e.baseVersion != null &&
        e.baseVersion != existing!['version'];
    final row = existing ?? <String, dynamic>{'id': e.entityId};
    row.addAll(e.payload);
    row['id'] = e.entityId;
    row['version'] = ((existing?['version'] as int?) ?? 0) + 1;
    table[e.entityId] = row;
    _c.tombstones.remove(key);
    final s = _emit(
      e.entity,
      'upsert',
      e.entityId,
      row['version'] as int,
      row,
      device,
    );
    return PushResult(
      mutationId: e.mutationId,
      status: PushStatus.applied,
      entityId: e.entityId,
      version: row['version'] as int,
      serverSeq: s,
      serverState: stale ? Map<String, dynamic>.from(row) : null,
      merged: stale,
    );
  }

  // ------------------------------------------------------------ catalog ops

  /// BE `STRIP`: payload keys a sync mutation can never set.
  static const _strip = {
    'id',
    'version',
    'loyalty_points',
    'image_pending',
    'image_upload',
    'thumbnail',
    'image',
    'tenant',
  };

  /// BE `_unique_conflict`: (field, conflicting row) or null. Every row of
  /// the tenant counts, inactive and tombstoned ones too. A category's
  /// parent is the payload's, else (update) the row's own (the BE reads only
  /// the payload, see the Task 5 report).
  (String, Map<String, dynamic>)? _uniqueClash(
    String entity,
    Map<String, dynamic> p, {
    String? exclude,
    Map<String, dynamic>? existing,
  }) {
    final rows = (_c.tables[entity] ?? const {}).values;
    Map<String, dynamic>? first(bool Function(Map<String, dynamic> r) f) {
      for (final r in rows) {
        if (r['id'] != exclude && f(r)) return r;
      }
      return null;
    }

    String t(Object? v) => v is String ? v.trim() : '';
    switch (entity) {
      case 'product':
        for (final f in const ['sku', 'barcode']) {
          final v = t(p[f]);
          if (v.isEmpty) continue;
          final r = first((r) => t(r[f]) == v);
          if (r != null) return (f, r);
        }
      case 'vendor':
        final v = t(p['name']).toLowerCase();
        if (v.isEmpty) return null;
        final r = first((r) => t(r['name']).toLowerCase() == v);
        if (r != null) return ('name', r);
      case 'category':
        final name = p['name'];
        if (name is! String || name.isEmpty) return null;
        final parent = p.containsKey('parent')
            ? p['parent']
            : existing?['parent'];
        final r = first((r) => r['name'] == name && r['parent'] == parent);
        if (r != null) return ('name', r);
    }
    return null;
  }

  PushResult _conflictUnique(
    OutboxEntry e,
    String field,
    Map<String, dynamic> row,
  ) => _reject(
    e,
    'conflict_unique',
    'Another ${e.entity} already uses this $field.',
    state: Map<String, dynamic>.from(row),
    conflictEntityId: row['id'] as String?,
    errors: {
      field: ['Already exists.'],
    },
  );

  /// BE `catalog_create` / `catalog_update` / `catalog_delete`.
  PushResult _catalogOp(OutboxEntry e, String device) {
    final table = _c.tables.putIfAbsent(e.entity, () => {});
    final key = '${e.entity}/${e.entityId}';
    final existing = table[e.entityId];
    final tombstoned = _c.tombstones.containsKey(key);
    final payload = <String, dynamic>{
      for (final en in e.payload.entries)
        if (!_strip.contains(en.key)) en.key: en.value,
    };
    PushResult applied(int version, int? seq, {Map<String, dynamic>? state}) =>
        PushResult(
          mutationId: e.mutationId,
          status: PushStatus.applied,
          entityId: e.entityId,
          version: version,
          serverSeq: seq,
          serverState: state,
          merged: state != null,
        );
    switch (e.op) {
      case 'create':
        if (existing != null) {
          return _reject(
            e,
            'conflict_unique',
            'Entity already exists.',
            state: Map<String, dynamic>.from(existing),
            conflictEntityId: e.entityId,
          );
        }
        final clash = _uniqueClash(e.entity, payload);
        if (clash != null) return _conflictUnique(e, clash.$1, clash.$2);
        final limit = _c.productLimit;
        if (e.entity == 'product' && limit != null) {
          final active = table.values.where((r) => r['is_active'] != false);
          if (active.length >= limit) {
            return _reject(e, 'limit_exceeded', 'Plan allows $limit products.');
          }
        }
        final row = <String, dynamic>{
          'id': e.entityId,
          'is_active': true,
          ...payload,
          'version': 1,
        };
        table[e.entityId] = row;
        final s = _emit(e.entity, 'upsert', e.entityId, 1, row, device);
        return applied(1, s);
      case 'update':
        if (existing == null) {
          return tombstoned
              ? _reject(e, 'entity_deleted', 'The record was deleted.')
              : _reject(e, 'not_found', 'Record not found.');
        }
        if (tombstoned) {
          return _reject(
            e,
            'entity_deleted',
            'The record was deleted.',
            state: Map<String, dynamic>.from(existing),
          );
        }
        final clash = _uniqueClash(
          e.entity,
          payload,
          exclude: e.entityId,
          existing: existing,
        );
        if (clash != null) return _conflictUnique(e, clash.$1, clash.$2);
        final stale =
            e.baseVersion != null && e.baseVersion != existing['version'];
        existing.addAll(payload);
        final v = (existing['version'] as int) + 1;
        existing['version'] = v;
        final s = _emit(e.entity, 'upsert', e.entityId, v, existing, device);
        return applied(
          v,
          s,
          state: stale ? Map<String, dynamic>.from(existing) : null,
        );
      case 'delete':
        if (existing == null) {
          return _reject(e, 'not_found', 'Record not found.');
        }
        if (tombstoned) {
          // Already deleted: idempotent, no new change row.
          return applied(existing['version'] as int, null);
        }
        if (existing['is_active'] != false) {
          existing['is_active'] = false;
          existing['version'] = (existing['version'] as int) + 1;
        }
        final v = existing['version'] as int;
        _c.tombstones[key] = v;
        final s = _emit(e.entity, 'delete', e.entityId, v, null, device);
        return applied(v, s);
      default:
        return _reject(
          e,
          'validation_error',
          'Unsupported mutation ${e.entity}.${e.op}.',
        );
    }
  }

  // ------------------------------------------------------------ images

  /// BE `_ImagePutView.put` + `set_entity_image`: same bytes -> no-op
  /// (`unchanged`), else store, bump `version` and emit a feed row whose
  /// `image_hash` is the sha256 of the uploaded bytes.
  @override
  Future<ImageUploadResult> putImage({
    required String entity,
    required String entityId,
    required List<int> bytes,
    required String sha256,
    required String scope,
  }) async {
    await _gate();
    imagePutCalls++;
    if (entity != 'product' && entity != 'category') {
      throw ArgumentError.value(entity, 'entity', 'product or category');
    }
    SyncTransportException fail(int status, String code, String msg) =>
        SyncTransportException(
          kind: SyncTransportKind.server,
          httpStatus: status,
          code: code,
          message: msg,
        );
    if (role == 'cashier') {
      throw fail(403, 'forbidden', 'You do not have permission.');
    }
    final row = _c.tables[entity]?[entityId];
    if (row == null) throw fail(404, 'not_found', 'Not found.');
    final digest = crypto.sha256.convert(bytes).toString();
    if (sha256.toLowerCase() != digest) {
      throw fail(400, 'hash_mismatch', 'Uploaded bytes do not match.');
    }
    final unchanged = row['image_hash'] == digest && row['image'] != null;
    if (!unchanged) {
      final tag = digest.substring(0, 12);
      final base = 'https://fake.local/media/$entity/$entityId';
      row['image'] = '$base/full.webp?v=$tag';
      row['thumbnail_url'] = '$base/thumb.webp?v=$tag';
      row['image_hash'] = digest;
      row['image_bytes'] = bytes.length;
      row['thumbnail_bytes'] = (bytes.length ~/ 4) + 1;
      final v = ((row['version'] as int?) ?? 0) + 1;
      row['version'] = v;
      _emit(entity, 'upsert', entityId, v, row, 'image');
      _c.imageStores++;
    }
    if (dropImageResponseAfterApply > 0) {
      dropImageResponseAfterApply--;
      throw SyncTransportException(kind: SyncTransportKind.timeout);
    }
    return ImageUploadResult(
      entityId: entityId,
      imageHash: digest,
      image: row['image'] as String?,
      thumbnailUrl: row['thumbnail_url'] as String?,
      version: row['version'] as int?,
      imageBytes: row['image_bytes'] as int?,
      thumbnailBytes: row['thumbnail_bytes'] as int?,
      unchanged: unchanged,
    );
  }

  // ------------------------------------------------------------ catalog

  /// Mirrors the BE's catalog checks (apps/sync/handlers.py): with
  /// [strictCatalog], stock ops / inbound on an unknown product are rejected
  /// `not_found`, a sale line of an unknown product is accepted with a
  /// `product_missing` warning and NO stock movement, ids must be UUIDs, and
  /// an unknown sale customer warns `customer_missing`. Off (default, legacy
  /// tests), unknown products behave like tracked ones.
  bool get strictCatalog => _c.strictCatalog;
  set strictCatalog(bool v) => _c.strictCatalog = v;

  /// Server-side catalog row (what the bootstrap would have downloaded).
  void seedProduct(
    String id, {
    String name = '',
    String price = '0',
    String? costPrice,
    bool trackInventory = true,
    bool isActive = true,
  }) {
    _c.tables.putIfAbsent('product', () => {})[id] = {
      'id': id,
      'version': 1,
      'name': name,
      'price': price,
      'cost_price': costPrice,
      'track_inventory': trackInventory,
      'is_active': isActive,
    };
  }

  void seedVendor(String id) =>
      _c.tables.putIfAbsent('vendor', () => {})[id] = {'id': id, 'version': 1};

  void seedCustomer(String id) =>
      _c.tables.putIfAbsent('customer', () => {})[id] = {
        'id': id,
        'version': 1,
      };

  /// Existing StockLevel (bootstrap state, no feed row).
  void seedStock(String productId, String shopId, String quantity) {
    _c.stock['$productId|$shopId'] = _parseDec(quantity);
    _stockId(productId, shopId);
  }

  /// StockLevel id of (product, shop), as the stock feed rows carry it.
  String stockLevelId(String productId, String shopId) =>
      _stockId(productId, shopId);

  bool _productKnown(String id) =>
      (_c.tables['product'] ?? const {}).containsKey(id);

  // ------------------------------------------------------------ decimals

  static final _decRe = RegExp(r'^[+-]?(\d+(\.\d*)?|\.\d+)$');

  /// Decimal places of a wire decimal (DRF DecimalField counts trailing
  /// zeros: '1.5000' has 4).
  static int _places(Object? raw) {
    final s = '$raw'.trim();
    if (!_decRe.hasMatch(s)) throw FormatException('Bad decimal: $raw');
    final i = s.indexOf('.');
    return i < 0 ? 0 : s.length - i - 1;
  }

  /// DRF `DecimalField(decimal_places: dp)` + optional min value.
  static BigInt _field(Object? raw, int dp, {BigInt? min}) {
    if (raw is! String && raw is! num) throw FormatException('Bad: $raw');
    if (_places(raw) > dp) throw FormatException('Too many decimals: $raw');
    final v = _parseDec(raw);
    if (min != null && v < min) throw FormatException('Too small: $raw');
    return v;
  }

  /// round(num / den) half away from zero (Python ROUND_HALF_UP, Postgres
  /// numeric rounding). [den] > 0.
  static BigInt _divHalfUp(BigInt num, BigInt den) {
    final neg = num.isNegative;
    final a = num.abs();
    var q = a ~/ den;
    if ((a % den) * BigInt.two >= den) q += BigInt.one;
    return neg ? -q : q;
  }

  /// Scale-6 units -> fixed string with [dp] decimals (half up), like a
  /// Django DecimalField(decimal_places: dp) read back from Postgres.
  static String _fixed(BigInt units6, int dp) {
    final p = BigInt.from(10).pow(_scale - dp);
    final r = _divHalfUp(units6, p);
    final neg = r.isNegative;
    final a = r.abs();
    final base = BigInt.from(10).pow(dp);
    final body = dp == 0
        ? '$a'
        : '${a ~/ base}.${(a % base).toString().padLeft(dp, '0')}';
    return neg && a != BigInt.zero ? '-$body' : body;
  }

  static BigInt _cents6(BigInt cents) =>
      cents * BigInt.from(10).pow(_scale - 2);

  static final _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}$',
  );

  void _uuid(Object? v, String field) {
    if (!_c.strictCatalog) return;
    if (v is! String || !_uuidRe.hasMatch(v)) {
      throw FormatException('$field is not a UUID: $v');
    }
  }

  String _iso(DateTime t) => t.toUtc().toIso8601String();

  // ------------------------------------------------------------ stock

  /// BE `_stock_after`: sorted unique (product, shop); a missing StockLevel
  /// reads "0", an existing one its 3-decimal DB value.
  List<StockAfter> _stockAfter(Iterable<(String, String)> pairs) {
    final keys = {for (final (p, s) in pairs) '$p|$s'}.toList()..sort();
    return [
      for (final k in keys)
        StockAfter(
          productId: k.substring(0, k.indexOf('|')),
          shopId: k.substring(k.indexOf('|') + 1),
          quantity: _c.stock.containsKey(k) ? _fixed(_c.stock[k]!, 3) : '0',
        ),
    ];
  }

  static List<String> _negativeWarning(List<StockAfter> after) => [
    if (after.any((a) => _parseDec(a.quantity).isNegative)) 'negative_stock',
  ];

  /// Moves (product, shop) by [delta] (get_or_create the level first) and
  /// emits a `ser_stock` change (StockLevel is unversioned: version 0).
  /// Returns the change seq, or null when nothing was saved.
  int? _moveStock(String product, String shop, BigInt delta, String device) {
    final k = '$product|$shop';
    final created = !_c.stock.containsKey(k);
    if (!created && delta == BigInt.zero) return null;
    final q = (_c.stock[k] ?? BigInt.zero) + delta;
    _c.stock[k] = q;
    return _emit('stock', 'upsert', _stockId(product, shop), 0, {
      'id': _stockId(product, shop),
      'product_id': product,
      'shop_id': shop,
      'quantity': _fixed(q, 3),
      'updated_at': _iso(_serverTime),
    }, device);
  }

  /// Stable StockLevel-style UUID per (product, shop), like the BE feed id.
  String _stockId(String product, String shop) =>
      _c.stockIds.putIfAbsent('$product|$shop', () {
        final n = (_c.stockIds.length + 1).toRadixString(16).padLeft(12, '0');
        return '5a0c0000-0000-4000-8000-$n';
      });

  /// BE `stock_op`: add (delta > 0), remove (-|delta|), adjust (signed),
  /// count, transfer. Result `entity_id` is the PRODUCT id.
  PushResult _stockOp(OutboxEntry e, String device) {
    final p = e.payload;
    // Parse/validate everything before mutating anything.
    final String prod;
    final List<(String, String, BigInt)> steps;
    try {
      prod = p['product_id'] as String;
      _uuid(prod, 'product_id');
      switch (e.op) {
        case 'transfer':
          final q = _parseDec(p['quantity']);
          final from = p['from_shop'] as String;
          final to = p['to_shop'] as String;
          if (q <= BigInt.zero || from == to) {
            return _reject(
              e,
              'validation_error',
              'Transfer needs a positive quantity and two different shops.',
            );
          }
          steps = [(prod, from, -q), (prod, to, q)];
        case 'count':
          final shop = p['shop_id'] as String;
          final cur = _c.stock['$prod|$shop'] ?? BigInt.zero;
          steps = [(prod, shop, _parseDec(p['counted_quantity']) - cur)];
        case 'add' || 'remove' || 'adjust':
          final shop = p['shop_id'] as String;
          _uuid(shop, 'shop_id');
          var d = _parseDec(p['delta']);
          if (e.op == 'add' && d <= BigInt.zero) {
            return _reject(
              e,
              'validation_error',
              'add needs a positive delta.',
            );
          }
          if (e.op == 'remove') d = -d.abs();
          steps = [(prod, shop, d)];
        default:
          return _reject(
            e,
            'validation_error',
            'Unsupported mutation stock.${e.op}.',
          );
      }
    } catch (_) {
      return _reject(e, 'validation_error', 'Bad stock payload');
    }
    if (_c.strictCatalog && !_productKnown(prod)) {
      return _reject(e, 'not_found', 'Product not found.');
    }
    int? seq;
    for (final (pr, shop, d) in steps) {
      seq = _moveStock(pr, shop, d, device) ?? seq;
    }
    final after = _stockAfter([for (final (pr, s, _) in steps) (pr, s)]);
    return PushResult(
      mutationId: e.mutationId,
      status: PushStatus.applied,
      entityId: prod,
      serverSeq: seq,
      warnings: _negativeWarning(after),
      stockAfter: after,
    );
  }

  // ------------------------------------------------------------ sales

  static const _paymentMethods = {
    'cash',
    'bankak',
    'card',
    'bank_transfer',
    'mobile_wallet',
    'loyalty_points',
    'split',
    'credit',
  };

  PushResult _saleOp(OutboxEntry e, String device) {
    switch (e.op) {
      case 'create':
        return _saleCreate(e, device);
      case 'refund':
        return _saleRefund(e, device);
      case 'cancel':
        return _saleCancel(e, device);
      default:
        return _reject(e, 'validation_error', 'Unknown sale op ${e.op}');
    }
  }

  /// BE `sale_create` + `create_sale(accept_always=True)`: never refused for
  /// stock/product state; refused only for malformed input, a payments sum
  /// off by more than 0.01 from the net, or reused line ids.
  PushResult _saleCreate(OutboxEntry e, String device) {
    final p = e.payload;
    final table = _c.tables.putIfAbsent('sale', () => {});

    // ---- OfflineSaleInputSerializer ----
    final String shop;
    final String method;
    final BigInt saleDiscount;
    final lines = <_SaleLineIn>[];
    try {
      _uuid(e.entityId, 'entity_id');
      shop = p['shop'] as String;
      _uuid(shop, 'shop');
      method = (p['payment_method'] as String?) ?? 'cash';
      if (!_paymentMethods.contains(method)) {
        throw FormatException('payment_method $method');
      }
      saleDiscount = p['discount_amount'] == null
          ? BigInt.zero
          : _field(p['discount_amount'], 2);
      final items = p['items'] as List;
      if (items.isEmpty) throw const FormatException('items: min 1');
      for (final raw in items) {
        final it = Map<String, dynamic>.from(raw as Map);
        final pid = it['product_id'];
        if (pid != null) _uuid(pid, 'items.product_id');
        if (it['id'] != null) _uuid(it['id'], 'items.id');
        lines.add(
          _SaleLineIn(
            id: it['id'] as String?,
            productId: pid as String?,
            custom: it['custom'] == true,
            note: (it['note'] as String?) ?? '',
            quantity: _field(it['quantity'], 3, min: BigInt.from(1000)),
            unitPrice: it['unit_price'] == null
                ? null
                : _field(it['unit_price'], 2, min: BigInt.zero),
            discount: it['discount'] == null
                ? BigInt.zero
                : _field(it['discount'], 2),
            unitCost: it['unit_cost'] == null
                ? null
                : _parseDec(it['unit_cost']),
            productName: (it['product_name'] as String?) ?? '',
          ),
        );
      }
    } catch (err) {
      return _reject(e, 'validation_error', 'Invalid sale: $err');
    }

    final existing = table[e.entityId];
    if (existing != null) {
      // Same sale already created under another mutation: idempotent,
      // `applied` with no stock_after (BE handler early return).
      return PushResult(
        mutationId: e.mutationId,
        status: PushStatus.applied,
        entityId: e.entityId,
        receiptNumber: existing['receipt_number'] as String?,
      );
    }

    final warnings = <String>[];
    final cust = p['customer'] ?? p['customer_id'];
    var customer = cust is String ? cust : null;
    if (customer != null &&
        (_c.tombstones.containsKey('customer/$customer') ||
            (_c.strictCatalog &&
                !(_c.tables['customer'] ?? const {}).containsKey(customer)))) {
      warnings.add('customer_missing');
      customer = null;
    }

    final hasTax = ['tax_rate', 'tax_inclusive', 'tax_name'].any(p.containsKey);
    final BigInt rate;
    final bool inclusive;
    try {
      rate = hasTax ? _parseDec(p['tax_rate'] ?? '0') : BigInt.zero;
    } catch (err) {
      return _reject(e, 'validation_error', 'tax_rate: $err');
    }
    inclusive = hasTax && p['tax_inclusive'] == true;

    final payments = <(String, BigInt)>[];
    final rawPayments = p['payments'];
    if (rawPayments is List && rawPayments.isNotEmpty) {
      for (final part in rawPayments) {
        final m = part as Map;
        if (!_paymentMethods.contains(m['method'])) {
          return _reject(e, 'validation_error', 'Unknown payment method.');
        }
        try {
          payments.add((m['method'] as String, _parseDec(m['amount'])));
        } catch (_) {
          return _reject(e, 'validation_error', 'payments.amount');
        }
      }
    }

    final ids = [for (final l in lines) ?l.id];
    if (ids.toSet().length != ids.length) {
      return _reject(e, 'validation_error', 'Duplicate line ids.');
    }
    if (ids.any(_c.saleItemIds.contains)) {
      return _reject(e, 'forbidden', 'Line id is not available.');
    }

    // ---- create_sale ----
    final products = _c.tables['product'] ?? const {};
    var total = BigInt.zero;
    final out = <Map<String, dynamic>>[];
    final moves = <(String, BigInt)>[];
    for (final l in lines) {
      if (l.custom || l.productId == null) {
        if (!l.custom || l.unitPrice == null || l.unitPrice! <= BigInt.zero) {
          return _reject(
            e,
            'validation_error',
            'A custom amount needs a unit price greater than 0.',
          );
        }
        final sub = l.unitPrice! * l.quantity ~/ _one - l.discount;
        total += sub;
        out.add(
          _saleItemRow(
            l,
            '${e.entityId}-i${out.length}',
            null,
            '',
            null,
            l.unitPrice!,
            sub,
          ),
        );
        continue;
      }
      final prod = products[l.productId];
      final phantom = prod == null && !_c.strictCatalog;
      final price =
          l.unitPrice ??
          (prod == null ? BigInt.zero : _parseDec(prod['price'] ?? '0'));
      final sub = price * l.quantity ~/ _one - l.discount;
      total += sub;
      if (prod == null && !phantom) {
        warnings.add('product_missing');
      } else if (prod != null && prod['is_active'] == false) {
        warnings.add('product_inactive');
      }
      final cost =
          l.unitCost ??
          (prod?['cost_price'] == null ? null : _parseDec(prod!['cost_price']));
      final name = prod != null ? '${prod['name'] ?? ''}' : l.productName;
      out.add(
        _saleItemRow(
          l,
          '${e.entityId}-i${out.length}',
          prod == null && !phantom ? null : l.productId,
          name,
          cost,
          price,
          sub,
        ),
      );
      if (prod == null && !phantom) continue; // no product: no stock
      final tracked =
          phantom ||
          prod!['track_inventory'] != false ||
          _c.stock.containsKey('${l.productId}|$shop');
      if (tracked) moves.add((l.productId!, l.quantity));
    }

    final taxable = total - saleDiscount;
    BigInt taxAmount;
    BigInt net;
    if (rate > BigInt.zero) {
      final hundred = BigInt.from(100) * _one;
      if (inclusive) {
        // tax = taxable - taxable / (1 + rate/100), quantized half up.
        taxAmount = _cents6(
          _divHalfUp(
            taxable * rate * BigInt.from(100),
            (hundred + rate) * _one,
          ),
        );
        net = _cents6(_divHalfUp(taxable * BigInt.from(100), _one));
      } else {
        taxAmount = _cents6(
          _divHalfUp(taxable * rate * BigInt.from(100), hundred * _one),
        );
        net = _cents6(
          _divHalfUp(
            (taxable * hundred + taxable * rate) * BigInt.from(100),
            hundred * _one,
          ),
        );
      }
    } else {
      taxAmount = BigInt.zero;
      net = taxable; // unquantized, like the BE
    }

    final paymentRows = <(String, BigInt)>[];
    if (payments.isNotEmpty) {
      final paid = payments.fold(BigInt.zero, (a, x) => a + x.$2);
      if ((paid - net).abs() > _one ~/ BigInt.from(100)) {
        return _reject(
          e,
          'validation_error',
          'Payment parts (${_fmtDec(paid)}) do not add up to the sale total '
              '(${_fmtDec(net)}).',
        );
      }
      paymentRows.addAll(payments);
    } else if (method != 'split') {
      paymentRows.add((method, net));
    }

    final now = _serverTime;
    final occurredRaw = p['occurred_at'];
    final occurred = occurredRaw is String
        ? DateTime.tryParse(occurredRaw)?.toUtc()
        : null;
    final suspect =
        occurred != null && occurred.isAfter(now.add(const Duration(days: 7)));
    if (suspect) warnings.add('occurred_at_suspect');
    final createdAt = occurred != null && !suspect ? occurred : now;
    final d = now;
    final receipt =
        'REC-${d.year}${'${d.month}'.padLeft(2, '0')}'
        '${'${d.day}'.padLeft(2, '0')}-'
        '${(++_c.receiptCounter).toRadixString(16).toUpperCase().padLeft(8, '0')}';

    // Items in BE lock order (product id; custom lines first).
    out.sort(
      (a, b) => '${a['product'] ?? ''}'.compareTo('${b['product'] ?? ''}'),
    );
    for (final it in out) {
      _c.saleItemIds.add(it['id'] as String);
    }
    final row = <String, dynamic>{
      'id': e.entityId,
      'shop': shop,
      'cashier': p['cashier'],
      'customer': customer,
      'receipt_number': receipt,
      'local_receipt_number': p['local_receipt_number'] ?? '',
      'client_sale_id': e.entityId,
      'device_id': p['device_id'] ?? device,
      'total_amount': _fixed(total, 2),
      'discount_amount': _fixed(saleDiscount, 2),
      'tax_amount': _fixed(taxAmount, 2),
      'tax_rate': _fixed(rate, 2),
      'tax_inclusive': inclusive,
      'tax_name': hasTax ? '${p['tax_name'] ?? ''}' : '',
      'net_amount': _fixed(net, 2),
      'payment_method': method,
      'bankak_account_snapshot': '',
      'status': 'completed',
      'notes': p['notes'] ?? '',
      'occurred_at': occurred == null ? null : _iso(occurred),
      'received_at': _iso(now),
      'occurred_at_suspect': suspect,
      'created_at': _iso(createdAt),
      'updated_at': _iso(now),
      'refunded_amount': '0',
      'payments': [
        for (final (m, a) in paymentRows) {'method': m, 'amount': _fixed(a, 2)},
      ],
      'items': out,
    };
    table[e.entityId] = row;
    var seq = _emit('sale', 'upsert', e.entityId, 0, row, device);
    for (final (pid, q) in moves) {
      seq = _moveStock(pid, shop, -q, device) ?? seq;
    }
    final after = _stockAfter([
      for (final it in out)
        if (it['product'] != null) (it['product'] as String, shop),
    ]);
    warnings.addAll(_negativeWarning(after));
    return PushResult(
      mutationId: e.mutationId,
      status: PushStatus.applied,
      entityId: e.entityId,
      serverSeq: seq,
      warnings: warnings.toSet().toList()..sort(),
      stockAfter: after,
      receiptNumber: receipt,
    );
  }

  Map<String, dynamic> _saleItemRow(
    _SaleLineIn l,
    String fallbackId,
    String? product,
    String name,
    BigInt? cost,
    BigInt price,
    BigInt sub,
  ) => {
    'id': l.id ?? fallbackId,
    'product': product,
    'product_name': name,
    'is_custom': l.custom || l.productId == null,
    'note': l.note.trim().length > 120
        ? l.note.trim().substring(0, 120)
        : l.note.trim(),
    'quantity': _fixed(l.quantity, 3),
    'unit_price': _fixed(price, 2),
    'unit_cost': cost == null ? null : _fixed(cost, 2),
    'discount': _fixed(l.discount, 2),
    'subtotal': _fixed(sub, 2),
    'returned_quantity': '0',
  };

  /// Fake refund, BE contract shape: payload `sale_id`, `reference`,
  /// `items: [{sale_item_id, quantity}]`, `method`, `reason`, `occurred_at`.
  /// Unknown sale -> `retry` `dependency_pending`; same `(sale, reference)`
  /// -> `duplicate`; cumulative qty per line above sold ->
  /// `rejected` `refund_exceeds_sold` + `server_state`. Applied: restocks,
  /// emits a `refund` feed row (`ser_refund` shape) and the updated sale.
  PushResult _saleRefund(OutboxEntry e, String device) {
    final p = e.payload;
    final table = _c.tables.putIfAbsent('sale', () => {});
    final saleId = p['sale_id'];
    final sale = saleId is String ? table[saleId] : null;
    if (sale == null) {
      return _reject(
        e,
        'dependency_pending',
        'Sale not yet known',
        status: PushStatus.retry,
      );
    }
    final reference = '${p['reference'] ?? ''}';
    final refKey = '$saleId|$reference';
    final known = _c.refundRefs[refKey];
    if (known != null) {
      return PushResult(
        mutationId: e.mutationId,
        status: PushStatus.duplicate,
        entityId: e.entityId,
        refundReference: reference,
        refundTotal: known,
      );
    }
    final lines = <String, Map>{};
    for (final it in (sale['items'] as List)) {
      final m = it as Map;
      lines['${m['id']}'] = m;
    }
    final req = <String, BigInt>{};
    for (final it in (p['items'] as List? ?? const [])) {
      final m = it as Map;
      final id = '${m['sale_item_id']}';
      req[id] = (req[id] ?? BigInt.zero) + _parseDec(m['quantity']);
    }
    for (final en in req.entries) {
      final line = lines[en.key];
      final sold = line == null ? BigInt.zero : _parseDec(line['quantity']);
      final done = _c.refunded['$saleId|${en.key}'] ?? BigInt.zero;
      if (line == null || done + en.value > sold) {
        return _reject(
          e,
          'refund_exceeds_sold',
          'Refund exceeds sold',
          state: Map<String, dynamic>.from(sale),
        );
      }
    }
    final shop = sale['shop'] as String;
    var total = BigInt.zero;
    final pairs = <(String, String)>[];
    final refundItems = <Map<String, dynamic>>[];
    var seq = 0;
    for (final en in req.entries) {
      final line = lines[en.key]!;
      final sold = _parseDec(line['quantity']);
      final lineNet = _parseDec(line['subtotal']) - _parseDec(line['discount']);
      final amount = _divHalfUp(lineNet * en.value, sold);
      total += amount;
      refundItems.add({
        'sale_item': en.key,
        'quantity': _fixed(en.value, 3),
        'amount': _fixed(amount, 2),
      });
      _c.refunded['$saleId|${en.key}'] =
          (_c.refunded['$saleId|${en.key}'] ?? BigInt.zero) + en.value;
      final pid = line['product'];
      if (pid is String) {
        pairs.add((pid, shop));
        seq = _moveStock(pid, shop, en.value, device) ?? seq;
      }
    }
    final totalStr = _fixed(total, 2);
    _c.refundRefs[refKey] = totalStr;
    var allBack = true;
    for (final en in lines.entries) {
      final back = _c.refunded['$saleId|${en.key}'] ?? BigInt.zero;
      if (back < _parseDec(en.value['quantity'])) allBack = false;
    }
    sale['status'] = allBack ? 'refunded' : 'partial_refund';
    sale['updated_at'] = _iso(_serverTime);
    final occurredRaw = p['occurred_at'];
    final occurred = occurredRaw is String
        ? DateTime.tryParse(occurredRaw)?.toUtc()
        : null;
    final createdAt = occurred ?? _serverTime;
    final refundId = 'rf-${_c.refundRefs.length}-$saleId';
    seq = _emit('refund', 'upsert', refundId, null, {
      'id': refundId,
      'sale': saleId,
      'shop': shop,
      'reference': reference,
      'total': totalStr,
      'method': p['method'],
      'notes': p['reason'] ?? '',
      'refunded_by': null,
      'occurred_at': _iso(createdAt),
      'created_at': _iso(createdAt),
      'items': refundItems,
    }, device);
    seq = _emit('sale', 'upsert', saleId as String, 0, sale, device);
    final after = _stockAfter(pairs);
    return PushResult(
      mutationId: e.mutationId,
      status: PushStatus.applied,
      entityId: e.entityId,
      serverSeq: seq,
      warnings: _negativeWarning(after),
      stockAfter: after,
      refundReference: reference,
      refundTotal: totalStr,
    );
  }

  /// Cumulative refunded quantity of a sale line, thousandths.
  BigInt refundedQuantity(String saleId, String saleItemId) =>
      (_c.refunded['$saleId|$saleItemId'] ?? BigInt.zero) ~/
      BigInt.from(1000);

  PushResult _saleCancel(OutboxEntry e, String device) {
    final table = _c.tables.putIfAbsent('sale', () => {});
    final sale = table[e.entityId];
    if (sale == null) {
      return _reject(
        e,
        'dependency_pending',
        'Sale not yet known',
        status: PushStatus.retry,
      );
    }
    final shop = sale['shop'] as String;
    final pairs = <(String, String)>[];
    if (sale['status'] != 'cancelled') {
      for (final it in (sale['items'] as List)) {
        final m = it as Map;
        final pid = m['product'];
        if (pid is! String) continue;
        pairs.add((pid, shop));
        _moveStock(pid, shop, _parseDec(m['quantity']), device);
      }
      sale['status'] = 'cancelled';
      sale['updated_at'] = _iso(_serverTime);
    }
    final seq = _emit('sale', 'upsert', e.entityId, 0, sale, device);
    final after = _stockAfter(pairs);
    return PushResult(
      mutationId: e.mutationId,
      status: PushStatus.applied,
      entityId: e.entityId,
      serverSeq: seq,
      warnings: _negativeWarning(after),
      stockAfter: after,
    );
  }

  // ------------------------------------------------------------ inbound

  /// BE `inbound_create`: InboundReceiveSerializer payload (`shop_id`,
  /// `reference`, `vendor_id`, `items: [{product_id, quantity, ...}]`);
  /// the mutation `entity_id` is the InboundTransaction id. Raises stock per
  /// line and answers `stock_after`; a known id answers `applied` with no
  /// stock_after; a reused reference is `conflict_unique`.
  PushResult _inboundCreate(OutboxEntry e, String device) {
    final p = e.payload;
    final table = _c.tables.putIfAbsent('inbound', () => {});
    if (table.containsKey(e.entityId)) {
      return PushResult(
        mutationId: e.mutationId,
        status: PushStatus.applied,
        entityId: e.entityId,
      );
    }
    final String shop;
    final String reference;
    final String vendor;
    final lines = <(String, BigInt, Map<String, dynamic>)>[];
    try {
      _uuid(e.entityId, 'entity_id');
      shop = p['shop_id'] as String;
      reference = (p['reference'] as String).trim();
      if (reference.isEmpty || reference.length > 255) {
        throw const FormatException('reference');
      }
      vendor = p['vendor_id'] as String;
      final items = p['items'] as List;
      if (items.isEmpty) throw const FormatException('items: min 1');
      for (final raw in items) {
        final it = Map<String, dynamic>.from(raw as Map);
        final pid = it['product_id'] as String;
        _uuid(pid, 'items.product_id');
        final q = _field(it['quantity'], 3);
        if (q <= BigInt.zero) throw const FormatException('quantity <= 0');
        lines.add((pid, q, it));
      }
    } catch (err) {
      return _reject(e, 'validation_error', 'Invalid inbound: $err');
    }
    if (_c.strictCatalog &&
        !(_c.tables['vendor'] ?? const {}).containsKey(vendor)) {
      return _reject(e, 'not_found', 'Vendor not found.');
    }
    if (_c.strictCatalog) {
      for (final (pid, _, _) in lines) {
        if (!_productKnown(pid)) {
          return _reject(e, 'not_found', 'Product not found.');
        }
      }
    }
    if (table.values.any((r) => r['reference'] == reference)) {
      return _reject(e, 'conflict_unique', 'Inbound reference already exists.');
    }
    lines.sort((a, b) => a.$1.compareTo(b.$1));
    final row = <String, dynamic>{
      'id': e.entityId,
      'shop': shop,
      'vendor': vendor,
      'reference': reference,
      'notes': p['notes'] ?? '',
      'created_by': null,
      'created_at': _iso(_serverTime),
      'items': [
        for (final (pid, q, it) in lines)
          {
            'product': pid,
            'quantity': _fixed(q, 3),
            'unit_cost': it['unit_cost'] == null
                ? null
                : _fixed(_parseDec(it['unit_cost']), 2),
            'expiry_date': it['expiry_date'],
            'batch_number': it['batch_number'] ?? '',
          },
      ],
    };
    table[e.entityId] = row;
    var seq = _emit('inbound', 'upsert', e.entityId, 0, row, device);
    for (final (pid, q, _) in lines) {
      seq = _moveStock(pid, shop, q, device) ?? seq;
    }
    return PushResult(
      mutationId: e.mutationId,
      status: PushStatus.applied,
      entityId: e.entityId,
      serverSeq: seq,
      stockAfter: _stockAfter([for (final (pid, _, _) in lines) (pid, shop)]),
    );
  }
}

class _SaleLineIn {
  _SaleLineIn({
    required this.id,
    required this.productId,
    required this.custom,
    required this.note,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.unitCost,
    required this.productName,
  });

  final String? id;
  final String? productId;
  final bool custom;
  final String note;
  final BigInt quantity;
  final BigInt? unitPrice;
  final BigInt discount;
  final BigInt? unitCost;
  final String productName;
}
