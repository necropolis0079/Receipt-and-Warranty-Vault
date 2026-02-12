import '../../../../core/database/daos/receipts_dao.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/exceptions/repository_exception.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../models/receipt_mapper.dart';

/// Local-only [ReceiptRepository] backed by Drift + SQLCipher.
class LocalReceiptRepository implements ReceiptRepository {
  LocalReceiptRepository({
    required ReceiptsDao receiptsDao,
  }) : _receiptsDao = receiptsDao;

  final ReceiptsDao _receiptsDao;

  @override
  Stream<List<Receipt>> watchUserReceipts(String userId) {
    try {
      return _receiptsDao
          .watchUserReceipts(userId)
          .map((entries) => entries.map(ReceiptMapper.toReceipt).toList());
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to load receipts.',
        type: RepositoryErrorType.database,
        cause: e,
      );
    }
  }

  @override
  Future<Receipt?> getById(String receiptId) async {
    try {
      final entry = await _receiptsDao.getById(receiptId);
      return entry == null ? null : ReceiptMapper.toReceipt(entry);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to load receipt.',
        type: RepositoryErrorType.database,
        cause: e,
      );
    }
  }

  @override
  Future<void> saveReceipt(Receipt receipt) async {
    try {
      final companion = ReceiptMapper.toCompanion(receipt);
      await _receiptsDao.insertReceipt(companion);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to save receipt.',
        type: RepositoryErrorType.database,
        cause: e,
      );
    }
  }

  @override
  Future<void> updateReceipt(Receipt receipt) async {
    try {
      final companion = ReceiptMapper.toCompanion(receipt);
      await _receiptsDao.updateReceipt(companion);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to update receipt.',
        type: RepositoryErrorType.database,
        cause: e,
      );
    }
  }

  @override
  Future<void> softDelete(String receiptId) async {
    try {
      await _receiptsDao.softDelete(receiptId);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to delete receipt.',
        type: RepositoryErrorType.database,
        cause: e,
      );
    }
  }

  @override
  Future<void> hardDelete(String receiptId) async {
    try {
      await _receiptsDao.hardDelete(receiptId);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to permanently delete receipt.',
        type: RepositoryErrorType.database,
        cause: e,
      );
    }
  }

  @override
  Stream<List<Receipt>> watchByStatus(String userId, ReceiptStatus status) {
    try {
      return _receiptsDao
          .watchByStatus(userId, status.name)
          .map((entries) => entries.map(ReceiptMapper.toReceipt).toList());
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to load receipts by status.',
        type: RepositoryErrorType.database,
        cause: e,
      );
    }
  }

  @override
  Future<List<Receipt>> getExpiringWarranties(
    String userId,
    int daysAhead,
  ) async {
    try {
      final entries =
          await _receiptsDao.getExpiringWarranties(userId, daysAhead);
      return entries.map(ReceiptMapper.toReceipt).toList();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to load expiring warranties.',
        type: RepositoryErrorType.database,
        cause: e,
      );
    }
  }

  @override
  Future<List<Receipt>> getExpiredWarranties(String userId) async {
    try {
      final entries = await _receiptsDao.getExpiredWarranties(userId);
      return entries.map(ReceiptMapper.toReceipt).toList();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to load expired warranties.',
        type: RepositoryErrorType.database,
        cause: e,
      );
    }
  }

  @override
  Future<List<Receipt>> search(String userId, String query) async {
    try {
      final entries = await _receiptsDao.search(userId, query);
      return entries.map(ReceiptMapper.toReceipt).toList();
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to search receipts.',
        type: RepositoryErrorType.database,
        cause: e,
      );
    }
  }

  @override
  Future<int> countActive(String userId) {
    try {
      return _receiptsDao.countActive(userId);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to count receipts.',
        type: RepositoryErrorType.database,
        cause: e,
      );
    }
  }

  @override
  Future<void> restoreReceipt(String receiptId) async {
    try {
      await _receiptsDao.restoreReceipt(receiptId);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to restore receipt.',
        type: RepositoryErrorType.database,
        cause: e,
      );
    }
  }

  @override
  Future<int> purgeOldDeleted(int days) {
    try {
      return _receiptsDao.purgeOldDeleted(days);
    } catch (e) {
      throw RepositoryException(
        message: 'Failed to purge old receipts.',
        type: RepositoryErrorType.database,
        cause: e,
      );
    }
  }
}
