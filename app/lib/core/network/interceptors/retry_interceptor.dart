import 'dart:math';
import 'package:dio/dio.dart';

/// Retries 5xx and timeout errors with exponential backoff.
/// Only retries idempotent methods (GET, PUT, DELETE).
class RetryInterceptor extends Interceptor {
  RetryInterceptor({required Dio dio, this.maxRetries = 3})
      : _dio = dio;

  final Dio _dio;
  final int maxRetries;
  static const _idempotentMethods = {'GET', 'PUT', 'DELETE'};
  final _random = Random();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final method = err.requestOptions.method.toUpperCase();
    if (!_idempotentMethods.contains(method)) {
      return handler.next(err);
    }

    final isRetryable = _isRetryable(err);
    if (!isRetryable) {
      return handler.next(err);
    }

    final retryCount = err.requestOptions.extra['_retryCount'] as int? ?? 0;
    if (retryCount >= maxRetries) {
      return handler.next(err);
    }

    // Exponential backoff: 1s, 2s, 4s + random jitter 0-500ms
    final delay = Duration(
      milliseconds: (1000 * pow(2, retryCount)).toInt() + _random.nextInt(500),
    );
    await Future.delayed(delay);

    try {
      err.requestOptions.extra['_retryCount'] = retryCount + 1;
      final response = await _dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _isRetryable(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }
    final statusCode = err.response?.statusCode;
    return statusCode != null && statusCode >= 500;
  }
}
