import 'dart:async';
import 'package:amana_pos/core/offline/data/offline_local_cache.dart';
import 'package:amana_pos/features/inventory/data/models/responses/expiry_report_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/inbound_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/premium_summary_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/stock_response_dto.dart';
import 'package:amana_pos/features/inventory/data/models/responses/vendor_summary_dto.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'premium_inventory_event.dart';
part 'premium_inventory_state.dart';

class PremiumInventoryBloc extends Bloc<PremiumInventoryEvent, PremiumInventoryState> {
  final InventoryUseCase useCase;
  final OfflineLocalCache offlineLocalCache;
  final Future<bool> Function() isOnline;

  PremiumInventoryBloc({
    required this.useCase,
    required this.offlineLocalCache,
    required this.isOnline,
  }) : super(PremiumInventoryState.initial()) {
    on<OnPremiumInventoryStarted>(_onStarted);
    on<OnPremiumInventoryRefreshed>(_onStarted);
    on<OnPremiumInventoryReset>(_onReset);
  }

  Future<void> _onStarted(
    PremiumInventoryEvent event,
    Emitter<PremiumInventoryState> emit,
  ) async {
    emit(state.copyWith(status: PremiumInventoryStatus.loading));

    // 1. Load caches in parallel
    final cacheResults = await Future.wait([
      offlineLocalCache.getPremiumSummary(),
      offlineLocalCache.getVendors(),
      offlineLocalCache.getInboundTransactions(limit: 50),
      offlineLocalCache.getStock(),
    ]);

    final cachedSummary = cacheResults[0] as PremiumSummaryData?;
    final cachedVendors = cacheResults[1] as List;
    final cachedInbound = cacheResults[2] as List;
    final cachedStock = cacheResults[3] as List;

    final hasCache = cachedSummary != null ||
        cachedVendors.isNotEmpty ||
        cachedInbound.isNotEmpty ||
        cachedStock.isNotEmpty;

    if (hasCache) {
      emit(state.copyWith(
        status: PremiumInventoryStatus.success,
        premiumSummary: cachedSummary,
        recentInbound: List<InboundTransactionData>.from(cachedInbound),
        stockPage: List<StockData>.from(cachedStock),
        isFromCache: true,
      ));
    }

    // 2. Network refresh
    final online = await isOnline();
    if (!online) {
      if (!hasCache) {
        emit(state.copyWith(status: PremiumInventoryStatus.failure, isFromCache: false));
      }
      return;
    }

    try {
      final summaryResult = await useCase.getPremiumSummary();
      final vendorSummaryResult = await useCase.getVendorSummary();
      final expiryResult = await useCase.getExpiryReport(status: 'expiring_soon');
      final inboundResult = await useCase.getInboundList(pageSize: 50);
      final stockResult = await useCase.getStock(page: 1, pageSize: 20);

      final summary = summaryResult.fold<PremiumSummaryData?>((_) => null, (v) => v);
      final vendorSummary = vendorSummaryResult.fold<VendorSummaryData?>((_) => null, (v) => v);
      final expiryItems = expiryResult.fold<List<ExpiryReportItem>>(
        (_) => <ExpiryReportItem>[],
        (v) => v.results,
      );
      final inboundTxns = inboundResult.fold<List<InboundTransactionData>>(
        (_) => <InboundTransactionData>[],
        (v) => v.results,
      );
      final stockList = stockResult.fold<List<StockData>>(
        (_) => <StockData>[],
        (v) => v.results ?? <StockData>[],
      );

      final lowStock = stockList
          .where((s) => (s.isLowStock ?? false) || (s.isOutOfStock ?? false))
          .take(5)
          .toList();

      // Save caches
      if (summary != null) await offlineLocalCache.savePremiumSummary(summary);
      if (inboundTxns.isNotEmpty) await offlineLocalCache.saveInboundTransactions(inboundTxns);

      emit(state.copyWith(
        status: PremiumInventoryStatus.success,
        premiumSummary: summary,
        vendorSummary: vendorSummary,
        expiryPreview: expiryItems.take(5).toList(),
        recentInbound: inboundTxns,
        stockPage: stockList,
        lowStockItems: lowStock,
        isFromCache: false,
        clearResponseError: true,
      ));
    } catch (e) {
      if (!hasCache) {
        emit(state.copyWith(
          status: PremiumInventoryStatus.failure,
          responseError: e.toString(),
        ));
      }
    }
  }

  void _onReset(OnPremiumInventoryReset event, Emitter<PremiumInventoryState> emit) {
    emit(PremiumInventoryState.initial());
  }
}
