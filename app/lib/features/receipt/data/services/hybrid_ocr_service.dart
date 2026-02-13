import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/entities/ocr_result.dart';
import '../../domain/services/ocr_service.dart';

/// Hybrid OCR service: ML Kit for Latin scripts, Tesseract for Greek.
///
/// The recognition pipeline runs ML Kit first. If Greek characters are
/// detected in the result or confidence is very low (< 0.33), Tesseract
/// is used with `ell+eng` to get a better Greek reading.
class HybridOcrService implements OcrService {
  HybridOcrService();

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Returns `true` if [text] contains Greek Unicode characters (U+0370–U+03FF).
  static bool containsGreekCharacters(String text) {
    return RegExp(r'[\u0370-\u03FF]').hasMatch(text);
  }

  @override
  Future<OcrResult> recognizeText(String imagePath) async {
    // Step 1: Run ML Kit (Latin + numbers).
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final mlKitResult = parseRawText(recognizedText.text);

    // Step 2: If Greek characters detected or confidence is very low,
    // run Tesseract with Greek + English for better results.
    if (containsGreekCharacters(recognizedText.text) ||
        mlKitResult.confidence < 0.33) {
      try {
        final tesseractText = await FlutterTesseractOcr.extractText(
          imagePath,
          language: 'ell+eng',
        );

        if (tesseractText.trim().isNotEmpty) {
          final tesseractResult =
              _parseRawTextWithGreek(tesseractText, recognizedText.text);
          // Use whichever result has higher confidence.
          if (tesseractResult.confidence >= mlKitResult.confidence) {
            return tesseractResult;
          }
        }
      } catch (e) {
        // Tesseract not available or failed — fall back to ML Kit result.
        // Log for diagnostics so configuration issues are visible.
        // ignore: avoid_print
        print('HybridOcrService: Tesseract fallback failed: $e');
      }
    }

    return mlKitResult;
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

    final hasGreek =
        results.any((r) => r.detectedLanguage == 'el');

    return OcrResult(
      rawText: mergedText,
      extractedStoreName: firstWithStore?.extractedStoreName,
      extractedDate: firstWithDate?.extractedDate,
      extractedTotal: firstWithTotal?.extractedTotal,
      extractedCurrency: firstWithTotal?.extractedCurrency ?? 'EUR',
      confidence: bestConfidence,
      detectedLanguage: hasGreek ? 'el' : 'en',
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

    // Store name: look at the first several lines for the best candidate.
    // Receipts typically have the store name at the top, often in uppercase.
    // Skip lines that look like dates, amounts, phone numbers, or addresses.
    final skipPatterns = [
      RegExp(r'^\d{2}[/.\-]\d{2}[/.\-]\d{2,4}'), // Dates
      RegExp(r'^\d+[.,]\d{2}\s*$'), // Bare amounts
      RegExp(r'^\+?\d[\d\s\-]{7,}$'), // Phone numbers
      RegExp(r'^\d{3,}\s'), // Lines starting with long numbers (addresses)
      RegExp(r'(?:TOTAL|SUBTOTAL|CHANGE|CASH|CARD|VISA|MASTER|VAT|TAX|ΦΠΑ|ΣΥΝΟΛΟ|ΜΕΤΡΗΤΑ)',
          caseSensitive: false),
      RegExp(r'^[\d\s.,€$£%]+$'), // Pure numeric/currency lines
      RegExp(r'^\*+$'), // Separator lines
      RegExp(r'^-+$'), // Separator lines
      RegExp(r'^={2,}'), // Separator lines
    ];

    // Check the first 5 non-skip lines for a store name candidate.
    // Prefer lines that are mostly uppercase or short (business names).
    String? bestCandidate;
    for (final line in lines.take(8)) {
      if (line.length < 2) continue;
      final shouldSkip = skipPatterns.any((p) => p.hasMatch(line));
      if (shouldSkip) continue;

      // Good candidate: has at least 2 letter characters
      final letterCount = RegExp(r'[A-Za-z\u0391-\u03C9]').allMatches(line).length;
      if (letterCount >= 2) {
        bestCandidate = line;
        break;
      }
    }
    storeName = bestCandidate;

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

    // Total amount extraction.
    //
    // Strategy: first scan for explicit TOTAL keywords (most reliable),
    // then fall back to any amount with currency symbol (prefer bottom lines
    // which are more likely to be totals).
    final totalKeywordPatterns = [
      // "TOTAL 12.34" or "TOTAL: €12.34" or "ΣΥΝΟΛΟ 12,34"
      RegExp(
        r'(?:GRAND\s*TOTAL|TOTAL\s*DUE|AMOUNT\s*DUE|TOTAL|ΣΥΝΟΛΟ|ΠΛΗΡΩΤΕΟ|ΣYNΟΛΟ)\s*:?\s*[€$£]?\s*(\d{1,6}[.,]\d{2})',
        caseSensitive: false,
      ),
      // "TOTAL: € 12.34" (space between symbol and amount)
      RegExp(
        r'(?:TOTAL|ΣΥΝΟΛΟ)\s*:?\s*[€$£]\s+(\d{1,6}[.,]\d{2})',
        caseSensitive: false,
      ),
      // "12.34 TOTAL"
      RegExp(
        r'(\d{1,6}[.,]\d{2})\s*(?:TOTAL|ΣΥΝΟΛΟ)',
        caseSensitive: false,
      ),
    ];

    final currencyAmountPatterns = [
      // €12.34 or $ 12.34
      RegExp(r'[€$£]\s*(\d{1,6}[.,]\d{2})'),
      // 12.34 EUR or 12,34€
      RegExp(
        r'(\d{1,6}[.,]\d{2})\s*(?:EUR|USD|GBP|€|\$|£)',
        caseSensitive: false,
      ),
    ];

    // First pass: look for lines with TOTAL keyword (search from bottom)
    for (final line in lines.reversed) {
      for (final pattern in totalKeywordPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final amountStr = match.group(1)?.replaceAll(',', '.') ?? '';
          total = double.tryParse(amountStr);
          if (total != null && total > 0) {
            currency = _detectCurrency(line);
            break;
          }
        }
      }
      if (total != null) break;
    }

    // Second pass: if no keyword match, find the largest amount near bottom
    if (total == null) {
      double largestAmount = 0;
      String? largestLine;
      // Check only the bottom half of the receipt
      final bottomLines = lines.length > 4
          ? lines.sublist(lines.length ~/ 2)
          : lines;
      for (final line in bottomLines.reversed) {
        for (final pattern in currencyAmountPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final amountStr = match.group(1)?.replaceAll(',', '.') ?? '';
            final parsed = double.tryParse(amountStr);
            if (parsed != null && parsed > largestAmount) {
              largestAmount = parsed;
              largestLine = line;
            }
          }
        }
      }
      if (largestAmount > 0) {
        total = largestAmount;
        currency = _detectCurrency(largestLine ?? '');
      }
    }

