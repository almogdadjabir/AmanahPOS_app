import 'dart:async';

import 'package:amana_pos/core/network/network_monitor.dart';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/core/offline/offline_first_manager.dart';
import 'package:amana_pos/core/sync/sync_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'offline_status_event.dart';
part 'offline_status_state.dart';

class OfflineStatusBloc extends Bloc<OfflineStatusEvent, OfflineStatusState> {
  final NetworkMonitor networkMonitor;
  final OfflineLocalCache localCache;
  final OfflineFirstManager offlineFirstManager;
  final SyncManager syncManager;

  StreamSubscription<bool>? _connectionSubscription;

  OfflineStatusBloc({
    required this.networkMonitor,
    required this.localCache,
    required this.offlineFirstManager,
    required this.syncManager,
  }) : super(OfflineStatusState.initial()) {
    on<OnOfflineStatusStarted>(_onStarted);
    on<OnOfflineStatusRefreshRequested>(_onRefreshRequested);
    on<OnOfflineStatusSyncSalesRequested>(_onSyncSalesRequested);
    on<OnOfflineConnectionChanged>(_onConnectionChanged);
    on<OnOfflinePendingSalesCountChanged>(_onPendingSalesCountChanged);
  }

  Future<void> _onStarted(
      OnOfflineStatusStarted event,
      Emitter<OfflineStatusState> emit,
      ) async {
    final hasCache = await localCache.hasBootstrapCache();
    final isOnline = await networkMonitor.isOnline;
    final pendingSalesCount = await syncManager.pendingSalesCount();

    emit(
      state.copyWith(
        hasCache: hasCache,
        canUseAppOffline: hasCache,
        pendingSalesCount: pendingSalesCount,
        connectionStatus: isOnline
            ? OfflineConnectionStatus.online
            : OfflineConnectionStatus.offline,
        clearErrorMessage: true,
      ),
    );

    _connectionSubscription ??= networkMonitor.onStatusChanged.listen(
          (isOnline) {
        add(OnOfflineConnectionChanged(isOnline: isOnline));
      },
    );

    networkMonitor.start();

    if (!hasCache && !isOnline) {
      emit(
        state.copyWith(
          bootstrapStatus: OfflineBootstrapStatus.failure,
          errorMessage:
          'Internet is required only for the first setup. Please connect once to prepare offline mode.',
        ),
      );
      return;
    }

    if (!hasCache && isOnline) {
      await _refreshAll(emit);
      return;
    }

    if (hasCache && isOnline) {
      unawaited(_backgroundRefresh());
    }
  }

  Future<void> _onRefreshRequested(
      OnOfflineStatusRefreshRequested event,
      Emitter<OfflineStatusState> emit,
      ) async {
    await _refreshAll(emit);
  }

  Future<void> _onSyncSalesRequested(
      OnOfflineStatusSyncSalesRequested event,
      Emitter<OfflineStatusState> emit,
      ) async {
    await _syncSales(emit);
  }

  Future<void> _onConnectionChanged(
      OnOfflineConnectionChanged event,
      Emitter<OfflineStatusState> emit,
      ) async {
    emit(
      state.copyWith(
        connectionStatus: event.isOnline
            ? OfflineConnectionStatus.online
            : OfflineConnectionStatus.offline,
        clearErrorMessage: true,
      ),
    );

    if (event.isOnline) {
      unawaited(_backgroundRefresh());
      unawaited(_backgroundSyncSales());
    }
  }

  void _onPendingSalesCountChanged(
      OnOfflinePendingSalesCountChanged event,
      Emitter<OfflineStatusState> emit,
      ) {
    emit(state.copyWith(pendingSalesCount: event.count));
  }

  Future<void> _refreshAll(Emitter<OfflineStatusState> emit) async {
    final isOnline = await networkMonitor.isOnline;

    if (!isOnline) {
      emit(
        state.copyWith(
          connectionStatus: OfflineConnectionStatus.offline,
          bootstrapStatus: state.hasCache
              ? state.bootstrapStatus
              : OfflineBootstrapStatus.failure,
          errorMessage: state.hasCache
              ? null
              : 'Internet is required for first offline setup.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        connectionStatus: OfflineConnectionStatus.online,
        bootstrapStatus: OfflineBootstrapStatus.loading,
        assetStatus: OfflineAssetStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      await offlineFirstManager.refreshBootstrap();

      emit(
        state.copyWith(
          bootstrapStatus: OfflineBootstrapStatus.success,
          hasCache: true,
          canUseAppOffline: true,
          lastBootstrapSyncAt: DateTime.now(),
          clearErrorMessage: true,
        ),
      );

      try {
        await offlineFirstManager.refreshAssetManifest(silent: true);

        emit(
          state.copyWith(
            assetStatus: OfflineAssetStatus.success,
            lastAssetSyncAt: DateTime.now(),
          ),
        );
      } catch (_) {
        emit(
          state.copyWith(
            assetStatus: OfflineAssetStatus.failure,
            errorMessage: 'Assets update failed. App can still work offline.',
          ),
        );
      }

      await _syncSales(emit);
    } catch (e) {
      emit(
        state.copyWith(
          bootstrapStatus: OfflineBootstrapStatus.failure,
          assetStatus: OfflineAssetStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _syncSales(Emitter<OfflineStatusState> emit) async {
    final isOnline = await networkMonitor.isOnline;

    if (!isOnline) {
      final count = await syncManager.pendingSalesCount();

      emit(
        state.copyWith(
          connectionStatus: OfflineConnectionStatus.offline,
          pendingSalesCount: count,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        salesSyncStatus: OfflineSalesSyncStatus.syncing,
        clearErrorMessage: true,
      ),
    );

    try {
      await syncManager.syncPendingSales();

      final count = await syncManager.pendingSalesCount();

      emit(
        state.copyWith(
          salesSyncStatus: OfflineSalesSyncStatus.success,
          pendingSalesCount: count,
          lastSalesSyncAt: DateTime.now(),
        ),
      );
    } catch (e) {
      final count = await syncManager.pendingSalesCount();

      emit(
        state.copyWith(
          salesSyncStatus: OfflineSalesSyncStatus.failure,
          pendingSalesCount: count,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _backgroundRefresh() async {
    try {
      final isOnline = await networkMonitor.isOnline;
      if (!isOnline) return;

      await offlineFirstManager.refreshBootstrap();

      add(const OnOfflineStatusRefreshRequested());
    } catch (_) {
      // Silent background refresh failure.
    }
  }

  Future<void> _backgroundSyncSales() async {
    try {
      final isOnline = await networkMonitor.isOnline;
      if (!isOnline) return;

      await syncManager.syncPendingSales();
      final count = await syncManager.pendingSalesCount();

      add(OnOfflinePendingSalesCountChanged(count: count));
    } catch (_) {
      // Silent background sync failure.
    }
  }

  @override
  Future<void> close() async {
    await _connectionSubscription?.cancel();
    return super.close();
  }
}