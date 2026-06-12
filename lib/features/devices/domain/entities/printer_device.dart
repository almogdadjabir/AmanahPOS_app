import 'package:equatable/equatable.dart';

/// A Bluetooth receipt printer (e.g. "SAM4s Compact 3\"").
class PrinterDevice extends Equatable {
  final String name;
  final String address;

  const PrinterDevice({
    required this.name,
    required this.address,
  });

  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
      };

  @override
  List<Object?> get props => [name, address];
}
