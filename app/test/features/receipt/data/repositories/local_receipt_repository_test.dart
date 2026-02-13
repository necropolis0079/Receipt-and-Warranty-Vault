import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/core/database/app_database.dart';
import 'package:warrantyvault/core/database/daos/receipts_dao.dart';
import 'package:warrantyvault/features/receipt/data/repositories/local_receipt_repository.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/domain/exceptions/repository_exception.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockReceiptsDao extends Mock implements ReceiptsDao {}

// We cannot easily construct a real ReceiptEntry (Drift-generated data class)
// without a database, so we use Fake for fallback values and a helper to
// create genuine-looking ReceiptEntry instances via the .fromData constructor
// that Drift generates.  However, since ReceiptEntry is a simple data class
// with named fields, we can instantiate it directly.

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [ReceiptEntry] matching the Drift-generated data class fields.
///
/// Drift generates ReceiptEntry with a constructor that has positional /
/// named parameters matching every column.  We rely on the fact that
/// ReceiptEntry is a data class with fields identical to the Receipts table.
ReceiptEntry _makeEntry({
  String receiptId = 'r-dao-001',
  String userId = 'user-1',
  String? storeName = 'DAO Store',
  String? extractedMerchantName,
  String? purchaseDate = '2026-01-15',
  String? extractedDate,
  double? totalAmount = 42.50,
  double? extractedTotal,
  String currency = 'EUR',
  String? category = 'Electronics',
  int warrantyMonths = 12,
  String? warrantyExpiryDate = '2027-01-15',
  String status = 'active',
  String? imageKeys,
  String? thumbnailKeys,
  String? ocrRawText,
  int llmConfidence = 80,
  String? userNotes,
  String? userTags,
  bool isFavorite = false,
  String? userEditedFields,
  String createdAt = '2026-01-15T10:00:00.000Z',
  String updatedAt = '2026-01-15T12:00:00.000Z',
  int version = 1,
  String? deletedAt,
  String syncStatus = 'pending',
  String? lastSyncedAt,
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
    createdAt: createdAt,
    updatedAt: updatedAt,
    version: version,
    deletedAt: deletedAt,
    syncStatus: syncStatus,
    lastSyncedAt: lastSyncedAt,
    localImagePaths: localImagePaths,
  );
}

