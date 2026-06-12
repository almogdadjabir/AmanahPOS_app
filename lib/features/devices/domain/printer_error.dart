/// Typed failure reasons surfaced to the UI, which maps them to
/// localized, user-friendly messages.
enum PrinterError {
  bluetoothOff,
  permissionDenied,
  connectionFailed,
  printFailed,
  noPrinterSaved,
  scanFailed,
}

class PrinterException implements Exception {
  final PrinterError error;
  final Object? cause;

  const PrinterException(this.error, [this.cause]);

  @override
  String toString() => 'PrinterException($error${cause == null ? '' : ', $cause'})';
}
