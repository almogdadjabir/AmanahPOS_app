import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

const _defaultConnectTimeout = Duration(minutes: 3);
const _defaultReceiveTimeout = Duration(minutes: 3);

class DioClient {
  final String baseUrl;

  Dio dio;

  List<Interceptor> interceptors;

  DioClient(this.baseUrl, {required this.dio, required this.interceptors}) {
    dio = dio;

    if (kDebugMode) {
      /// setting proxy for reflecting network calls in Proxy man.
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (X509Certificate cert, String host, int port) {
            return true;
          };
          // Config the client.
          client.findProxy = (uri) {
            return 'PROXY 172.16.10.52:9099';
          };
           return client;
        },
      );
      //========end Proxy config==============
    }
    dio
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = _defaultConnectTimeout
      ..options.receiveTimeout = _defaultReceiveTimeout
      ..options.receiveDataWhenStatusError = true
      ..httpClientAdapter;
    if (interceptors.isNotEmpty) {
      dio.interceptors.addAll(interceptors);
    }
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          responseBody: true,
          error: true,
          requestHeader: true,
          responseHeader: true,
          request: true,
          requestBody: true,
        ),
      );
    }
  }

  Future<Response> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    data,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    var response = await dio.get(
      uri,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
    return response;
  }

  Future<Response> post(
    String uri, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    var response = await dio.post(
      uri,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return response;
  }

  Future<Response> put(
    String uri, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    var response = await dio.put(
      uri,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return response;
  }

  Future<Response> patch(
    String uri, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    var response = await dio.patch(
      uri,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return response;
  }

  Future<Response> delete(
    String uri, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    var response = await dio.delete(
      uri,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    return response;
  }

  Future<Response> fetch(RequestOptions requestOptions) async {
    var response = await dio.fetch(requestOptions);
    return response;
  }
}
