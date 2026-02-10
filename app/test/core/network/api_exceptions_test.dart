import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/network/api_exceptions.dart';

void main() {
  group('ApiException', () {
    test('has message, statusCode, code, and body', () {
      const exception = ApiException(
        message: 'Something went wrong',
        statusCode: 500,
        code: 'INTERNAL',
        body: {'error': 'details'},
      );

      expect(exception.message, 'Something went wrong');
      expect(exception.statusCode, 500);
      expect(exception.code, 'INTERNAL');
      expect(exception.body, {'error': 'details'});
    });

    test('toString() returns formatted string with statusCode and message', () {
      const exception = ApiException(
        message: 'Bad request',
        statusCode: 400,
      );

      expect(exception.toString(), 'ApiException(400): Bad request');
    });

    test('toString() handles null statusCode', () {
      const exception = ApiException(message: 'Unknown error');

      expect(exception.toString(), 'ApiException(null): Unknown error');
    });
  });

  group('OfflineException', () {
    test('has correct message and null statusCode', () {
      const exception = OfflineException();

      expect(exception.message, 'No internet connection');
      expect(exception.statusCode, isNull);
      expect(exception.code, isNull);
    });

    test('is an ApiException subtype', () {
      const exception = OfflineException();

      expect(exception, isA<ApiException>());
    });
  });

  group('AuthExpiredException', () {
    test('has statusCode 401 and code AUTH_EXPIRED', () {
      const exception = AuthExpiredException();

      expect(exception.message, 'Authentication expired');
      expect(exception.statusCode, 401);
      expect(exception.code, 'AUTH_EXPIRED');
    });

    test('is an ApiException subtype', () {
      const exception = AuthExpiredException();

      expect(exception, isA<ApiException>());
    });
  });

  group('ConflictException', () {
    test('has statusCode 409 and code CONFLICT', () {
      const exception = ConflictException(message: 'Version mismatch');

      expect(exception.message, 'Version mismatch');
      expect(exception.statusCode, 409);
      expect(exception.code, 'CONFLICT');
    });

    test('accepts optional body', () {
      const exception = ConflictException(
        message: 'Conflict',
        body: {'serverVersion': 5},
      );

      expect(exception.body, {'serverVersion': 5});
    });

    test('is an ApiException subtype', () {
      const exception = ConflictException(message: 'conflict');

      expect(exception, isA<ApiException>());
    });
  });

  group('NotFoundException', () {
    test('has statusCode 404 and code NOT_FOUND', () {
      const exception = NotFoundException(message: 'Receipt not found');

      expect(exception.message, 'Receipt not found');
      expect(exception.statusCode, 404);
      expect(exception.code, 'NOT_FOUND');
    });

    test('is an ApiException subtype', () {
      const exception = NotFoundException(message: 'not found');

      expect(exception, isA<ApiException>());
    });
  });

  group('ValidationException', () {
    test('has statusCode 400 and code VALIDATION_ERROR', () {
      const exception = ValidationException(message: 'Invalid field');

      expect(exception.message, 'Invalid field');
      expect(exception.statusCode, 400);
      expect(exception.code, 'VALIDATION_ERROR');
    });

    test('accepts optional body', () {
      const exception = ValidationException(
        message: 'Validation failed',
        body: {'field': 'name', 'reason': 'required'},
      );

      expect(exception.body, {'field': 'name', 'reason': 'required'});
    });

    test('is an ApiException subtype', () {
      const exception = ValidationException(message: 'invalid');

      expect(exception, isA<ApiException>());
    });
  });

  group('ServerException', () {
    test('has correct code SERVER_ERROR', () {
      const exception = ServerException(message: 'Internal server error');

      expect(exception.message, 'Internal server error');
      expect(exception.code, 'SERVER_ERROR');
    });

    test('accepts optional statusCode', () {
      const exception = ServerException(
        message: 'Bad gateway',
        statusCode: 502,
      );

      expect(exception.statusCode, 502);
    });

    test('is an ApiException subtype', () {
      const exception = ServerException(message: 'error');

      expect(exception, isA<ApiException>());
    });
  });

  group('All exceptions are ApiException subtypes', () {
    test('every concrete exception is an ApiException', () {
      const offlineException = OfflineException();
      const authExpiredException = AuthExpiredException();
      const conflictException = ConflictException(message: 'conflict');
      const notFoundException = NotFoundException(message: 'not found');
      const validationException = ValidationException(message: 'invalid');
      const serverException = ServerException(message: 'error');

      expect(offlineException, isA<ApiException>());
      expect(authExpiredException, isA<ApiException>());
      expect(conflictException, isA<ApiException>());
      expect(notFoundException, isA<ApiException>());
      expect(validationException, isA<ApiException>());
      expect(serverException, isA<ApiException>());
    });
  });
}
