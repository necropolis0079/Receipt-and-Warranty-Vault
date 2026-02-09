import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/domain/entities/ocr_result.dart';

void main() {
  group('OcrResult', () {
    test('constructs with required fields', () {
      const result = OcrResult(rawText: 'Store ABC\nTotal: 42.50');
      expect(result.rawText, 'Store ABC\nTotal: 42.50');
      expect(result.confidence, 0.0);
      expect(result.extractedStoreName, isNull);
    });

    test('constructs with all fields', () {
      const result = OcrResult(
        rawText: 'Store ABC\nTotal: 42.50',
        extractedStoreName: 'Store ABC',
        extractedDate: '2026-02-09',
        extractedTotal: 42.50,
        extractedCurrency: 'EUR',
        confidence: 0.85,
        detectedLanguage: 'en',
      );
      expect(result.extractedStoreName, 'Store ABC');
      expect(result.extractedTotal, 42.50);
      expect(result.confidence, 0.85);
    });

    test('copyWith creates modified copy', () {
      const original = OcrResult(rawText: 'test');
      final copy = original.copyWith(confidence: 0.9);
      expect(copy.confidence, 0.9);
      expect(copy.rawText, 'test');
    });

    test('equatable compares by value', () {
      const a = OcrResult(rawText: 'test', confidence: 0.5);
      const b = OcrResult(rawText: 'test', confidence: 0.5);
      expect(a, equals(b));
    });
  });
}
