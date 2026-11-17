import 'dart:convert';

enum OutboxStatus { pending, inflight, done, rejected, blocked }

class OutboxEntry {
  OutboxEntry({
    this.seq,
    required this.mutationId,
    required this.entity,
    required this.op,
    required this.entityId,
    this.dependsOn = const [],
    this.baseVersion,
    required this.occurredAt,
    required this.payload,
    this.status = OutboxStatus.pending,
    this.attempts = 0,
    this.nextAttemptAt,
    this.errorCode,
    this.errorMessage,
    this.errorEntityId,
    this.leaseUntil,
    this.scope = '',
  });

  int? seq;
  String mutationId;
  String entity;
  String op;
  String entityId;

  /// Entity ids this row waits on (`depends_on_json`): it stays `blocked`
  /// while any of them has an open `create` in [scope].
  List<String> dependsOn;
  int? baseVersion;
  DateTime occurredAt;
  Map<String, dynamic> payload;
  OutboxStatus status;
  int attempts;
  DateTime? nextAttemptAt;
  String? errorCode;
  String? errorMessage;

  /// Server `conflict_entity_id` of a `conflict_unique` rejection (DB v14
  /// `error_entity_id`): the existing row "Merge into existing" maps this
  /// row onto. Null for every other outcome.
  String? errorEntityId;

  /// Lease expiry recorded when this row was claimed (read-only claim info,
  /// never written by [toRow]). Used as an ownership token: a runner may only
  /// write the result of a row it still holds under this exact lease.
  DateTime? leaseUntil;

  /// `userId|tenantId` that owns this row; only that session may push it.
  String scope;

  /// Row map for insert. [createdAt] is required by the schema.
  Map<String, Object?> toRow({DateTime? createdAt}) => {
    if (seq != null) 'seq': seq,
    'mutation_id': mutationId,
    'entity': entity,
    'op': op,
    'entity_id': entityId,
    'depends_on_json': dependsOn.isEmpty ? null : jsonEncode(dependsOn),
    'base_version': baseVersion,
    'occurred_at': occurredAt.toUtc().toIso8601String(),
    'payload_json': jsonEncode(payload),
    'status': status.name,
    'attempts': attempts,
    'next_attempt_at': nextAttemptAt?.toUtc().toIso8601String(),
    'error_code': errorCode,
    'error_message': errorMessage,
    'error_entity_id': errorEntityId,
    'scope': scope,
    'created_at': (createdAt ?? DateTime.now()).toUtc().toIso8601String(),
  };

  factory OutboxEntry.fromRow(Map<String, Object?> r) => OutboxEntry(
    seq: r['seq'] as int?,
    mutationId: r['mutation_id'] as String,
    entity: r['entity'] as String,
    op: r['op'] as String,
    entityId: r['entity_id'] as String,
    dependsOn: decodeDependsOn(r['depends_on_json']),
    baseVersion: r['base_version'] as int?,
    occurredAt: DateTime.parse(r['occurred_at'] as String).toUtc(),
    payload: Map<String, dynamic>.from(
      jsonDecode(r['payload_json'] as String) as Map,
    ),
    status: OutboxStatus.values.byName(r['status'] as String),
    attempts: (r['attempts'] as int?) ?? 0,
    nextAttemptAt: r['next_attempt_at'] == null
        ? null
        : DateTime.parse(r['next_attempt_at'] as String).toUtc(),
    errorCode: r['error_code'] as String?,
    errorMessage: r['error_message'] as String?,
    errorEntityId: r['error_entity_id'] as String?,
    leaseUntil: r['lease_until'] == null
        ? null
        : DateTime.parse(r['lease_until'] as String).toUtc(),
    scope: (r['scope'] as String?) ?? '',
  );

  /// `depends_on_json` -> list; NULL / malformed -> empty.
  static List<String> decodeDependsOn(Object? raw) {
    if (raw is! String || raw.isEmpty) return const [];
    try {
      final v = jsonDecode(raw);
      if (v is! List) return const [];
      return [
        for (final x in v)
          if (x is String && x.isNotEmpty) x,
      ];
    } on FormatException {
      return const [];
    }
  }
}
