import 'package:amana_pos/features/devices/domain/entities/printer_device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrinterDevice JSON', () {
    test('network printer round-trips with type and port', () {
      const device = PrinterDevice(
        name: 'SAM4s GIANT-100',
        address: '192.168.1.50',
        type: PrinterConnectionType.network,
        port: 9100,
      );

      expect(PrinterDevice.fromJson(device.toJson()), device);
    });

    test('bluetooth printer round-trips', () {
      const device = PrinterDevice(name: 'BT Printer', address: 'AA:BB:CC');

      expect(PrinterDevice.fromJson(device.toJson()), device);
    });

    test('legacy JSON without type defaults to bluetooth', () {
      final device = PrinterDevice.fromJson(
          const {'name': 'Old printer', 'address': 'AA:BB:CC'});

      expect(device.type, PrinterConnectionType.bluetooth);
      expect(device.port, PrinterDevice.defaultNetworkPort);
    });

    test('displayAddress includes port only for network printers', () {
      const network = PrinterDevice(
        name: 'LAN',
        address: '10.0.0.5',
        type: PrinterConnectionType.network,
        port: 9100,
      );
      const bluetooth = PrinterDevice(name: 'BT', address: 'AA:BB:CC');

      expect(network.displayAddress, '10.0.0.5:9100');
      expect(bluetooth.displayAddress, 'AA:BB:CC');
    });
  });
}
