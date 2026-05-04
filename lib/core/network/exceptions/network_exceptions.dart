import 'dart:io';

import 'package:dio/dio.dart';

class NetworkExceptions {
  static String getErrorMessage(error) {
    if (error is Exception) {
      try {
        String networkExceptionMessage;
        if (error is DioException) {
          switch (error.type) {
            case DioExceptionType.cancel:
              networkExceptionMessage = 'Request Cancelled';
              break;
            case DioExceptionType.connectionTimeout:
              networkExceptionMessage = 'Connection timeout';
              break;
            case DioExceptionType.unknown:
              networkExceptionMessage = 'Unknown Error';
              break;
            case DioExceptionType.receiveTimeout:
              networkExceptionMessage = 'Receive Timeout';
              break;
            case DioExceptionType.badResponse:
              switch (error.response?.statusCode) {
                case 400:
                  networkExceptionMessage =
                      error.response?.data['detail'] ?? '400 : UnAuthorized';
                  break;
                case 401:
                  networkExceptionMessage =
                      error.response?.data['detail'] ?? '401 : UnAuthorized';
                  break;
                case 403:
                  networkExceptionMessage =
                      error.response?.data['detail'] ?? '403 : UnAuthorized';
                  break;
                case 404:
                  networkExceptionMessage =
                      error.response?.data['detail'] ?? '404 : Not found';
                  break;
                case 409:
                  networkExceptionMessage =
                      error.response?.data['detail'] ?? '409 : Conflict';
                  break;
                case 408:
                  networkExceptionMessage =
                      error.response?.data['detail'] ?? '408 : UnAuthorized';
                  break;
                case 500:
                  networkExceptionMessage =
                      '${error.response?.data['detail'] ?? '500:Internal Server Error'}';
                  break;
                case 503:
                  networkExceptionMessage = '503 : Unavailable';
                  break;
                case 422:
                  networkExceptionMessage =
                      '${error.response?.data['detail'] ?? 'Error response'}';
                  break;
                case 429:
                  networkExceptionMessage = '429 : Too many requests';
                  break;
                default:
                  var responseCode = error.response?.statusCode;
                  networkExceptionMessage =
                      'Received invalid status code: $responseCode';
              }
              break;
            case DioExceptionType.sendTimeout:
              networkExceptionMessage = 'Timeout';
              break;
            case DioExceptionType.badCertificate:
              networkExceptionMessage = 'Bad Certificate';
            case DioExceptionType.connectionError:
              networkExceptionMessage = 'Connection Error';
          }
        } else if (error is SocketException) {
          networkExceptionMessage = 'No Internet Connection';
        } else {
          networkExceptionMessage = 'UnExpected';
        }
        return networkExceptionMessage;
      } on FormatException {
        return 'Format Exception';
      } catch (_) {
        return 'Unexpected error';
      }
    } else {
      if (error.toString().contains('is not a subtype of')) {
        return 'Unable to process';
      } else {
        return 'Unexpected error';
      }
    }
  }
}
