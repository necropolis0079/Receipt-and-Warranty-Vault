import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/features/receipt/data/services/mock_export_service.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/domain/services/export_service.dart';

void main() {
  late MockExportService service;

  final now = DateTime.now().toIso8601String();

  final testReceipt = Receipt(
    receiptId: 'test-id',
    userId: 'user-1',
    storeName: 'Test Store',
    totalAmount: 42.50,
    currency: 'EUR',
    category: 'Electronics',
    purchaseDate: '2026-01-15',
    warrantyMonths: 24,
    warrantyExpiryDate: '2028-01-15',
    status: ReceiptStatus.active,
    createdAt: now,
    updatedAt: now,
  );

  final testReceipt2 = Receipt(
    receiptId: 'test-id-2',
    userId: 'user-1',
    storeName: 'Another Store',
    totalAmount: 19.99,
    currency: 'USD',
    purchaseDate: '2026-02-01',
    status: ReceiptStatus.active,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    service = MockExportService();
  });

  group('MockExportService', () {
    test('implements ExportService', () {
      expect(service, isA<ExportService>());
    });

    group('shareReceipt', () {
      test('adds receipt to sharedReceipts list', () async {
        expect(service.sharedReceipts, isEmpty);

        await service.shareReceipt(testReceipt);

        expect(service.sharedReceipts, hasLength(1));
        expect(service.sharedReceipts.first, equals(testReceipt));

        // Share a second receipt to verify accumulation
        await service.shareReceipt(testReceipt2);

        expect(service.sharedReceipts, hasLength(2));
        expect(service.sharedReceipts[1], equals(testReceipt2));
      });
    });

    group('formatReceiptAsText', () {
      test('returns non-empty formatted text with store name', () {
        final text = service.formatReceiptAsText(testReceipt);

        expect(text, isNotEmpty);
        expect(text, contains('Test Store'));
        expect(text, contains('--- Receipt ---'));
        expect(text, contains('---'));
      });

      test('includes date, amount, category, and warranty info', () {
        final text = service.formatReceiptAsText(testReceipt);

        expect(text, contains('Date: 2026-01-15'));
        expect(text, contains('Total: 42.50 EUR'));
        expect(text, contains('Category: Electronics'));
        expect(text, contains('Warranty: 24 months'));
        expect(text, contains('Warranty Expires: 2028-01-15'));
      });

      test('uses displayName (falls back to Unknown Store when no store name)',
          () {
        final noStoreReceipt = Receipt(
          receiptId: 'no-store',
          userId: 'user-1',
          status: ReceiptStatus.active,
          createdAt: now,
          updatedAt: now,
        );

        final text = service.formatReceiptAsText(noStoreReceipt);

        expect(text, contains('Unknown Store'));
      });
    });

    group('batchExportCsv', () {
      test('returns CSV string with headers and data rows', () {
        final csv = service.batchExportCsv([testReceipt, testReceipt2]);

        final lines = csv.split('\n');
        // Header + 2 data rows
        expect(lines.length, 3);

        // Verify header
        expect(
          lines[0],
          'Store,Date,Amount,Currency,Category,Warranty Months,Expiry Date,Status,Notes',
        );

        // Verify first data row contains receipt data
        expect(lines[1], contains('Test Store'));
        expect(lines[1], contains('42.50'));
        expect(lines[1], contains('EUR'));
        expect(lines[1], contains('Electronics'));
        expect(lines[1], contains('24'));

        // Verify second data row
        expect(lines[2], contains('Another Store'));
        expect(lines[2], contains('19.99'));
        expect(lines[2], contains('USD'));

        // Verify lastCsvOutput is set
        expect(service.lastCsvOutput, equals(csv));
      });

      test('with empty list returns header-only CSV', () {
        final csv = service.batchExportCsv([]);

        final lines = csv.split('\n');
        // Header line + empty data (the join of empty list produces nothing after header)
        expect(lines[0],
            'Store,Date,Amount,Currency,Category,Warranty Months,Expiry Date,Status,Notes');
        // With empty list, rows.join('\n') produces '', so csv is "header\n"
        // which splits into ['header', '']
        expect(lines.length, 2);
        expect(lines[1], isEmpty);
      });
    });

    group('shareFile', () {
      test('adds file path to sharedFiles list', () async {
        expect(service.sharedFiles, isEmpty);

        await service.shareFile('/path/to/receipt.pdf', mimeType: 'application/pdf');

        expect(service.sharedFiles, hasLength(1));
        expect(service.sharedFiles.first, '/path/to/receipt.pdf');

        // Share another file
        await service.shareFile('/path/to/export.csv');

        expect(service.sharedFiles, hasLength(2));
        expect(service.sharedFiles[1], '/path/to/export.csv');
      });
    });
  });
}
