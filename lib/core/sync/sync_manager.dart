import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/features/inventory/data/models/responses/inbound_response_dto.dart';
import 'package:amana_pos/features/inventory/data/offline/offline_inbound_queue.dart';
import 'package:amana_pos/features/pos/data/datasources/pos_remote_data_source.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sale_dto.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sales_queue.dart';

class SyncManager {
  SyncManager({
    required OfflineSalesQueue salesQueue,
    required OfflineInboundQueue inboundQueue,
    required PosRemoteDataSource posRemoteDataSource,
    required RequestHandler requestHandler,
  })  : _salesQueue = salesQueue,
        _inboundQueue = inboundQueue,
        _posRemoteDataSource = posRemoteDataSource,
        _requestHandler = requestHandler;

  final OfflineSalesQueue _salesQueue;
  final OfflineInboundQueue _inboundQueue;
  final PosRemoteDataSource _posRemoteDataSource;
  final RequestHandler _requestHandler;

  bool _syncingSales = false;
  bool _syncingInbound = false;
  DateTime? _lastSyncAt;

  static const _kMinSyncInterval = Duration(seconds: 20);

  Future<int> pendingSalesCount() async {
    final sales = await _salesQueue.pendingCount();
    final inbound = await _inboundQueue.pendingCount();
    return sales + inbound;
  }

  Future<int> blockingPendingSalesCount() async {
    final sales = await _salesQueue.blockingPendingCount();
    final inbound = await _inboundQueue.pendingCount();
    return sales + inbound;
  }

  Future<List<OfflineSaleDto>> getAllPendingSales() {
    return _salesQueue.getAllNonSyncedSales();
  }

  Future<void> deleteSale(String clientSaleId) {
    return _salesQueue.deleteSale(clientSaleId);
  }

  Future<void> clearAllPendingSales() async {
    await _salesQueue.clearAll();
    await _inboundQueue.clearAll();
  }

  Future<void> syncPendingSales() async {
    if (_syncingSales || _syncingInbound) return;

    final now = DateTime.now();
    if (_lastSyncAt != null &&
        now.difference(_lastSyncAt!) < _kMinSyncInterval) {
      return;
    }

    _lastSyncAt = now;

    try {
      await _syncPendingSalesOnly();
      await syncPendingInbound();
    } finally {
      _lastSyncAt = null;
    }
  }

  Future<void> _syncPendingSalesOnly() async {
    if (_syncingSales) return;

    _syncingSales = true;

    try {
      await _salesQueue.resetStuckSyncingSales();

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

  Future<void> syncPendingInbound() async {
    if (_syncingInbound) return;

    _syncingInbound = true;

    try {
      await _inboundQueue.resetStuckSyncing();

      final pending = await _inboundQueue.getPending(limit: 20);
      if (pending.isEmpty) return;

      for (final txn in pending) {
        await _inboundQueue.markSyncing(txn.clientInboundId);

        final response = await _requestHandler.handlePostRequest(
          'api/v1/inventory/inbound/',
              (data) => InboundResponseDto.fromJson(
            data as Map<String, dynamic>,
          ),
          data: txn.request.toJson(),
        );

        final error = response.getLeft().toNullable();
        final success = response.getRight().toNullable()?.success == true;

        if (error == null && success) {
          await _inboundQueue.markSynced(txn.clientInboundId);
        } else {
          await _inboundQueue.markFailed(
            clientInboundId: txn.clientInboundId,
            error: error ?? 'Failed to sync inbound transaction',
          );
        }
      }
    } finally {
      _syncingInbound = false;
    }
  }
}