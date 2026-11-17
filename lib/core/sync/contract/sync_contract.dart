import '../outbox/outbox_entry.dart';

/// Wire contract DTOs for the sync endpoints (see docs/BE_GAPS.md sections
/// 2, 3, 4, 5, 6). JSON keys are snake_case. Quantities/money are strings.

enum PushStatus { applied, duplicate, rejected, retry }

PushStatus _statusFrom(Object? raw) {
  for (final s in PushStatus.values) {
    if (s.name == raw) return s;
  }
  throw FormatException('Unknown push status: $raw');
}

DateTime _dt(Object? raw, String where) {
  if (raw is! String) {
    throw FormatException('$where must be an ISO date string');
  }
  return DateTime.parse(raw).toUtc();
}

String _str(Map<String, dynamic> j, String k, String cls) {
  final v = j[k];
  if (v is String) return v;
  throw FormatException('$cls.$k must be a string');
}

String? _strN(Map<String, dynamic> j, String k, String cls) {
  final v = j[k];
  if (v == null || v is String) return v as String?;
  throw FormatException('$cls.$k must be a string or null');
}

int _int(Map<String, dynamic> j, String k, String cls) {
  final v = j[k];
  if (v is num) return v.toInt();
  throw FormatException('$cls.$k must be a number');
}

int? _intN(Map<String, dynamic> j, String k, String cls) {
  final v = j[k];
  if (v == null) return null;
  if (v is num) return v.toInt();
  throw FormatException('$cls.$k must be a number or null');
}

bool _bool(Map<String, dynamic> j, String k, String cls) {
  final v = j[k];
  if (v == null) return false;
  if (v is bool) return v;
  throw FormatException('$cls.$k must be a bool');
}

Map<String, dynamic>? _mapN(Map<String, dynamic> j, String k, String cls) {
  final v = j[k];
  if (v == null) return null;
  if (v is Map) return Map<String, dynamic>.from(v);
  throw FormatException('$cls.$k must be an object or null');
}

List<Object?> _list(Map<String, dynamic> j, String k, String cls) {
  final v = j[k];
  if (v == null) return const [];
  if (v is List) return v;
  throw FormatException('$cls.$k must be a list');
}

Map<String, dynamic> _obj(Object? v, String where) {
  if (v is Map) return Map<String, dynamic>.from(v);
  throw FormatException('$where must be an object');
}

class StockAfter {
  const StockAfter({
    required this.productId,
    required this.shopId,
    required this.quantity,
  });

  final String productId;
  final String shopId;

  /// Decimal-safe string, never a double.
  final String quantity;

  factory StockAfter.fromJson(Map<String, dynamic> j) => StockAfter(
    productId: _str(j, 'product_id', 'StockAfter'),
    shopId: _str(j, 'shop_id', 'StockAfter'),
    quantity: _quantity(j['quantity']),
  );

  /// Servers should send quantities as strings; a JSON number is tolerated
  /// and converted with num.toString().
  static String _quantity(Object? v) {
    if (v is String) return v;
    if (v is num) return v.toString();
    throw const FormatException(
      'StockAfter.quantity must be a string or number',
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'shop_id': shopId,
    'quantity': quantity,
  };
}

class PushResult {
  const PushResult({
    required this.mutationId,
    required this.status,
    this.entityId,
    this.version,
    this.serverSeq,
    this.code,
    this.message,
    this.serverState,
    this.warnings = const [],
    this.stockAfter = const [],
    this.merged = false,
    this.receiptNumber,
    this.conflictEntityId,
    this.dependsOn = const [],
    this.errors,
    this.inviteSent,
    this.refundReference,
    this.refundTotal,
    this.occurredAtSuspect = false,
    this.extra = const {},
  });

  final String mutationId;
  final PushStatus status;
  final String? entityId;
  final int? version;
  final int? serverSeq;
  final String? code;
  final String? message;
  final Map<String, dynamic>? serverState;
  final List<String> warnings;
  final List<StockAfter> stockAfter;

  /// Stale base_version was merged server-side (replaces warnings ['merged']).
  final bool merged;
  final String? receiptNumber;
  final String? conflictEntityId;
  final List<String> dependsOn;

