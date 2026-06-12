import 'package:amana_pos/features/devices/domain/entities/printer_device.dart';
import 'package:amana_pos/features/devices/domain/entities/receipt_data.dart';
import 'package:amana_pos/features/devices/domain/printer_error.dart';
import 'package:amana_pos/features/devices/domain/repositories/printer_repository.dart';
import 'package:amana_pos/features/devices/domain/services/esc_pos_encoder.dart';

class PrinterUseCase {
  final PrinterRepository repository;
  final EscPosEncoder encoder;

  PrinterUseCase({
    required this.repository,
    this.encoder = const EscPosEncoder(),
  });

  Future<PrinterDevice?> getSavedPrinter() => repository.getSavedPrinter();

  Future<void> savePrinter(PrinterDevice device) =>
      repository.savePrinter(device);

  Future<void> removeSavedPrinter() => repository.removeSavedPrinter();

  Future<List<PrinterDevice>> scanForDevices() => repository.scanForDevices();

  Future<bool> isBluetoothEnabled() => repository.isBluetoothEnabled();

  Future<bool> ensurePermissions() => repository.ensurePermissions();

  Future<bool> connect(PrinterDevice device) => repository.connect(device);

  /// Whether the saved default printer is currently reachable.
  Future<bool> isConnected() async {
    final printer = await repository.getSavedPrinter();
    if (printer == null) return false;
    return repository.isConnected(printer);
  }

  Future<void> disconnect() => repository.disconnect();

  /// Prints [data] on the saved printer, reconnecting first if the
  /// connection dropped. Throws [PrinterException] on failure.
  Future<void> printReceipt(ReceiptData data) async {
    final printer = await _ensureConnected();

    final ok =
        await repository.printBytes(printer, encoder.encodeReceipt(data));
    if (!ok) {
      throw const PrinterException(PrinterError.printFailed);
    }
  }

  Future<void> printTestTicket({
    required String businessName,
    required String dateLabel,
  }) async {
    final printer = await _ensureConnected();

    final ok = await repository.printBytes(
      printer,
      encoder.encodeTestTicket(
        businessName: businessName,
        printerName: printer.name,
        dateLabel: dateLabel,
      ),
    );
    if (!ok) {
      throw const PrinterException(PrinterError.printFailed);
    }
  }

  Future<PrinterDevice> _ensureConnected() async {
    final printer = await repository.getSavedPrinter();
    if (printer == null) {
      throw const PrinterException(PrinterError.noPrinterSaved);
    }

    if (!await repository.isConnected(printer)) {
      final connected = await repository.connect(printer);
      if (!connected) {
        throw const PrinterException(PrinterError.connectionFailed);
      }
    }

    return printer;
  }
}
