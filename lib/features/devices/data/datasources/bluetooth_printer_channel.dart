import 'package:amana_pos/features/devices/domain/entities/printer_device.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

/// Thin seam over the `print_bluetooth_thermal` plugin so the repository
/// (and tests) never touch its static API directly.
abstract class BluetoothPrinterChannel {
  Future<bool> isBluetoothEnabled();

  /// Paired devices on Android/Windows; a BLE scan on iOS/macOS.
  Future<List<PrinterDevice>> discoverDevices();

  Future<bool> connect(String address);

  Future<bool> isConnected();

  Future<bool> disconnect();

  Future<bool> writeBytes(List<int> bytes);
}

class PrintBluetoothThermalChannel implements BluetoothPrinterChannel {
  @override
  Future<bool> isBluetoothEnabled() => PrintBluetoothThermal.bluetoothEnabled;

  @override
  Future<List<PrinterDevice>> discoverDevices() async {
    final devices = await PrintBluetoothThermal.pairedBluetooths;
    return devices
        .map((d) => PrinterDevice(name: d.name, address: d.macAdress))
        .where((d) => d.address.isNotEmpty)
        .toList();
  }

  @override
  Future<bool> connect(String address) =>
      PrintBluetoothThermal.connect(macPrinterAddress: address);

  @override
  Future<bool> isConnected() => PrintBluetoothThermal.connectionStatus;

  @override
  Future<bool> disconnect() => PrintBluetoothThermal.disconnect;

  @override
  Future<bool> writeBytes(List<int> bytes) =>
      PrintBluetoothThermal.writeBytes(bytes);
}
