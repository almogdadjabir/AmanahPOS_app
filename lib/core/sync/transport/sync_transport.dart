import '../contract/sync_contract.dart';
import '../outbox/outbox_entry.dart';

enum SyncTransportKind {
  network,
  timeout,
  server,
  unauthorized,
  tokenExpired,
  accountDisabled,
  deviceRevoked,
  tooLarge,
  maintenance,

  /// The signed-in session no longer matches the scope the request was
  /// built for; nothing was sent. The engine aborts quietly.
  scopeChanged,
}

class SyncTransportException implements Exception {
  SyncTransportException({
    required this.kind,
    this.httpStatus,
    this.code,
    this.message,
    this.retryAfterSeconds,
  });

  final SyncTransportKind kind;
  final int? httpStatus;
  final String? code;
  final String? message;
  final int? retryAfterSeconds;

  @override
  String toString() =>
      'SyncTransportException(${kind.name}, http=$httpStatus, code=$code, '
      'message=$message)';
}

abstract class SyncTransport {
  Future<PingResponse> ping();

  Future<PushResponse> push({
    required String deviceId,
    required String appVersion,
    required List<OutboxEntry> mutations,

    /// `userId|tenantId` the batch belongs to. Real transports refuse to
    /// send when the current auth session differs.
    required String scope,
  });

  Future<PullResponse> pull({
    String? cursor,
    int limit = 500,
    required String scope,
  });

  /// Bootstrap manifest: visible entities + the snapshot cursor.
  Future<BootstrapManifest> bootstrapManifest({required String scope});

  /// One keyset page of [entity]. [snapshotCursor] is echoed from the
  /// manifest; [salesSinceDays] only affects sale/refund.
  Future<BootstrapPage> bootstrapPage({
    required String entity,
    String? pageCursor,
    int limit = 500,
    String? snapshotCursor,
    int salesSinceDays = 90,
    required String scope,
  });
}