  /// `{field: [msgs]}` on validation_error.
  final Map<String, dynamic>? errors;
  final bool? inviteSent;
  final String? refundReference;

  /// Decimal-safe string (a JSON number is converted with num.toString()).
  final String? refundTotal;
  final bool occurredAtSuspect;

  /// Every unrecognised key, verbatim.
  final Map<String, dynamic> extra;

  static const _known = {
    'mutation_id',
    'status',
    'entity_id',
    'version',
    'server_seq',
    'code',
    'message',
    'server_state',
    'warnings',
    'stock_after',
    'merged',
    'receipt_number',
    'conflict_entity_id',
    'depends_on',
    'errors',
    'invite_sent',
    'refund_reference',
    'refund_total',
    'occurred_at_suspect',
  };

  static bool? _boolN(Map<String, dynamic> j, String k) {
    final v = j[k];
    if (v == null || v is bool) return v as bool?;
    throw FormatException('PushResult.$k must be a bool or null');
  }

  static List<String> _strList(Map<String, dynamic> j, String k) =>
      _list(j, k, 'PushResult').map((e) {
        if (e is String) return e;
        throw FormatException('PushResult.$k must hold strings');
      }).toList();

  factory PushResult.fromJson(Map<String, dynamic> j) {
    final rt = j['refund_total'];
    if (rt != null && rt is! String && rt is! num) {
      throw const FormatException(
        'PushResult.refund_total must be a string or number',
      );
    }
    return PushResult(
      mutationId: _str(j, 'mutation_id', 'PushResult'),
      status: _statusFrom(j['status']),
      entityId: _strN(j, 'entity_id', 'PushResult'),
      version: _intN(j, 'version', 'PushResult'),
      serverSeq: _intN(j, 'server_seq', 'PushResult'),
      code: _strN(j, 'code', 'PushResult'),
      message: _strN(j, 'message', 'PushResult'),
      serverState: _mapN(j, 'server_state', 'PushResult'),
      warnings: _strList(j, 'warnings'),
      stockAfter: _list(j, 'stock_after', 'PushResult')
          .map((e) => StockAfter.fromJson(_obj(e, 'PushResult.stock_after[]')))
          .toList(),
      merged: _bool(j, 'merged', 'PushResult'),
      receiptNumber: _strN(j, 'receipt_number', 'PushResult'),
      conflictEntityId: _strN(j, 'conflict_entity_id', 'PushResult'),
      dependsOn: _strList(j, 'depends_on'),
      errors: _mapN(j, 'errors', 'PushResult'),
      inviteSent: _boolN(j, 'invite_sent'),
      refundReference: _strN(j, 'refund_reference', 'PushResult'),
      refundTotal: rt?.toString(),
      occurredAtSuspect: _bool(j, 'occurred_at_suspect', 'PushResult'),
      extra: {
        for (final e in j.entries)
          if (!_known.contains(e.key)) e.key: e.value,
      },
    );
  }

  Map<String, dynamic> toJson() => {
    ...extra,
    'mutation_id': mutationId,
    'status': status.name,
    if (entityId != null) 'entity_id': entityId,
    if (version != null) 'version': version,
    if (serverSeq != null) 'server_seq': serverSeq,
    if (code != null) 'code': code,
    if (message != null) 'message': message,
    if (serverState != null) 'server_state': serverState,
    'warnings': warnings,
    'stock_after': stockAfter.map((e) => e.toJson()).toList(),
    if (merged) 'merged': true,
    if (receiptNumber != null) 'receipt_number': receiptNumber,
    if (conflictEntityId != null) 'conflict_entity_id': conflictEntityId,
    if (dependsOn.isNotEmpty) 'depends_on': dependsOn,
    if (errors != null) 'errors': errors,
    if (inviteSent != null) 'invite_sent': inviteSent,
    if (refundReference != null) 'refund_reference': refundReference,
    if (refundTotal != null) 'refund_total': refundTotal,
    if (occurredAtSuspect) 'occurred_at_suspect': true,
  };
}

class PushResponse {
  const PushResponse({
    required this.serverTime,
    required this.results,
    this.nextCursor,
  });

