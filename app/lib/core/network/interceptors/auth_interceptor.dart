import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:dio/dio.dart';
import '../api_exceptions.dart';

/// Attaches Cognito JWT access token to every request.
/// On 401, attempts silent token refresh.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final session = await Amplify.Auth.fetchAuthSession(
        options: const FetchAuthSessionOptions(forceRefresh: false),
      );
      if (session is CognitoAuthSession) {
        final token = session.userPoolTokensResult.value.accessToken.raw;
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // If auth fails, let the request proceed without token —
      // the server will return 401 and we handle it in onError.
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        // Force refresh the token
        final session = await Amplify.Auth.fetchAuthSession(
          options: const FetchAuthSessionOptions(forceRefresh: true),
        );
        if (session is CognitoAuthSession) {
          final token = session.userPoolTokensResult.value.accessToken.raw;
          // Retry the original request with new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $token';
          final response = await Dio().fetch(options);
          return handler.resolve(response);
        }
      } catch (_) {
        // Token refresh failed — propagate auth expired
        return handler.reject(DioException(
          requestOptions: err.requestOptions,
          error: const AuthExpiredException(),
          type: DioExceptionType.unknown,
        ));
      }
    }
    handler.next(err);
  }
}
