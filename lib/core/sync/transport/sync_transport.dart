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
  });

  Future<PullResponse> pull({String? cursor, int limit = 500});
}
