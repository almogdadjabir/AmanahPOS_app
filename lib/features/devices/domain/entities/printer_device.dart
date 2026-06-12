import 'package:equatable/equatable.dart';

/// How the app reaches a receipt printer.
///
/// - [bluetooth]: classic/BLE thermal printers paired over Bluetooth.
/// - [network]: LAN/WiFi printers speaking ESC/POS RAW on TCP port 9100
///   (e.g. SAM4s GIANT-100, which has no Bluetooth radio).
enum PrinterConnectionType { bluetooth, network }

/// A receipt printer the user can save as default.
class PrinterDevice extends Equatable {
  static const int defaultNetworkPort = 9100;

  final String name;

  /// Bluetooth MAC address, or IP address for network printers.
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
      type: json['type'] == 'network'
          ? PrinterConnectionType.network
          : PrinterConnectionType.bluetooth,
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

  /// "192.168.1.50:9100" for network printers, the MAC for Bluetooth.
  String get displayAddress => isNetwork ? '$address:$port' : address;

  @override
  List<Object?> get props => [name, address, type, port];
}
