// In-memory stand-in for the real backend (docs/BE_GAPS.md sections 2-6, 10).
//
// Payload conventions the fake relies on (the real DTOs may carry more):
//  * dependency detection (the wire has no depends_on field): a mutation is
//    rejected `dependency_failed` when any of these reference an entity id
//    whose *create* was rejected earlier: `payload['depends_on']` (String or
//    List<String>), `payload['product_id']`, `payload['category_id']`,
//    `payload['sale_id']`, `payload['items'][i]['product_id']`, or the
//    mutation's own `entity_id` on a non-create op.
//  * catalog entities (category/product/customer/vendor/shop): create/update
//    payload fields are merged into the row; product `barcode` is unique.
//  * stock ops (`stock` entity): `product_id`, `shop_id`, `delta` (signed
//    decimal string) for adjust/add/remove; `count` uses `counted_quantity`;
//    `transfer` uses `product_id`, `from_shop`, `to_shop`, `quantity`.
//  * `sale.create`: `shop_id`, `items: [{product_id, quantity}]`,
//    optional `customer_id`. `sale.refund`: `sale_id`,
//    `items: [{product_id, quantity}]`. `sale.cancel`: entity_id is the sale.
//  * merge semantic (BE_GAPS 10): an update with a stale `base_version` still
//    applies and the result carries `merged: true` plus the final
//    `server_state` (warnings stay free of 'merged').
//  * `conflict_unique` results carry the conflicting row as `server_state`
//    (its `id` is the conflicting row id).
//  * push `next_cursor` is the server head. Engines must NOT adopt it as the
//    pull cursor: it can skip other devices' changes made before it.
//  * replaying a mutation_id: previously applied -> `duplicate`; previously
//    rejected -> the same rejected result (status/code/message unchanged).
//  * fault knobs (down, failNextWith, latency, flakyRate, lostResponseRate,
//    dropResponseAfterApply, clockSkew) are PER VIEW; minAppVersion,
//    fullResyncRequired and capabilities are shared server state.
//  * Other entities (inbound, user, notification, ...) are generic upserts.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:amana_pos/core/sync/contract/sync_contract.dart';
import 'package:amana_pos/core/sync/outbox/outbox_entry.dart';
import 'package:amana_pos/core/sync/transport/sync_transport.dart';

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
  final stockVersion = <String, int>{};
  final tombstones = <String, int>{};
  final rejectedCreates = <String>{};
  final refunded = <String, BigInt>{}; // sale|product -> refunded qty
  int seq = 0;
  int receiptCounter = 0;

  String? minAppVersion;
  bool fullResyncRequired = false;
  Set<String> capabilities = {};
}

class FakeSyncServer implements SyncTransport {
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

  DateTime get _serverTime => now().add(clockSkew).toUtc();

