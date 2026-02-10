import 'package:dio/dio.dart';
import '../../services/connectivity_service.dart';
import '../api_exceptions.dart';

/// Pre-flight connectivity check before each request.
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor({required ConnectivityService connectivityService})
      : _connectivityService = connectivityService;

  final ConnectivityService _connectivityService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final state = await _connectivityService.check();
    if (state == ConnectivityState.offline) {
      return handler.reject(DioException(
        requestOptions: options,
        error: const OfflineException(),
        type: DioExceptionType.connectionError,
      ));
    }
    handler.next(options);
  }
}
