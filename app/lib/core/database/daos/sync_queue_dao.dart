import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

/// Data access object for the [SyncQueue] table.
///
/// Manages the offline-first sync queue. Operations are added when the user
/// modifies a receipt while offline (or when an immediate sync fails).
/// The background sync service processes entries by priority then age.
@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  /// Maximum retries before an operation is considered failed.
  static const int maxRetries = 10;

  /// Add an operation to the sync queue.
  Future<int> enqueue({
    required String receiptId,
    required String operation,
    String? payload,
    int priority = 0,
  }) {
    return into(syncQueue).insert(SyncQueueCompanion.insert(
      receiptId: receiptId,
      operation: operation,
      payload: Value(payload),
      createdAt: DateTime.now().toIso8601String(),
      priority: Value(priority),
    ));
  }

  /// Get the next unprocessed operation (highest priority, then oldest).
  Future<SyncQueueEntry?> getNext() {
    return (select(syncQueue)
          ..where((q) => q.retryCount.isSmallerThanValue(maxRetries))
          ..orderBy([
            (q) => OrderingTerm.desc(q.priority),
            (q) => OrderingTerm.asc(q.createdAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get a batch of pending operations (up to [limit]).
  Future<List<SyncQueueEntry>> getPendingBatch({int limit = 20}) {
    return (select(syncQueue)
          ..where((q) => q.retryCount.isSmallerThanValue(maxRetries))
          ..orderBy([
            (q) => OrderingTerm.desc(q.priority),
            (q) => OrderingTerm.asc(q.createdAt),
          ])
          ..limit(limit))
        .get();
  }

  /// Remove an operation after successful sync.
  Future<void> markCompleted(int id) {
    return (delete(syncQueue)..where((q) => q.id.equals(id))).go();
  }

  /// Increment retry count and record the error message.
  Future<void> markFailed(int id, String error) {
    return customStatement(
      'UPDATE sync_queue SET retry_count = retry_count + 1, '
      'last_error = ? WHERE id = ?',
      [error, id],
    );
  }

  /// Get all operations for a specific receipt.
  Future<List<SyncQueueEntry>> getForReceipt(String receiptId) {
    return (select(syncQueue)
          ..where((q) => q.receiptId.equals(receiptId))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  /// Get all failed operations (retryCount >= maxRetries).
  Future<List<SyncQueueEntry>> getFailed() {
    return (select(syncQueue)
          ..where(
              (q) => q.retryCount.isBiggerOrEqualValue(maxRetries)))
        .get();
  }

  /// Watch the total count of pending operations.
  Stream<int> watchPendingCount() {
    final count = syncQueue.id.count();
    return (selectOnly(syncQueue)
          ..addColumns([count])
          ..where(syncQueue.retryCount.isSmallerThanValue(maxRetries)))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  /// Remove all completed and pending operations.
  Future<void> clearAll() {
    return delete(syncQueue).go();
  }

  /// Remove all operations for a specific receipt.
  Future<void> clearForReceipt(String receiptId) {
    return (delete(syncQueue)
          ..where((q) => q.receiptId.equals(receiptId)))
        .go();
  }
}
