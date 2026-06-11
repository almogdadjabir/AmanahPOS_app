import 'package:amana_pos/features/sales_history/domain/usecases/sales_history_usecase.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesReportBloc extends Bloc<SalesReportEvent, SalesReportState> {
  final SalesHistoryUseCase _useCase;

  SalesReportBloc({required SalesHistoryUseCase useCase})
      : _useCase = useCase,
        super(const SalesReportState()) {
    on<SalesReportRangeChanged>(_onRangeChanged);
    on<SalesReportRefreshed>(_onRefreshed);
    add(const SalesReportRangeChanged(preset: ReportPreset.today));
  }

  Future<void> _onRangeChanged(
    SalesReportRangeChanged event,
    Emitter<SalesReportState> emit,
  ) async {
    emit(state.copyWith(
      status: SalesReportBlocStatus.loading,
      preset: event.preset,
      customRange: event.customRange,
      clearReport: true,
      clearCustomRange: event.preset != ReportPreset.custom,
    ));
    await _fetch(emit);
  }

  Future<void> _onRefreshed(
    SalesReportRefreshed event,
    Emitter<SalesReportState> emit,
  ) async {
    emit(state.copyWith(status: SalesReportBlocStatus.loading));
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<SalesReportState> emit) async {
    final (from, to) = _resolvedDates;
    final result = await _useCase.getSalesReport(from: from, to: to);
    if (emit.isDone) return;
    result.fold(
      (error) => emit(state.copyWith(
        status: SalesReportBlocStatus.failure,
        errorMessage: error,
      )),
      (report) => emit(state.copyWith(
        status: SalesReportBlocStatus.loaded,
        report: report,
        clearError: true,
      )),
    );
  }

  (DateTime, DateTime) get _resolvedDates {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (state.preset) {
      ReportPreset.today => (today, today),
      ReportPreset.yesterday => (
          today.subtract(const Duration(days: 1)),
          today.subtract(const Duration(days: 1)),
        ),
      ReportPreset.thisWeek => (
          today.subtract(Duration(days: today.weekday - 1)),
          today,
        ),
      ReportPreset.thisMonth => (
          DateTime(now.year, now.month, 1),
          today,
        ),
      ReportPreset.custom => (
          state.customRange?.start ?? today,
          state.customRange?.end ?? today,
        ),
    };
  }
}
