import 'package:amana_pos/features/pos/data/datasources/pos_remote_data_source.dart';
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

  Future<int> pendingSalesCount() {
    return _salesQueue.pendingCount();
  }

  Future<void> syncPendingSales() async {
    if (_syncingSales) return;

    _syncingSales = true;

    try {
      final pendingSales = await _salesQueue.getPendingSales(limit: 20);
      if (pendingSales.isEmpty) return;

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