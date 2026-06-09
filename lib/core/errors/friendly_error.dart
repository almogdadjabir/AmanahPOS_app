import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
String friendlyError(Object? error) {
  if (error is String) {
    final trimmed = error.trim();
    return trimmed.isEmpty ? _kGeneric : trimmed;
  }

  if (error is SocketException) return _kNoInternet;
  if (error is TimeoutException) return _kTimeout;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _kTimeout;
      case DioExceptionType.connectionError:
        return _kNoInternet;
      case DioExceptionType.badCertificate:
        return _kGeneric;
      case DioExceptionType.cancel:
        return _kGeneric;
      case DioExceptionType.badResponse:
      // Prefer a clean message the server sent us; otherwise stay generic.
        return _serverMessage(error.response?.data) ??
            _statusMessage(error.response?.statusCode);
      case DioExceptionType.unknown:
      // `unknown` is frequently a wrapped SocketException (offline).
        if (error.error is SocketException) return _kNoInternet;
        return _kGeneric;
    }
  }

  if (error is FormatException) return _kGeneric;

  return _kGeneric;
}

const String _kGeneric =
    'Something went wrong. Please try again.';
const String _kNoInternet =
    'No internet connection. Please check your network and try again.';
const String _kTimeout =
    'The connection timed out. Please try again.';

String _statusMessage(int? statusCode) {
  switch (statusCode) {
    case 401:
    case 403:
      return 'Your session has expired. Please sign in again.';
    case 404:
      return 'We couldn\'t find what you were looking for.';
    case 408:
      return _kTimeout;
    case 409:
      return 'That action conflicts with existing data. Please refresh and try again.';
    case 429:
      return 'Too many attempts. Please wait a moment and try again.';
    case 500:
    case 502:
    case 503:
    case 504:
      return 'The server is having trouble right now. Please try again shortly.';
    default:
      return _kGeneric;
  }
}

String? _serverMessage(dynamic data) {
  if (data is! Map) return null;

  // New format: { "error": { "message": "...", "details": { "field": ["..."] } } }
  final errorObj = data['error'];
  if (errorObj is Map) {
    final details = errorObj['details'];
    if (details is Map && details.isNotEmpty) {
      final firstField = details.values.first;
      if (firstField is List && firstField.isNotEmpty) {
        final msg = firstField.first?.toString().trim();
        if (msg != null && msg.isNotEmpty) return msg;
      }
    }
    final msg = errorObj['message']?.toString().trim();
    if (msg != null && msg.isNotEmpty) return msg;
  }

  // Legacy flat shapes.
  const fields = ['readable_message', 'detail', 'title', 'message'];
  for (final field in fields) {
    final value = data[field]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }

  return null;
}