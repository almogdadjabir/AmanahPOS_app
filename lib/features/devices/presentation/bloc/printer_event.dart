part of 'printer_bloc.dart';

sealed class PrinterEvent extends Equatable {
  const PrinterEvent();

  @override
  List<Object?> get props => [];
}

/// Load the saved printer and silently try to reconnect to it.
class PrinterInitialized extends PrinterEvent {
  const PrinterInitialized();
}

class PrinterScanRequested extends PrinterEvent {
  const PrinterScanRequested();
}

/// User picked a printer from the scan list: save as default and connect.
class PrinterDeviceSelected extends PrinterEvent {
  final PrinterDevice device;

  const PrinterDeviceSelected(this.device);

  @override
  List<Object?> get props => [device];
}

class PrinterConnectRequested extends PrinterEvent {
  const PrinterConnectRequested();
}

class PrinterDisconnectRequested extends PrinterEvent {
  const PrinterDisconnectRequested();
}

/// Remove the saved default printer.
class PrinterForgotten extends PrinterEvent {
  const PrinterForgotten();
}

class PrinterTestPrintRequested extends PrinterEvent {
  final String businessName;

  const PrinterTestPrintRequested({required this.businessName});

  @override
  List<Object?> get props => [businessName];
}

class PrinterReceiptPrintRequested extends PrinterEvent {
  final ReceiptData receipt;

  const PrinterReceiptPrintRequested(this.receipt);

  @override
  List<Object?> get props => [receipt];
}

/// Prints a receipt already turned into ESC/POS raster bytes.
class PrinterRawPrintRequested extends PrinterEvent {
  final List<int> bytes;

  const PrinterRawPrintRequested(this.bytes);

  @override
  List<Object?> get props => [bytes];
}
