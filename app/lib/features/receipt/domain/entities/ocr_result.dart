import 'package:equatable/equatable.dart';

class OcrResult extends Equatable {
  const OcrResult({
    required this.rawText,
    this.extractedStoreName,
    this.extractedDate,
    this.extractedTotal,
    this.extractedCurrency,
    this.confidence = 0.0,
    this.detectedLanguage,
  });

  final String rawText;
  final String? extractedStoreName;
  final String? extractedDate;
  final double? extractedTotal;
  final String? extractedCurrency;
  final double confidence;
  final String? detectedLanguage;

  OcrResult copyWith({
    String? rawText,
    String? extractedStoreName,
    String? extractedDate,
    double? extractedTotal,
    String? extractedCurrency,
    double? confidence,
    String? detectedLanguage,
  }) {
    return OcrResult(
      rawText: rawText ?? this.rawText,
      extractedStoreName: extractedStoreName ?? this.extractedStoreName,
      extractedDate: extractedDate ?? this.extractedDate,
      extractedTotal: extractedTotal ?? this.extractedTotal,
      extractedCurrency: extractedCurrency ?? this.extractedCurrency,
      confidence: confidence ?? this.confidence,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
    );
  }

  @override
  List<Object?> get props => [
        rawText,
        extractedStoreName,
        extractedDate,
        extractedTotal,
        extractedCurrency,
        confidence,
        detectedLanguage,
      ];
}
