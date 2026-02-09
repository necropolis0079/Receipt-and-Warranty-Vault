import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';

void main() {
  Receipt createReceipt({
    String receiptId = 'r1',
    String userId = 'u1',
    String? storeName = 'Test Store',
    int warrantyMonths = 12,
    String? warrantyExpiryDate,
    ReceiptStatus status = ReceiptStatus.active,
    bool isFavorite = false,
  }) {
    return Receipt(
      receiptId: receiptId,
      userId: userId,
      storeName: storeName,
      warrantyMonths: warrantyMonths,
      warrantyExpiryDate: warrantyExpiryDate,
      status: status,
      isFavorite: isFavorite,
      createdAt: '2026-02-09T10:00:00.000Z',
      updatedAt: '2026-02-09T10:00:00.000Z',
    );
  }

  group('Receipt', () {
    test('constructs with required fields', () {
      final receipt = createReceipt();
      expect(receipt.receiptId, 'r1');
      expect(receipt.userId, 'u1');
      expect(receipt.storeName, 'Test Store');
      expect(receipt.currency, 'EUR');
      expect(receipt.status, ReceiptStatus.active);
      expect(receipt.syncStatus, SyncStatus.pending);
      expect(receipt.version, 1);
    });

    test('copyWith creates modified copy', () {
      final original = createReceipt();
      final copy = original.copyWith(storeName: 'New Store', isFavorite: true);
      expect(copy.storeName, 'New Store');
      expect(copy.isFavorite, true);
      expect(copy.receiptId, original.receiptId);
    });

    test('isWarrantyActive returns true when warranty not expired', () {
      final futureDate = DateTime.now().add(const Duration(days: 365));
      final receipt = createReceipt(
        warrantyMonths: 12,
        warrantyExpiryDate: futureDate.toIso8601String().substring(0, 10),
      );
      expect(receipt.isWarrantyActive, true);
    });

    test('isWarrantyActive returns false when warranty expired', () {
      final receipt = createReceipt(
        warrantyMonths: 12,
        warrantyExpiryDate: '2020-01-01',
      );
      expect(receipt.isWarrantyActive, false);
    });

    test('isWarrantyActive returns false when no warranty', () {
      final receipt = createReceipt(warrantyMonths: 0);
      expect(receipt.isWarrantyActive, false);
    });

    test('displayName returns storeName when available', () {
      final receipt = createReceipt(storeName: 'My Store');
      expect(receipt.displayName, 'My Store');
    });

    test('displayName falls back to extractedMerchantName', () {
      final receipt = createReceipt(storeName: null).copyWith(
        extractedMerchantName: 'Extracted Store',
      );
      expect(receipt.displayName, 'Extracted Store');
    });

    test('displayName falls back to Unknown Store', () {
      final receipt = createReceipt(storeName: null);
      expect(receipt.displayName, 'Unknown Store');
    });

    test('equatable compares by value', () {
      final a = createReceipt();
      final b = createReceipt();
      expect(a, equals(b));
    });

    test('equatable detects differences', () {
      final a = createReceipt(receiptId: 'r1');
      final b = createReceipt(receiptId: 'r2');
      expect(a, isNot(equals(b)));
    });
  });

  group('ReceiptStatus', () {
    test('has all expected values', () {
      expect(ReceiptStatus.values.length, 3);
      expect(ReceiptStatus.values, contains(ReceiptStatus.active));
      expect(ReceiptStatus.values, contains(ReceiptStatus.returned));
      expect(ReceiptStatus.values, contains(ReceiptStatus.deleted));
    });
  });

  group('SyncStatus', () {
    test('has all expected values', () {
      expect(SyncStatus.values.length, 3);
      expect(SyncStatus.values, contains(SyncStatus.synced));
      expect(SyncStatus.values, contains(SyncStatus.pending));
      expect(SyncStatus.values, contains(SyncStatus.conflict));
    });
  });
}
