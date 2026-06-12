import 'dart:io';

import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/features/devices/data/datasources/ble_printer_channel.dart';
import 'package:amana_pos/features/devices/data/datasources/bluetooth_printer_channel.dart';
import 'package:amana_pos/features/devices/data/datasources/network_printer_channel.dart';
import 'package:amana_pos/features/devices/data/services/printer_permission_service.dart';
import 'package:amana_pos/features/devices/domain/entities/printer_device.dart';
import 'package:amana_pos/features/devices/domain/printer_error.dart';
import 'package:amana_pos/features/devices/domain/repositories/printer_repository.dart';
import 'package:flutter/foundation.dart';

class PrinterRepoImpl implements PrinterRepository {
  final BluetoothPrinterChannel channel;
  final BlePrinterChannel bleChannel;
  final NetworkPrinterChannel networkChannel;
  final CacheStorage cacheStorage;
  final PrinterPermissionService permissionService;

  /// Whether scans should also run a BLE discovery. Only needed on Android,
  /// where the classic-Bluetooth plugin can't see BLE-only printers; on
  /// iOS/macOS/Windows the plugin scan is already BLE, so merging would
  /// just duplicate results.
  final bool includeBleScan;

  PrinterRepoImpl({
    required this.channel,
    required this.bleChannel,
    required this.networkChannel,
    required this.cacheStorage,
    required this.permissionService,
    bool? includeBleScan,
  }) : includeBleScan = includeBleScan ?? (!kIsWeb && Platform.isAndroid);

  @override
  Future<PrinterDevice?> getSavedPrinter() {
    return cacheStorage.getTypedObject<PrinterDevice>(
      Constants.savedPrinter,
      PrinterDevice.fromJson,
    );
  }

  @override
  Future<void> savePrinter(PrinterDevice device) {
    return cacheStorage.saveObject(Constants.savedPrinter, device.toJson());
  }

  @override
  Future<void> removeSavedPrinter() {
    return cacheStorage.saveObject(Constants.savedPrinter, null);
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    try {
      return await channel.isBluetoothEnabled();
    } catch (e) {
      throw PrinterException(PrinterError.bluetoothOff, e);
    }
  }

  @override
  Future<bool> ensurePermissions() {
    return permissionService.ensureBluetoothPermissions();
  }

  @override
  Future<List<PrinterDevice>> scanForDevices() async {
    if (!await ensurePermissions()) {
      throw const PrinterException(PrinterError.permissionDenied);
    }
    if (!await isBluetoothEnabled()) {
      throw const PrinterException(PrinterError.bluetoothOff);
    }

    try {
      final devices = await channel.discoverDevices();
      final byAddress = {for (final d in devices) d.address: d};

      if (includeBleScan) {
        // Best-effort: classic results are still useful if BLE scan fails.
        try {
          for (final device in await bleChannel.scan()) {
            byAddress.putIfAbsent(device.address, () => device);
          }
        } catch (_) {
          // Ignore BLE scan failures; surface only classic results.
        }
      }

      return byAddress.values.toList();
    } on PrinterException {
      rethrow;
    } catch (e) {
      throw PrinterException(PrinterError.scanFailed, e);
    }
  }

  @override
  Future<bool> connect(PrinterDevice device) async {
    if (device.isNetwork) {
      try {
        return await networkChannel.connect(device.address, device.port);
      } catch (e) {
        throw PrinterException(PrinterError.connectionFailed, e);
      }
    }

    if (!await ensurePermissions()) {
      throw const PrinterException(PrinterError.permissionDenied);
    }

    try {
      return device.isBle
          ? await bleChannel.connect(device.address)
          : await channel.connect(device.address);
    } catch (e) {
      throw PrinterException(PrinterError.connectionFailed, e);
    }
  }

  @override
  Future<bool> isConnected(PrinterDevice device) async {
    try {
      if (device.isNetwork) return await networkChannel.isConnected();
      if (device.isBle) return await bleChannel.isConnected();
      return await channel.isConnected();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    // Disconnecting an absent or dead link is a no-op, so drop all
    // transports rather than tracking which one is live.
    try {
      await networkChannel.disconnect();
      await bleChannel.disconnect();
      await channel.disconnect();
    } catch (_) {
      // Not an error worth surfacing.
    }
  }

  @override
  Future<bool> printBytes(PrinterDevice device, List<int> bytes) async {
    try {
      if (device.isNetwork) return await networkChannel.writeBytes(bytes);
      if (device.isBle) return await bleChannel.writeBytes(bytes);
      return await channel.writeBytes(bytes);
    } catch (e) {
      throw PrinterException(PrinterError.printFailed, e);
    }
  }
}
