part of 'barcode_scanner_bloc.dart';

enum BarcodeScannerStatus {
  initial,
  checkingPermission,
  permissionGranted,
  permissionDenied,
  permissionPermanentlyDenied,
  permissionRestricted,
  scanning,
  detected,
  failure,
}

class BarcodeScannerState extends Equatable {
  final BarcodeScannerStatus status;
  final String? scannedCode;
  final String? errorMessage;
  final bool canScan;

  const BarcodeScannerState({
    this.status = BarcodeScannerStatus.initial,
    this.scannedCode,
    this.errorMessage,
    this.canScan = true,
  });

  BarcodeScannerState copyWith({
    BarcodeScannerStatus? status,
    String? scannedCode,
    String? errorMessage,
    bool? canScan,
    bool clearScannedCode = false,
    bool clearError = false,
  }) {
    return BarcodeScannerState(
      status: status ?? this.status,
      scannedCode: clearScannedCode ? null : scannedCode ?? this.scannedCode,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      canScan: canScan ?? this.canScan,
    );
  }

  bool get hasCameraPermission =>
      status == BarcodeScannerStatus.permissionGranted ||
          status == BarcodeScannerStatus.scanning ||
          status == BarcodeScannerStatus.detected;

  @override
  List<Object?> get props => [
    status,
    scannedCode,
    errorMessage,
    canScan,
  ];
}