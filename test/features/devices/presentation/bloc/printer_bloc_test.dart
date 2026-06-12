import 'package:amana_pos/features/devices/domain/entities/printer_device.dart';
import 'package:amana_pos/features/devices/domain/entities/receipt_data.dart';
import 'package:amana_pos/features/devices/domain/printer_error.dart';
import 'package:amana_pos/features/devices/domain/usecases/printer_usecase.dart';
import 'package:amana_pos/features/devices/presentation/bloc/printer_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPrinterUseCase extends Mock implements PrinterUseCase {}

const printer = PrinterDevice(name: 'SAM4s Compact 3"', address: 'AA:BB:CC');
const otherPrinter = PrinterDevice(name: 'Generic 58mm', address: '11:22:33');

const receipt = ReceiptData(
  businessName: 'Amana Store',
  reference: 'Ref: RCP-001',
  dateLabel: '12 Jun 2026 10:30',
  lines: [ReceiptLine(name: 'Sugar', quantity: 1, amount: '1,200 SDG')],
  summary: [ReceiptRow(label: 'TOTAL', value: '1,200 SDG', emphasized: true)],
  paymentLabel: 'Cash',
);

void main() {
  late _MockPrinterUseCase useCase;

  setUp(() {
    useCase = _MockPrinterUseCase();
  });

  PrinterBloc build() => PrinterBloc(useCase: useCase);

  group('PrinterInitialized', () {
    blocTest<PrinterBloc, PrinterState>(
      'stays notConnected when no printer is saved',
      build: build,
      setUp: () =>
          when(() => useCase.getSavedPrinter()).thenAnswer((_) async => null),
      act: (bloc) => bloc.add(const PrinterInitialized()),
      expect: () => const <PrinterState>[],
    );

    blocTest<PrinterBloc, PrinterState>(
      'loads saved printer and silently reconnects',
      build: build,
      setUp: () {
        when(() => useCase.getSavedPrinter()).thenAnswer((_) async => printer);
        when(() => useCase.isConnected()).thenAnswer((_) async => false);
        when(() => useCase.connect(printer)).thenAnswer((_) async => true);
      },
      act: (bloc) => bloc.add(const PrinterInitialized()),
      expect: () => const [
        PrinterState(savedPrinter: printer, status: PrinterStatus.connecting),
        PrinterState(savedPrinter: printer, status: PrinterStatus.connected),
      ],
    );

    blocTest<PrinterBloc, PrinterState>(
      'falls back to notConnected (not connectionFailed) when silent '
      'reconnect fails',
      build: build,
      setUp: () {
        when(() => useCase.getSavedPrinter()).thenAnswer((_) async => printer);
        when(() => useCase.isConnected()).thenAnswer((_) async => false);
        when(() => useCase.connect(printer)).thenThrow(
            const PrinterException(PrinterError.connectionFailed));
      },
      act: (bloc) => bloc.add(const PrinterInitialized()),
      expect: () => const [
        PrinterState(savedPrinter: printer, status: PrinterStatus.connecting),
        PrinterState(
            savedPrinter: printer, status: PrinterStatus.notConnected),
      ],
    );
  });

  group('PrinterScanRequested', () {
    blocTest<PrinterBloc, PrinterState>(
      'emits scanning then discovered devices',
      build: build,
      setUp: () => when(() => useCase.scanForDevices())
          .thenAnswer((_) async => [printer, otherPrinter]),
      act: (bloc) => bloc.add(const PrinterScanRequested()),
      expect: () => const [
        PrinterState(isScanning: true),
        PrinterState(availableDevices: [printer, otherPrinter]),
      ],
    );

    blocTest<PrinterBloc, PrinterState>(
      'surfaces typed error when Bluetooth is off',
      build: build,
      setUp: () => when(() => useCase.scanForDevices())
          .thenThrow(const PrinterException(PrinterError.bluetoothOff)),
      act: (bloc) => bloc.add(const PrinterScanRequested()),
      expect: () => const [
        PrinterState(isScanning: true),
        PrinterState(error: PrinterError.bluetoothOff),
      ],
    );
  });

  group('PrinterDeviceSelected', () {
    blocTest<PrinterBloc, PrinterState>(
      'saves the printer as default and connects',
      build: build,
      setUp: () {
        when(() => useCase.savePrinter(printer)).thenAnswer((_) async {});
        when(() => useCase.connect(printer)).thenAnswer((_) async => true);
      },
      act: (bloc) => bloc.add(const PrinterDeviceSelected(printer)),
      expect: () => const [
        PrinterState(savedPrinter: printer),
        PrinterState(savedPrinter: printer, status: PrinterStatus.connecting),
        PrinterState(savedPrinter: printer, status: PrinterStatus.connected),
      ],
      verify: (_) => verify(() => useCase.savePrinter(printer)).called(1),
    );

    blocTest<PrinterBloc, PrinterState>(
      'reports connectionFailed when the printer refuses',
      build: build,
      setUp: () {
        when(() => useCase.savePrinter(printer)).thenAnswer((_) async {});
        when(() => useCase.connect(printer)).thenAnswer((_) async => false);
      },
      act: (bloc) => bloc.add(const PrinterDeviceSelected(printer)),
      expect: () => const [
        PrinterState(savedPrinter: printer),
        PrinterState(savedPrinter: printer, status: PrinterStatus.connecting),
        PrinterState(
          savedPrinter: printer,
          status: PrinterStatus.connectionFailed,
          error: PrinterError.connectionFailed,
        ),
      ],
    );
  });

  group('PrinterConnectRequested', () {
    blocTest<PrinterBloc, PrinterState>(
      'errors with noPrinterSaved when nothing is saved',
      build: build,
      act: (bloc) => bloc.add(const PrinterConnectRequested()),
      expect: () => const [
        PrinterState(error: PrinterError.noPrinterSaved),
      ],
    );
  });

  group('PrinterDisconnectRequested', () {
    blocTest<PrinterBloc, PrinterState>(
      'disconnects and returns to notConnected',
      build: build,
      seed: () => const PrinterState(
          savedPrinter: printer, status: PrinterStatus.connected),
      setUp: () => when(() => useCase.disconnect()).thenAnswer((_) async {}),
      act: (bloc) => bloc.add(const PrinterDisconnectRequested()),
      expect: () => const [
        PrinterState(
            savedPrinter: printer, status: PrinterStatus.notConnected),
      ],
    );
  });

  group('PrinterForgotten', () {
    blocTest<PrinterBloc, PrinterState>(
      'removes the saved printer',
      build: build,
      seed: () => const PrinterState(
          savedPrinter: printer, status: PrinterStatus.connected),
      setUp: () {
        when(() => useCase.disconnect()).thenAnswer((_) async {});
        when(() => useCase.removeSavedPrinter()).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const PrinterForgotten()),
      expect: () => const [
        PrinterState(status: PrinterStatus.notConnected),
      ],
      verify: (_) => verify(() => useCase.removeSavedPrinter()).called(1),
    );
  });

  group('PrinterReceiptPrintRequested', () {
    blocTest<PrinterBloc, PrinterState>(
      'walks printing -> printSuccess -> connected on success',
      build: build,
      seed: () => const PrinterState(
          savedPrinter: printer, status: PrinterStatus.connected),
      setUp: () =>
          when(() => useCase.printReceipt(receipt)).thenAnswer((_) async {}),
      act: (bloc) => bloc.add(const PrinterReceiptPrintRequested(receipt)),
      expect: () => const [
        PrinterState(savedPrinter: printer, status: PrinterStatus.printing),
        PrinterState(
            savedPrinter: printer, status: PrinterStatus.printSuccess),
        PrinterState(savedPrinter: printer, status: PrinterStatus.connected),
      ],
    );

    blocTest<PrinterBloc, PrinterState>(
      'walks printing -> printFailed -> notConnected when the link died',
      build: build,
      seed: () => const PrinterState(
          savedPrinter: printer, status: PrinterStatus.connected),
      setUp: () {
        when(() => useCase.printReceipt(receipt))
            .thenThrow(const PrinterException(PrinterError.printFailed));
        when(() => useCase.isConnected()).thenAnswer((_) async => false);
      },
      act: (bloc) => bloc.add(const PrinterReceiptPrintRequested(receipt)),
      expect: () => const [
        PrinterState(savedPrinter: printer, status: PrinterStatus.printing),
        PrinterState(
          savedPrinter: printer,
          status: PrinterStatus.printFailed,
          error: PrinterError.printFailed,
        ),
        PrinterState(
          savedPrinter: printer,
          status: PrinterStatus.notConnected,
          error: PrinterError.printFailed,
        ),
      ],
    );
  });
}
