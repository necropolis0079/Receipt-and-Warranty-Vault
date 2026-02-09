import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/data/services/mock_ocr_service.dart';
import 'package:warrantyvault/features/receipt/domain/entities/ocr_result.dart';
import 'package:warrantyvault/features/receipt/domain/services/ocr_service.dart';

void main() {
  late MockOcrService service;

  setUp(() {
    service = MockOcrService(simulatedDelayMs: 0);
  });

  group('MockOcrService', () {
    test('implements OcrService', () {
      expect(service, isA<OcrService>());
    });

    group('recognizeText', () {
      test('returns OcrResult with raw text and extracted fields', () async {
        final result = await service.recognizeText('/test/image.jpg');

        expect(result, isA<OcrResult>());
        expect(result.rawText, isNotEmpty);
        expect(result.rawText, contains('SUPERMARKET ABC'));
        expect(result.confidence, 0.85);
        expect(result.detectedLanguage, 'en');
      });

      test('returns failure result when shouldFail is true', () async {
        final failService = MockOcrService(
          shouldFail: true,
          simulatedDelayMs: 0,
        );

        final result = await failService.recognizeText('/test/image.jpg');

        expect(result.rawText, isEmpty);
        expect(result.confidence, 0.0);
      });
    });

    group('recognizeMultipleImages', () {
      test('merges text from multiple images (delegates to recognizeText)',
          () async {
        final result = await service.recognizeMultipleImages([
          '/test/image1.jpg',
          '/test/image2.jpg',
        ]);

        expect(result, isA<OcrResult>());
        expect(result.rawText, isNotEmpty);
        expect(result.rawText, contains('SUPERMARKET ABC'));
        expect(result.extractedStoreName, isNotNull);
        expect(result.extractedTotal, isNotNull);
      });

      test('returns empty result for empty list', () async {
        final result = await service.recognizeMultipleImages([]);

        expect(result.rawText, isEmpty);
        expect(result.confidence, 0.0);
      });
    });

    group('parseRawText', () {
      test('extracts store name from first non-empty line', () {
        final result = service.parseRawText('MY STORE\nItem 1.00\nTOTAL 1.00');

        expect(result.extractedStoreName, 'MY STORE');
      });

      test('extracts date in DD/MM/YYYY format', () {
        final result = service.parseRawText(
          'Store\nDate: 15/01/2026\nTOTAL 10.00',
        );

        expect(result.extractedDate, '15/01/2026');
      });

      test('extracts date in YYYY-MM-DD format', () {
        final result = service.parseRawText(
          'Store\nDate: 2026-01-15\nTOTAL 10.00',
        );

        expect(result.extractedDate, '2026-01-15');
      });

      test('extracts total amount', () {
        final result = service.parseRawText(
          'Store\nItem 2.50\nTOTAL 8.50 EUR',
        );

        expect(result.extractedTotal, 8.50);
      });

      test('extracts currency from TOTAL line', () {
        final result = service.parseRawText(
          'Store\nTOTAL 25.00 USD',
        );

        expect(result.extractedCurrency, 'USD');
      });

      test('defaults currency to EUR when not specified in TOTAL line', () {
        final result = service.parseRawText(
          'Store\nTOTAL 25.00',
        );

        expect(result.extractedCurrency, 'EUR');
      });

      test('handles raw text with all fields from fake receipt', () {
        const fakeRawText = '''SUPERMARKET ABC
123 Main Street
Date: 15/01/2026
-----------------
Milk          2.50
Bread         1.80
Cheese        4.20
-----------------
TOTAL        8.50 EUR''';

        final result = service.parseRawText(fakeRawText);

        expect(result.extractedStoreName, 'SUPERMARKET ABC');
        expect(result.extractedDate, '15/01/2026');
        expect(result.extractedTotal, 8.50);
        expect(result.extractedCurrency, 'EUR');
        expect(result.rawText, fakeRawText);
        expect(result.confidence, 0.85);
        expect(result.detectedLanguage, 'en');
      });

      test('handles empty text gracefully', () {
        final result = service.parseRawText('');

        expect(result.rawText, isEmpty);
        // No lines to parse, so storeName should be null
        expect(result.extractedStoreName, isNull);
        expect(result.extractedDate, isNull);
        expect(result.extractedTotal, isNull);
      });
    });

    group('isAvailable', () {
      test('returns true when shouldFail is false', () async {
        final result = await service.isAvailable();

        expect(result, isTrue);
      });

      test('returns false when shouldFail is true', () async {
        final failService = MockOcrService(
          shouldFail: true,
          simulatedDelayMs: 0,
        );

        final result = await failService.isAvailable();

        expect(result, isFalse);
      });
    });
  });
}
