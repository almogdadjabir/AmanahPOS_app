import 'package:amana_pos/core/network/app_interceptors.dart';
import 'package:amana_pos/core/network/dio_client.dart';
import 'package:amana_pos/core/network/error_handler.dart';
import 'package:amana_pos/core/network/multipart_file_extended.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

class RequestHandler {
  RequestHandler(this.dioClient);
  final DioClient dioClient;

  Future<Either<String?, T>> handleGetRequest<T>(
      String path,
      T Function(dynamic) fromJson, {
        dynamic data,
        Map<String, dynamic>? headers,
      }) async {
    try {
      final response = await dioClient.get(
        path,
        data: data,
        options: headers != null
            ? Options(headers: headers)
            : Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return Right(fromJson(response.data));
      } else {
        return Left(response.statusMessage);
      }
    } on DioException catch (e) {
      if (AppInterceptors.isSessionExpiredError(e)) return const Left(null);
      final errorMessage = ErrorHandler.handleException(e, context: 'GET $path');
      return Left(errorMessage);
    } catch (e) {
      final errorMessage = ErrorHandler.handleException(e, context: 'GET $path');
      return Left(errorMessage);
    }
  }

  Future<Either<String?, T>> handlePostRequest<T>(
      String path,
      T Function(dynamic) fromJson, {
        dynamic data,
        Map<String, dynamic>? headers,
        ProgressCallback? onSendProgress,
        ResponseType? responseType,
      }) async {
    try {

      final isMultipart = data is FormData;

      final options = Options(
        headers: headers ??
            {
              if (!isMultipart) 'Content-Type': 'application/json',
            },
        contentType: isMultipart ? 'multipart/form-data' : null,
        responseType: responseType ?? ResponseType.json,
      );

      options.extra ??= {};

      if (data is FormData) {
        options.extra!['__formDataBackup'] = await _extractFormData(data);
      }

      final response = await dioClient.post(
        path,
        data: data,
        options: options,
        onSendProgress: onSendProgress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(fromJson(response.data));
      } else {
        return Left(response.statusMessage);
      }
    } on DioException catch (e) {
      if (AppInterceptors.isSessionExpiredError(e)) return const Left(null);
      return Left(_handleDioError(e, 'POST $path'));
    } catch (e) {
      final errorMessage = ErrorHandler.handleException(e, context: 'POST $path');
      return Left(errorMessage);
    }
  }

