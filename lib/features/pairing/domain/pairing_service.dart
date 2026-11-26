import 'package:dio/dio.dart';

/// A code the desktop till types to link itself to this business.
class PairingCode {
  const PairingCode({
    required this.pairingId,
    required this.code,
    required this.expiresAt,
    required this.ttlSeconds,
    this.businessName,
  });

  final String pairingId;
  final String code;
  final DateTime expiresAt;
  final int ttlSeconds;
  final String? businessName;
}

/// Server wording for where a code is: pending (waiting), choosing (the
/// desktop typed it), used (linked), expired, replaced (a newer code was made).
enum PairingStatus { pending, choosing, used, expired, replaced }

class PairingProgress {
  const PairingProgress(this.status, {this.deviceName});
  final PairingStatus status;
  final String? deviceName;
}

enum PairingFailure { rateLimited, offline, forbidden, other }

class PairingException implements Exception {
  const PairingException(this.failure);
  final PairingFailure failure;
  @override
  String toString() => 'PairingException($failure)';
}

/// `POST api/v1/sync/pairing/` and `GET api/v1/sync/pairing/<id>/`: what the
/// dashboard's link-device page does, started from the phone. Online only,
/// nothing is stored or queued.
class PairingService {
  PairingService(this._dio);

  final Dio _dio;

  static const String path = 'api/v1/sync/pairing/';

  /// A desktop QR is any address with `link-device` in its path.
  static bool isLinkDeviceCode(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return false;
    }
    return uri.pathSegments.contains('link-device');
  }

  Future<PairingCode> create({String? businessId}) async {
    final Response<dynamic> r;
    try {
      r = await _dio.post<dynamic>(
        path,
        data: {if (businessId != null && businessId.isNotEmpty) 'business_id': businessId},
      );
    } on DioException catch (e) {
      throw _map(e);
    }
    final d = _data(r);
    final code = d['code']?.toString();
    final id = d['pairing_id']?.toString();
    final expires = DateTime.tryParse('${d['expires_at']}');
    if (code == null || id == null || expires == null) {
      throw const PairingException(PairingFailure.other);
    }
    return PairingCode(
      pairingId: id,
      code: code,
      expiresAt: expires.toUtc(),
      ttlSeconds: (d['ttl_seconds'] as num?)?.toInt() ?? 300,
      businessName: d['business_name']?.toString(),
    );
  }

  Future<PairingProgress> status(String pairingId) async {
    final Response<dynamic> r;
    try {
      r = await _dio.get<dynamic>('$path$pairingId/');
    } on DioException catch (e) {
      throw _map(e);
    }
    final d = _data(r);
    final status = PairingStatus.values.firstWhere(
      (s) => s.name == d['status'],
      orElse: () => PairingStatus.pending,
    );
    final name = d['device_name']?.toString();
    return PairingProgress(
      status,
      deviceName: (name == null || name.isEmpty) ? null : name,
    );
  }

  Map<String, dynamic> _data(Response<dynamic> r) {
    final body = r.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    throw const PairingException(PairingFailure.other);
  }

  PairingException _map(DioException e) {
    final code = e.response?.statusCode;
    if (code == 429) return const PairingException(PairingFailure.rateLimited);
    if (code == 403) return const PairingException(PairingFailure.forbidden);
    if (code == null &&
        (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout)) {
      return const PairingException(PairingFailure.offline);
    }
    return const PairingException(PairingFailure.other);
  }
}
