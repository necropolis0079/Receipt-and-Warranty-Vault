import '../../../../core/database/daos/receipts_dao.dart';
import '../../domain/entities/receipt.dart';
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
  }

  @override
  Future<void> updateReceipt(Receipt receipt) async {
    final companion = ReceiptMapper.toCompanion(receipt);
    await _receiptsDao.updateReceipt(companion);
  }

  @override
  Future<void> softDelete(String receiptId) async {
    await _receiptsDao.softDelete(receiptId);
  }

  @override
  Future<void> hardDelete(String receiptId) async {
    await _receiptsDao.hardDelete(receiptId);
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

  @override
  Future<void> restoreReceipt(String receiptId) async {
    await _receiptsDao.restoreReceipt(receiptId);
  }

  @override
  Future<int> purgeOldDeleted(int days) {
    return _receiptsDao.purgeOldDeleted(days);
  }
}
