import 'dart:async';
import 'package:amana_pos/features/inventory/data/models/responses/expiry_report_response_dto.dart';
import 'package:amana_pos/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'expiry_report_event.dart';
part 'expiry_report_state.dart';

class ExpiryReportBloc extends Bloc<ExpiryReportEvent, ExpiryReportState> {
  final InventoryUseCase useCase;

  ExpiryReportBloc({required this.useCase}) : super(ExpiryReportState.initial()) {
    on<OnExpiryReportStarted>(_onStarted);
    on<OnExpiryReportLoadMore>(_onLoadMore);
    on<OnExpiryReportFilterChanged>(_onFilterChanged);
    on<OnExpiryReportReset>(_onReset);
  }

  Future<void> _onStarted(OnExpiryReportStarted event, Emitter<ExpiryReportState> emit) async {
    emit(state.copyWith(status: ExpiryReportStatus.loading, items: []));
    try {
      final statusParam = switch (state.filter) {
        ExpiryReportFilter.expiringSoon => 'expiring_soon',
        ExpiryReportFilter.expired => 'expired',
        ExpiryReportFilter.all => 'all',
      };
      final result = await useCase.getExpiryReport(status: statusParam, page: 1);
      result.fold(
        (error) => emit(state.copyWith(
          status: ExpiryReportStatus.failure,
          responseError: error,
        )),
        (dto) => emit(state.copyWith(
          status: ExpiryReportStatus.success,
          items: dto.results,
          currentPage: 1,
          totalPages: dto.totalPages,
          clearResponseError: true,
        )),
      );
    } catch (e) {
      emit(state.copyWith(status: ExpiryReportStatus.failure, responseError: e.toString()));
    }
  }

  Future<void> _onLoadMore(OnExpiryReportLoadMore event, Emitter<ExpiryReportState> emit) async {
    if (!state.hasMorePages) return;
    if (state.status == ExpiryReportStatus.loadingMore) return;
    emit(state.copyWith(status: ExpiryReportStatus.loadingMore));
    try {
      final statusParam = switch (state.filter) {
        ExpiryReportFilter.expiringSoon => 'expiring_soon',
        ExpiryReportFilter.expired => 'expired',
        ExpiryReportFilter.all => 'all',
      };
      final nextPage = state.currentPage + 1;
      final result = await useCase.getExpiryReport(status: statusParam, page: nextPage);
      result.fold(
        (_) => emit(state.copyWith(status: ExpiryReportStatus.success)),
        (dto) => emit(state.copyWith(
          status: ExpiryReportStatus.success,
          items: [...state.items, ...dto.results],
          currentPage: nextPage,
          totalPages: dto.totalPages,
        )),
      );
    } catch (_) {
      emit(state.copyWith(status: ExpiryReportStatus.success));
    }
  }

  void _onFilterChanged(OnExpiryReportFilterChanged event, Emitter<ExpiryReportState> emit) {
    emit(state.copyWith(filter: event.filter));
    add(const OnExpiryReportStarted());
  }

  void _onReset(OnExpiryReportReset event, Emitter<ExpiryReportState> emit) {
    emit(ExpiryReportState.initial());
  }
}
