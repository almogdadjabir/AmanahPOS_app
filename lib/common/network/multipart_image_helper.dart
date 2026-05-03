import 'package:amana_pos/api/network/multipart_file_extended.dart';
import 'package:amana_pos/common/services/image/app_image_picker.dart';
import 'package:dio/dio.dart';

class MultipartImageHelper {
  static Future<MultipartFile?> toMultipartFile(
      PickedAppImage? image,
      ) async {
    if (image == null) return null;

    return ExtendedMultipartFile.fromFileSync(
      image.path,
      filename: image.name,
    );
  }
}