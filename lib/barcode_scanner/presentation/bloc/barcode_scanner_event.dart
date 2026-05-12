part of 'barcode_scanner_bloc.dart';

abstract class BarcodeScannerEvent extends Equatable {
  const BarcodeScannerEvent();

  @override
  List<Object?> get props => [];
}

class BarcodeScannerStarted extends BarcodeScannerEvent {
  const BarcodeScannerStarted();
}

class BarcodeScannerPermissionRequested extends BarcodeScannerEvent {
  const BarcodeScannerPermissionRequested();
}

class BarcodeScannerPermissionRefreshed extends BarcodeScannerEvent {
  const BarcodeScannerPermissionRefreshed();
}

class BarcodeScannerCodeDetected extends BarcodeScannerEvent {
  final String code;

  const BarcodeScannerCodeDetected(this.code);

  @override
  List<Object?> get props => [code];
}

class BarcodeScannerResumed extends BarcodeScannerEvent {
  const BarcodeScannerResumed();
}

class BarcodeScannerPaused extends BarcodeScannerEvent {
  const BarcodeScannerPaused();
}

class BarcodeScannerOpenSettingsRequested extends BarcodeScannerEvent {
  const BarcodeScannerOpenSettingsRequested();
}