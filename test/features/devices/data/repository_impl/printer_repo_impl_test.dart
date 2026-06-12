import 'package:amana_pos/common/services/local/local_storage.dart';
import 'package:amana_pos/config/constants.dart';
import 'package:amana_pos/features/devices/data/datasources/bluetooth_printer_channel.dart';
import 'package:amana_pos/features/devices/data/datasources/network_printer_channel.dart';
import 'package:amana_pos/features/devices/data/repository_impl/printer_repo_impl.dart';
import 'package:amana_pos/features/devices/data/services/printer_permission_service.dart';
import 'package:amana_pos/features/devices/domain/entities/printer_device.dart';
import 'package:amana_pos/features/devices/domain/printer_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockChannel extends Mock implements BluetoothPrinterChannel {}

class _MockNetworkChannel extends Mock implements NetworkPrinterChannel {}

class _MockCacheStorage extends Mock implements CacheStorage {}

class _MockPermissionService extends Mock implements PrinterPermissionService {}

const printer = PrinterDevice(name: 'SAM4s Compact 3"', address: 'AA:BB:CC');

const networkPrinter = PrinterDevice(
  name: 'SAM4s GIANT-100',
  address: '192.168.1.50',
  type: PrinterConnectionType.network,
  port: 9100,
);

void main() {
  late _MockChannel channel;
  late _MockNetworkChannel networkChannel;
  late _MockCacheStorage cache;
  late _MockPermissionService permissions;
  late PrinterRepoImpl repo;

  setUp(() {
    channel = _MockChannel();
    networkChannel = _MockNetworkChannel();
    cache = _MockCacheStorage();
    permissions = _MockPermissionService();
    repo = PrinterRepoImpl(
      channel: channel,
      networkChannel: networkChannel,
      cacheStorage: cache,
      permissionService: permissions,
    );

    when(() => permissions.ensureBluetoothPermissions())
        .thenAnswer((_) async => true);
  });

  group('persistence', () {
    test('savePrinter stores JSON under the saved_printer key', () async {
      when(() => cache.saveObject(Constants.savedPrinter, printer.toJson()))
          .thenAnswer((_) async => true);

      await repo.savePrinter(printer);

      verify(() =>
              cache.saveObject(Constants.savedPrinter, printer.toJson()))
          .called(1);
    });

    test('getSavedPrinter round-trips the device', () async {
      when(() => cache.getTypedObject<PrinterDevice>(
            Constants.savedPrinter,
            PrinterDevice.fromJson,
          )).thenAnswer((_) async => printer);

      expect(await repo.getSavedPrinter(), printer);
    });

    test('removeSavedPrinter clears the key', () async {
      when(() => cache.saveObject(Constants.savedPrinter, null))
          .thenAnswer((_) async => true);

      await repo.removeSavedPrinter();

      verify(() => cache.saveObject(Constants.savedPrinter, null)).called(1);
    });
  });

  group('scanForDevices', () {
    test('throws permissionDenied when permissions are refused', () async {
      when(() => permissions.ensureBluetoothPermissions())
          .thenAnswer((_) async => false);

      expect(
        repo.scanForDevices(),
        throwsA(isA<PrinterException>()
            .having((e) => e.error, 'error', PrinterError.permissionDenied)),
      );
    });

    test('throws bluetoothOff when the radio is disabled', () async {
      when(() => channel.isBluetoothEnabled()).thenAnswer((_) async => false);

      expect(
        repo.scanForDevices(),
        throwsA(isA<PrinterException>()
            .having((e) => e.error, 'error', PrinterError.bluetoothOff)),
      );
    });

    test('returns discovered devices', () async {
      when(() => channel.isBluetoothEnabled()).thenAnswer((_) async => true);
      when(() => channel.discoverDevices())
          .thenAnswer((_) async => [printer]);

      expect(await repo.scanForDevices(), [printer]);
    });

    test('wraps plugin failures as scanFailed', () async {
      when(() => channel.isBluetoothEnabled()).thenAnswer((_) async => true);
      when(() => channel.discoverDevices()).thenThrow(Exception('boom'));

      expect(
        repo.scanForDevices(),
        throwsA(isA<PrinterException>()
            .having((e) => e.error, 'error', PrinterError.scanFailed)),
      );
    });
  });

  group('connect / print', () {
    test('connect wraps plugin failures as connectionFailed', () async {
      when(() => channel.connect(printer.address))
          .thenThrow(Exception('boom'));

      expect(
        repo.connect(printer),
        throwsA(isA<PrinterException>()
            .having((e) => e.error, 'error', PrinterError.connectionFailed)),
      );
    });

    test('printBytes wraps plugin failures as printFailed', () async {
      when(() => channel.writeBytes(any())).thenThrow(Exception('boom'));

      expect(
        repo.printBytes(printer, [0x1B, 0x40]),
        throwsA(isA<PrinterException>()
            .having((e) => e.error, 'error', PrinterError.printFailed)),
      );
    });

    test('isConnected swallows plugin errors and reports false', () async {
      when(() => channel.isConnected()).thenThrow(Exception('boom'));

      expect(await repo.isConnected(printer), isFalse);
    });
  });

  group('network printers', () {
    test('connect routes to the network channel without Bluetooth '
        'permissions', () async {
      when(() => networkChannel.connect('192.168.1.50', 9100))
          .thenAnswer((_) async => true);

      expect(await repo.connect(networkPrinter), isTrue);

      verify(() => networkChannel.connect('192.168.1.50', 9100)).called(1);
      verifyNever(() => permissions.ensureBluetoothPermissions());
      verifyNever(() => channel.connect(any()));
    });

    test('printBytes routes to the network channel', () async {
      when(() => networkChannel.writeBytes(any()))
          .thenAnswer((_) async => true);

      expect(await repo.printBytes(networkPrinter, [0x1B, 0x40]), isTrue);

      verify(() => networkChannel.writeBytes([0x1B, 0x40])).called(1);
      verifyNever(() => channel.writeBytes(any()));
    });

    test('isConnected routes to the network channel', () async {
      when(() => networkChannel.isConnected()).thenAnswer((_) async => true);

      expect(await repo.isConnected(networkPrinter), isTrue);

      verifyNever(() => channel.isConnected());
    });

    test('unreachable host surfaces as connectionFailed', () async {
      when(() => networkChannel.connect(any(), any()))
          .thenThrow(Exception('unreachable'));

      expect(
        repo.connect(networkPrinter),
        throwsA(isA<PrinterException>()
            .having((e) => e.error, 'error', PrinterError.connectionFailed)),
      );
    });
  });
}
