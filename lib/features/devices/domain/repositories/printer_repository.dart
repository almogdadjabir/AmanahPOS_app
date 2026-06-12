import 'package:amana_pos/features/devices/domain/entities/printer_device.dart';

/// Bluetooth receipt printer operations + default-printer persistence.
/// Methods throw [PrinterException] with a typed [PrinterError] on failure.
abstract class PrinterRepository {
  /// The printer the user saved as default, or null if none was set up.
  Future<PrinterDevice?> getSavedPrinter();

  Future<void> savePrinter(PrinterDevice device);

  Future<void> removeSavedPrinter();

  /// Available printers. On Android/Windows these are the devices paired in
  /// system Bluetooth settings; on iOS/macOS this is a live BLE scan.
  Future<List<PrinterDevice>> scanForDevices();

  Future<bool> isBluetoothEnabled();

  /// Requests Bluetooth runtime permissions where the platform needs them
  /// (Android 12+). Returns true when granted.
  Future<bool> ensurePermissions();

  Future<bool> connect(PrinterDevice device);

  Future<bool> isConnected();

  Future<void> disconnect();

  /// Sends raw ESC/POS bytes to the connected printer.
  Future<bool> printBytes(List<int> bytes);
}
