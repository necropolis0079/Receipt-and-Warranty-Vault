import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/entities/ocr_result.dart';
import '../../domain/services/ocr_service.dart';

/// Hybrid OCR service: ML Kit for Latin scripts, with regex field extraction.
///
/// Tesseract (Greek) integration is planned but deferred — ML Kit handles
/// Latin + numbers which covers most receipt content.
class HybridOcrService implements OcrService {
  HybridOcrService();

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return parseRawText(recognizedText.text);
  }

  @override
  Future<OcrResult> recognizeMultipleImages(List<String> imagePaths) async {
    if (imagePaths.isEmpty) {
      return const OcrResult(rawText: '', confidence: 0.0);
    }

    final results = <OcrResult>[];
    for (final path in imagePaths) {
      results.add(await recognizeText(path));
    }

    // Merge: concatenate raw text, take best confidence, use first extracted fields
    final mergedText = results.map((r) => r.rawText).join('\n---\n');
    final bestConfidence =
        results.map((r) => r.confidence).reduce((a, b) => a > b ? a : b);

    final firstWithStore =
        results.where((r) => r.extractedStoreName != null).firstOrNull;
    final firstWithDate =
        results.where((r) => r.extractedDate != null).firstOrNull;
    final firstWithTotal =
        results.where((r) => r.extractedTotal != null).firstOrNull;

    return OcrResult(
      rawText: mergedText,
      extractedStoreName: firstWithStore?.extractedStoreName,
      extractedDate: firstWithDate?.extractedDate,
      extractedTotal: firstWithTotal?.extractedTotal,
      extractedCurrency: firstWithTotal?.extractedCurrency ?? 'EUR',
      confidence: bestConfidence,
      detectedLanguage: 'en',
    );
  }

  @override
  OcrResult parseRawText(String rawText) {
    if (rawText.trim().isEmpty) {
      return const OcrResult(rawText: '', confidence: 0.0);
    }

    String? storeName;
    String? date;
    double? total;
    String? currency;

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Store name: first line that's mostly alphabetic
    for (final line in lines) {
      if (RegExp(r'^[A-Za-z\u0391-\u03C9\s&.,-]{3,}$').hasMatch(line)) {
        storeName = line;
        break;
      }
    }

    // Date extraction (multiple formats)
    final datePatterns = [
      RegExp(r'(\d{2})/(\d{2})/(\d{4})'), // DD/MM/YYYY
      RegExp(r'(\d{2})-(\d{2})-(\d{4})'), // DD-MM-YYYY
      RegExp(r'(\d{4})-(\d{2})-(\d{2})'), // YYYY-MM-DD
      RegExp(r'(\d{2})\.(\d{2})\.(\d{4})'), // DD.MM.YYYY
    ];
    for (final line in lines) {
      for (final pattern in datePatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          date = match.group(0);
          break;
        }
      }
      if (date != null) break;
    }

    // Total amount extraction (scan from bottom)
    final totalPatterns = [
      RegExp(
        r'(?:TOTAL|ΣΥΝΟΛΟ|GRAND\s*TOTAL|SUBTOTAL)\s*:?\s*[€$£]?\s*(\d+[.,]\d{2})',
        caseSensitive: false,
      ),
      RegExp(r'[€$£]\s*(\d+[.,]\d{2})'),
      RegExp(
        r'(\d+[.,]\d{2})\s*(?:EUR|USD|GBP|€|\$|£)',
        caseSensitive: false,
      ),
    ];
    for (final line in lines.reversed) {
      for (final pattern in totalPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final amountStr = match.group(1)?.replaceAll(',', '.') ?? '';
          total = double.tryParse(amountStr);
          if (line.contains('€') || line.toUpperCase().contains('EUR')) {
            currency = 'EUR';
          } else if (line.contains('\$') || line.toUpperCase().contains('USD')) {
            currency = 'USD';
          } else if (line.contains('£') || line.toUpperCase().contains('GBP')) {
            currency = 'GBP';
          }
          if (total != null) break;
        }
      }
      if (total != null) break;
    }

    // Confidence based on how many fields were extracted
    int fieldsFound = 0;
    if (storeName != null) fieldsFound++;
    if (date != null) fieldsFound++;
    if (total != null) fieldsFound++;
    final confidence = fieldsFound / 3.0;

    return OcrResult(
      rawText: rawText,
      extractedStoreName: storeName,
      extractedDate: date,
      extractedTotal: total,
      extractedCurrency: currency ?? 'EUR',
      confidence: confidence,
      detectedLanguage: 'en',
    );
  }

  @override
  Future<bool> isAvailable() async => true;

  void dispose() {
    _textRecognizer.close();
  }
}
