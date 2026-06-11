import 'package:amana_pos/features/sales_history/data/models/sales_report_dto.dart';
import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_event.dart';
import 'package:flutter/material.dart';

enum SalesReportBlocStatus { initial, loading, loaded, failure }

class SalesReportState {
  final SalesReportBlocStatus status;
  final ReportPreset preset;
  final DateTimeRange? customRange;
  final SalesReport? report;
  final String? errorMessage;

  const SalesReportState({
    this.status = SalesReportBlocStatus.initial,
    this.preset = ReportPreset.today,
    this.customRange,
    this.report,
    this.errorMessage,
  });

  SalesReportState copyWith({
    SalesReportBlocStatus? status,
    ReportPreset? preset,
    DateTimeRange? customRange,
    SalesReport? report,
    String? errorMessage,
    bool clearReport = false,
    bool clearError = false,
  }) =>
      SalesReportState(
        status: status ?? this.status,
        preset: preset ?? this.preset,
        customRange: customRange ?? this.customRange,
        report: clearReport ? null : (report ?? this.report),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}
