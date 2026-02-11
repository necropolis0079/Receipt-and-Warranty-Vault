import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/services/home_widget_service.dart';

void main() {
  late HomeWidgetService service;

  setUp(() {
    service = HomeWidgetService();
  });

  group('HomeWidgetService', () {
    group('consumePendingUri', () {
      test('returns null when no URI has been stored', () {
        expect(service.consumePendingUri(), isNull);
      });

      test('returns null on second call (consumes once)', () {
        // No way to set _pendingUri directly without calling native code,
        // so we verify the "empty" path works correctly.
        final first = service.consumePendingUri();
        final second = service.consumePendingUri();
        expect(first, isNull);
        expect(second, isNull);
      });
    });

    group('widgetClickStream', () {
      test('stream is accessible and returns a Stream<Uri?>', () {
        // Verifies the getter doesn't throw.
        expect(service.widgetClickStream, isA<Stream<Uri?>>());
      });
    });
  });
}
