import 'package:amana_pos/common/localization/app_localizations_extension.dart';
import 'package:amana_pos/features/devices/domain/printer_error.dart';
import 'package:amana_pos/features/devices/presentation/bloc/printer_bloc.dart';
import 'package:amana_pos/theme/app_colors.dart';
import 'package:amana_pos/theme/app_theme_colors.dart';
import 'package:flutter/material.dart';

/// Maps printer connection states to localized labels and accent colors.
extension PrinterStatusL10n on PrinterStatus {
  String label(BuildContext context) {
    final tr = context.tr;
    return switch (this) {
      PrinterStatus.notConnected => tr.printerStatusNotConnected,
      PrinterStatus.connecting => tr.printerStatusConnecting,
      PrinterStatus.connected => tr.printerStatusConnected,
      PrinterStatus.connectionFailed => tr.printerStatusConnectionFailed,
      PrinterStatus.printing => tr.printerStatusPrinting,
      PrinterStatus.printSuccess => tr.printerStatusPrintSuccess,
      PrinterStatus.printFailed => tr.printerStatusPrintFailed,
    };
  }

  Color color(BuildContext context) {
    return switch (this) {
      PrinterStatus.notConnected => context.appColors.textHint,
      PrinterStatus.connecting ||
      PrinterStatus.printing =>
        AppColors.warning,
      PrinterStatus.connected ||
      PrinterStatus.printSuccess =>
        AppColors.success,
      PrinterStatus.connectionFailed ||
      PrinterStatus.printFailed =>
        AppColors.danger,
    };
  }
}

/// User-friendly localized message for a typed printer failure.
String printerErrorMessage(BuildContext context, PrinterError error) {
  final tr = context.tr;
  return switch (error) {
    PrinterError.bluetoothOff => tr.printerErrorBluetoothOff,
    PrinterError.permissionDenied => tr.printerErrorPermissionDenied,
    PrinterError.connectionFailed => tr.printerErrorConnectionFailed,
    PrinterError.printFailed => tr.printerErrorPrintFailed,
    PrinterError.noPrinterSaved => tr.printerErrorNoPrinterSaved,
    PrinterError.scanFailed => tr.printerErrorScanFailed,
  };
}
