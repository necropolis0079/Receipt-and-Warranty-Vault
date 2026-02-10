import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/core/network/interceptors/retry_interceptor.dart';

class MockDio extends Mock implements Dio {}

class MockErrorInterceptorHandler extends Mock
    implements ErrorInterceptorHandler {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeResponse extends Fake implements Response<dynamic> {}

void main() {
  late MockDio mockDio;
  late MockErrorInterceptorHandler mockHandler;
  late RetryInterceptor interceptor;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeResponse());
  });

  setUp(() {
    mockDio = MockDio();
    mockHandler = MockErrorInterceptorHandler();
    interceptor = RetryInterceptor(dio: mockDio, maxRetries: 3);
  });

  DioException makeDioException({
    required String method,
    int? statusCode,
    DioExceptionType type = DioExceptionType.badResponse,
    Map<String, dynamic>? extras,
  }) {
    final options = RequestOptions(path: '/api/receipts', method: method);
    if (extras != null) {
      options.extra.addAll(extras);
    }
    return DioException(
      requestOptions: options,
      type: type,
      response: statusCode != null
          ? Response(
              requestOptions: options,
              statusCode: statusCode,
            )
          : null,
    );
  }

  group('RetryInterceptor', () {
    test('does not retry on non-idempotent method (POST)', () {
      final err = makeDioException(method: 'POST', statusCode: 500);

      interceptor.onError(err, mockHandler);

      verify(() => mockHandler.next(err)).called(1);
      verifyNever(() => mockDio.fetch<dynamic>(any()));
    });

    test('does not retry on 4xx errors', () {
      final err = makeDioException(method: 'GET', statusCode: 400);

      interceptor.onError(err, mockHandler);

      verify(() => mockHandler.next(err)).called(1);
      verifyNever(() => mockDio.fetch<dynamic>(any()));
    });

    test('retries on 500 error for GET request', () async {
      final successResponse = Response(
        requestOptions: RequestOptions(path: '/api/receipts', method: 'GET'),
        statusCode: 200,
        data: {'ok': true},
      );

      when(() => mockDio.fetch<dynamic>(any()))
          .thenAnswer((_) async => successResponse);

      final err = makeDioException(method: 'GET', statusCode: 500);

      interceptor.onError(err, mockHandler);

      // Allow the async retry (exponential backoff) to complete.
      // The first retry delay is ~1000-1500ms. We wait enough time.
      await Future.delayed(const Duration(milliseconds: 2000));

      // Verify that dio.fetch was called (the retry happened) and capture args
      final captured =
          verify(() => mockDio.fetch<dynamic>(captureAny())).captured;
      expect(captured, hasLength(1));

      // Verify that the retry count was incremented in the request extras
      final retryOptions = captured.first as RequestOptions;
      expect(retryOptions.extra['_retryCount'], 1);

      // Verify that handler.resolve was called with the success response
      verify(() => mockHandler.resolve(successResponse)).called(1);
    });

    test('does not retry after max retries reached', () {
      final err = makeDioException(
        method: 'GET',
        statusCode: 500,
        extras: {'_retryCount': 3},
      );

      interceptor.onError(err, mockHandler);

      verify(() => mockHandler.next(err)).called(1);
      verifyNever(() => mockDio.fetch<dynamic>(any()));
    });

    test('does not retry on non-retryable errors (e.g. cancel)', () {
      final options = RequestOptions(path: '/api/receipts', method: 'GET');
      final err = DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
      );

      interceptor.onError(err, mockHandler);

      verify(() => mockHandler.next(err)).called(1);
      verifyNever(() => mockDio.fetch<dynamic>(any()));
    });
  });
}
