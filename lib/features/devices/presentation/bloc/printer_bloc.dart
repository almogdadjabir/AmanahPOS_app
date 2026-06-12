import 'package:amana_pos/features/devices/domain/entities/printer_device.dart';
import 'package:amana_pos/features/devices/domain/entities/receipt_data.dart';
import 'package:amana_pos/features/devices/domain/printer_error.dart';
import 'package:amana_pos/features/devices/domain/usecases/printer_usecase.dart';
import 'package:amana_pos/utilities/format.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'printer_event.dart';
part 'printer_state.dart';

class PrinterBloc extends Bloc<PrinterEvent, PrinterState> {
  final PrinterUseCase useCase;

  PrinterBloc({required this.useCase}) : super(const PrinterState()) {
    on<PrinterInitialized>(_onInitialized);
    on<PrinterScanRequested>(_onScanRequested);
    on<PrinterDeviceSelected>(_onDeviceSelected);
    on<PrinterConnectRequested>(_onConnectRequested);
    on<PrinterDisconnectRequested>(_onDisconnectRequested);
    on<PrinterForgotten>(_onForgotten);
    on<PrinterTestPrintRequested>(_onTestPrintRequested);
    on<PrinterReceiptPrintRequested>(_onReceiptPrintRequested);
  }

  Future<void> _onInitialized(
    PrinterInitialized event,
    Emitter<PrinterState> emit,
  ) async {
    final saved = await useCase.getSavedPrinter();
    if (saved == null) return;

    emit(state.copyWith(
      savedPrinter: saved,
      status: PrinterStatus.connecting,
      clearError: true,
    ));

    // Best-effort silent reconnect: a missing/off printer at app start is
    // expected, so failures land on notConnected, not connectionFailed.
    try {
      final connected =
          await useCase.isConnected() || await useCase.connect(saved);
      emit(state.copyWith(
        status:
            connected ? PrinterStatus.connected : PrinterStatus.notConnected,
      ));
    } on PrinterException {
      emit(state.copyWith(status: PrinterStatus.notConnected));
    }
  }

  Future<void> _onScanRequested(
    PrinterScanRequested event,
    Emitter<PrinterState> emit,
  ) async {
    emit(state.copyWith(isScanning: true, clearError: true));

    try {
      final devices = await useCase.scanForDevices();
      emit(state.copyWith(isScanning: false, availableDevices: devices));
    } on PrinterException catch (e) {
      emit(state.copyWith(
        isScanning: false,
        availableDevices: const [],
        error: e.error,
      ));
    }
  }

  Future<void> _onDeviceSelected(
    PrinterDeviceSelected event,
    Emitter<PrinterState> emit,
  ) async {
    await useCase.savePrinter(event.device);
    emit(state.copyWith(savedPrinter: event.device, clearError: true));
    await _connect(emit);
  }

  Future<void> _onConnectRequested(
    PrinterConnectRequested event,
    Emitter<PrinterState> emit,
  ) async {
    await _connect(emit);
  }

  Future<void> _onDisconnectRequested(
    PrinterDisconnectRequested event,
    Emitter<PrinterState> emit,
  ) async {
    await useCase.disconnect();
    emit(state.copyWith(
      status: PrinterStatus.notConnected,
      clearError: true,
    ));
  }

  Future<void> _onForgotten(
    PrinterForgotten event,
    Emitter<PrinterState> emit,
  ) async {
    await useCase.disconnect();
    await useCase.removeSavedPrinter();
    emit(state.copyWith(
      status: PrinterStatus.notConnected,
      clearSavedPrinter: true,
      clearError: true,
    ));
  }

  Future<void> _onTestPrintRequested(
    PrinterTestPrintRequested event,
    Emitter<PrinterState> emit,
  ) async {
    await _print(
      emit,
      () => useCase.printTestTicket(
        businessName: event.businessName,
        dateLabel: AppFormat.receiptDate(DateTime.now()),
      ),
    );
  }

  Future<void> _onReceiptPrintRequested(
    PrinterReceiptPrintRequested event,
    Emitter<PrinterState> emit,
  ) async {
    await _print(emit, () => useCase.printReceipt(event.receipt));
  }

  Future<void> _connect(Emitter<PrinterState> emit) async {
    final printer = state.savedPrinter;
    if (printer == null) {
      emit(state.copyWith(
        status: PrinterStatus.notConnected,
        error: PrinterError.noPrinterSaved,
      ));
      return;
    }

    emit(state.copyWith(status: PrinterStatus.connecting, clearError: true));

    try {
      final connected = await useCase.connect(printer);
      if (connected) {
        emit(state.copyWith(status: PrinterStatus.connected));
      } else {
        emit(state.copyWith(
          status: PrinterStatus.connectionFailed,
          error: PrinterError.connectionFailed,
        ));
      }
    } on PrinterException catch (e) {
      emit(state.copyWith(status: PrinterStatus.connectionFailed, error: e.error));
    }
  }

  Future<void> _print(
    Emitter<PrinterState> emit,
    Future<void> Function() job,
  ) async {
    emit(state.copyWith(status: PrinterStatus.printing, clearError: true));

    try {
      await job();
      emit(state.copyWith(status: PrinterStatus.printSuccess));
      emit(state.copyWith(status: PrinterStatus.connected));
    } on PrinterException catch (e) {
      emit(state.copyWith(status: PrinterStatus.printFailed, error: e.error));
      final stillConnected = await useCase.isConnected();
      emit(state.copyWith(
        status: stillConnected
            ? PrinterStatus.connected
            : PrinterStatus.notConnected,
      ));
    }
  }
}
