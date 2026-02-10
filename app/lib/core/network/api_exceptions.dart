/// Typed API exceptions.
class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.code, this.body});
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? body;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class OfflineException extends ApiException {
  const OfflineException() : super(message: 'No internet connection');
}

class AuthExpiredException extends ApiException {
  const AuthExpiredException() : super(message: 'Authentication expired', statusCode: 401, code: 'AUTH_EXPIRED');
}

class ConflictException extends ApiException {
  const ConflictException({required super.message, super.body}) : super(statusCode: 409, code: 'CONFLICT');
}

class NotFoundException extends ApiException {
  const NotFoundException({required super.message}) : super(statusCode: 404, code: 'NOT_FOUND');
}

class ValidationException extends ApiException {
  const ValidationException({required super.message, super.body}) : super(statusCode: 400, code: 'VALIDATION_ERROR');
}

class ServerException extends ApiException {
  const ServerException({required super.message, super.statusCode}) : super(code: 'SERVER_ERROR');
}
