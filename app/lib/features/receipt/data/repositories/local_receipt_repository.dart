import '../../../../core/database/daos/receipts_dao.dart';
import '../../../../core/database/daos/sync_queue_dao.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../models/receipt_mapper.dart';

/// Local-only [ReceiptRepository] backed by Drift + SQLCipher.
///
/// Every save/update/delete auto-enqueues to [SyncQueueDao] for later sync.
class LocalReceiptRepository implements ReceiptRepository {
  LocalReceiptRepository({
    required ReceiptsDao receiptsDao,
    required SyncQueueDao syncQueueDao,
  })  : _receiptsDao = receiptsDao,
        _syncQueueDao = syncQueueDao;

  final ReceiptsDao _receiptsDao;
  final SyncQueueDao _syncQueueDao;

  @override
  Stream<List<Receipt>> watchUserReceipts(String userId) {
    return _receiptsDao
        .watchUserReceipts(userId)
        .map((entries) => entries.map(ReceiptMapper.toReceipt).toList());
  }

  @override
  Future<Receipt?> getById(String receiptId) async {
    final entry = await _receiptsDao.getById(receiptId);
    return entry == null ? null : ReceiptMapper.toReceipt(entry);
  }

  @override
  Future<void> saveReceipt(Receipt receipt) async {
    final companion = ReceiptMapper.toCompanion(receipt);
    await _receiptsDao.insertReceipt(companion);
    await _syncQueueDao.enqueue(
      receiptId: receipt.receiptId,
      operation: 'create',
    );
  }

  @override
  Future<void> updateReceipt(Receipt receipt) async {
    final companion = ReceiptMapper.toCompanion(receipt);
    await _receiptsDao.updateReceipt(companion);
    await _syncQueueDao.enqueue(
      receiptId: receipt.receiptId,
      operation: 'update',
    );
  }

  @override
  Future<void> softDelete(String receiptId) async {
    await _receiptsDao.softDelete(receiptId);
    await _syncQueueDao.enqueue(
      receiptId: receiptId,
      operation: 'delete',
    );
  }

  @override
  Future<void> hardDelete(String receiptId) async {
    await _receiptsDao.hardDelete(receiptId);
    await _syncQueueDao.clearForReceipt(receiptId);
  }

  @override
  Stream<List<Receipt>> watchByStatus(String userId, ReceiptStatus status) {
    return _receiptsDao
        .watchByStatus(userId, status.name)
        .map((entries) => entries.map(ReceiptMapper.toReceipt).toList());
  }

  @override
  Future<List<Receipt>> getExpiringWarranties(
    String userId,
    int daysAhead,
  ) async {
    final entries =
        await _receiptsDao.getExpiringWarranties(userId, daysAhead);
    return entries.map(ReceiptMapper.toReceipt).toList();
  }

  @override
  Future<List<Receipt>> getExpiredWarranties(String userId) async {
    final entries = await _receiptsDao.getExpiredWarranties(userId);
    return entries.map(ReceiptMapper.toReceipt).toList();
  }

  @override
  Future<List<Receipt>> search(String userId, String query) async {
    final entries = await _receiptsDao.search(userId, query);
    return entries.map(ReceiptMapper.toReceipt).toList();
  }

  @override
  Future<int> countActive(String userId) {
    return _receiptsDao.countActive(userId);
  }
}
