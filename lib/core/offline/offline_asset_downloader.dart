import 'dart:io';

import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/models/offline_asset_record.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

class OfflineAssetDownloadProgress {
  final int downloaded;
  final int total;
  final String? currentUrl;

  const OfflineAssetDownloadProgress({
    required this.downloaded,
    required this.total,
    this.currentUrl,
  });

  double get progress {
    if (total <= 0) return 0;
    return downloaded / total;
  }
}

class OfflineAssetDownloader {
  OfflineAssetDownloader({
    required Dio dio,
    required OfflineLocalCache localCache,
  })  : _dio = dio,
        _localCache = localCache;

  final Dio _dio;
  final OfflineLocalCache _localCache;

  bool _isRunning = false;

  Future<void> downloadMissingAssets({
    int batchSize = 50,
    int maxRounds = 100,
    void Function(OfflineAssetDownloadProgress progress)? onProgress,
  }) async {
    if (_isRunning) return;

    _isRunning = true;

    try {
      var downloadedCount = 0;

      for (var round = 0; round < maxRounds; round++) {
        final assets = await _localCache.getAssetsMissingLocalFiles(
          limit: batchSize,
        );

        if (assets.isEmpty) {
          onProgress?.call(
            OfflineAssetDownloadProgress(
              downloaded: downloadedCount,
              total: downloadedCount,
            ),
          );
          return;
        }

        final totalEstimate = downloadedCount + assets.length;

        for (final asset in assets) {
          if (!asset.isValid) continue;

          onProgress?.call(
            OfflineAssetDownloadProgress(
              downloaded: downloadedCount,
              total: totalEstimate,
              currentUrl: asset.url,
            ),
          );

          final localPath = await _downloadOne(asset);

          if (localPath != null) {
            await _localCache.markAssetDownloaded(
              id: asset.id,
              type: asset.type,
              localPath: localPath,
            );
          }

          downloadedCount++;

          onProgress?.call(
            OfflineAssetDownloadProgress(
              downloaded: downloadedCount,
              total: totalEstimate,
              currentUrl: asset.url,
            ),
          );
        }
      }
    } finally {
      _isRunning = false;
    }
  }

  Future<String?> _downloadOne(OfflineAssetRecord asset) async {
    try {
      final assetsDir = await _localCache.getOfflineAssetsDirectory();

      final extension = _extensionFromUrl(asset.url);
      final safeName = _safeFileName(
        '${asset.type}_${asset.id}_${asset.hash ?? asset.url.hashCode}$extension',
      );

      final targetPath = p.join(assetsDir.path, safeName);
      final tempPath = '$targetPath.tmp';

      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        return targetPath;
      }

      await _dio.download(
        asset.url,
        tempPath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(minutes: 2),
          sendTimeout: const Duration(minutes: 1),
        ),
      );

      final tempFile = File(tempPath);
      if (!await tempFile.exists()) return null;

      await tempFile.rename(targetPath);
      return targetPath;
    } catch (_) {
      return null;
    }
  }

  String _extensionFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path ?? url;
    final ext = p.extension(path).toLowerCase();

    if (ext == '.jpg' ||
        ext == '.jpeg' ||
        ext == '.png' ||
        ext == '.webp' ||
        ext == '.gif') {
      return ext;
    }

    return '.img';
  }

  String _safeFileName(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }
}