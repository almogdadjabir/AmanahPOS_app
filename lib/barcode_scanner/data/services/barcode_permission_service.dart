import 'package:permission_handler/permission_handler.dart';

enum BarcodeCameraPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
}

class BarcodePermissionService {
  Future<BarcodeCameraPermissionStatus> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return _mapStatus(status);
  }

  Future<BarcodeCameraPermissionStatus> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return _mapStatus(status);
  }

  Future<bool> openAppSettingsPage() {
    return openAppSettings();
  }

  BarcodeCameraPermissionStatus _mapStatus(PermissionStatus status) {
    if (status.isGranted) {
      return BarcodeCameraPermissionStatus.granted;
    }

    if (status.isPermanentlyDenied) {
      return BarcodeCameraPermissionStatus.permanentlyDenied;
    }

    if (status.isRestricted) {
      return BarcodeCameraPermissionStatus.restricted;
    }

    if (status.isLimited) {
      return BarcodeCameraPermissionStatus.limited;
    }

    return BarcodeCameraPermissionStatus.denied;
  }
}