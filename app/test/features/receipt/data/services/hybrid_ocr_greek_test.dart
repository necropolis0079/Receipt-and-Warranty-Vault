import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/data/services/hybrid_ocr_service.dart';

void main() {
  late HybridOcrService service;

  setUp(() {
    service = HybridOcrService();
  });

  group('containsGreekCharacters', () {
    test('returns true for Greek uppercase', () {
      expect(HybridOcrService.containsGreekCharacters('ΣΥΝΟΛΟ'), isTrue);
    });

    test('returns true for Greek lowercase', () {
      expect(HybridOcrService.containsGreekCharacters('αποδειξη'), isTrue);
    });

    test('returns true for mixed Greek and Latin', () {
      expect(
          HybridOcrService.containsGreekCharacters('TOTAL ΣΥΝΟΛΟ'), isTrue);
    });

    test('returns false for Latin-only text', () {
      expect(
          HybridOcrService.containsGreekCharacters('Store ABC 12.34'), isFalse);
    });

    test('returns false for empty text', () {
      expect(HybridOcrService.containsGreekCharacters(''), isFalse);
    });

    test('returns false for numbers only', () {
      expect(HybridOcrService.containsGreekCharacters('12345'), isFalse);
    });
  });

  group('parseRawText — Greek detection', () {
    test('detects Greek language when Greek characters present', () {
      final result = service.parseRawText(
        'ΣΚΛΑΒΕΝΙΤΗΣ\n15/01/2024\nΣΥΝΟΛΟ €12,50',
      );
      expect(result.detectedLanguage, 'el');
    });

    test('detects English language for Latin-only text', () {
      final result = service.parseRawText(
        'STORE ABC\n15/01/2024\nTOTAL €12.50',
      );
      expect(result.detectedLanguage, 'en');
    });
  });

  group('parseRawText — Greek total patterns', () {
    test('extracts total from ΣΥΝΟΛΟ keyword', () {
      final result = service.parseRawText(
        'ΣΚΛΑΒΕΝΙΤΗΣ\n15/01/2024\nΣΥΝΟΛΟ 12,50',
      );
      expect(result.extractedTotal, 12.50);
    });

    test('extracts total from ΣΥΝΟΛΟ with € symbol', () {
      final result = service.parseRawText(
        'ΣΚΛΑΒΕΝΙΤΗΣ\n15/01/2024\nΣΥΝΟΛΟ €25,99',
      );
      expect(result.extractedTotal, 25.99);
    });

    test('extracts store name from first line of Greek receipt', () {
      final result = service.parseRawText(
        'ΣΚΛΑΒΕΝΙΤΗΣ\n15/01/2024\nΣΥΝΟΛΟ 12,50',
      );
      expect(result.extractedStoreName, 'ΣΚΛΑΒΕΝΙΤΗΣ');
    });
  });

  group('parseRawText — general extraction', () {
    test('extracts date in DD/MM/YYYY format', () {
      final result = service.parseRawText(
        'Store Name\n15/01/2024\nTOTAL 49.99',
      );
      expect(result.extractedDate, '15/01/2024');
    });

    test('extracts date in YYYY-MM-DD format', () {
      final result = service.parseRawText(
        'Store Name\n2024-01-15\nTOTAL 49.99',
      );
      expect(result.extractedDate, '2024-01-15');
    });

    test('extracts total from TOTAL keyword', () {
      final result = service.parseRawText(
        'Store Name\n15/01/2024\nTOTAL 49.99',
      );
      expect(result.extractedTotal, 49.99);
    });

    test('extracts EUR currency from € symbol', () {
      final result = service.parseRawText(
        'Store Name\n15/01/2024\nTOTAL €49.99',
      );
      expect(result.extractedCurrency, 'EUR');
    });

    test('returns 0.0 confidence for empty text', () {
      final result = service.parseRawText('');
      expect(result.confidence, 0.0);
      expect(result.rawText, '');
    });

    test('confidence reflects number of fields extracted', () {
      // All 3 fields: store + date + total → 1.0
      final fullResult = service.parseRawText(
        'Store ABC\n15/01/2024\nTOTAL 49.99',
      );
      expect(fullResult.confidence, closeTo(1.0, 0.01));

      // No fields extractable
      final emptyResult = service.parseRawText('***\n---\n===');
      expect(emptyResult.confidence, closeTo(0.0, 0.01));
    });
  });

  group('_detectCurrency', () {
    test('detects EUR from € symbol', () {
      final result = service.parseRawText('Store\n01/01/2024\nTOTAL €10.00');
      expect(result.extractedCurrency, 'EUR');
    });

    test('defaults to EUR when no currency detected', () {
      final result = service.parseRawText('Store\n01/01/2024\nTOTAL 10.00');
      expect(result.extractedCurrency, 'EUR');
    });
  });
}
