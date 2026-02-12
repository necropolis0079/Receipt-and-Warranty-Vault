import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/receipt.dart';

/// Bidirectional mapper between Drift [ReceiptEntry] and domain [Receipt].
///
/// Handles JSON encode/decode for list fields (imageKeys, thumbnailKeys,
/// userTags, userEditedFields, localImagePaths) and enum string conversion.
class ReceiptMapper {
  ReceiptMapper._();

  /// Convert a Drift [ReceiptEntry] to a domain [Receipt].
  static Receipt toReceipt(ReceiptEntry entry) {
    return Receipt(
      receiptId: entry.receiptId,
      userId: entry.userId,
      storeName: entry.storeName,
      extractedMerchantName: entry.extractedMerchantName,
      purchaseDate: entry.purchaseDate,
      extractedDate: entry.extractedDate,
      totalAmount: entry.totalAmount,
      extractedTotal: entry.extractedTotal,
      currency: entry.currency,
      category: entry.category,
      warrantyMonths: entry.warrantyMonths,
      warrantyExpiryDate: entry.warrantyExpiryDate,
      status: _parseStatus(entry.status),
      imageKeys: _decodeJsonList(entry.imageKeys),
      thumbnailKeys: _decodeJsonList(entry.thumbnailKeys),
      ocrRawText: entry.ocrRawText,
      llmConfidence: entry.llmConfidence,
      userNotes: entry.userNotes,
      userTags: _decodeJsonList(entry.userTags),
      isFavorite: entry.isFavorite,
      userEditedFields: _decodeJsonList(entry.userEditedFields),
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      version: entry.version,
      deletedAt: entry.deletedAt,
      localImagePaths: _decodeJsonList(entry.localImagePaths),
    );
  }

  /// Convert a domain [Receipt] to a Drift [ReceiptsCompanion] for insert/update.
  static ReceiptsCompanion toCompanion(Receipt receipt) {
    return ReceiptsCompanion(
      receiptId: Value(receipt.receiptId),
      userId: Value(receipt.userId),
      storeName: Value(receipt.storeName),
      extractedMerchantName: Value(receipt.extractedMerchantName),
      purchaseDate: Value(receipt.purchaseDate),
      extractedDate: Value(receipt.extractedDate),
      totalAmount: Value(receipt.totalAmount),
      extractedTotal: Value(receipt.extractedTotal),
      currency: Value(receipt.currency),
      category: Value(receipt.category),
      warrantyMonths: Value(receipt.warrantyMonths),
      warrantyExpiryDate: Value(receipt.warrantyExpiryDate),
      status: Value(receipt.status.name),
      imageKeys: Value(_encodeJsonList(receipt.imageKeys)),
      thumbnailKeys: Value(_encodeJsonList(receipt.thumbnailKeys)),
      ocrRawText: Value(receipt.ocrRawText),
      llmConfidence: Value(receipt.llmConfidence),
      userNotes: Value(receipt.userNotes),
      userTags: Value(_encodeJsonList(receipt.userTags)),
      isFavorite: Value(receipt.isFavorite),
      userEditedFields: Value(_encodeJsonList(receipt.userEditedFields)),
      createdAt: Value(receipt.createdAt),
      updatedAt: Value(receipt.updatedAt),
      version: Value(receipt.version),
      deletedAt: Value(receipt.deletedAt),
      localImagePaths: Value(_encodeJsonList(receipt.localImagePaths)),
    );
  }

  static ReceiptStatus _parseStatus(String status) {
    return ReceiptStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ReceiptStatus.active,
    );
  }

  static List<String> _decodeJsonList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded.cast<String>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static String? _encodeJsonList(List<String> list) {
    if (list.isEmpty) return null;
    return jsonEncode(list);
  }
}