/// Creates a domain [Receipt] for use in tests where we need to pass a
/// Receipt to the repository (e.g., saveReceipt, updateReceipt).
Receipt _makeReceipt({
  String receiptId = 'r-dao-001',
  String userId = 'user-1',
  String? storeName = 'DAO Store',
  int warrantyMonths = 12,
  String createdAt = '2026-01-15T10:00:00.000Z',
  String updatedAt = '2026-01-15T12:00:00.000Z',
}) {
  return Receipt(
    receiptId: receiptId,
    userId: userId,
    storeName: storeName,
    warrantyMonths: warrantyMonths,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

void main() {
  late MockReceiptsDao mockDao;
  late LocalReceiptRepository repository;

  setUpAll(() {
    // Register fallback values for mocktail matchers.
    registerFallbackValue(ReceiptsCompanion());
  });

  setUp(() {
    mockDao = MockReceiptsDao();
    repository = LocalReceiptRepository(receiptsDao: mockDao);
  });

  // =========================================================================
  // saveReceipt
  // =========================================================================
  group('saveReceipt', () {
    test('calls dao.insertReceipt with mapped companion', () async {
      when(() => mockDao.insertReceipt(any())).thenAnswer((_) async {});

      final receipt = _makeReceipt();
      await repository.saveReceipt(receipt);

      verify(() => mockDao.insertReceipt(any())).called(1);
    });

    test('throws RepositoryException when dao throws', () async {
      when(() => mockDao.insertReceipt(any()))
          .thenThrow(Exception('DB insert failed'));

      expect(
        () => repository.saveReceipt(_makeReceipt()),
        throwsA(isA<RepositoryException>().having(
          (e) => e.type,
          'type',
          RepositoryErrorType.database,
        )),
      );
    });
  });

  // =========================================================================
  // getById
  // =========================================================================
  group('getById', () {
    test('returns mapped Receipt when dao finds entry', () async {
      final entry = _makeEntry(receiptId: 'r-found');
      when(() => mockDao.getById('r-found')).thenAnswer((_) async => entry);

      final result = await repository.getById('r-found');

      expect(result, isNotNull);
      expect(result!.receiptId, 'r-found');
      expect(result.storeName, 'DAO Store');
      verify(() => mockDao.getById('r-found')).called(1);
    });

    test('returns null when dao returns null', () async {
      when(() => mockDao.getById('r-missing')).thenAnswer((_) async => null);

      final result = await repository.getById('r-missing');

      expect(result, isNull);
      verify(() => mockDao.getById('r-missing')).called(1);
    });

    test('throws RepositoryException when dao throws', () async {
      when(() => mockDao.getById(any())).thenThrow(Exception('DB read error'));

      expect(
        () => repository.getById('r-error'),
        throwsA(isA<RepositoryException>().having(
          (e) => e.type,
          'type',
          RepositoryErrorType.database,
        )),
      );
    });
  });

  // =========================================================================
  // updateReceipt
  // =========================================================================
  group('updateReceipt', () {
    test('calls dao.updateReceipt with mapped companion', () async {
      when(() => mockDao.updateReceipt(any())).thenAnswer((_) async => true);

      await repository.updateReceipt(_makeReceipt());

      verify(() => mockDao.updateReceipt(any())).called(1);
    });

    test('throws RepositoryException when dao throws', () async {
      when(() => mockDao.updateReceipt(any()))
          .thenThrow(Exception('DB update failed'));

      expect(
        () => repository.updateReceipt(_makeReceipt()),
        throwsA(isA<RepositoryException>().having(
          (e) => e.type,
          'type',
          RepositoryErrorType.database,
        )),
      );
    });
  });

  // =========================================================================
  // softDelete
  // =========================================================================
  group('softDelete', () {
    test('calls dao.softDelete with receipt ID', () async {
      when(() => mockDao.softDelete(any())).thenAnswer((_) async {});

      await repository.softDelete('r-delete-me');

      verify(() => mockDao.softDelete('r-delete-me')).called(1);
    });

    test('throws RepositoryException when dao throws', () async {
      when(() => mockDao.softDelete(any()))
          .thenThrow(Exception('DB soft delete failed'));

      expect(
        () => repository.softDelete('r-delete-me'),
        throwsA(isA<RepositoryException>().having(
          (e) => e.type,
          'type',
          RepositoryErrorType.database,
        )),
      );
    });
  });

  // =========================================================================
  // hardDelete
  // =========================================================================
  group('hardDelete', () {
    test('calls dao.hardDelete with receipt ID', () async {
      when(() => mockDao.hardDelete(any())).thenAnswer((_) async {});

      await repository.hardDelete('r-hard-delete');

      verify(() => mockDao.hardDelete('r-hard-delete')).called(1);
    });

    test('throws RepositoryException when dao throws', () async {
      when(() => mockDao.hardDelete(any()))
          .thenThrow(Exception('DB hard delete failed'));

      expect(
        () => repository.hardDelete('r-hard-delete'),
        throwsA(isA<RepositoryException>().having(
          (e) => e.type,
          'type',
          RepositoryErrorType.database,
        )),
      );
    });
  });

  // =========================================================================
  // search
  // =========================================================================
  group('search', () {
    test('calls dao.search and returns mapped receipts', () async {
      final entries = [
        _makeEntry(receiptId: 'r-s1', storeName: 'Apple Store'),
        _makeEntry(receiptId: 'r-s2', storeName: 'App World'),
      ];
      when(() => mockDao.search('user-1', 'App'))
          .thenAnswer((_) async => entries);

      final results = await repository.search('user-1', 'App');

      expect(results, hasLength(2));
      expect(results[0].receiptId, 'r-s1');
      expect(results[1].receiptId, 'r-s2');
      verify(() => mockDao.search('user-1', 'App')).called(1);
    });

    test('returns empty list when dao returns empty', () async {
      when(() => mockDao.search(any(), any()))
          .thenAnswer((_) async => <ReceiptEntry>[]);

      final results = await repository.search('user-1', 'nothing');

      expect(results, isEmpty);
    });

    test('throws RepositoryException when dao throws', () async {
      when(() => mockDao.search(any(), any()))
          .thenThrow(Exception('FTS error'));

      expect(
        () => repository.search('user-1', 'query'),
        throwsA(isA<RepositoryException>().having(
          (e) => e.type,
          'type',
          RepositoryErrorType.database,
        )),
      );
    });
  });

  // =========================================================================
  // countActive
  // =========================================================================
  group('countActive', () {
    test('returns count from dao', () async {
      when(() => mockDao.countActive('user-1')).thenAnswer((_) async => 42);

      final count = await repository.countActive('user-1');

      expect(count, 42);
      verify(() => mockDao.countActive('user-1')).called(1);
    });

    test('returns 0 when no active receipts', () async {
      when(() => mockDao.countActive(any())).thenAnswer((_) async => 0);

      final count = await repository.countActive('user-empty');

      expect(count, 0);
    });

    test('throws RepositoryException when dao throws', () async {
      when(() => mockDao.countActive(any()))
          .thenThrow(Exception('Count failed'));

      expect(
        () => repository.countActive('user-1'),
        throwsA(isA<RepositoryException>().having(
          (e) => e.type,
          'type',
          RepositoryErrorType.database,
        )),
      );
    });
  });

  // =========================================================================
  // getExpiringWarranties
  // =========================================================================
  group('getExpiringWarranties', () {
    test('delegates to dao and returns mapped receipts', () async {
      final entries = [
        _makeEntry(
          receiptId: 'r-exp1',
          warrantyExpiryDate: '2026-02-20',
        ),
      ];
      when(() => mockDao.getExpiringWarranties('user-1', 30))
          .thenAnswer((_) async => entries);

      final results = await repository.getExpiringWarranties('user-1', 30);

      expect(results, hasLength(1));
      expect(results[0].receiptId, 'r-exp1');
      verify(() => mockDao.getExpiringWarranties('user-1', 30)).called(1);
    });

    test('returns empty when no expiring warranties', () async {
      when(() => mockDao.getExpiringWarranties(any(), any()))
          .thenAnswer((_) async => <ReceiptEntry>[]);

      final results = await repository.getExpiringWarranties('user-1', 7);

      expect(results, isEmpty);
    });

    test('throws RepositoryException when dao throws', () async {
      when(() => mockDao.getExpiringWarranties(any(), any()))
          .thenThrow(Exception('Expiring query failed'));

      expect(
        () => repository.getExpiringWarranties('user-1', 30),
        throwsA(isA<RepositoryException>().having(
          (e) => e.type,
          'type',
          RepositoryErrorType.database,
        )),
      );
    });
  });

  // =========================================================================
  // getExpiredWarranties
  // =========================================================================
  group('getExpiredWarranties', () {
    test('delegates to dao and returns mapped receipts', () async {
      final entries = [
        _makeEntry(
          receiptId: 'r-past1',
          warrantyExpiryDate: '2024-06-01',
        ),
        _makeEntry(
          receiptId: 'r-past2',
          warrantyExpiryDate: '2025-01-01',
        ),
      ];
      when(() => mockDao.getExpiredWarranties('user-1'))
          .thenAnswer((_) async => entries);

      final results = await repository.getExpiredWarranties('user-1');

      expect(results, hasLength(2));
      expect(results[0].receiptId, 'r-past1');
      expect(results[1].receiptId, 'r-past2');
      verify(() => mockDao.getExpiredWarranties('user-1')).called(1);
    });

    test('returns empty when no expired warranties', () async {
      when(() => mockDao.getExpiredWarranties(any()))
          .thenAnswer((_) async => <ReceiptEntry>[]);

      final results = await repository.getExpiredWarranties('user-1');

      expect(results, isEmpty);
    });

    test('throws RepositoryException when dao throws', () async {
      when(() => mockDao.getExpiredWarranties(any()))
          .thenThrow(Exception('Expired query failed'));

      expect(
        () => repository.getExpiredWarranties('user-1'),
        throwsA(isA<RepositoryException>().having(
          (e) => e.type,
          'type',
          RepositoryErrorType.database,
        )),
      );
    });
  });

  // =========================================================================
  // restoreReceipt
  // =========================================================================
  group('restoreReceipt', () {
    test('calls dao.restoreReceipt with receipt ID', () async {
      when(() => mockDao.restoreReceipt(any())).thenAnswer((_) async {});

      await repository.restoreReceipt('r-restore-me');

      verify(() => mockDao.restoreReceipt('r-restore-me')).called(1);
    });

    test('throws RepositoryException when dao throws', () async {
      when(() => mockDao.restoreReceipt(any()))
          .thenThrow(Exception('Restore failed'));

      expect(
        () => repository.restoreReceipt('r-restore-me'),
        throwsA(isA<RepositoryException>().having(
          (e) => e.type,
          'type',
          RepositoryErrorType.database,
        )),
      );
    });
  });

  // =========================================================================
  // purgeOldDeleted
  // =========================================================================
  group('purgeOldDeleted', () {
    test('delegates to dao and returns purged count', () async {
      when(() => mockDao.purgeOldDeleted(30)).thenAnswer((_) async => 5);

      final purged = await repository.purgeOldDeleted(30);

      expect(purged, 5);
      verify(() => mockDao.purgeOldDeleted(30)).called(1);
    });

    test('returns 0 when nothing to purge', () async {
      when(() => mockDao.purgeOldDeleted(any())).thenAnswer((_) async => 0);

      final purged = await repository.purgeOldDeleted(30);

      expect(purged, 0);
    });

    test('throws RepositoryException when dao throws', () async {
      when(() => mockDao.purgeOldDeleted(any()))
          .thenThrow(Exception('Purge failed'));

      expect(
        () => repository.purgeOldDeleted(30),
        throwsA(isA<RepositoryException>().having(
          (e) => e.type,
          'type',
          RepositoryErrorType.database,
        )),
      );
    });
  });

  // =========================================================================
  // watchUserReceipts (stream)
  // =========================================================================
  group('watchUserReceipts', () {
    test('returns mapped receipt stream from dao', () {
      final entries = [
        _makeEntry(receiptId: 'r-w1'),
        _makeEntry(receiptId: 'r-w2'),
      ];
      when(() => mockDao.watchUserReceipts('user-1'))
          .thenAnswer((_) => Stream.value(entries));

      final stream = repository.watchUserReceipts('user-1');

      expect(
        stream,
        emits(allOf(
          hasLength(2),
          isA<List<Receipt>>(),
        )),
      );
      verify(() => mockDao.watchUserReceipts('user-1')).called(1);
    });
  });

  // =========================================================================
  // watchByStatus (stream)
  // =========================================================================
  group('watchByStatus', () {
    test('passes status name string to dao', () {
      final entries = [_makeEntry(status: 'returned')];
      when(() => mockDao.watchByStatus('user-1', 'returned'))
          .thenAnswer((_) => Stream.value(entries));

      final stream =
          repository.watchByStatus('user-1', ReceiptStatus.returned);

      expect(stream, emits(hasLength(1)));
      verify(() => mockDao.watchByStatus('user-1', 'returned')).called(1);
    });
  });

  // =========================================================================
  // Error handling — RepositoryException details
  // =========================================================================
  group('RepositoryException details', () {
    test('exception wraps original cause', () async {
      final originalError = Exception('original DB error');
      when(() => mockDao.getById(any())).thenThrow(originalError);

      try {
        await repository.getById('any-id');
        fail('Expected RepositoryException');
      } on RepositoryException catch (e) {
        expect(e.type, RepositoryErrorType.database);
        expect(e.cause, originalError);
        expect(e.message, contains('Failed to load receipt'));
        expect(e.toString(), contains('RepositoryException'));
      }
    });

    test('saveReceipt exception has descriptive message', () async {
      when(() => mockDao.insertReceipt(any()))
          .thenThrow(Exception('constraint violation'));

      try {
        await repository.saveReceipt(_makeReceipt());
        fail('Expected RepositoryException');
      } on RepositoryException catch (e) {
        expect(e.message, 'Failed to save receipt.');
        expect(e.type, RepositoryErrorType.database);
      }
    });

    test('updateReceipt exception has descriptive message', () async {
      when(() => mockDao.updateReceipt(any()))
          .thenThrow(Exception('update error'));

      try {
        await repository.updateReceipt(_makeReceipt());
        fail('Expected RepositoryException');
      } on RepositoryException catch (e) {
        expect(e.message, 'Failed to update receipt.');
      }
    });

    test('softDelete exception has descriptive message', () async {
      when(() => mockDao.softDelete(any()))
          .thenThrow(Exception('delete error'));

      try {
        await repository.softDelete('r-1');
        fail('Expected RepositoryException');
      } on RepositoryException catch (e) {
        expect(e.message, 'Failed to delete receipt.');
      }
    });

    test('hardDelete exception has descriptive message', () async {
      when(() => mockDao.hardDelete(any()))
          .thenThrow(Exception('hard delete error'));

      try {
        await repository.hardDelete('r-1');
        fail('Expected RepositoryException');
      } on RepositoryException catch (e) {
        expect(e.message, 'Failed to permanently delete receipt.');
      }
    });

    test('search exception has descriptive message', () async {
      when(() => mockDao.search(any(), any()))
          .thenThrow(Exception('search error'));

      try {
        await repository.search('user-1', 'query');
        fail('Expected RepositoryException');
      } on RepositoryException catch (e) {
        expect(e.message, 'Failed to search receipts.');
      }
    });

    test('restoreReceipt exception has descriptive message', () async {
      when(() => mockDao.restoreReceipt(any()))
          .thenThrow(Exception('restore error'));

      try {
        await repository.restoreReceipt('r-1');
        fail('Expected RepositoryException');
      } on RepositoryException catch (e) {
        expect(e.message, 'Failed to restore receipt.');
      }
    });

    test('purgeOldDeleted exception has descriptive message', () async {
      when(() => mockDao.purgeOldDeleted(any()))
          .thenThrow(Exception('purge error'));

      try {
        await repository.purgeOldDeleted(30);
        fail('Expected RepositoryException');
      } on RepositoryException catch (e) {
        expect(e.message, 'Failed to purge old receipts.');
      }
    });
  });
}