  Future<Either<String?, T>> handlePutRequest<T>(
      String path,
      T Function(dynamic) fromJson, {
        dynamic data,
        Map<String, dynamic>? headers,
      }) async {
    try {
      final isMultipart = data is FormData;

      final options = Options(
        headers: headers ??
            {
              if (!isMultipart) 'Content-Type': 'application/json',
            },
        contentType: isMultipart ? 'multipart/form-data' : null,
      );

      options.extra ??= {};

      if (data is FormData) {
        options.extra!['__formDataBackup'] = await _extractFormData(data);
      }

      final response = await dioClient.put(path, data: data, options: options);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(fromJson(response.data));
      } else {
        return Left(response.statusMessage);
      }
    } on DioException catch (e) {
      if (AppInterceptors.isSessionExpiredError(e)) return const Left(null);
      return Left(_handleDioError(e, 'PUT $path'));
    } catch (e) {
      final errorMessage = ErrorHandler.handleException(e, context: 'PUT $path');
      return Left(errorMessage);
    }
  }

  Future<Either<String?, T>> handlePatchRequest<T>(
      String path,
      T Function(dynamic) fromJson, {
        dynamic data,
        Map<String, dynamic>? headers,
      }) async {
    try {
      final isMultipart = data is FormData;

      final options = Options(
        headers: headers ??
            {
              if (!isMultipart) 'Content-Type': 'application/json',
            },
        contentType: isMultipart ? 'multipart/form-data' : null,
      );
      options.extra ??= {};

      if (data is FormData) {
        options.extra!['__formDataBackup'] = await _extractFormData(data);
      }

      final response = await dioClient.patch(path, data: data, options: options);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(fromJson(response.data));
      } else {
        return Left(response.statusMessage);
      }
    } on DioException catch (e) {
      if (AppInterceptors.isSessionExpiredError(e)) return const Left(null);
      return Left(_handleDioError(e, 'PUT $path'));
    } catch (e) {
      final errorMessage = ErrorHandler.handleException(e, context: 'PUT $path');
      return Left(errorMessage);
    }
  }

  Future<Either<String?, List<T>>> handleGetRequestList<T>(
      String path,
      T Function(dynamic) fromJson,
      ) async {
    try {
      final response = await dioClient.get(path);

      if (response.statusCode == 200) {
        List<T> data = (response.data as List).map((item) => fromJson(item)).toList();
        return Right(data);
      } else {
        return Left(response.statusMessage);
      }
    } on DioException catch (e) {
      if (AppInterceptors.isSessionExpiredError(e)) return const Left(null);
      final errorMessage = ErrorHandler.handleException(e, context: 'GET $path');
      return Left(errorMessage);
    } catch (e) {
      final errorMessage = ErrorHandler.handleException(e, context: 'GET $path');
      return Left(errorMessage);
    }
  }

  Future<Either<String?, T>> handleDeleteRequest<T>(
      String path,
      T Function(dynamic) fromJson, {
        dynamic data,
        Map<String, dynamic>? headers,
      }) async {
    try {
      final response = await dioClient.delete(
        path,
        data: data,
        options: headers != null
            ? Options(headers: headers)
            : Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return Right(fromJson(response.data));
      } else {
        return Left(response.statusMessage);
      }
    } on DioException catch (e) {
      if (AppInterceptors.isSessionExpiredError(e)) return const Left(null);
      final errorMessage = ErrorHandler.handleException(e, context: 'DELETE $path');
      return Left(errorMessage);
    } catch (e) {
      final errorMessage = ErrorHandler.handleException(e, context: 'DELETE $path');
      return Left(errorMessage);
    }
  }

  Future<Either<String?, List<T>>> fetchDataList<T>(
      String path,
      T Function(Map<String, dynamic>) fromJson,
      ) async {
    try {
      final response = await dioClient.get(path);

      if (response.statusCode == 200) {
        List<T> data = (response.data as List)
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();
        return Right(data);
      } else {
        return Left(response.statusMessage);
      }
    } on DioException catch (e) {
      if (AppInterceptors.isSessionExpiredError(e)) return const Left(null);
      final errorMessage = ErrorHandler.handleException(e, context: 'GET $path');
      return Left(errorMessage);
    } catch (e) {
      final errorMessage = ErrorHandler.handleException(e, context: 'GET $path');
      return Left(errorMessage);
    }
  }

  String _handleDioError(DioException e, String context) {
    final data = e.response?.data;
    final code = _extractErrorCode(data);

    // Special codes - return as-is for UI to handle
    if (code == '78052') return '78052';//RestrictedRegion
    if (code == '80005') return '80005';//IdentityClaim
    if (code == '71340') return '71340';// IdentityClaim
    if (code == '93007') return '93007'; // invalid username/password
    if (code == '90008') return '90008';// Card not found/user don't have card
    if (code == '909090') return '909090';//IdentityClaim
    if (code == '92011') return '92011'; //phoneReclaim

    // Try catalog lookup first
    if (code != null) {
      final params = _extractParams(data);
      // final catalogMessage = ErrorCatalogService.instance.getErrorMessage(code, params);
      // if (catalogMessage != null) {
      //   return catalogMessage;
      // }
    }

    // Fallback to readable_message/detail from response
    final readableMessage = _extractReadableMessage(data);
    if (readableMessage != null) {
      return readableMessage;
    }

    // Final fallback
    return e.message ?? ErrorHandler.handleException(e, context: context);
  }

  String? _extractErrorCode(dynamic data) {
    if (data is! Map) return null;

    // ── New format: { "error": { "code": "..." } } ──
    final errorObj = data['error'];
    if (errorObj is Map) {
      final code = errorObj['code']?.toString().trim();
      if (code != null && code.isNotEmpty) return code;
    }

    // ── Legacy flat format ──
    final code = data['errorCode'] ?? data['error_code'] ?? data['code'];
    if (code == null) return null;
    final str = code.toString().trim();
    return str.isEmpty ? null : str;
  }

  String? _extractReadableMessage(dynamic data) {
    if (data is! Map) return null;

    // ── New format: { "error": { "message": "...", "details": { "phone": ["..."] } } } ──
    final errorObj = data['error'];
    if (errorObj is Map) {
      // Try field-level details first — more specific
      final details = errorObj['details'];
      if (details is Map && details.isNotEmpty) {
        final firstField = details.values.first;
        if (firstField is List && firstField.isNotEmpty) {
          return firstField.first.toString();
        }
      }
      // Fall back to top-level error message
      final msg = errorObj['message']?.toString().trim();
      if (msg != null && msg.isNotEmpty) return msg;
    }

    // ── Legacy flat format ──
    const fields = ['readable_message', 'detail', 'title', 'message'];
    for (final field in fields) {
      final value = data[field]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return null;
  }

  Map<String, String>? _extractParams(dynamic data) {
    if (data is! Map) return null;

    // ── New format: expose details map as params ──
    final errorObj = data['error'];
    if (errorObj is Map) {
      final details = errorObj['details'];
      if (details is Map && details.isNotEmpty) {
        return details.map((k, v) {
          final value = v is List ? v.join(', ') : v.toString();
          return MapEntry(k.toString(), value);
        });
      }
    }

    // ── Legacy flat format ──
    final templateVars = data['template_variables'];
    if (templateVars is Map && templateVars.isNotEmpty) {
      return templateVars.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    final param = data['param'];
    if (param != null) return {'param': param.toString()};
    final params = data['params'];
    if (params is Map) {
      return params.map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> _extractFormData(FormData formData) async {
    final backup = <Map<String, dynamic>>[];

    for (final field in formData.fields) {
      backup.add({'type': 'field', 'name': field.key, 'value': field.value});
    }

    for (final f in formData.files) {
      final file = f.value;
      if (file is! ExtendedMultipartFile) {
        throw Exception('Please use ExtendedMultipartFile to avoid finalize issues');
      }

      backup.add({
        'type': 'file',
        'name': f.key,
        'filename': file.filename,
        'contentType': file.contentType?.toString(),
        'filePath': file.filePath,
        'bytes': file.rawBytes,
      });
    }

    return backup;
  }
}