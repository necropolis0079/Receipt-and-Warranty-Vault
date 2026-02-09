import '../entities/receipt.dart';

/// Abstract repository for receipt persistence and queries.
abstract class ReceiptRepository {
  /// Watch all active receipts for a user, newest first.
  Stream<List<Receipt>> watchUserReceipts(String userId);

  /// Get a single receipt by ID.
  Future<Receipt?> getById(String receiptId);

  /// Save a new receipt. Auto-enqueues to sync queue.
  Future<void> saveReceipt(Receipt receipt);

  /// Update an existing receipt. Auto-enqueues to sync queue.
  Future<void> updateReceipt(Receipt receipt);

  /// Soft-delete a receipt. Auto-enqueues to sync queue.
  Future<void> softDelete(String receiptId);

  /// Permanently remove a receipt.
  Future<void> hardDelete(String receiptId);

  /// Watch receipts filtered by status.
  Stream<List<Receipt>> watchByStatus(String userId, ReceiptStatus status);

  /// Get receipts with warranties expiring within [daysAhead] days.
  Future<List<Receipt>> getExpiringWarranties(String userId, int daysAhead);

  /// Get receipts with already-expired warranties.
  Future<List<Receipt>> getExpiredWarranties(String userId);

  /// Full-text search.
  Future<List<Receipt>> search(String userId, String query);

  /// Count active receipts for a user.
  Future<int> countActive(String userId);

  /// Restore a soft-deleted receipt to active status.
  Future<void> restoreReceipt(String receiptId);

  /// Hard-delete receipts that have been in trash for more than [days] days.
  Future<int> purgeOldDeleted(int days);
}
