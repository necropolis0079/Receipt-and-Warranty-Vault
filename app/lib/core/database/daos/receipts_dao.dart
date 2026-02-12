import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/receipts_table.dart';

part 'receipts_dao.g.dart';

/// Data access object for the [Receipts] table.
///
/// Provides CRUD operations, warranty expiry queries, FTS5 full-text search,
/// and sync-status management.
@DriftAccessor(tables: [Receipts])
class ReceiptsDao extends DatabaseAccessor<AppDatabase>
    with _$ReceiptsDaoMixin {
  ReceiptsDao(super.db);

  /// Watch all active receipts for a user, newest first.
  Stream<List<ReceiptEntry>> watchUserReceipts(String userId) {
    return (select(receipts)
          ..where(
              (r) => r.userId.equals(userId) & r.status.equals('active'))
          ..orderBy([(r) => OrderingTerm.desc(r.purchaseDate)]))
        .watch();
  }

  /// Get a single receipt by ID, or null if not found.
  Future<ReceiptEntry?> getById(String receiptId) {
    return (select(receipts)
          ..where((r) => r.receiptId.equals(receiptId)))
        .getSingleOrNull();
  }

  /// Insert a new receipt.
  Future<void> insertReceipt(ReceiptsCompanion entry) {
    return into(receipts).insert(entry);
  }

  /// Update an existing receipt. Returns true if a row was updated.
  Future<bool> updateReceipt(ReceiptsCompanion entry) async {
    final rows = await (update(receipts)
          ..where((r) => r.receiptId.equals(entry.receiptId.value)))
        .write(entry);
    return rows > 0;
  }

  /// Soft-delete a receipt: sets status to 'deleted' and records timestamp.
  Future<void> softDelete(String receiptId) {
    final now = DateTime.now().toIso8601String();
    return (update(receipts)
          ..where((r) => r.receiptId.equals(receiptId)))
        .write(ReceiptsCompanion(
      status: const Value('deleted'),
      deletedAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  /// Permanently remove a receipt from the local database.
  Future<void> hardDelete(String receiptId) {
    return (delete(receipts)
          ..where((r) => r.receiptId.equals(receiptId)))
        .go();
  }

  /// Watch receipts filtered by status (active, returned, deleted).
  Stream<List<ReceiptEntry>> watchByStatus(String userId, String status) {
    return (select(receipts)
          ..where(
              (r) => r.userId.equals(userId) & r.status.equals(status))
          ..orderBy([(r) => OrderingTerm.desc(r.purchaseDate)]))
        .watch();
  }

  /// Get receipts with warranties expiring within [daysAhead] days.
  Future<List<ReceiptEntry>> getExpiringWarranties(
    String userId,
    int daysAhead,
  ) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: daysAhead));
    final nowStr = _dateOnly(now);
    final cutoffStr = _dateOnly(cutoff);

    return (select(receipts)
          ..where((r) =>
              r.userId.equals(userId) &
              r.status.equals('active') &
              r.warrantyExpiryDate.isNotNull() &
              r.warrantyExpiryDate.isBiggerOrEqualValue(nowStr) &
              r.warrantyExpiryDate.isSmallerOrEqualValue(cutoffStr))
          ..orderBy([(r) => OrderingTerm.asc(r.warrantyExpiryDate)]))
        .get();
  }

  /// Get receipts with already-expired warranties.
  Future<List<ReceiptEntry>> getExpiredWarranties(String userId) {
    final nowStr = _dateOnly(DateTime.now());
    return (select(receipts)
          ..where((r) =>
              r.userId.equals(userId) &
              r.status.equals('active') &
              r.warrantyExpiryDate.isNotNull() &
              r.warrantyExpiryDate.isSmallerThanValue(nowStr))
          ..orderBy([(r) => OrderingTerm.desc(r.warrantyExpiryDate)]))
        .get();
  }

  /// Full-text search via FTS5, with LIKE fallback on query-syntax errors.
  Future<List<ReceiptEntry>> search(String userId, String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      return await customSelect(
        'SELECT r.* FROM receipts r '
        'INNER JOIN receipts_fts ON receipts_fts.rowid = r.rowid '
        'WHERE receipts_fts MATCH ? AND r.user_id = ? AND r.status = ?',
        variables: [
          Variable.withString(trimmed),
          Variable.withString(userId),
          Variable.withString('active'),
        ],
        readsFrom: {receipts},
      ).map((row) => receipts.map(row.data)).get();
    } catch (_) {
      // FTS5 query-syntax error — fall back to LIKE search.
      final like = '%$trimmed%';
      return (select(receipts)
            ..where((r) =>
                r.userId.equals(userId) &
                r.status.equals('active') &
                (r.storeName.like(like) |
                    r.ocrRawText.like(like) |
                    r.userNotes.like(like) |
                    r.userTags.like(like))))
          .get();
    }
  }

  /// Count active receipts for a user.
  Future<int> countActive(String userId) async {
    final count = receipts.receiptId.count();
    final query = selectOnly(receipts)
      ..addColumns([count])
      ..where(
          receipts.userId.equals(userId) & receipts.status.equals('active'));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Restore a soft-deleted receipt to active status.
  Future<void> restoreReceipt(String receiptId) {
    final now = DateTime.now().toIso8601String();
    return (update(receipts)
          ..where((r) => r.receiptId.equals(receiptId)))
        .write(ReceiptsCompanion(
      status: const Value('active'),
      deletedAt: const Value(null),
      updatedAt: Value(now),
    ));
  }

  /// Hard-delete receipts that have been soft-deleted for more than [days] days.
  /// Returns the number of deleted rows.
  Future<int> purgeOldDeleted(int days) {
    final cutoff =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return (delete(receipts)
          ..where((r) =>
              r.status.equals('deleted') &
              r.deletedAt.isNotNull() &
              r.deletedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  /// ISO 8601 date-only helper (YYYY-MM-DD).
  static String _dateOnly(DateTime dt) => dt.toIso8601String().substring(0, 10);
}