  final DateTime serverTime;
  final List<PushResult> results;
  final String? nextCursor;

  factory PushResponse.fromJson(Map<String, dynamic> j) => PushResponse(
    serverTime: _dt(j['server_time'], 'PushResponse.server_time'),
    results: _list(j, 'results', 'PushResponse')
        .map((e) => PushResult.fromJson(_obj(e, 'PushResponse.results[]')))
        .toList(),
    nextCursor: _strN(j, 'next_cursor', 'PushResponse'),
  );

  Map<String, dynamic> toJson() => {
    'server_time': serverTime.toUtc().toIso8601String(),
    'results': results.map((e) => e.toJson()).toList(),
    'next_cursor': nextCursor,
  };
}

class PullChange {
  const PullChange({
    required this.seq,
    required this.entity,
    required this.op,
    required this.id,
    this.version,
    this.data,
    this.originDeviceId,
    this.shopId,
  });

  final int seq;
  final String entity;
  final String op;
  final String id;
  final int? version;
  final Map<String, dynamic>? data;
  final String? originDeviceId;
  final String? shopId;

  factory PullChange.fromJson(Map<String, dynamic> j) => PullChange(
    seq: _int(j, 'seq', 'PullChange'),
    entity: _str(j, 'entity', 'PullChange'),
    op: _str(j, 'op', 'PullChange'),
    id: _str(j, 'id', 'PullChange'),
    version: _intN(j, 'version', 'PullChange'),
    data: _mapN(j, 'data', 'PullChange'),
    originDeviceId: _strN(j, 'origin_device_id', 'PullChange'),
    shopId: _strN(j, 'shop_id', 'PullChange'),
  );

  Map<String, dynamic> toJson() => {
    'seq': seq,
    'entity': entity,
    'op': op,
    'id': id,
    if (version != null) 'version': version,
    if (data != null) 'data': data,
    if (originDeviceId != null) 'origin_device_id': originDeviceId,
    if (shopId != null) 'shop_id': shopId,
  };
}

class PullResponse {
  const PullResponse({
    required this.serverTime,
    required this.changes,
    required this.nextCursor,
    this.hasMore = false,
    this.fullResyncRequired = false,
  });

  final DateTime serverTime;
  final List<PullChange> changes;
  final String nextCursor;
  final bool hasMore;
  final bool fullResyncRequired;

  factory PullResponse.fromJson(Map<String, dynamic> j) => PullResponse(
    serverTime: _dt(j['server_time'], 'PullResponse.server_time'),
    changes: _list(j, 'changes', 'PullResponse')
        .map((e) => PullChange.fromJson(_obj(e, 'PullResponse.changes[]')))
        .toList(),
    nextCursor: _str(j, 'next_cursor', 'PullResponse'),
    hasMore: _bool(j, 'has_more', 'PullResponse'),
    fullResyncRequired: _bool(j, 'full_resync_required', 'PullResponse'),
  );

  Map<String, dynamic> toJson() => {
    'server_time': serverTime.toUtc().toIso8601String(),
    'changes': changes.map((e) => e.toJson()).toList(),
    'next_cursor': nextCursor,
    'has_more': hasMore,
    'full_resync_required': fullResyncRequired,
  };
}

/// `GET api/v1/sync/bootstrap/` (no entity): the entities this user may
/// download and the snapshot cursor all pages must echo.
class BootstrapManifest {
  const BootstrapManifest({
    required this.serverTime,
    required this.entities,
    required this.snapshotCursor,
  });

  final DateTime serverTime;
  final List<String> entities;
  final String snapshotCursor;

  factory BootstrapManifest.fromJson(Map<String, dynamic> j) =>
      BootstrapManifest(
        serverTime: _dt(j['server_time'], 'BootstrapManifest.server_time'),
        entities: _list(j, 'entities', 'BootstrapManifest').map((e) {
          if (e is String) return e;
          throw const FormatException(
            'BootstrapManifest.entities must hold strings',
          );
        }).toList(),
        snapshotCursor: _str(j, 'snapshot_cursor', 'BootstrapManifest'),
      );

