import 'package:equatable/equatable.dart';

enum ReceiptStatus { active, returned, deleted }

class Receipt extends Equatable {
  const Receipt({
    required this.receiptId,
    required this.userId,
    this.storeName,
    this.extractedMerchantName,
    this.purchaseDate,
    this.extractedDate,
    this.totalAmount,
    this.extractedTotal,
    this.currency = 'EUR',
    this.category,
    this.warrantyMonths = 0,
    this.warrantyExpiryDate,
    this.status = ReceiptStatus.active,
    this.imageKeys = const [],
    this.thumbnailKeys = const [],
    this.ocrRawText,
    this.llmConfidence = 0,
    this.userNotes,
    this.userTags = const [],
    this.isFavorite = false,
    this.userEditedFields = const [],
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.deletedAt,
    this.localImagePaths = const [],
  });

  final String receiptId;
  final String userId;
  final String? storeName;
  final String? extractedMerchantName;
  final String? purchaseDate;
  final String? extractedDate;
  final double? totalAmount;
  final double? extractedTotal;
  final String currency;
  final String? category;
  final int warrantyMonths;
  final String? warrantyExpiryDate;
  final ReceiptStatus status;
  final List<String> imageKeys;
  final List<String> thumbnailKeys;
  final String? ocrRawText;
  final int llmConfidence;
  final String? userNotes;
  final List<String> userTags;
  final bool isFavorite;
  final List<String> userEditedFields;
  final String createdAt;
  final String updatedAt;
  final int version;
  final String? deletedAt;
  final List<String> localImagePaths;

  /// Whether the warranty is currently active (not expired).
  bool get isWarrantyActive {
    if (warrantyMonths <= 0 || warrantyExpiryDate == null) return false;
    final expiry = DateTime.tryParse(warrantyExpiryDate!);
    if (expiry == null) return false;
    return expiry.isAfter(DateTime.now());
  }

  /// Display name: user-edited store name, or extracted, or 'Unknown Store'.
  String get displayName => storeName ?? extractedMerchantName ?? 'Unknown Store';

  Receipt copyWith({
    String? receiptId,
    String? userId,
    String? storeName,
    String? extractedMerchantName,
    String? purchaseDate,
    String? extractedDate,
    double? totalAmount,
    double? extractedTotal,
    String? currency,
    String? category,
    int? warrantyMonths,
    String? warrantyExpiryDate,
    ReceiptStatus? status,
    List<String>? imageKeys,
    List<String>? thumbnailKeys,
    String? ocrRawText,
    int? llmConfidence,
    String? userNotes,
    List<String>? userTags,
    bool? isFavorite,
    List<String>? userEditedFields,
    String? createdAt,
    String? updatedAt,
    int? version,
    String? deletedAt,
    List<String>? localImagePaths,
  }) {
    return Receipt(
      receiptId: receiptId ?? this.receiptId,
      userId: userId ?? this.userId,
      storeName: storeName ?? this.storeName,
      extractedMerchantName: extractedMerchantName ?? this.extractedMerchantName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      extractedDate: extractedDate ?? this.extractedDate,
      totalAmount: totalAmount ?? this.totalAmount,
      extractedTotal: extractedTotal ?? this.extractedTotal,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      warrantyExpiryDate: warrantyExpiryDate ?? this.warrantyExpiryDate,
      status: status ?? this.status,
      imageKeys: imageKeys ?? this.imageKeys,
      thumbnailKeys: thumbnailKeys ?? this.thumbnailKeys,
      ocrRawText: ocrRawText ?? this.ocrRawText,
      llmConfidence: llmConfidence ?? this.llmConfidence,
      userNotes: userNotes ?? this.userNotes,
      userTags: userTags ?? this.userTags,
      isFavorite: isFavorite ?? this.isFavorite,
      userEditedFields: userEditedFields ?? this.userEditedFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      localImagePaths: localImagePaths ?? this.localImagePaths,
    );
  }

  @override
  List<Object?> get props => [
        receiptId,
        userId,
        storeName,
        extractedMerchantName,
        purchaseDate,
        extractedDate,
        totalAmount,
        extractedTotal,
        currency,
        category,
        warrantyMonths,
        warrantyExpiryDate,
        status,
        imageKeys,
        thumbnailKeys,
        ocrRawText,
        llmConfidence,
        userNotes,
        userTags,
        isFavorite,
        userEditedFields,
        createdAt,
        updatedAt,
        version,
        deletedAt,
        localImagePaths,
      ];
}
