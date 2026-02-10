import 'package:dio/dio.dart';
import 'api_config.dart';
import 'api_exceptions.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Singleton API client wrapping Dio.
class ApiClient {
  ApiClient({required AuthInterceptor authInterceptor, required ConnectivityInterceptor connectivityInterceptor}) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    // Order matters: connectivity check first, then auth, then retry, then logging
    _dio.interceptors.addAll([
      connectivityInterceptor,
      authInterceptor,
      RetryInterceptor(dio: _dio),
      LoggingInterceptor(),
    ]);
  }

  late final Dio _dio;

  /// Access the raw Dio instance (for presigned URL uploads that bypass base URL).
  Dio get dio => _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path, queryParameters: queryParameters);
      return _extractBody<T>(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<T> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data, queryParameters: queryParameters);
      return _extractBody<T>(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<T> put<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(path, data: data, queryParameters: queryParameters);
      return _extractBody<T>(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<T> delete<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(path, queryParameters: queryParameters);
      return _extractBody<T>(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<T> patch<T>(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(path, data: data);
      return _extractBody<T>(response);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  T _extractBody<T>(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) return {} as T;
    // API Gateway responses come through as the body directly
    return data as T;
  }

  ApiException _mapDioException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final message = data is Map ? data['message'] ?? data['error'] ?? e.message : e.message ?? 'Unknown error';
    final code = data is Map ? data['code'] : null;

    if (statusCode == 401) return const AuthExpiredException();
    if (statusCode == 404) return NotFoundException(message: message.toString());
    if (statusCode == 409) return ConflictException(message: message.toString(), body: data is Map<String, dynamic> ? data : null);
    if (statusCode == 400) return ValidationException(message: message.toString(), body: data is Map<String, dynamic> ? data : null);
    if (statusCode != null && statusCode >= 500) return ServerException(message: message.toString(), statusCode: statusCode);

    return ApiException(message: message.toString(), statusCode: statusCode, code: code?.toString());
  }
}
