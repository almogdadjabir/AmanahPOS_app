import 'package:equatable/equatable.dart';

/// How the app reaches a receipt printer.
///
/// - [bluetooth]: classic (SPP) printers paired in system settings; on
///   iOS/macOS/Windows the underlying plugin speaks BLE through this type.
/// - [ble]: Bluetooth Low Energy printers driven through GATT
///   characteristics (covers BLE-only printers on Android).
/// - [network]: LAN/WiFi printers speaking ESC/POS RAW on TCP port 9100
///   (e.g. SAM4s GIANT-100, which has no Bluetooth radio).
enum PrinterConnectionType { bluetooth, ble, network }

/// A receipt printer the user can save as default.
class PrinterDevice extends Equatable {
  static const int defaultNetworkPort = 9100;

  final String name;

  /// Bluetooth MAC address / BLE remote id, or IP for network printers.
  final String address;

  final PrinterConnectionType type;

  /// TCP port for network printers; ignored for Bluetooth.
  final int port;

  const PrinterDevice({
    required this.name,
    required this.address,
    this.type = PrinterConnectionType.bluetooth,
    this.port = defaultNetworkPort,
  });

  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      type: PrinterConnectionType.values.asNameMap()[json['type']] ??
          PrinterConnectionType.bluetooth,
      port: json['port'] as int? ?? defaultNetworkPort,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'type': type.name,
        'port': port,
      };

  bool get isNetwork => type == PrinterConnectionType.network;

  bool get isBle => type == PrinterConnectionType.ble;

  /// "192.168.1.50:9100" for network printers, the MAC for Bluetooth.
  String get displayAddress => isNetwork ? '$address:$port' : address;

  @override
  List<Object?> get props => [name, address, type, port];
}
