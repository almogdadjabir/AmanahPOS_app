import 'package:amana_pos/barcode_scanner/data/services/barcode_permission_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


part 'barcode_scanner_event.dart';
part 'barcode_scanner_state.dart';

class BarcodeScannerBloc
    extends Bloc<BarcodeScannerEvent, BarcodeScannerState> {
  final BarcodePermissionService permissionService;

  BarcodeScannerBloc({
    required this.permissionService,
  }) : super(const BarcodeScannerState()) {
    on<BarcodeScannerStarted>(_onStarted);
    on<BarcodeScannerPermissionRequested>(_onPermissionRequested);
    on<BarcodeScannerPermissionRefreshed>(_onPermissionRefreshed);
    on<BarcodeScannerCodeDetected>(_onCodeDetected);
    on<BarcodeScannerResumed>(_onResumed);
    on<BarcodeScannerPaused>(_onPaused);
    on<BarcodeScannerOpenSettingsRequested>(_onOpenSettingsRequested);
  }

  Future<void> _onStarted(
      BarcodeScannerStarted event,
      Emitter<BarcodeScannerState> emit,
      ) async {
    emit(state.copyWith(
      status: BarcodeScannerStatus.checkingPermission,
      clearError: true,
      clearScannedCode: true,
      canScan: true,
    ));

    final permission = await permissionService.checkCameraPermission();
    _emitPermissionState(permission, emit);
  }

  Future<void> _onPermissionRequested(
      BarcodeScannerPermissionRequested event,
      Emitter<BarcodeScannerState> emit,
      ) async {
    emit(state.copyWith(
      status: BarcodeScannerStatus.checkingPermission,
      clearError: true,
    ));

    final permission = await permissionService.requestCameraPermission();
    _emitPermissionState(permission, emit);
  }

  Future<void> _onPermissionRefreshed(
      BarcodeScannerPermissionRefreshed event,
      Emitter<BarcodeScannerState> emit,
      ) async {
    final permission = await permissionService.checkCameraPermission();
    _emitPermissionState(permission, emit);
  }

  void _onCodeDetected(
      BarcodeScannerCodeDetected event,
      Emitter<BarcodeScannerState> emit,
      ) {
    final code = event.code.trim();

    if (code.isEmpty || !state.canScan) return;

    emit(state.copyWith(
      status: BarcodeScannerStatus.detected,
      scannedCode: code,
      canScan: false,
    ));
  }

  void _onResumed(
      BarcodeScannerResumed event,
      Emitter<BarcodeScannerState> emit,
      ) {
    if (state.hasCameraPermission) {
      emit(state.copyWith(
        status: BarcodeScannerStatus.scanning,
        canScan: true,
        clearScannedCode: true,
        clearError: true,
      ));
    }
  }

  void _onPaused(
      BarcodeScannerPaused event,
      Emitter<BarcodeScannerState> emit,
      ) {
    emit(state.copyWith(canScan: false));
  }

  Future<void> _onOpenSettingsRequested(
      BarcodeScannerOpenSettingsRequested event,
      Emitter<BarcodeScannerState> emit,
      ) async {
    await permissionService.openAppSettingsPage();
  }

  void _emitPermissionState(
      BarcodeCameraPermissionStatus permission,
      Emitter<BarcodeScannerState> emit,
      ) {
    switch (permission) {
      case BarcodeCameraPermissionStatus.granted:
        emit(state.copyWith(
          status: BarcodeScannerStatus.scanning,
          canScan: true,
          clearError: true,
        ));
        break;

      case BarcodeCameraPermissionStatus.denied:
        emit(state.copyWith(
          status: BarcodeScannerStatus.permissionDenied,
          errorMessage: 'Camera permission is required to scan barcodes.',
          canScan: false,
        ));
        break;

      case BarcodeCameraPermissionStatus.permanentlyDenied:
        emit(state.copyWith(
          status: BarcodeScannerStatus.permissionPermanentlyDenied,
          errorMessage:
          'Camera permission is disabled. Please enable it from settings.',
          canScan: false,
        ));
        break;

      case BarcodeCameraPermissionStatus.restricted:
      case BarcodeCameraPermissionStatus.limited:
        emit(state.copyWith(
          status: BarcodeScannerStatus.permissionRestricted,
          errorMessage:
          'Camera access is restricted on this device. Please check device settings.',
          canScan: false,
        ));
        break;
    }
  }
}