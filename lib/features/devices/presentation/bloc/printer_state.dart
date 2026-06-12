part of 'printer_bloc.dart';

enum PrinterStatus {
  notConnected,
  connecting,
  connected,
  connectionFailed,
  printing,
  printSuccess,
  printFailed,
}

extension PrinterStatusX on PrinterStatus {
  bool get isBusy =>
      this == PrinterStatus.connecting || this == PrinterStatus.printing;

  bool get isConnected =>
      this == PrinterStatus.connected ||
      this == PrinterStatus.printing ||
      this == PrinterStatus.printSuccess;
}

class PrinterState extends Equatable {
  final PrinterStatus status;
  final PrinterDevice? savedPrinter;
  final List<PrinterDevice> availableDevices;
  final bool isScanning;

  /// Typed reason for the last failure; the UI maps it to a localized
  /// message. Null when the last operation succeeded.
  final PrinterError? error;

  const PrinterState({
    this.status = PrinterStatus.notConnected,
    this.savedPrinter,
    this.availableDevices = const [],
    this.isScanning = false,
    this.error,
  });

  bool get hasSavedPrinter => savedPrinter != null;

  PrinterState copyWith({
    PrinterStatus? status,
    PrinterDevice? savedPrinter,
    bool clearSavedPrinter = false,
    List<PrinterDevice>? availableDevices,
    bool? isScanning,
    PrinterError? error,
    bool clearError = false,
  }) {
    return PrinterState(
      status: status ?? this.status,
      savedPrinter:
          clearSavedPrinter ? null : (savedPrinter ?? this.savedPrinter),
      availableDevices: availableDevices ?? this.availableDevices,
      isScanning: isScanning ?? this.isScanning,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [status, savedPrinter, availableDevices, isScanning, error];
}