    // Third pass: last resort — find any decimal number on a line by itself
    // near the bottom (common in minimal receipts)
    if (total == null) {
      final bareAmountPattern = RegExp(r'^(\d{1,6}[.,]\d{2})\s*$');
      for (final line in lines.reversed) {
        final match = bareAmountPattern.firstMatch(line);
        if (match != null) {
          final amountStr = match.group(1)?.replaceAll(',', '.') ?? '';
          total = double.tryParse(amountStr);
          if (total != null && total > 0) break;
        }
      }
    }

    // Confidence based on how many fields were extracted
    int fieldsFound = 0;
    if (storeName != null) fieldsFound++;
    if (date != null) fieldsFound++;
    if (total != null) fieldsFound++;
    final confidence = fieldsFound / 3.0;

    final isGreek = containsGreekCharacters(rawText);
    return OcrResult(
      rawText: rawText,
      extractedStoreName: storeName,
      extractedDate: date,
      extractedTotal: total,
      extractedCurrency: currency ?? 'EUR',
      confidence: confidence,
      detectedLanguage: isGreek ? 'el' : 'en',
    );
  }

  /// Parse Tesseract Greek output, merging with ML Kit Latin text for
  /// best field extraction.
  OcrResult _parseRawTextWithGreek(String tesseractText, String mlKitText) {
    // Combine both texts for field extraction (Tesseract is better for Greek
    // words, ML Kit is better for numbers/dates).
    final combinedText = '$tesseractText\n$mlKitText';
    final lines = combinedText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? storeName;
    String? date;
    double? total;
    String? currency;

    // Greek-specific total patterns.
    final greekTotalPatterns = [
      RegExp(
        r'(?:ΣΥΝΟΛΟ|ΠΛΗΡΩΤΕΟ|ΣYNΟΛΟ|ΓΕΝΙΚΟ\s*ΣΥΝΟΛΟ|ΤΕΛΙΚΟ\s*ΠΟΣΟ)\s*:?\s*[€]?\s*(\d{1,6}[.,]\d{2})',
        caseSensitive: false,
      ),
      RegExp(
        r'(\d{1,6}[.,]\d{2})\s*(?:ΣΥΝΟΛΟ|€)',
        caseSensitive: false,
      ),
    ];

    // Try Greek total patterns first (from bottom).
    for (final line in lines.reversed) {
      for (final pattern in greekTotalPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final amountStr = match.group(1)?.replaceAll(',', '.') ?? '';
          total = double.tryParse(amountStr);
          if (total != null && total > 0) {
            currency = _detectCurrency(line);
            break;
          }
        }
      }
      if (total != null) break;
    }

    // Fall back to generic parsing for remaining fields.
    final genericResult = parseRawText(combinedText);
    storeName = genericResult.extractedStoreName;
    date = genericResult.extractedDate;
    total ??= genericResult.extractedTotal;
    currency ??= genericResult.extractedCurrency;

    int fieldsFound = 0;
    if (storeName != null) fieldsFound++;
    if (date != null) fieldsFound++;
    if (total != null) fieldsFound++;

    return OcrResult(
      rawText: tesseractText,
      extractedStoreName: storeName,
      extractedDate: date,
      extractedTotal: total,
      extractedCurrency: currency ?? 'EUR',
      confidence: fieldsFound / 3.0,
      detectedLanguage: 'el',
    );
  }

  /// Detect currency from a line of text.
  static String _detectCurrency(String line) {
    if (line.contains('€') || line.toUpperCase().contains('EUR')) return 'EUR';
    if (line.contains('\$') || line.toUpperCase().contains('USD')) return 'USD';
    if (line.contains('£') || line.toUpperCase().contains('GBP')) return 'GBP';
    return 'EUR'; // Default
  }

  @override
  Future<bool> isAvailable() async => true;

  void dispose() {
    _textRecognizer.close();
  }
}
