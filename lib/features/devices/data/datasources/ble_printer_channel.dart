import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:amana_pos/features/devices/domain/entities/printer_device.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// ESC/POS printing over Bluetooth Low Energy GATT.
///
/// Covers BLE-only thermal printers, which `print_bluetooth_thermal` cannot
/// reach on Android (it only lists classic SPP paired devices there).
/// Receipt bytes are streamed to the printer's writable characteristic in
/// MTU-sized chunks.
class BlePrinterChannel {
  static const Duration scanTimeout = Duration(seconds: 5);
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _writeWithoutResponseDelay =
      Duration(milliseconds: 15);

  /// Writable characteristics used by common ESC/POS BLE printer modules,
  /// tried in this order before falling back to any writable characteristic.
  static final List<Guid> _knownWriteCharacteristics = [
    Guid('2af1'), // Standard BLE printing (service 18f0)
    Guid('49535343-8841-43f4-a8d4-ecbe34729bb3'), // ISSC/Microchip transparent UART
    Guid('ffe9'), // common Chinese printer modules (service ffe5)
    Guid('ffe1'), // HM-10 style modules (service ffe0)
  ];

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;

  bool get isPlatformSupported =>
      !kIsWeb &&
      (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isWindows);

  Future<bool> isBluetoothEnabled() async {
    if (!isPlatformSupported) return false;
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  /// Scans for nearby BLE devices advertising a name. Unnamed advertisements
  /// are dropped — a printer the user can pick must be identifiable.
  Future<List<PrinterDevice>> scan() async {
    if (!isPlatformSupported) return const [];

    final found = <String, PrinterDevice>{};

    final subscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        final name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : result.advertisementData.advName;
        if (name.isEmpty) continue;

        found[result.device.remoteId.str] = PrinterDevice(
          name: name,
          address: result.device.remoteId.str,
          type: PrinterConnectionType.ble,
        );
      }
    });

    try {
      await FlutterBluePlus.startScan(timeout: scanTimeout);
      // startScan returns immediately; wait for the timeout to elapse.
      await FlutterBluePlus.isScanning.where((scanning) => !scanning).first;
    } finally {
      await subscription.cancel();
    }

    return found.values.toList();
  }

  Future<bool> connect(String deviceId) async {
    final device = BluetoothDevice.fromId(deviceId);

    try {
      if (!device.isConnected) {
        // connect() negotiates a 512-byte MTU on Android by default.
        await device.connect(timeout: _connectTimeout);
      }

      final characteristic = await _findWriteCharacteristic(device);
      if (characteristic == null) {
        await device.disconnect();
        return false;
      }

      _device = device;
      _writeCharacteristic = characteristic;
      return true;
    } catch (_) {
      _device = null;
      _writeCharacteristic = null;
      return false;
    }
  }

  Future<bool> isConnected() async => _device?.isConnected ?? false;

  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } finally {
      _device = null;
      _writeCharacteristic = null;
    }
  }

  Future<bool> writeBytes(List<int> bytes) async {
    final device = _device;
    final characteristic = _writeCharacteristic;
    if (device == null || characteristic == null || !device.isConnected) {
      return false;
    }

    // Reliable writes when the printer supports them; otherwise fire-and-
    // forget with a short pacing delay so the module's buffer keeps up.
    final withoutResponse = !characteristic.properties.write;
    final chunkSize = max(20, device.mtuNow - 3);

    try {
      for (var offset = 0; offset < bytes.length; offset += chunkSize) {
        final chunk =
            bytes.sublist(offset, min(offset + chunkSize, bytes.length));
        await characteristic.write(chunk, withoutResponse: withoutResponse);
        if (withoutResponse) {
          await Future<void>.delayed(_writeWithoutResponseDelay);
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<BluetoothCharacteristic?> _findWriteCharacteristic(
    BluetoothDevice device,
  ) async {
    final services = await device.discoverServices();
    final writable = <BluetoothCharacteristic>[
      for (final service in services)
        for (final characteristic in service.characteristics)
          if (characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse)
            characteristic,
    ];
    if (writable.isEmpty) return null;

    for (final known in _knownWriteCharacteristics) {
      for (final characteristic in writable) {
        if (characteristic.uuid == known) return characteristic;
      }
    }
    return writable.first;
  }
}
