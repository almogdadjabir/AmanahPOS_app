import 'package:amana_pos/features/sales_history/presentation/bloc/sales_report_state.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

sealed class SalesReportEvent extends Equatable {
  const SalesReportEvent();
}

class SalesReportRangeChanged extends SalesReportEvent {
  final ReportPreset preset;
  final DateTimeRange? customRange;
  const SalesReportRangeChanged({required this.preset, this.customRange});

  @override
  List<Object?> get props => [preset, customRange];
}

class SalesReportRefreshed extends SalesReportEvent {
  const SalesReportRefreshed();

  @override
  List<Object?> get props => [];
}
