import 'dart:async';

import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/data/offline_remote_data_source.dart';
import 'package:amana_pos/core/sync/sync_manager.dart';

enum OfflineFirstStatus {
  readyFromCache,
  readyFresh,
  blockedNeedsFirstOnlineSync,
  refreshFailedUsingCache,
}

class OfflineFirstResult {
  final OfflineFirstStatus status;
  final bool hasCache;
  final bool refreshedBootstrap;
  final bool refreshedAssetManifest;
  final String? message;

  const OfflineFirstResult({
    required this.status,
    required this.hasCache,
    required this.refreshedBootstrap,
    required this.refreshedAssetManifest,
    this.message,
  });

  bool get canOpenApp {
    return status == OfflineFirstStatus.readyFromCache ||
        status == OfflineFirstStatus.readyFresh ||
        status == OfflineFirstStatus.refreshFailedUsingCache;
  }
}

class OfflineFirstManager {
  OfflineFirstManager({
    required NetworkMonitor networkMonitor,
    required OfflineLocalCache localCache,
    required OfflineRemoteDataSource remoteDataSource,
    required SyncManager syncManager,
  })  : _networkMonitor = networkMonitor,
        _localCache = localCache,
        _remoteDataSource = remoteDataSource,
        _syncManager = syncManager;

  final NetworkMonitor _networkMonitor;
  final OfflineLocalCache _localCache;
  final OfflineRemoteDataSource _remoteDataSource;
  final SyncManager _syncManager;

  bool _started = false;
  bool _refreshingBootstrap = false;
  bool _refreshingAssets = false;

  StreamSubscription<bool>? _networkSubscription;

  Future<OfflineFirstResult> initializeAfterLogin() async {
    final hasCache = await _localCache.hasBootstrapCache();
    final online = await _networkMonitor.isOnline;

    _startNetworkWatcherOnce();

    if (!hasCache && !online) {
      return const OfflineFirstResult(
        status: OfflineFirstStatus.blockedNeedsFirstOnlineSync,
        hasCache: false,
        refreshedBootstrap: false,
        refreshedAssetManifest: false,
        message: 'Internet is required only for the first setup. Please connect once to prepare offline mode.',
      );
    }

    if (!hasCache && online) {
      try {
        await refreshBootstrap();
        await refreshAssetManifest(silent: true);
        unawaited(_syncManager.syncPendingSales());

        return const OfflineFirstResult(
          status: OfflineFirstStatus.readyFresh,
          hasCache: true,
          refreshedBootstrap: true,
          refreshedAssetManifest: true,
        );
      } catch (e) {
        return OfflineFirstResult(
          status: OfflineFirstStatus.blockedNeedsFirstOnlineSync,
          hasCache: false,
          refreshedBootstrap: false,
          refreshedAssetManifest: false,
          message: e.toString(),
        );
      }
    }

    if (hasCache && online) {
      unawaited(refreshBootstrap());
      unawaited(refreshAssetManifest(silent: true));
      unawaited(_syncManager.syncPendingSales());

      return const OfflineFirstResult(
        status: OfflineFirstStatus.readyFromCache,
        hasCache: true,
        refreshedBootstrap: false,
        refreshedAssetManifest: false,
      );
    }

    return const OfflineFirstResult(
      status: OfflineFirstStatus.readyFromCache,
      hasCache: true,
      refreshedBootstrap: false,
      refreshedAssetManifest: false,
    );
  }

  Future<void> refreshBootstrap() async {
    if (_refreshingBootstrap) return;

    _refreshingBootstrap = true;
    try {
      final dto = await _remoteDataSource.getBootstrap();

      if (!dto.success) {
        throw Exception('Bootstrap failed');
      }

      await _localCache.saveBootstrap(dto);
    } finally {
      _refreshingBootstrap = false;
    }
  }

  Future<void> refreshAssetManifest({bool silent = false}) async {
    if (_refreshingAssets) return;

    _refreshingAssets = true;
    try {
      final dto = await _remoteDataSource.getAssetManifest();

      if (!dto.success) {
        throw Exception('Asset manifest failed');
      }

      await _localCache.saveAssetManifest(dto);
    } catch (e) {
      if (!silent) rethrow;
    } finally {
      _refreshingAssets = false;
    }
  }

  void _startNetworkWatcherOnce() {
    if (_started) return;
    _started = true;

    _networkMonitor.start();

    _networkSubscription = _networkMonitor.onStatusChanged.listen((online) {
      if (!online) return;

      unawaited(_syncManager.syncPendingSales());
      unawaited(refreshBootstrap());
      unawaited(refreshAssetManifest(silent: true));
    });
  }

  Future<void> dispose() async {
    await _networkSubscription?.cancel();
  }
}