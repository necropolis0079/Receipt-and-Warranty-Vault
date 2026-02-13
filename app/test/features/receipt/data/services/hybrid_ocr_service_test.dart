import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/data/services/hybrid_ocr_service.dart';
import 'package:warrantyvault/features/receipt/domain/entities/ocr_result.dart';

void main() {
  late HybridOcrService service;

  setUp(() {
    service = HybridOcrService();
  });

  group('parseRawText', () {
    // ---------------------------------------------------------------
    // 1. Empty text returns 0 confidence
    // ---------------------------------------------------------------
    test('returns 0 confidence and empty rawText for empty input', () {
      final result = service.parseRawText('');
      expect(result, isA<OcrResult>());
      expect(result.rawText, '');
      expect(result.confidence, 0.0);
      expect(result.extractedStoreName, isNull);
      expect(result.extractedDate, isNull);
      expect(result.extractedTotal, isNull);
    });

    test('returns 0 confidence for whitespace-only input', () {
      final result = service.parseRawText('   \n  \n  ');
      expect(result.confidence, 0.0);
      expect(result.rawText, '');
    });

    // ---------------------------------------------------------------
    // 2. Store name extraction — first non-skip line with letters
    // ---------------------------------------------------------------
    test('extracts store name from the first non-skip line with letters', () {
      const text = 'WALMART SUPERCENTER\n15/01/2024\nTOTAL 49.99';
      final result = service.parseRawText(text);
      expect(result.extractedStoreName, 'WALMART SUPERCENTER');
    });

    test('extracts store name skipping initial separator lines', () {
      const text = '***\n---\n===\nBEST BUY\n15/01/2024\nTOTAL 199.99';
      final result = service.parseRawText(text);
      expect(result.extractedStoreName, 'BEST BUY');
    });

    test('extracts store name from line with mixed alpha-numeric', () {
      const text = 'STORE No.42\n01/06/2025\nTOTAL 5.00';
      final result = service.parseRawText(text);
      expect(result.extractedStoreName, 'STORE No.42');
    });

    // ---------------------------------------------------------------
    // 3. Date extraction — DD/MM/YYYY format
    // ---------------------------------------------------------------
    test('extracts date in DD/MM/YYYY format', () {
      const text = 'My Shop\n25/12/2025\nTOTAL 10.00';
      final result = service.parseRawText(text);
      expect(result.extractedDate, '25/12/2025');
    });

    // ---------------------------------------------------------------
    // 4. Date extraction — YYYY-MM-DD format
    // ---------------------------------------------------------------
    test('extracts date in YYYY-MM-DD format', () {
      const text = 'My Shop\n2025-12-25\nTOTAL 10.00';
      final result = service.parseRawText(text);
      expect(result.extractedDate, '2025-12-25');
    });

    // ---------------------------------------------------------------
    // 5. Date extraction — DD.MM.YYYY format
    // ---------------------------------------------------------------
    test('extracts date in DD.MM.YYYY format', () {
      const text = 'My Shop\n25.12.2025\nTOTAL 10.00';
      final result = service.parseRawText(text);
      expect(result.extractedDate, '25.12.2025');
    });

    test('extracts date in DD-MM-YYYY format', () {
      const text = 'My Shop\n25-12-2025\nTOTAL 10.00';
      final result = service.parseRawText(text);
      expect(result.extractedDate, '25-12-2025');
    });

    // ---------------------------------------------------------------
    // 6. Total extraction with TOTAL keyword
    // ---------------------------------------------------------------
    test('extracts total from TOTAL keyword', () {
      const text = 'Store\n01/01/2025\nTOTAL 42.99';
      final result = service.parseRawText(text);
      expect(result.extractedTotal, 42.99);
    });

    test('extracts total from TOTAL: keyword with colon', () {
      const text = 'Store\n01/01/2025\nTOTAL: 42.99';
      final result = service.parseRawText(text);
      expect(result.extractedTotal, 42.99);
    });

    test('extracts total from GRAND TOTAL keyword', () {
      const text = 'Store\n01/01/2025\nSUBTOTAL 40.00\nGRAND TOTAL 42.99';
      final result = service.parseRawText(text);
      expect(result.extractedTotal, 42.99);
    });

    test('extracts total from AMOUNT DUE keyword', () {
      const text = 'Store\n01/01/2025\nAMOUNT DUE 55.00';
      final result = service.parseRawText(text);
      expect(result.extractedTotal, 55.00);
    });

    // ---------------------------------------------------------------
    // 7. Total extraction with Greek ΣΥΝΟΛΟ keyword
    // ---------------------------------------------------------------
    test('extracts total from Greek ΣΥΝΟΛΟ keyword', () {
      const text = 'ΣΚΛΑΒΕΝΙΤΗΣ\n15/01/2024\nΣΥΝΟΛΟ 12,50';
      final result = service.parseRawText(text);
      expect(result.extractedTotal, 12.50);
    });

    test('extracts total from Greek ΠΛΗΡΩΤΕΟ keyword', () {
      const text = 'ΣΚΛΑΒΕΝΙΤΗΣ\n15/01/2024\nΠΛΗΡΩΤΕΟ 18,75';
      final result = service.parseRawText(text);
      expect(result.extractedTotal, 18.75);
    });

    test('extracts total from ΣΥΝΟΛΟ with € symbol', () {
      const text = 'ΣΚΛΑΒΕΝΙΤΗΣ\n15/01/2024\nΣΥΝΟΛΟ €25,99';
      final result = service.parseRawText(text);
      expect(result.extractedTotal, 25.99);
    });

    // ---------------------------------------------------------------
    // 8. Total extraction with € currency symbol
    // ---------------------------------------------------------------
    test('extracts total when only € symbol is present without keyword', () {
      const text = 'Store\n01/01/2025\nItem 5.00\n€42.99';
      final result = service.parseRawText(text);
      expect(result.extractedTotal, 42.99);
      expect(result.extractedCurrency, 'EUR');
    });

    test('extracts total from TOTAL with € prefix', () {
      const text = 'Store\n01/01/2025\nTOTAL €99.95';
      final result = service.parseRawText(text);
      expect(result.extractedTotal, 99.95);
      expect(result.extractedCurrency, 'EUR');
    });

    // ---------------------------------------------------------------
    // 9. Currency detection — EUR, USD, GBP
    // ---------------------------------------------------------------
    test('detects EUR currency from € symbol', () {
      const text = 'Store\n01/01/2025\nTOTAL €49.99';
      final result = service.parseRawText(text);
      expect(result.extractedCurrency, 'EUR');
    });

    test('detects EUR currency from EUR text', () {
      const text = 'Store\n01/01/2025\nTOTAL 49.99 EUR';
      final result = service.parseRawText(text);
      expect(result.extractedCurrency, 'EUR');
    });

    test('detects USD currency from \$ symbol', () {
      const text = 'Store\n01/01/2025\nTOTAL \$49.99';
      final result = service.parseRawText(text);
      expect(result.extractedCurrency, 'USD');
    });

    test('detects USD currency from USD text', () {
      const text = 'Store\n01/01/2025\nTOTAL 49.99 USD';
      final result = service.parseRawText(text);
      expect(result.extractedCurrency, 'USD');
    });

    test('detects GBP currency from £ symbol', () {
      const text = 'Store\n01/01/2025\nTOTAL £49.99';
      final result = service.parseRawText(text);
      expect(result.extractedCurrency, 'GBP');
    });

    test('detects GBP currency from GBP text', () {
      const text = 'Store\n01/01/2025\nTOTAL 49.99 GBP';
      final result = service.parseRawText(text);
      expect(result.extractedCurrency, 'GBP');
    });

    test('defaults to EUR when no currency indicator present', () {
      const text = 'Store\n01/01/2025\nTOTAL 49.99';
      final result = service.parseRawText(text);
      expect(result.extractedCurrency, 'EUR');
    });

    // ---------------------------------------------------------------
    // 10. Confidence scoring: 0, 1, 2, or 3 fields
    // ---------------------------------------------------------------
    test('confidence is 0.0 when no fields are extracted', () {
      // Only separator and numeric lines — no store, no date, no total
      const text = '***\n---\n===';
      final result = service.parseRawText(text);
      expect(result.confidence, closeTo(0.0, 0.01));
    });

    test('confidence is ~0.33 when 1 field is extracted', () {
      // Only a store name, no date, no total
      const text = 'WALMART SUPERCENTER';
      final result = service.parseRawText(text);
      expect(result.extractedStoreName, isNotNull);
      expect(result.extractedDate, isNull);
      expect(result.extractedTotal, isNull);
      expect(result.confidence, closeTo(1.0 / 3.0, 0.01));
    });

    test('confidence is ~0.67 when 2 fields are extracted', () {
      // Store name + date, but no total keyword or currency amount
      const text = 'WALMART SUPERCENTER\n15/01/2025';
      final result = service.parseRawText(text);
      expect(result.extractedStoreName, isNotNull);
      expect(result.extractedDate, isNotNull);
      expect(result.extractedTotal, isNull);
      expect(result.confidence, closeTo(2.0 / 3.0, 0.01));
    });

    test('confidence is 1.0 when all 3 fields are extracted', () {
      const text = 'WALMART SUPERCENTER\n15/01/2025\nTOTAL 49.99';
      final result = service.parseRawText(text);
      expect(result.extractedStoreName, isNotNull);
      expect(result.extractedDate, isNotNull);
      expect(result.extractedTotal, isNotNull);
      expect(result.confidence, closeTo(1.0, 0.01));
    });

    // ---------------------------------------------------------------
    // 12. Skip patterns: lines with dates, amounts, phone numbers
    //     are not selected as store names
    // ---------------------------------------------------------------
    test('skips date-like lines when looking for store name', () {
      const text = '15/01/2025\nACME MART\nTOTAL 10.00';
      final result = service.parseRawText(text);
      expect(result.extractedStoreName, 'ACME MART');
    });

    test('skips bare amount lines when looking for store name', () {
      const text = '42.99\nACME MART\nTOTAL 42.99';
      final result = service.parseRawText(text);
      expect(result.extractedStoreName, 'ACME MART');
    });

    test('skips phone number lines when looking for store name', () {
      const text = '+30 210 1234567\nACME MART\n01/01/2025\nTOTAL 5.00';
      final result = service.parseRawText(text);
      expect(result.extractedStoreName, 'ACME MART');
    });

    test('skips TOTAL/SUBTOTAL lines when looking for store name', () {
      const text = 'TOTAL 42.99\nACME MART\n01/01/2025';
      final result = service.parseRawText(text);
      expect(result.extractedStoreName, 'ACME MART');
    });

    test('skips pure numeric lines when looking for store name', () {
      const text = '123.45\n€50.00\nACME MART\n01/01/2025\nTOTAL 50.00';
      final result = service.parseRawText(text);
      expect(result.extractedStoreName, 'ACME MART');
    });

    test('skips separator lines (***) when looking for store name', () {
      const text = '***\n=========\nACME MART\n01/01/2025\nTOTAL 10.00';
      final result = service.parseRawText(text);
      expect(result.extractedStoreName, 'ACME MART');
    });

    // ---------------------------------------------------------------
    // 13. Full receipt text — English receipt parsing
    // ---------------------------------------------------------------
    test('parses a full English receipt correctly', () {
      const text = '''WALMART SUPERCENTER
123 Main Street, Springfield
Tel: +1 555-1234567
Date: 15/01/2025
-----------------
Milk          2.50
Bread         1.80
Cheese        4.20
Eggs          3.49
-----------------
SUBTOTAL      12.00
TAX            0.99
TOTAL         12.99 USD
-----------------
VISA ****1234
Thank you for shopping!''';

      final result = service.parseRawText(text);

      expect(result.extractedStoreName, 'WALMART SUPERCENTER');
      expect(result.extractedDate, '15/01/2025');
      expect(result.extractedTotal, 12.99);
      expect(result.extractedCurrency, 'USD');
      expect(result.confidence, closeTo(1.0, 0.01));
      expect(result.detectedLanguage, 'en');
      expect(result.rawText, text);
    });

    test('parses English receipt with YYYY-MM-DD date format', () {
      const text = '''BEST BUY
2025-06-20
Samsung TV       499.99
Extended Warranty 59.99
GRAND TOTAL      559.98 USD''';

      final result = service.parseRawText(text);

      expect(result.extractedStoreName, 'BEST BUY');
      expect(result.extractedDate, '2025-06-20');
      expect(result.extractedTotal, 559.98);
      expect(result.extractedCurrency, 'USD');
      expect(result.confidence, closeTo(1.0, 0.01));
    });

    // ---------------------------------------------------------------
    // 14. Full receipt text — Greek receipt parsing
    // ---------------------------------------------------------------
    test('parses a full Greek receipt correctly', () {
      const text = '''ΣΚΛΑΒΕΝΙΤΗΣ
Λεωφ. Κηφισίας 42
ΑΦΜ: 123456789
15/01/2024
-----------------
Γάλα          2,50
Ψωμί         1,80
Τυρί          4,20
-----------------
ΣΥΝΟΛΟ €12,50
ΜΕΤΡΗΤΑ 15,00
ΡΕΣΤΑ   2,50''';

      final result = service.parseRawText(text);

      expect(result.extractedStoreName, 'ΣΚΛΑΒΕΝΙΤΗΣ');
      expect(result.extractedDate, '15/01/2024');
      expect(result.extractedTotal, 12.50);
      expect(result.extractedCurrency, 'EUR');
      expect(result.confidence, closeTo(1.0, 0.01));
      expect(result.detectedLanguage, 'el');
    });

    test('parses Greek receipt with ΠΛΗΡΩΤΕΟ keyword', () {
      const text = '''ΑΒ ΒΑΣΙΛΟΠΟΥΛΟΣ
Ερμού 15, Αθήνα
10.02.2025
-----------------
Νερό          0,50
Καφές         3,80
-----------------
ΠΛΗΡΩΤΕΟ 4,30''';

      final result = service.parseRawText(text);

      expect(result.extractedStoreName, 'ΑΒ ΒΑΣΙΛΟΠΟΥΛΟΣ');
      expect(result.extractedDate, '10.02.2025');
      expect(result.extractedTotal, 4.30);
      expect(result.detectedLanguage, 'el');
      expect(result.confidence, closeTo(1.0, 0.01));
    });

    test('handles Greek receipt with comma decimal separator', () {
      const text = 'ΜΑΣΟΥΤΗΣ\n20/03/2025\nΣΥΝΟΛΟ 155,99';
      final result = service.parseRawText(text);
      expect(result.extractedTotal, 155.99);
      expect(result.extractedStoreName, 'ΜΑΣΟΥΤΗΣ');
    });
  });

  // -----------------------------------------------------------------
  // 11. Greek character detection (true/false cases)
  // -----------------------------------------------------------------
  group('containsGreekCharacters', () {
    test('returns true for Greek uppercase text', () {
      expect(HybridOcrService.containsGreekCharacters('ΣΥΝΟΛΟ'), isTrue);
    });

    test('returns true for Greek lowercase text', () {
      expect(HybridOcrService.containsGreekCharacters('αποδειξη'), isTrue);
    });

    test('returns true for mixed Greek and Latin text', () {
      expect(
        HybridOcrService.containsGreekCharacters('TOTAL ΣΥΝΟΛΟ 12.50'),
        isTrue,
      );
    });

    test('returns true for single Greek character', () {
      expect(HybridOcrService.containsGreekCharacters('α'), isTrue);
    });

    test('returns true for Greek character embedded in numbers', () {
      expect(HybridOcrService.containsGreekCharacters('123Ω456'), isTrue);
    });

    test('returns false for empty string', () {
      expect(HybridOcrService.containsGreekCharacters(''), isFalse);
    });

    test('returns false for Latin-only text', () {
      expect(
        HybridOcrService.containsGreekCharacters('Hello World'),
        isFalse,
      );
    });

    test('returns false for numbers only', () {
      expect(HybridOcrService.containsGreekCharacters('12345'), isFalse);
    });

    test('returns false for symbols only', () {
      expect(
        HybridOcrService.containsGreekCharacters('€\$£!@#%^&*'),
        isFalse,
      );
    });

    test('returns false for Latin text with accents (non-Greek Unicode)', () {
      expect(
        HybridOcrService.containsGreekCharacters('café résumé naïve'),
        isFalse,
      );
    });
  });
}
