import 'package:flutter/material.dart';

enum ReportPreset { today, yesterday, custom }

sealed class SalesReportEvent {
  const SalesReportEvent();
}

class SalesReportRangeChanged extends SalesReportEvent {
  final ReportPreset preset;
  final DateTimeRange? customRange;
  const SalesReportRangeChanged({required this.preset, this.customRange});
}

class SalesReportRefreshed extends SalesReportEvent {
  const SalesReportRefreshed();
}
