import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../../offline/offline_db.dart';
import '../db_change_notifier.dart';
import 'asset_sync.dart';

/// Shared construction rules for [AssetSync], used by the app's DI and by
/// the OS background worker (its own isolate, its own instance).

/// Folder owned by [AssetSync]: `<appSupport>/synced_assets` (never the
/// retired legacy `offline_assets` folder, which logout deletes).
const String kSyncedAssetsDirName = 'synced_assets';

Directory syncedAssetsDir(String appSupportPath) =>
    Directory(p.join(appSupportPath, kSyncedAssetsDirName));

/// A PLAIN Dio for image downloads: no interceptors (not the sync auth
/// interceptor, which would send tenant/device headers to every host), no
/// base url, no default headers. [AssetSync] adds the BE headers itself,
/// only for the BE host.
Dio createAssetDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: <String, dynamic>{},
    ),
  );
  dio.interceptors.removeImplyContentTypeInterceptor();
  return dio;
}

/// Bearer + `X-Tenant-ID` read at CALL time (the token is refreshed by the
/// app; a captured value would go stale). Missing values are left out.
Future<Map<String, String>> Function() assetBeHeaders({
  required Future<String?> Function() readAccessToken,
  required Future<String?> Function() readTenantId,
}) {
  return () async {
    final token = await readAccessToken();
    final tenant = await readTenantId();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (tenant != null && tenant.isNotEmpty) 'X-Tenant-ID': tenant,
    };
  };
}

AssetSync buildAssetSync({
  required OfflineDb db,
  required DbChangeNotifier notifier,
  required String? Function() scopeProvider,
  required String appSupportPath,
  required String baseUrl,
  required Future<String?> Function() readAccessToken,
  required Future<String?> Function() readTenantId,
  Dio? dio,
}) {
  final dir = syncedAssetsDir(appSupportPath);
  return AssetSync(
    db: db,
    dio: dio ?? createAssetDio(),
    assetsDir: () => dir,
    notifier: notifier,
    scopeProvider: scopeProvider,
    beBaseUrl: Uri.parse(baseUrl),
    beHeaders: assetBeHeaders(
      readAccessToken: readAccessToken,
      readTenantId: readTenantId,
    ),
  );
}
