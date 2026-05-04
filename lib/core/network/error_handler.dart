import 'package:amana_pos/core/network/exceptions/network_exceptions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ErrorHandler {

  static String handleError(Response response, {String? context}) {
    // Extract error message
    if (response.data is Map && response.data.containsKey('detail')) {
      return response.data['detail'];
    } else if (response.statusMessage != null &&
        response.statusMessage!.isNotEmpty) {
      return response.statusMessage!;
    } else {
      return 'An unknown error occurred';
    }
  }

  static String handleException(
      dynamic exception, {
        String? context,
        Map<String, dynamic>? extras,
      }) {
    final errorMessage = NetworkExceptions.getErrorMessage(exception);

    // Only report non-network exceptions to Sentry
    if (exception is DioException) {
      _handleDioException(exception, context, extras);
    } else {
    }

    return errorMessage;
  }

  static void _handleDioException(
      DioException exception,
      String? context,
      Map<String, dynamic>? extras,
      ) {
    final statusCode = exception.response?.statusCode;

    // Skip network errors (they're noisy and not actionable)
    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout ||
        exception.type == DioExceptionType.connectionError) {
      if (kDebugMode) {
        debugPrint('Network error: ${exception.message}');
      }
      return;
    }
  }
}