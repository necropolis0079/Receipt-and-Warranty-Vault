import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs request/response details in debug mode, errors only in release.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      dev.log('\u2192 ${options.method} ${options.uri}', name: 'API');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final ms = response.requestOptions.extra['_startTime'] != null
          ? DateTime.now().difference(response.requestOptions.extra['_startTime'] as DateTime).inMilliseconds
          : 0;
      dev.log('\u2190 ${response.statusCode} ${response.requestOptions.uri} (${ms}ms)', name: 'API');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    dev.log(
      '\u2715 ${err.requestOptions.method} ${err.requestOptions.uri} \u2192 ${err.response?.statusCode ?? err.type}',
      name: 'API',
      error: err.message,
    );
    handler.next(err);
  }
}
