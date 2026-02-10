import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/core/network/api_exceptions.dart';
import 'package:warrantyvault/core/network/interceptors/connectivity_interceptor.dart';
import 'package:warrantyvault/core/services/connectivity_service.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

class FakeRequestOptions extends Fake implements RequestOptions {}

class FakeDioException extends Fake implements DioException {}

void main() {
  late MockConnectivityService mockConnectivityService;
  late MockRequestInterceptorHandler mockHandler;
  late ConnectivityInterceptor interceptor;
  late RequestOptions requestOptions;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeDioException());
  });

  setUp(() {
    mockConnectivityService = MockConnectivityService();
    mockHandler = MockRequestInterceptorHandler();
    interceptor = ConnectivityInterceptor(
      connectivityService: mockConnectivityService,
    );
    requestOptions = RequestOptions(path: '/api/receipts');
  });

  group('ConnectivityInterceptor', () {
    test('allows request when online (handler.next is called)', () async {
      when(() => mockConnectivityService.check())
          .thenAnswer((_) async => ConnectivityState.online);

      interceptor.onRequest(requestOptions, mockHandler);

      // Allow the async check() to complete
      await Future.delayed(Duration.zero);

      verify(() => mockHandler.next(requestOptions)).called(1);
      verifyNever(() => mockHandler.reject(any()));
    });

    test('rejects request with OfflineException when offline', () async {
      when(() => mockConnectivityService.check())
          .thenAnswer((_) async => ConnectivityState.offline);

      interceptor.onRequest(requestOptions, mockHandler);

      // Allow the async check() to complete
      await Future.delayed(Duration.zero);

      verifyNever(() => mockHandler.next(any()));

      final captured =
          verify(() => mockHandler.reject(captureAny())).captured;
      expect(captured, hasLength(1));

      final dioException = captured.first as DioException;
      expect(dioException.error, isA<OfflineException>());
      expect(dioException.type, DioExceptionType.connectionError);
      expect(dioException.requestOptions, requestOptions);
    });

    test('allows request when connectivity is limited (should still try)',
        () async {
      when(() => mockConnectivityService.check())
          .thenAnswer((_) async => ConnectivityState.limited);

      interceptor.onRequest(requestOptions, mockHandler);

      // Allow the async check() to complete
      await Future.delayed(Duration.zero);

      verify(() => mockHandler.next(requestOptions)).called(1);
      verifyNever(() => mockHandler.reject(any()));
    });
  });
}