  // ---- observable state ----
  Map<String, Map<String, Map<String, dynamic>>> get tables => _c.tables;
  List<PullChange> get feed => _c.feed;
  Map<String, PushResult> get applied => _c.applied;
  int get headSeq => _c.seq;
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
  Future<PullResponse> pull({String? cursor, int limit = 500}) async {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit', 'must be > 0');
    await _gate();
    if (_c.fullResyncRequired) {
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

  @override
  Future<PushResponse> push({
    required String deviceId,
    required String appVersion,
    required List<OutboxEntry> mutations,
  }) async {
    await _gate();
    final order = List.generate(mutations.length, (i) => i)
      ..sort((a, b) {
        final c = (mutations[a].seq ?? 0).compareTo(mutations[b].seq ?? 0);
        return c != 0 ? c : a.compareTo(b);
      });
    final results = <PushResult>[];
    for (final i in order) {
      results.add(_applyOne(mutations[i], deviceId));
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

  PushResult _applyOne(OutboxEntry e, String device) {
    final stored = _c.applied[e.mutationId];
    if (stored != null) {
      if (stored.status != PushStatus.applied) return stored;
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
    PushResult result;
    try {
      result = _dispatch(e, device);
    } catch (err) {
      result = _reject(e, 'validation_error', 'Malformed payload: $err');
    }
    if (result.status == PushStatus.rejected && e.op == 'create') {
      _c.rejectedCreates.add(e.entityId);
    }
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
  }) => PushResult(
    mutationId: e.mutationId,
    status: status,
    entityId: e.entityId,
    code: code,
    message: msg,
    serverState: state,
    conflictEntityId: conflictEntityId,
    dependsOn: dependsOn,
  );

  Iterable<String> _deps(OutboxEntry e) sync* {
    final p = e.payload;
    final d = p['depends_on'];
    if (d is String) yield d;
    if (d is List) yield* d.whereType<String>();
    for (final k in ['product_id', 'category_id', 'sale_id']) {
      final v = p[k];
      if (v is String) yield v;
    }
    final items = p['items'];
    if (items is List) {
      for (final it in items) {
        if (it is Map && it['product_id'] is String) {
          yield it['product_id'] as String;
        }
      }
    }
    if (e.op != 'create') yield e.entityId;
  }

  PushResult _dispatch(OutboxEntry e, String device) {
    for (final d in _deps(e)) {
      if (_c.rejectedCreates.contains(d)) {
        return _reject(
          e,
          'dependency_failed',
          'Depends on rejected $d',
          dependsOn: [d],
        );
      }
    }
    switch (e.entity) {
      case 'stock':
        return _stockOp(e, device);
      case 'sale':
        return _saleOp(e, device);
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

  Map<String, dynamic>? _barcodeClash(OutboxEntry e) {
    if (e.entity != 'product') return null;
    final bc = e.payload['barcode'];
    if (bc is! String || bc.isEmpty) return null;
    for (final r in (_c.tables['product'] ?? {}).values) {
      if (r['id'] != e.entityId && r['barcode'] == bc) {
        return Map<String, dynamic>.from(r);
      }
    }
    return null;
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
    final clash = _barcodeClash(e);
    if (clash != null) {
      return _reject(
        e,
        'conflict_unique',
        'Duplicate barcode',
        state: clash,
        conflictEntityId: clash['id'] as String?,
      );
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

  /// Adds [delta] to the ledger, emits a stock change. Returns (seq, after).
  int _addStock(
    String product,
    String shop,
    BigInt delta,
    String device,
    List<StockAfter> after,
    List<String> warnings,
  ) {
    final k = '$product|$shop';
    final q = (_c.stock[k] ?? BigInt.zero) + delta;
    _c.stock[k] = q;
    final v = (_c.stockVersion[k] ?? 0) + 1;
    _c.stockVersion[k] = v;
    if (q.isNegative && !warnings.contains('negative_stock')) {
      warnings.add('negative_stock');
    }
    after.removeWhere((a) => a.productId == product && a.shopId == shop);
    after.add(
      StockAfter(productId: product, shopId: shop, quantity: _fmtDec(q)),
    );
    return _emit('stock', 'upsert', '$product:$shop', v, {
      'product_id': product,
      'shop_id': shop,
      'quantity': _fmtDec(q),
    }, device);
  }

  PushResult _stockOp(OutboxEntry e, String device) {
    final p = e.payload;
    final after = <StockAfter>[];
    final warnings = <String>[];
    // Parse/validate everything before mutating anything.
    late final List<(String, String, BigInt)> steps;
    try {
      final prod = p['product_id'] as String;
      switch (e.op) {
        case 'transfer':
          final q = _parseDec(p['quantity']);
          steps = [
            (prod, p['from_shop'] as String, -q),
            (prod, p['to_shop'] as String, q),
          ];
        case 'count':
          final shop = p['shop_id'] as String;
          final cur = _c.stock['$prod|$shop'] ?? BigInt.zero;
          steps = [(prod, shop, _parseDec(p['counted_quantity']) - cur)];
        default:
          steps = [(prod, p['shop_id'] as String, _parseDec(p['delta']))];
      }
    } catch (_) {
      return _reject(e, 'validation_error', 'Bad stock payload');
    }
    var seq = 0;
    for (final (prod, shop, d) in steps) {
      seq = _addStock(prod, shop, d, device, after, warnings);
    }
    return PushResult(
      mutationId: e.mutationId,
      status: PushStatus.applied,
      entityId: e.entityId,
      serverSeq: seq,
      warnings: warnings,
      stockAfter: after,
    );
  }

  PushResult _saleOp(OutboxEntry e, String device) {
    final p = e.payload;
    final table = _c.tables.putIfAbsent('sale', () => {});
    final after = <StockAfter>[];
    final warnings = <String>[];
    switch (e.op) {
      case 'create':
        final items = p['items'];
        final shop = p['shop_id'];
        if (items is! List || shop is! String) {
          return _reject(e, 'validation_error', 'items/shop_id required');
        }
        final lines = <(String, BigInt)>[];
        for (final it in items) {
          if (it is! Map || it['product_id'] is! String) {
            return _reject(e, 'validation_error', 'Bad line');
          }
          lines.add((it['product_id'] as String, _parseDec(it['quantity'])));
        }
        final existingSale = table[e.entityId];
        if (existingSale != null) {
          return PushResult(
            mutationId: e.mutationId,
            status: PushStatus.duplicate,
            entityId: e.entityId,
            version: existingSale['version'] as int,
          );
        }
        final cust = p['customer_id'];
        var custMissing = false;
        if (cust is String &&
            (_c.tombstones.containsKey('customer/$cust') ||
                _c.rejectedCreates.contains(cust))) {
          warnings.add('customer_missing');
          custMissing = true;
        }
        var seq = 0;
        for (final (prod, q) in lines) {
          seq = _addStock(prod, shop, -q, device, after, warnings);
        }
        final row = {
          ...p,
          if (custMissing) 'customer_id': null,
          'id': e.entityId,
          'version': 1,
          'status': 'done',
        };
        table[e.entityId] = row;
        seq = _emit('sale', 'upsert', e.entityId, 1, row, device);
        return PushResult(
          mutationId: e.mutationId,
          status: PushStatus.applied,
          entityId: e.entityId,
          version: 1,
          serverSeq: seq,
          warnings: warnings,
          stockAfter: after,
          receiptNumber: 'R-${++_c.receiptCounter}',
        );
      case 'refund':
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
        final sold = <String, BigInt>{};
        for (final it in (sale['items'] as List)) {
          final m = it as Map;
          sold[m['product_id'] as String] =
              (sold[m['product_id']] ?? BigInt.zero) + _parseDec(m['quantity']);
        }
        final req = <String, BigInt>{};
        for (final it in (p['items'] as List? ?? const [])) {
          final m = it as Map;
          req[m['product_id'] as String] =
              (req[m['product_id']] ?? BigInt.zero) + _parseDec(m['quantity']);
        }
        for (final en in req.entries) {
          final done = _c.refunded['$saleId|${en.key}'] ?? BigInt.zero;
          if (done + en.value > (sold[en.key] ?? BigInt.zero)) {
            return _reject(
              e,
              'refund_exceeds_sold',
              'Refund exceeds sold',
              state: Map<String, dynamic>.from(sale),
            );
          }
        }
        var seq = 0;
        for (final en in req.entries) {
          _c.refunded['$saleId|${en.key}'] =
              (_c.refunded['$saleId|${en.key}'] ?? BigInt.zero) + en.value;
          seq = _addStock(
            en.key,
            sale['shop_id'] as String,
            en.value,
            device,
            after,
            warnings,
          );
        }
        final v = (sale['version'] as int) + 1;
        sale['version'] = v;
        seq = _emit('sale', 'upsert', saleId as String, v, sale, device);
        return PushResult(
          mutationId: e.mutationId,
          status: PushStatus.applied,
          entityId: e.entityId,
          version: v,
          serverSeq: seq,
          warnings: warnings,
          stockAfter: after,
        );
      case 'cancel':
        final sale = table[e.entityId];
        if (sale == null) {
          return _reject(
            e,
            'dependency_pending',
            'Sale not yet known',
            status: PushStatus.retry,
          );
        }
        if (sale['status'] != 'cancelled') {
          for (final it in (sale['items'] as List)) {
            final m = it as Map;
            _addStock(
              m['product_id'] as String,
              sale['shop_id'] as String,
              _parseDec(m['quantity']),
              device,
              after,
              warnings,
            );
          }
          sale['status'] = 'cancelled';
          sale['version'] = (sale['version'] as int) + 1;
        }
        final seq = _emit(
          'sale',
          'upsert',
          e.entityId,
          sale['version'] as int,
          sale,
          device,
        );
        return PushResult(
          mutationId: e.mutationId,
          status: PushStatus.applied,
          entityId: e.entityId,
          version: sale['version'] as int,
          serverSeq: seq,
          warnings: warnings,
          stockAfter: after,
        );
      default:
        return _reject(e, 'validation_error', 'Unknown sale op ${e.op}');
    }
  }
}
