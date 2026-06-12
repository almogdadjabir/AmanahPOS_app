import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Bluetooth runtime permissions.
///
/// Only Android needs explicit runtime requests (scan/connect on 12+,
/// location-backed discovery below that). iOS/macOS prompt automatically on
/// first CoreBluetooth use, and Windows has no Bluetooth permission model.
class PrinterPermissionService {
  Future<bool> ensureBluetoothPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<bool> openAppSettingsPage() => openAppSettings();
}
