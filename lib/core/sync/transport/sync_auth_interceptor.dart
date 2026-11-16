import 'package:dio/dio.dart';

/// Attaches the same auth headers the app's `AppInterceptors` attaches
/// (Authorization bearer for `api/` paths, X-Tenant-ID, default Accept) plus
/// `X-Device-ID` when a device id is available.
///
/// Deliberately does NOT refresh tokens, retry, log out or navigate: an
/// unreachable server must never end the user's session. All 401s pass through
/// untouched for the transport to classify.
class SyncAuthInterceptor extends Interceptor {
  SyncAuthInterceptor({
    required this.readAccessToken,
    required this.readTenantId,
    this.readDeviceId,
  });

  final Future<String?> Function() readAccessToken;
  final Future<String?> Function() readTenantId;
  final Future<String?> Function()? readDeviceId;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await readAccessToken();
    final tenant = await readTenantId();
    final deviceId = await readDeviceId?.call();

    final requiresAuth =
        options.path.startsWith('api/') || options.path.startsWith('/api/');
    if (token != null && requiresAuth) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    if (tenant != null) {
      options.headers['X-Tenant-ID'] = tenant;
    }
    if (deviceId != null) {
      options.headers['X-Device-ID'] = deviceId;
    }
    final hasAccept = options.headers.keys.any(
      (k) => k.toLowerCase() == 'accept',
    );
    if (!hasAccept) options.headers['Accept'] = 'application/json';
    handler.next(options);
  }
}
