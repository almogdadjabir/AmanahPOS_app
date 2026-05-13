import 'package:amana_pos/features/pos/data/datasources/pos_remote_data_source.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sale_dto.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sales_queue.dart';

class SyncManager {
  SyncManager({
    required OfflineSalesQueue salesQueue,
    required PosRemoteDataSource posRemoteDataSource,
  })  : _salesQueue = salesQueue,
        _posRemoteDataSource = posRemoteDataSource;

  final OfflineSalesQueue _salesQueue;
  final PosRemoteDataSource _posRemoteDataSource;

  bool _syncingSales = false;
  DateTime? _lastSyncAt;

  static const _kMinSyncInterval = Duration(seconds: 20);

  /// Total unsynced count (pending + syncing + failed) — for display.
  Future<int> pendingSalesCount() {
    return _salesQueue.pendingCount();
  }

  /// Only counts rows that should block logout (pending + syncing).
  Future<int> blockingPendingSalesCount() {
    return _salesQueue.blockingPendingCount();
  }

  Future<List<OfflineSaleDto>> getAllPendingSales() {
    return _salesQueue.getAllNonSyncedSales();
  }

  Future<void> deleteSale(String clientSaleId) {
    return _salesQueue.deleteSale(clientSaleId);
  }

  Future<void> clearAllPendingSales() {
    return _salesQueue.clearAll();
  }

  Future<void> syncPendingSales() async {
    if (_syncingSales) return;

    final now = DateTime.now();
    if (_lastSyncAt != null && now.difference(_lastSyncAt!) < _kMinSyncInterval) {
      return;
    }
    _lastSyncAt = now;

    _syncingSales = true;

    try {
      // Recover sales stuck in 'syncing' from a previous interrupted run.
      await _salesQueue.resetStuckSyncingSales();

      final pendingSales = await _salesQueue.getPendingSales(limit: 20);
      if (pendingSales.isEmpty) {
        _lastSyncAt = null; // Reset so the next real sync isn't blocked.
        return;
      }

      for (final sale in pendingSales) {
        await _salesQueue.markSyncing(sale.clientSaleId);
      }

      final results = await _posRemoteDataSource.syncSales(
        pendingSales.map((sale) => sale.toSyncJson()).toList(),
      );

      for (final result in results) {
        if (result.status == 'synced') {
          await _salesQueue.markSynced(
            clientSaleId: result.clientSaleId,
            serverSaleId: result.serverSaleId,
          );
        } else {
          await _salesQueue.markFailed(
            clientSaleId: result.clientSaleId,
            error: result.message ?? 'Failed to sync sale',
          );
        }
      }
    } finally {
      _syncingSales = false;
    }
  }
}