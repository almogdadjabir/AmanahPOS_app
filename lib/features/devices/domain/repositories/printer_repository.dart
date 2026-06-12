import 'package:amana_pos/features/devices/domain/entities/printer_device.dart';

/// Receipt printer operations + default-printer persistence, covering both
/// Bluetooth and network (TCP/9100) printers.
/// Methods throw [PrinterException] with a typed [PrinterError] on failure.
abstract class PrinterRepository {
  /// The printer the user saved as default, or null if none was set up.
  Future<PrinterDevice?> getSavedPrinter();

  Future<void> savePrinter(PrinterDevice device);

  Future<void> removeSavedPrinter();

  /// Available Bluetooth printers. On Android/Windows these are the devices
  /// paired in system Bluetooth settings; on iOS/macOS this is a live BLE
  /// scan. Network printers are added manually by IP and never appear here.
  Future<List<PrinterDevice>> scanForDevices();

  Future<bool> isBluetoothEnabled();

  /// Requests Bluetooth runtime permissions where the platform needs them
  /// (Android 12+). Returns true when granted.
  Future<bool> ensurePermissions();

  Future<bool> connect(PrinterDevice device);

  Future<bool> isConnected(PrinterDevice device);

  Future<void> disconnect();

  /// Sends raw ESC/POS bytes to [device].
  Future<bool> printBytes(PrinterDevice device, List<int> bytes);
}
