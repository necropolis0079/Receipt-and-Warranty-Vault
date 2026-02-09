import '../../domain/entities/ocr_result.dart';
import '../../domain/services/ocr_service.dart';

/// Mock implementation of [OcrService] for dev/tests.
///
/// Returns deterministic fake extracted data from a fixed receipt template.
class MockOcrService implements OcrService {
  MockOcrService({
    this.shouldFail = false,
    this.simulatedDelayMs = 50,
  });

  final bool shouldFail;
  final int simulatedDelayMs;

  static const _fakeRawText = '''SUPERMARKET ABC
123 Main Street
Date: 15/01/2026
-----------------
Milk          2.50
Bread         1.80
Cheese        4.20
-----------------
TOTAL        8.50 EUR''';

  Future<void> _simulateDelay() async {
    await Future.delayed(Duration(milliseconds: simulatedDelayMs));
  }

  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    await _simulateDelay();
    if (shouldFail) {
      return const OcrResult(rawText: '', confidence: 0.0);
    }
    return parseRawText(_fakeRawText);
  }

  @override
  Future<OcrResult> recognizeMultipleImages(List<String> imagePaths) async {
    if (imagePaths.isEmpty) {
      return const OcrResult(rawText: '', confidence: 0.0);
    }
    return recognizeText(imagePaths.first);
  }

  @override
  OcrResult parseRawText(String rawText) {
    String? storeName;
    String? date;
    double? total;
    String? currency;

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // First non-empty line is store name
    if (lines.isNotEmpty) {
      storeName = lines.first;
    }

    // Find date pattern (DD/MM/YYYY or YYYY-MM-DD)
    final dateRegex = RegExp(r'(\d{2}/\d{2}/\d{4}|\d{4}-\d{2}-\d{2})');
    for (final line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        date = match.group(1);
        break;
      }
    }

    // Find total pattern
    final totalRegex = RegExp(
      r'TOTAL\s+(\d+\.?\d*)\s*(EUR|USD|GBP)?',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = totalRegex.firstMatch(line);
      if (match != null) {
        total = double.tryParse(match.group(1) ?? '');
        currency = match.group(2);
        break;
      }
    }

    return OcrResult(
      rawText: rawText,
      extractedStoreName: storeName,
      extractedDate: date,
      extractedTotal: total,
      extractedCurrency: currency ?? 'EUR',
      confidence: shouldFail ? 0.0 : 0.85,
      detectedLanguage: 'en',
    );
  }

  @override
  Future<bool> isAvailable() async => !shouldFail;
}
