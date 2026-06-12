import 'dart:async';
import 'dart:io';

import 'package:amana_pos/core/api/request_handler.dart';
import 'package:amana_pos/features/pos/data/datasources/pos_submit_exception.dart';
import 'package:amana_pos/features/pos/data/model/offline/offline_sale_sync_response_dto.dart';
import 'package:amana_pos/features/pos/data/model/pos_submit_result.dart';
import 'package:amana_pos/features/pos/data/model/requests/create_sale_request_dto.dart';
import 'package:dio/dio.dart';

class PosRemoteDataSource {
  PosRemoteDataSource(this._requestHandler);

  final RequestHandler _requestHandler;

  Future<PosSubmitResult> createSale(CreateSaleRequestDto dto) async {
    try {
      final response = await _requestHandler.dioClient.post(
        'api/v1/sales/',
        data: dto.toJson(),
        options: Options(
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          responseType: ResponseType.json,
        ),
      );

      final statusCode = response.statusCode ?? 0;

      if (statusCode != 200 && statusCode != 201) {
        throw _mapStatusCodeToSubmitException(
          statusCode: statusCode,
          data: response.data,
          fallbackMessage: response.statusMessage ?? 'Failed to create sale',
        );
      }

      final saleData = _extractSaleData(response.data);

      return PosSubmitResult.synced(
        clientSaleId: dto.clientSaleId,
        saleId: saleData['id']?.toString(),
        receiptNumber: saleData['receipt_number']?.toString(),
        taxAmount: saleData['tax_amount']?.toString(),
        taxRate: saleData['tax_rate']?.toString(),
        taxInclusive:
            saleData['tax_inclusive'] is bool ? saleData['tax_inclusive'] as bool : null,
        netAmount: saleData['net_amount']?.toString(),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on PosSubmitException {
      rethrow;
    } catch (_) {
      throw const PosSubmitException(
        message: 'Failed to submit sale. Please try again.',
        type: PosSubmitFailureType.unknown,
      );
    }
  }

  Future<List<OfflineSaleSyncResult>> syncSales(
      List<Map<String, dynamic>> sales,
      ) async {
    final response =
    await _requestHandler.handlePostRequest<OfflineSaleSyncResponseDto>(
      'api/v1/sales/offline-sync/',
      OfflineSaleSyncResponseDto.fromJson,
      data: {'sales': sales},
    );

    return response.match(
          (error) => throw Exception(error ?? 'Failed to sync offline sales'),
          (data) => data.results,
    );
  }

  Map<String, dynamic> _extractSaleData(dynamic data) {
    if (data is! Map) return <String, dynamic>{};

    final root = Map<String, dynamic>.from(data);

    final nestedData = root['data'];
    if (nestedData is Map) {
      return Map<String, dynamic>.from(nestedData);
    }

    return root;
  }

  PosSubmitException _mapDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return PosSubmitException(
          message: _extractReadableMessage(exception.response?.data) ??
              'Connection timeout. Sale saved offline.',
          type: PosSubmitFailureType.timeout,
        );

      case DioExceptionType.connectionError:
        return PosSubmitException(
          message: _extractReadableMessage(exception.response?.data) ??
              'No internet connection. Sale saved offline.',
          type: PosSubmitFailureType.network,
        );

      case DioExceptionType.badResponse:
        return _mapStatusCodeToSubmitException(
          statusCode: exception.response?.statusCode,
          data: exception.response?.data,
          fallbackMessage: exception.message ?? 'Failed to create sale',
        );

      case DioExceptionType.cancel:
        return const PosSubmitException(
          message: 'Sale request was cancelled.',
          type: PosSubmitFailureType.unknown,
        );

      case DioExceptionType.badCertificate:
        return const PosSubmitException(
          message: 'Secure connection failed. Please try again.',
          type: PosSubmitFailureType.unknown,
        );

      case DioExceptionType.unknown:
        final rawError = exception.error;

        if (rawError is SocketException) {
          return const PosSubmitException(
            message: 'No internet connection. Sale saved offline.',
            type: PosSubmitFailureType.network,
          );
        }

        if (rawError is TimeoutException) {
          return const PosSubmitException(
            message: 'Connection timeout. Sale saved offline.',
            type: PosSubmitFailureType.timeout,
          );
        }

        return PosSubmitException(
          message: exception.message ?? 'Failed to submit sale.',
          type: PosSubmitFailureType.unknown,
        );
    }
  }

  PosSubmitException _mapStatusCodeToSubmitException({
    required int? statusCode,
    required dynamic data,
    required String fallbackMessage,
  }) {
    final message = _extractReadableMessage(data) ?? fallbackMessage;
    final errorCode = _extractErrorCode(data);

    if (errorCode == 'BUSINESS_LOGIC_ERROR') {
      return PosSubmitException(
        message: message,
        type: PosSubmitFailureType.business,
      );
    }

    switch (statusCode) {
      case 400:
      case 404:
      case 409:
      case 422:
        return PosSubmitException(
          message: message,
          type: PosSubmitFailureType.business,
        );

      case 401:
      case 403:
        return PosSubmitException(
          message: message,
          type: PosSubmitFailureType.unauthorized,
        );

      case 502:
      case 503:
      case 504:
        return PosSubmitException(
          message: message,
          type: PosSubmitFailureType.serverUnavailable,
        );

      default:
        return PosSubmitException(
          message: message,
          type: PosSubmitFailureType.unknown,
        );
    }
  }

  String? _extractErrorCode(dynamic data) {
    if (data is! Map) return null;

    final error = data['error'];
    if (error is Map) {
      final code = error['code']?.toString().trim();
      if (code != null && code.isNotEmpty) return code;
    }

    final code = data['code'] ?? data['error_code'] ?? data['errorCode'];
    final value = code?.toString().trim();

    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? _extractReadableMessage(dynamic data) {
    if (data is! Map) return null;

    final error = data['error'];
    if (error is Map) {
      final details = error['details'];

      if (details is Map && details.isNotEmpty) {
        final firstValue = details.values.first;

        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }

        if (firstValue != null) {
          return firstValue.toString();
        }
      }

      final message = error['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }

    const fields = [
      'readable_message',
      'detail',
      'title',
      'message',
    ];

    for (final field in fields) {
      final value = data[field]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return null;
  }
}