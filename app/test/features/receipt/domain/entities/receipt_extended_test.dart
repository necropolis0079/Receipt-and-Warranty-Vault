import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';

void main() {
  /// Helper to create a fully-populated Receipt for testing.
  Receipt createFullReceipt({
    String receiptId = 'r-ext-001',
    String userId = 'user-ext-1',
    String? storeName = 'Full Store',
    String? extractedMerchantName = 'Extracted Merchant',
    String? purchaseDate = '2026-01-15',
    String? extractedDate = '2026-01-15',
    double? totalAmount = 99.99,
    double? extractedTotal = 99.98,
    String currency = 'EUR',
    String? category = 'Electronics',
    int warrantyMonths = 24,
    String? warrantyExpiryDate = '2028-01-15',
    ReceiptStatus status = ReceiptStatus.active,
    List<String> imageKeys = const ['img/001.jpg', 'img/002.jpg'],
    List<String> thumbnailKeys = const ['thumb/001.jpg'],
    String? ocrRawText = 'OCR raw text content here',
    int llmConfidence = 85,
    String? userNotes = 'Test note',
    List<String> userTags = const ['electronics', 'warranty'],
    bool isFavorite = true,
    List<String> userEditedFields = const ['storeName', 'totalAmount'],
    String createdAt = '2026-01-15T10:00:00.000Z',
    String updatedAt = '2026-01-15T12:00:00.000Z',
    int version = 2,
    String? deletedAt,
    List<String> localImagePaths = const ['/data/img/001.jpg'],
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

  /// Helper to create a minimal Receipt (only required fields + defaults).
  Receipt createMinimalReceipt({
    String receiptId = 'r-min-001',
    String userId = 'user-min-1',
  }) {
    return Receipt(
      receiptId: receiptId,
      userId: userId,
      createdAt: '2026-02-09T10:00:00.000Z',
      updatedAt: '2026-02-09T10:00:00.000Z',
    );
  }

  group('copyWith — field preservation', () {
    test('preserves all fields when no changes specified', () {
      final original = createFullReceipt();
      final copy = original.copyWith();

      expect(copy.receiptId, original.receiptId);
      expect(copy.userId, original.userId);
      expect(copy.storeName, original.storeName);
      expect(copy.extractedMerchantName, original.extractedMerchantName);
      expect(copy.purchaseDate, original.purchaseDate);
      expect(copy.extractedDate, original.extractedDate);
      expect(copy.totalAmount, original.totalAmount);
      expect(copy.extractedTotal, original.extractedTotal);
      expect(copy.currency, original.currency);
      expect(copy.category, original.category);
      expect(copy.warrantyMonths, original.warrantyMonths);
      expect(copy.warrantyExpiryDate, original.warrantyExpiryDate);
      expect(copy.status, original.status);
      expect(copy.imageKeys, original.imageKeys);
      expect(copy.thumbnailKeys, original.thumbnailKeys);
      expect(copy.ocrRawText, original.ocrRawText);
      expect(copy.llmConfidence, original.llmConfidence);
      expect(copy.userNotes, original.userNotes);
      expect(copy.userTags, original.userTags);
      expect(copy.isFavorite, original.isFavorite);
      expect(copy.userEditedFields, original.userEditedFields);
      expect(copy.createdAt, original.createdAt);
      expect(copy.updatedAt, original.updatedAt);
      expect(copy.version, original.version);
      expect(copy.deletedAt, original.deletedAt);
      expect(copy.localImagePaths, original.localImagePaths);
      // Equatable equality as well
      expect(copy, equals(original));
    });

    test('copyWith changes all fields when every field is overridden', () {
      final original = createFullReceipt();
      final copy = original.copyWith(
        receiptId: 'r-new-999',
        userId: 'user-new-999',
        storeName: 'New Store Name',
        extractedMerchantName: 'New Extracted',
        purchaseDate: '2027-06-01',
        extractedDate: '2027-06-01',
        totalAmount: 250.50,
        extractedTotal: 250.49,
        currency: 'USD',
        category: 'Appliances',
        warrantyMonths: 36,
        warrantyExpiryDate: '2030-06-01',
        status: ReceiptStatus.returned,
        imageKeys: ['img/new.jpg'],
        thumbnailKeys: ['thumb/new.jpg'],
        ocrRawText: 'New OCR text',
        llmConfidence: 92,
        userNotes: 'Updated note',
        userTags: ['appliance'],
        isFavorite: false,
        userEditedFields: ['category'],
        createdAt: '2027-06-01T08:00:00.000Z',
        updatedAt: '2027-06-01T09:00:00.000Z',
        version: 5,
        deletedAt: '2027-07-01T00:00:00.000Z',
        localImagePaths: ['/data/img/new.jpg'],
      );

      expect(copy.receiptId, 'r-new-999');
      expect(copy.userId, 'user-new-999');
      expect(copy.storeName, 'New Store Name');
      expect(copy.extractedMerchantName, 'New Extracted');
      expect(copy.purchaseDate, '2027-06-01');
      expect(copy.extractedDate, '2027-06-01');
      expect(copy.totalAmount, 250.50);
      expect(copy.extractedTotal, 250.49);
      expect(copy.currency, 'USD');
      expect(copy.category, 'Appliances');
      expect(copy.warrantyMonths, 36);
      expect(copy.warrantyExpiryDate, '2030-06-01');
      expect(copy.status, ReceiptStatus.returned);
      expect(copy.imageKeys, ['img/new.jpg']);
      expect(copy.thumbnailKeys, ['thumb/new.jpg']);
      expect(copy.ocrRawText, 'New OCR text');
      expect(copy.llmConfidence, 92);
      expect(copy.userNotes, 'Updated note');
      expect(copy.userTags, ['appliance']);
      expect(copy.isFavorite, false);
      expect(copy.userEditedFields, ['category']);
      expect(copy.createdAt, '2027-06-01T08:00:00.000Z');
      expect(copy.updatedAt, '2027-06-01T09:00:00.000Z');
      expect(copy.version, 5);
      expect(copy.deletedAt, '2027-07-01T00:00:00.000Z');
      expect(copy.localImagePaths, ['/data/img/new.jpg']);
      // Ensure it is NOT equal to the original
      expect(copy, isNot(equals(original)));
    });
  });

  group('isWarrantyActive — edge cases', () {
    test('returns true when warrantyExpiryDate is in the future', () {
      final futureDate =
          DateTime.now().add(const Duration(days: 365)).toIso8601String();
      final receipt = createFullReceipt(
        warrantyMonths: 12,
        warrantyExpiryDate: futureDate,
      );
      expect(receipt.isWarrantyActive, isTrue);
    });

    test('returns false when warrantyExpiryDate is in the past', () {
      final receipt = createFullReceipt(
        warrantyMonths: 12,
        warrantyExpiryDate: '2020-01-01',
      );
      expect(receipt.isWarrantyActive, isFalse);
    });

    test('returns false when warrantyExpiryDate is null', () {
      final receipt = createFullReceipt(
        warrantyMonths: 12,
        warrantyExpiryDate: null,
      );
      expect(receipt.isWarrantyActive, isFalse);
    });

    test('returns false when warrantyMonths is 0 even with future expiry', () {
      final futureDate =
          DateTime.now().add(const Duration(days: 365)).toIso8601String();
      final receipt = createFullReceipt(
        warrantyMonths: 0,
        warrantyExpiryDate: futureDate,
      );
      expect(receipt.isWarrantyActive, isFalse);
    });

    test('returns false when warrantyMonths is negative', () {
      final futureDate =
          DateTime.now().add(const Duration(days: 365)).toIso8601String();
      final receipt = createFullReceipt(
        warrantyMonths: -1,
        warrantyExpiryDate: futureDate,
      );
      expect(receipt.isWarrantyActive, isFalse);
    });

    test('returns false when warrantyExpiryDate is an invalid date string', () {
      final receipt = createFullReceipt(
        warrantyMonths: 12,
        warrantyExpiryDate: 'not-a-date',
      );
      expect(receipt.isWarrantyActive, isFalse);
    });

    test(
        'returns true on the expiry day itself '
        '(expiry date-only parses as midnight, isAfter checks against now)',
        () {
      // DateTime.tryParse on a date-only string returns midnight of that day.
      // If "now" is during the day and the expiry is tomorrow's midnight,
      // isAfter(now) will be true. We construct a date far enough in the future
      // to guarantee the expiry is after "now".
      final tomorrow =
          DateTime.now().add(const Duration(days: 1));
      final tomorrowStr = tomorrow.toIso8601String().substring(0, 10);
      final receipt = createFullReceipt(
        warrantyMonths: 1,
        warrantyExpiryDate: tomorrowStr,
      );
      // Tomorrow's midnight is always after now (during today), so this is true.
      expect(receipt.isWarrantyActive, isTrue);
    });

    test(
        'returns false when expiry is today as date-only '
        '(midnight today is before now unless test runs at midnight)', () {
      // A date-only string for today parses to midnight today, which is before
      // the current wall-clock time (unless the test runs exactly at midnight).
      final todayStr =
          DateTime.now().toIso8601String().substring(0, 10);
      final receipt = createFullReceipt(
        warrantyMonths: 1,
        warrantyExpiryDate: todayStr,
      );
      // Midnight today is NOT after "now" (which is later in the day).
      // This will be false unless the test runs at exactly 00:00:00.000.
      // The implementation uses isAfter, so today's date-only = expired.
      expect(receipt.isWarrantyActive, isFalse);
    });
  });

  group('displayName — edge cases', () {
    test('returns storeName when both storeName and extractedMerchantName exist',
        () {
      final receipt = createFullReceipt(
        storeName: 'User Store',
        extractedMerchantName: 'OCR Merchant',
      );
      expect(receipt.displayName, 'User Store');
    });

    test('falls back to extractedMerchantName when storeName is null', () {
      final receipt = createFullReceipt(
        storeName: null,
        extractedMerchantName: 'OCR Merchant',
      );
      expect(receipt.displayName, 'OCR Merchant');
    });

    test('falls back to "Unknown Store" when both names are null', () {
      final receipt = createFullReceipt(
        storeName: null,
        extractedMerchantName: null,
      );
      expect(receipt.displayName, 'Unknown Store');
    });

    test('returns empty string storeName when storeName is empty', () {
      // Note: copyWith cannot set storeName to empty because null-coalescing
      // keeps original. We construct directly.
      final receipt = Receipt(
        receiptId: 'r-empty',
        userId: 'u-1',
        storeName: '',
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
      );
      // displayName is storeName ?? extractedMerchantName ?? 'Unknown Store'.
      // Empty string is not null, so it returns ''.
      expect(receipt.displayName, '');
    });
  });

  group('Equatable — identity and equality', () {
    test('two receipts with identical fields are equal', () {
      final a = createFullReceipt();
      final b = createFullReceipt();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('receipts with different receiptId are not equal', () {
      final a = createFullReceipt(receiptId: 'r-001');
      final b = createFullReceipt(receiptId: 'r-002');
      expect(a, isNot(equals(b)));
    });

    test('receipts with different userId are not equal', () {
      final a = createFullReceipt(userId: 'user-1');
      final b = createFullReceipt(userId: 'user-2');
      expect(a, isNot(equals(b)));
    });

    test('receipts with different status are not equal', () {
      final a = createFullReceipt(status: ReceiptStatus.active);
      final b = createFullReceipt(status: ReceiptStatus.returned);
      expect(a, isNot(equals(b)));
    });

    test('receipts with different isFavorite are not equal', () {
      final a = createFullReceipt(isFavorite: true);
      final b = createFullReceipt(isFavorite: false);
      expect(a, isNot(equals(b)));
    });

    test('receipts with different list fields are not equal', () {
      final a = createFullReceipt(userTags: ['tag1']);
      final b = createFullReceipt(userTags: ['tag2']);
      expect(a, isNot(equals(b)));
    });

    test('receipt is equal to its own copyWith() with no changes', () {
      final original = createFullReceipt();
      expect(original, equals(original.copyWith()));
    });
  });

  group('Receipt with all nullable fields null', () {
    test('constructs successfully with only required fields', () {
      final receipt = createMinimalReceipt();

      expect(receipt.receiptId, 'r-min-001');
      expect(receipt.userId, 'user-min-1');
      expect(receipt.storeName, isNull);
      expect(receipt.extractedMerchantName, isNull);
      expect(receipt.purchaseDate, isNull);
      expect(receipt.extractedDate, isNull);
      expect(receipt.totalAmount, isNull);
      expect(receipt.extractedTotal, isNull);
      expect(receipt.category, isNull);
      expect(receipt.warrantyExpiryDate, isNull);
      expect(receipt.ocrRawText, isNull);
      expect(receipt.userNotes, isNull);
      expect(receipt.deletedAt, isNull);
    });

    test('default values are correct for non-nullable fields', () {
      final receipt = createMinimalReceipt();

      expect(receipt.currency, 'EUR');
      expect(receipt.warrantyMonths, 0);
      expect(receipt.status, ReceiptStatus.active);
      expect(receipt.imageKeys, isEmpty);
      expect(receipt.thumbnailKeys, isEmpty);
      expect(receipt.llmConfidence, 0);
      expect(receipt.userTags, isEmpty);
      expect(receipt.isFavorite, false);
      expect(receipt.userEditedFields, isEmpty);
      expect(receipt.version, 1);
      expect(receipt.localImagePaths, isEmpty);
    });

    test('isWarrantyActive is false when all warranty fields are defaults', () {
      final receipt = createMinimalReceipt();
      expect(receipt.isWarrantyActive, isFalse);
    });

    test('displayName falls back to Unknown Store', () {
      final receipt = createMinimalReceipt();
      expect(receipt.displayName, 'Unknown Store');
    });
  });

  group('Receipt with special characters in storeName', () {
    test('handles Unicode characters (Greek)', () {
      final receipt = createFullReceipt(storeName: '\u039a\u03c9\u03c4\u03c3\u03cc\u03b2\u03bf\u03bb\u03bf\u03c2');
      expect(receipt.storeName, '\u039a\u03c9\u03c4\u03c3\u03cc\u03b2\u03bf\u03bb\u03bf\u03c2');
      expect(receipt.displayName, '\u039a\u03c9\u03c4\u03c3\u03cc\u03b2\u03bf\u03bb\u03bf\u03c2');
    });

    test('handles emoji characters', () {
      final receipt = createFullReceipt(storeName: 'Store \ud83d\udcf1 Mobile');
      expect(receipt.displayName, 'Store \ud83d\udcf1 Mobile');
    });

    test('handles special punctuation and symbols', () {
      final receipt =
          createFullReceipt(storeName: "O'Reilly & Sons (Ltd.) - #1 Store!");
      expect(receipt.displayName, "O'Reilly & Sons (Ltd.) - #1 Store!");
    });

    test('handles very long storeName', () {
      final longName = 'A' * 1000;
      final receipt = createFullReceipt(storeName: longName);
      expect(receipt.displayName, longName);
      expect(receipt.displayName.length, 1000);
    });

    test('handles newlines and tabs in storeName', () {
      final receipt = createFullReceipt(storeName: 'Store\nName\tHere');
      expect(receipt.displayName, 'Store\nName\tHere');
    });

    test('preserves special characters through copyWith', () {
      final original =
          createFullReceipt(storeName: 'Caf\u00e9 "D\u00e9j\u00e0 Vu" & More');
      final copy = original.copyWith();
      expect(copy.storeName, original.storeName);
      expect(copy.displayName, 'Caf\u00e9 "D\u00e9j\u00e0 Vu" & More');
    });
  });

  group('props — Equatable completeness', () {
    test('props list contains 26 elements matching all fields', () {
      final receipt = createFullReceipt();
      // Receipt has 26 fields in its props list.
      expect(receipt.props.length, 26);
    });

    test('props includes all non-null field values', () {
      final receipt = createFullReceipt(
        receiptId: 'test-id',
        userId: 'test-user',
        currency: 'USD',
      );
      expect(receipt.props, contains('test-id'));
      expect(receipt.props, contains('test-user'));
      expect(receipt.props, contains('USD'));
    });
  });
}
