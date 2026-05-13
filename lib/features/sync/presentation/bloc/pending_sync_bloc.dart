import 'package:amana_pos/core/sync/sync_manager.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sale_dto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pending_sync_event.dart';
part 'pending_sync_state.dart';

class PendingSyncBloc extends Bloc<PendingSyncEvent, PendingSyncState> {
  final SyncManager syncManager;

  PendingSyncBloc({required this.syncManager}) : super(const PendingSyncState()) {
    on<OnPendingSyncLoad>(_onLoad);
    on<OnPendingSyncRetryAll>(_onRetryAll);
    on<OnPendingSyncDeleteSale>(_onDeleteSale);
  }

  Future<void> _onLoad(
    OnPendingSyncLoad event,
    Emitter<PendingSyncState> emit,
  ) async {
    emit(state.copyWith(status: PendingSyncStatus.loading, clearError: true));
    try {
      final sales = await syncManager.getAllPendingSales();
      emit(state.copyWith(status: PendingSyncStatus.loaded, sales: sales));
    } catch (e) {
      emit(state.copyWith(
        status: PendingSyncStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRetryAll(
    OnPendingSyncRetryAll event,
    Emitter<PendingSyncState> emit,
  ) async {
    emit(state.copyWith(status: PendingSyncStatus.syncing, clearError: true));
    try {
      await syncManager.syncPendingSales();
      final sales = await syncManager.getAllPendingSales();
      emit(state.copyWith(status: PendingSyncStatus.loaded, sales: sales));
    } catch (e) {
      final sales = await syncManager.getAllPendingSales();
      emit(state.copyWith(
        status: PendingSyncStatus.error,
        sales: sales,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteSale(
    OnPendingSyncDeleteSale event,
    Emitter<PendingSyncState> emit,
  ) async {
    try {
      await syncManager.deleteSale(event.clientSaleId);
      final sales = await syncManager.getAllPendingSales();
      emit(state.copyWith(status: PendingSyncStatus.loaded, sales: sales));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
