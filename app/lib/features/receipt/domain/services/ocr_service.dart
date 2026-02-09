import '../entities/ocr_result.dart';

/// Abstract service for OCR text recognition and field extraction.
abstract class OcrService {
  /// Recognize text from a single image.
  Future<OcrResult> recognizeText(String imagePath);

  /// Recognize text from multiple images and merge results.
  Future<OcrResult> recognizeMultipleImages(List<String> imagePaths);

  /// Parse raw OCR text to extract structured fields.
  OcrResult parseRawText(String rawText);

  /// Check if OCR is available on this device.
  Future<bool> isAvailable();
}
