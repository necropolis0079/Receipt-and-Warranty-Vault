import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/database/app_database.dart';
import 'package:warrantyvault/features/receipt/data/models/receipt_mapper.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';

void main() {
  group('ReceiptMapper', () {
    // Helper to create a fully-populated ReceiptEntry for testing.
    ReceiptEntry createEntry({
      String receiptId = 'r-001',
      String userId = 'u-001',
      String? storeName = 'Test Store',
      String? extractedMerchantName = 'Extracted Store',
      String? purchaseDate = '2026-01-15',
      String? extractedDate = '2026-01-15',
      double? totalAmount = 42.50,
      double? extractedTotal = 42.50,
      String currency = 'EUR',
      String? category = 'Electronics',
      int warrantyMonths = 24,
      String? warrantyExpiryDate = '2028-01-15',
      String status = 'active',
      String? imageKeys,
      String? thumbnailKeys,
      String? ocrRawText = 'Some OCR text',
      int llmConfidence = 85,
      String? userNotes = 'Test notes',
      String? userTags,
      bool isFavorite = true,
      String? userEditedFields,
      String createdAt = '2026-01-15T10:00:00.000Z',
      String updatedAt = '2026-01-15T12:00:00.000Z',
      int version = 1,
      String? deletedAt,
      String? localImagePaths,
    }) {
      return ReceiptEntry(
        receiptId: receiptId,
        userId: userId,
        storeName: storeName,
        extractedMerchantName: extractedMerchantName,
        purchaseDate: purchaseDate,
        extractedDate: extractedDate,
        totalAmount: totalAmount,
        extractedTotal: extractedTotal,
        currency: currency,
        category: category,
        warrantyMonths: warrantyMonths,
        warrantyExpiryDate: warrantyExpiryDate,
        status: status,
        imageKeys: imageKeys,
        thumbnailKeys: thumbnailKeys,
        ocrRawText: ocrRawText,
        llmConfidence: llmConfidence,
        userNotes: userNotes,
        userTags: userTags,
        isFavorite: isFavorite,
        userEditedFields: userEditedFields,
        syncStatus: 'pending', // Unused — column retained for DB migration safety
        createdAt: createdAt,
        updatedAt: updatedAt,
        version: version,
        deletedAt: deletedAt,
        localImagePaths: localImagePaths,
      );
    }

    // Helper to create a fully-populated Receipt for testing.
    Receipt createReceipt({
      String receiptId = 'r-001',
      String userId = 'u-001',
      String? storeName = 'Test Store',
      String? extractedMerchantName = 'Extracted Store',
      String? purchaseDate = '2026-01-15',
      String? extractedDate = '2026-01-15',
      double? totalAmount = 42.50,
      double? extractedTotal = 42.50,
      String currency = 'EUR',
      String? category = 'Electronics',
      int warrantyMonths = 24,
      String? warrantyExpiryDate = '2028-01-15',
      ReceiptStatus status = ReceiptStatus.active,
      List<String> imageKeys = const ['img/key1.jpg', 'img/key2.jpg'],
      List<String> thumbnailKeys = const ['thumb/key1.jpg'],
      String? ocrRawText = 'Some OCR text',
      int llmConfidence = 85,
      String? userNotes = 'Test notes',
      List<String> userTags = const ['important', 'electronics'],
      bool isFavorite = true,
      List<String> userEditedFields = const ['storeName', 'category'],
      String createdAt = '2026-01-15T10:00:00.000Z',
      String updatedAt = '2026-01-15T12:00:00.000Z',
      int version = 1,
      String? deletedAt,
      List<String> localImagePaths = const ['/local/img1.jpg'],
    }) {
      return Receipt(
        receiptId: receiptId,
        userId: userId,
        storeName: storeName,
        extractedMerchantName: extractedMerchantName,
        purchaseDate: purchaseDate,
        extractedDate: extractedDate,
        totalAmount: totalAmount,
        extractedTotal: extractedTotal,
        currency: currency,
        category: category,
        warrantyMonths: warrantyMonths,
        warrantyExpiryDate: warrantyExpiryDate,
        status: status,
        imageKeys: imageKeys,
        thumbnailKeys: thumbnailKeys,
        ocrRawText: ocrRawText,
        llmConfidence: llmConfidence,
        userNotes: userNotes,
        userTags: userTags,
        isFavorite: isFavorite,
        userEditedFields: userEditedFields,
        createdAt: createdAt,
        updatedAt: updatedAt,
        version: version,
        deletedAt: deletedAt,
        localImagePaths: localImagePaths,
      );
    }

    group('toReceipt', () {
      test('maps all simple fields correctly', () {
        final entry = createEntry();
        final receipt = ReceiptMapper.toReceipt(entry);

        expect(receipt.receiptId, 'r-001');
        expect(receipt.userId, 'u-001');
        expect(receipt.storeName, 'Test Store');
        expect(receipt.extractedMerchantName, 'Extracted Store');
        expect(receipt.purchaseDate, '2026-01-15');
        expect(receipt.extractedDate, '2026-01-15');
        expect(receipt.totalAmount, 42.50);
        expect(receipt.extractedTotal, 42.50);
        expect(receipt.currency, 'EUR');
        expect(receipt.category, 'Electronics');
        expect(receipt.warrantyMonths, 24);
        expect(receipt.warrantyExpiryDate, '2028-01-15');
        expect(receipt.ocrRawText, 'Some OCR text');
        expect(receipt.llmConfidence, 85);
        expect(receipt.userNotes, 'Test notes');
        expect(receipt.isFavorite, true);
        expect(receipt.createdAt, '2026-01-15T10:00:00.000Z');
        expect(receipt.updatedAt, '2026-01-15T12:00:00.000Z');
        expect(receipt.version, 1);
        expect(receipt.deletedAt, isNull);
      });

      test('decodes JSON list fields (imageKeys, userTags, localImagePaths, userEditedFields)',
          () {
        final entry = createEntry(
          imageKeys: jsonEncode(['key1.jpg', 'key2.jpg']),
          thumbnailKeys: jsonEncode(['thumb1.jpg']),
          userTags: jsonEncode(['tag1', 'tag2', 'tag3']),
          localImagePaths: jsonEncode(['/path/img1.jpg', '/path/img2.jpg']),
          userEditedFields: jsonEncode(['storeName', 'totalAmount']),
        );

        final receipt = ReceiptMapper.toReceipt(entry);

        expect(receipt.imageKeys, ['key1.jpg', 'key2.jpg']);
        expect(receipt.thumbnailKeys, ['thumb1.jpg']);
        expect(receipt.userTags, ['tag1', 'tag2', 'tag3']);
        expect(receipt.localImagePaths, ['/path/img1.jpg', '/path/img2.jpg']);
        expect(receipt.userEditedFields, ['storeName', 'totalAmount']);
      });

      test('returns empty lists when JSON list fields are null', () {
        final entry = createEntry(
          imageKeys: null,
          thumbnailKeys: null,
          userTags: null,
          localImagePaths: null,
          userEditedFields: null,
        );

        final receipt = ReceiptMapper.toReceipt(entry);

        expect(receipt.imageKeys, isEmpty);
        expect(receipt.thumbnailKeys, isEmpty);
        expect(receipt.userTags, isEmpty);
        expect(receipt.localImagePaths, isEmpty);
        expect(receipt.userEditedFields, isEmpty);
      });

      test('returns empty lists when JSON list fields are empty strings', () {
        final entry = createEntry(
          imageKeys: '',
          userTags: '',
          localImagePaths: '',
          userEditedFields: '',
        );

        final receipt = ReceiptMapper.toReceipt(entry);

        expect(receipt.imageKeys, isEmpty);
        expect(receipt.userTags, isEmpty);
        expect(receipt.localImagePaths, isEmpty);
        expect(receipt.userEditedFields, isEmpty);
      });

      test('parses status enums correctly', () {
        final activeEntry = createEntry(status: 'active');
        final activeReceipt = ReceiptMapper.toReceipt(activeEntry);
        expect(activeReceipt.status, ReceiptStatus.active);

        final returnedEntry = createEntry(status: 'returned');
        final returnedReceipt = ReceiptMapper.toReceipt(returnedEntry);
        expect(returnedReceipt.status, ReceiptStatus.returned);

        final deletedEntry = createEntry(status: 'deleted');
        final deletedReceipt = ReceiptMapper.toReceipt(deletedEntry);
        expect(deletedReceipt.status, ReceiptStatus.deleted);
      });

      test('defaults status when value is invalid', () {
        final entry = createEntry(status: 'unknown_status');
        final receipt = ReceiptMapper.toReceipt(entry);
        expect(receipt.status, ReceiptStatus.active);
      });
    });

    group('toCompanion', () {
      test('maps all fields correctly', () {
        final receipt = createReceipt();
        final companion = ReceiptMapper.toCompanion(receipt);

        expect(companion.receiptId.value, 'r-001');
        expect(companion.userId.value, 'u-001');
        expect(companion.storeName.value, 'Test Store');
        expect(companion.extractedMerchantName.value, 'Extracted Store');
        expect(companion.purchaseDate.value, '2026-01-15');
        expect(companion.extractedDate.value, '2026-01-15');
        expect(companion.totalAmount.value, 42.50);
        expect(companion.extractedTotal.value, 42.50);
        expect(companion.currency.value, 'EUR');
        expect(companion.category.value, 'Electronics');
        expect(companion.warrantyMonths.value, 24);
        expect(companion.warrantyExpiryDate.value, '2028-01-15');
        expect(companion.status.value, 'active');
        expect(companion.ocrRawText.value, 'Some OCR text');
        expect(companion.llmConfidence.value, 85);
        expect(companion.userNotes.value, 'Test notes');
        expect(companion.isFavorite.value, true);
        expect(companion.createdAt.value, '2026-01-15T10:00:00.000Z');
        expect(companion.updatedAt.value, '2026-01-15T12:00:00.000Z');
        expect(companion.version.value, 1);
      });

      test('encodes list fields as JSON strings', () {
        final receipt = createReceipt(
          imageKeys: ['img1.jpg', 'img2.jpg'],
          thumbnailKeys: ['thumb1.jpg'],
          userTags: ['tag1', 'tag2'],
          userEditedFields: ['storeName'],
          localImagePaths: ['/local/img1.jpg'],
        );

        final companion = ReceiptMapper.toCompanion(receipt);

        expect(companion.imageKeys.value, jsonEncode(['img1.jpg', 'img2.jpg']));
        expect(companion.thumbnailKeys.value, jsonEncode(['thumb1.jpg']));
        expect(companion.userTags.value, jsonEncode(['tag1', 'tag2']));
        expect(
            companion.userEditedFields.value, jsonEncode(['storeName']));
        expect(companion.localImagePaths.value,
            jsonEncode(['/local/img1.jpg']));
      });

      test('handles null values for optional fields', () {
        final receipt = createReceipt(
          storeName: null,
          extractedMerchantName: null,
          purchaseDate: null,
          extractedDate: null,
          totalAmount: null,
          extractedTotal: null,
          category: null,
          warrantyExpiryDate: null,
          ocrRawText: null,
          userNotes: null,
          deletedAt: null,
        );

        final companion = ReceiptMapper.toCompanion(receipt);

        expect(companion.storeName.value, isNull);
        expect(companion.extractedMerchantName.value, isNull);
        expect(companion.purchaseDate.value, isNull);
        expect(companion.extractedDate.value, isNull);
        expect(companion.totalAmount.value, isNull);
        expect(companion.extractedTotal.value, isNull);
        expect(companion.category.value, isNull);
        expect(companion.warrantyExpiryDate.value, isNull);
        expect(companion.ocrRawText.value, isNull);
        expect(companion.userNotes.value, isNull);
        expect(companion.deletedAt.value, isNull);
      });

      test('encodes empty lists as null', () {
        final receipt = createReceipt(
          imageKeys: const [],
          thumbnailKeys: const [],
          userTags: const [],
          userEditedFields: const [],
          localImagePaths: const [],
        );

        final companion = ReceiptMapper.toCompanion(receipt);

        expect(companion.imageKeys.value, isNull);
        expect(companion.thumbnailKeys.value, isNull);
        expect(companion.userTags.value, isNull);
        expect(companion.userEditedFields.value, isNull);
        expect(companion.localImagePaths.value, isNull);
      });

      test('encodes status enums as their name strings', () {
        final activeReceipt = createReceipt(status: ReceiptStatus.active);
        final companion = ReceiptMapper.toCompanion(activeReceipt);
        expect(companion.status.value, 'active');

        final returnedReceipt = createReceipt(status: ReceiptStatus.returned);
        final companion2 = ReceiptMapper.toCompanion(returnedReceipt);
        expect(companion2.status.value, 'returned');
      });
    });

    group('round-trip', () {
      test('toReceipt from toCompanion data preserves all fields', () {
        // Start with a Receipt that has data in all fields.
        final original = createReceipt(
          receiptId: 'rt-001',
          userId: 'user-rt',
          storeName: 'Round Trip Store',
          extractedMerchantName: 'RT Merchant',
          purchaseDate: '2026-03-01',
          extractedDate: '2026-03-01',
          totalAmount: 99.99,
          extractedTotal: 99.99,
          currency: 'USD',
          category: 'Groceries',
          warrantyMonths: 6,
          warrantyExpiryDate: '2026-09-01',
          status: ReceiptStatus.returned,
          imageKeys: ['s3/key1.jpg', 's3/key2.jpg'],
          thumbnailKeys: ['s3/thumb1.jpg'],
          ocrRawText: 'OCR round trip text',
          llmConfidence: 92,
          userNotes: 'Round trip notes',
          userTags: ['grocery', 'weekly'],
          isFavorite: true,
          userEditedFields: ['storeName', 'totalAmount'],
          createdAt: '2026-03-01T08:00:00.000Z',
          updatedAt: '2026-03-01T09:30:00.000Z',
          version: 3,
          deletedAt: null,
          localImagePaths: ['/local/rt1.jpg', '/local/rt2.jpg'],
        );

        // Convert to companion, extract values, build a ReceiptEntry,
        // then map back to Receipt.
        final companion = ReceiptMapper.toCompanion(original);

        final entry = ReceiptEntry(
          receiptId: companion.receiptId.value,
          userId: companion.userId.value,
          storeName: companion.storeName.value,
          extractedMerchantName: companion.extractedMerchantName.value,
          purchaseDate: companion.purchaseDate.value,
          extractedDate: companion.extractedDate.value,
          totalAmount: companion.totalAmount.value,
          extractedTotal: companion.extractedTotal.value,
          currency: companion.currency.value,
          category: companion.category.value,
          warrantyMonths: companion.warrantyMonths.value,
          warrantyExpiryDate: companion.warrantyExpiryDate.value,
          status: companion.status.value,
          imageKeys: companion.imageKeys.value,
          thumbnailKeys: companion.thumbnailKeys.value,
          ocrRawText: companion.ocrRawText.value,
          llmConfidence: companion.llmConfidence.value,
          userNotes: companion.userNotes.value,
          userTags: companion.userTags.value,
          isFavorite: companion.isFavorite.value,
          userEditedFields: companion.userEditedFields.value,
          syncStatus: 'pending', // Unused — column retained for DB migration safety
          createdAt: companion.createdAt.value,
          updatedAt: companion.updatedAt.value,
          version: companion.version.value,
          deletedAt: companion.deletedAt.value,
          localImagePaths: companion.localImagePaths.value,
        );

        final roundTripped = ReceiptMapper.toReceipt(entry);

        expect(roundTripped.receiptId, original.receiptId);
        expect(roundTripped.userId, original.userId);
        expect(roundTripped.storeName, original.storeName);
        expect(roundTripped.extractedMerchantName,
            original.extractedMerchantName);
        expect(roundTripped.purchaseDate, original.purchaseDate);
        expect(roundTripped.extractedDate, original.extractedDate);
        expect(roundTripped.totalAmount, original.totalAmount);
        expect(roundTripped.extractedTotal, original.extractedTotal);
        expect(roundTripped.currency, original.currency);
        expect(roundTripped.category, original.category);
        expect(roundTripped.warrantyMonths, original.warrantyMonths);
        expect(roundTripped.warrantyExpiryDate, original.warrantyExpiryDate);
        expect(roundTripped.status, original.status);
        expect(roundTripped.imageKeys, original.imageKeys);
        expect(roundTripped.thumbnailKeys, original.thumbnailKeys);
        expect(roundTripped.ocrRawText, original.ocrRawText);
        expect(roundTripped.llmConfidence, original.llmConfidence);
        expect(roundTripped.userNotes, original.userNotes);
        expect(roundTripped.userTags, original.userTags);
        expect(roundTripped.isFavorite, original.isFavorite);
        expect(roundTripped.userEditedFields, original.userEditedFields);
        expect(roundTripped.createdAt, original.createdAt);
        expect(roundTripped.updatedAt, original.updatedAt);
        expect(roundTripped.version, original.version);
        expect(roundTripped.deletedAt, original.deletedAt);
        expect(roundTripped.localImagePaths, original.localImagePaths);

        // Equatable comparison should also pass.
        expect(roundTripped, equals(original));
      });
    });
  });
}
