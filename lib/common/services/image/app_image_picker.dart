import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

enum ImagePickFailureReason {
  cancelled,
  permissionDenied,
  permissionPermanentlyDenied,
  permissionRestricted,
  unsupported,
  unknown,
}

class PickedAppImage {
  final File file;
  final String path;
  final String name;

  const PickedAppImage({
    required this.file,
    required this.path,
    required this.name,
  });
}

class ImagePickResult {
  final PickedAppImage? image;
  final ImagePickFailureReason? failureReason;

  const ImagePickResult._({
    this.image,
    this.failureReason,
  });

  factory ImagePickResult.success(PickedAppImage image) {
    return ImagePickResult._(image: image);
  }

  factory ImagePickResult.failure(ImagePickFailureReason reason) {
    return ImagePickResult._(failureReason: reason);
  }

  bool get isSuccess => image != null;
}

class AppImagePicker {
  static final ImagePicker _picker = ImagePicker();

  static Future<ImagePickResult> pickFromGallery() async {
    if (kIsWeb) {
      return ImagePickResult.failure(ImagePickFailureReason.unsupported);
    }

    final permission = await _ensureGalleryPermission();

    if (permission != null) {
      return ImagePickResult.failure(permission);
    }

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (image == null) {
        return ImagePickResult.failure(ImagePickFailureReason.cancelled);
      }

      return ImagePickResult.success(
        PickedAppImage(
          file: File(image.path),
          path: image.path,
          name: image.name,
        ),
      );
    } catch (_) {
      return ImagePickResult.failure(ImagePickFailureReason.unknown);
    }
  }

  static Future<ImagePickResult> pickFromCamera() async {
    if (kIsWeb) {
      return ImagePickResult.failure(ImagePickFailureReason.unsupported);
    }

    final permission = await _ensureCameraPermission();

    if (permission != null) {
      return ImagePickResult.failure(permission);
    }

    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (image == null) {
        return ImagePickResult.failure(ImagePickFailureReason.cancelled);
      }

      return ImagePickResult.success(
        PickedAppImage(
          file: File(image.path),
          path: image.path,
          name: image.name,
        ),
      );
    } catch (_) {
      return ImagePickResult.failure(ImagePickFailureReason.unknown);
    }
  }

  /// Returns null when permission is allowed.
  /// Returns failure reason when permission is not allowed.
  static Future<ImagePickFailureReason?> _ensureGalleryPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.status;

      if (status.isGranted || status.isLimited) return null;

      if (status.isPermanentlyDenied) {
        return ImagePickFailureReason.permissionPermanentlyDenied;
      }

      if (status.isRestricted) {
        return ImagePickFailureReason.permissionRestricted;
      }

      final requested = await Permission.photos.request();

      if (requested.isGranted || requested.isLimited) return null;

      if (requested.isPermanentlyDenied) {
        return ImagePickFailureReason.permissionPermanentlyDenied;
      }

      if (requested.isRestricted) {
        return ImagePickFailureReason.permissionRestricted;
      }

      return ImagePickFailureReason.permissionDenied;
    }

    if (Platform.isAndroid) {
      // On modern Android, image_picker uses the system Photo Picker and usually
      // does not need storage permission. So we allow picker directly.
      return null;
    }

    return null;
  }

  /// Returns null when permission is allowed.
  /// Returns failure reason when permission is not allowed.
  static Future<ImagePickFailureReason?> _ensureCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) return null;

    if (status.isPermanentlyDenied) {
      return ImagePickFailureReason.permissionPermanentlyDenied;
    }

    if (status.isRestricted) {
      return ImagePickFailureReason.permissionRestricted;
    }

    final requested = await Permission.camera.request();

    if (requested.isGranted) return null;

    if (requested.isPermanentlyDenied) {
      return ImagePickFailureReason.permissionPermanentlyDenied;
    }

    if (requested.isRestricted) {
      return ImagePickFailureReason.permissionRestricted;
    }

    return ImagePickFailureReason.permissionDenied;
  }
}