  Map<String, dynamic> toJson() => {
    'server_time': serverTime.toUtc().toIso8601String(),
    'entities': entities,
    'snapshot_cursor': snapshotCursor,
  };
}

/// One keyset page of an entity (`?entity=...`). Items are feed-shaped rows;
/// money stays as strings.
class BootstrapPage {
  const BootstrapPage({
    required this.entity,
    required this.snapshotCursor,
    required this.items,
    this.hasMore = false,
    this.nextPageCursor,
    this.serverTime,
  });

  final DateTime? serverTime;
  final String entity;
  final String snapshotCursor;
  final List<Map<String, dynamic>> items;
  final bool hasMore;
  final String? nextPageCursor;

  factory BootstrapPage.fromJson(Map<String, dynamic> j) {
    if (j['items'] is! List) {
      throw const FormatException('BootstrapPage.items must be a list');
    }
    return BootstrapPage(
      serverTime: j['server_time'] == null
          ? null
          : _dt(j['server_time'], 'BootstrapPage.server_time'),
      entity: _str(j, 'entity', 'BootstrapPage'),
      snapshotCursor: _str(j, 'snapshot_cursor', 'BootstrapPage'),
      items: (j['items'] as List)
          .map((e) => _obj(e, 'BootstrapPage.items[]'))
          .toList(),
      hasMore: _bool(j, 'has_more', 'BootstrapPage'),
      nextPageCursor: _strN(j, 'next_page_cursor', 'BootstrapPage'),
    );
  }

  Map<String, dynamic> toJson() => {
    if (serverTime != null)
      'server_time': serverTime!.toUtc().toIso8601String(),
    'entity': entity,
    'snapshot_cursor': snapshotCursor,
    'items': items,
    'has_more': hasMore,
    'next_page_cursor': nextPageCursor,
  };
}

class PingResponse {
  const PingResponse({
    required this.ok,
    required this.serverTime,
    this.minAppVersion,
    this.latestAppVersion,
    this.maintenance = false,
    this.retryAfterSeconds,
    this.capabilities = const {},
  });

  final bool ok;
  final DateTime serverTime;
  final String? minAppVersion;
  final String? latestAppVersion;
  final bool maintenance;
  final int? retryAfterSeconds;
  final Set<String> capabilities;

  factory PingResponse.fromJson(Map<String, dynamic> j) => PingResponse(
    ok: _bool(j, 'ok', 'PingResponse'),
    serverTime: _dt(j['server_time'], 'PingResponse.server_time'),
    minAppVersion: _strN(j, 'min_app_version', 'PingResponse'),
    latestAppVersion: _strN(j, 'latest_app_version', 'PingResponse'),
    maintenance: _bool(j, 'maintenance', 'PingResponse'),
    retryAfterSeconds: _intN(j, 'retry_after', 'PingResponse'),
    capabilities: _list(j, 'capabilities', 'PingResponse').map((e) {
      if (e is String) return e;
      throw const FormatException(
        'PingResponse.capabilities must hold strings',
      );
    }).toSet(),
  );

  Map<String, dynamic> toJson() => {
    'ok': ok,
    'server_time': serverTime.toUtc().toIso8601String(),
    'min_app_version': minAppVersion,
    'latest_app_version': latestAppVersion,
    'maintenance': maintenance,
    'retry_after': retryAfterSeconds,
    'capabilities': capabilities.toList(),
  };
}

/// Builds the push request body (BE_GAPS section 2).
Map<String, dynamic> buildPushRequestJson({
  required String deviceId,
  required String appVersion,
  required DateTime clientTime,
  required List<OutboxEntry> mutations,
}) => {
  'device_id': deviceId,
  'app_version': appVersion,
  'client_time': clientTime.toUtc().toIso8601String(),
  'mutations': mutations
      .map(
        (e) => {
          'mutation_id': e.mutationId,
          'seq': e.seq,
          'entity': e.entity,
          'op': e.op,
          'entity_id': e.entityId,
          'base_version': e.baseVersion,
          'occurred_at': e.occurredAt.toUtc().toIso8601String(),
          'payload': e.payload,
        },
      )
      .toList(),
};
