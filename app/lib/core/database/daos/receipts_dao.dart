import 'dart:convert';

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
      syncStatus: const Value('pending'),
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

  /// Get all receipts pending sync, oldest first.
  Future<List<ReceiptEntry>> getPendingSync(String userId) {
    return (select(receipts)
          ..where(
              (r) => r.userId.equals(userId) & r.syncStatus.equals('pending'))
          ..orderBy([(r) => OrderingTerm.asc(r.updatedAt)]))
        .get();
  }

  /// Mark a receipt as successfully synced, optionally updating version.
  Future<void> markSynced(String receiptId, [int? serverVersion]) {
    final companion = ReceiptsCompanion(
      syncStatus: const Value('synced'),
      lastSyncedAt: Value(DateTime.now().toIso8601String()),
      version: serverVersion != null ? Value(serverVersion) : const Value.absent(),
    );
    return (update(receipts)
          ..where((r) => r.receiptId.equals(receiptId)))
        .write(companion);
  }

  /// Mark a receipt as having a sync conflict.
  Future<void> markConflict(String receiptId) {
    return (update(receipts)
          ..where((r) => r.receiptId.equals(receiptId)))
        .write(const ReceiptsCompanion(
      syncStatus: Value('conflict'),
    ));
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
      syncStatus: const Value('pending'),
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

  /// Upsert a receipt from sync data (server-sourced Map).
  ///
  /// Inserts if the receipt doesn't exist locally, updates if it does.
  /// Marks as synced automatically.
  Future<void> upsertFromSync(Map<String, dynamic> data) async {
    final receiptId = data['receiptId'] as String;
    final now = DateTime.now().toIso8601String();

    final companion = ReceiptsCompanion(
      receiptId: Value(receiptId),
      userId: Value(data['userId'] as String? ?? ''),
      storeName: Value(data['storeName'] as String?),
      extractedMerchantName: Value(data['extractedMerchantName'] as String?),
      purchaseDate: Value(data['purchaseDate'] as String?),
      extractedDate: Value(data['extractedDate'] as String?),
      totalAmount: Value(data['totalAmount'] != null
          ? (data['totalAmount'] as num).toDouble()
          : null),
      extractedTotal: Value(data['extractedTotal'] != null
          ? (data['extractedTotal'] as num).toDouble()
          : null),
      currency: Value(data['currency'] as String? ?? 'EUR'),
      category: Value(data['category'] as String?),
      warrantyMonths: Value(data['warrantyMonths'] as int? ?? 0),
      warrantyExpiryDate: Value(data['warrantyExpiryDate'] as String?),
      status: Value(data['status'] as String? ?? 'active'),
      imageKeys: Value(_encodeList(data['imageKeys'])),
      thumbnailKeys: Value(_encodeList(data['thumbnailKeys'])),
      ocrRawText: Value(data['ocrRawText'] as String?),
      llmConfidence: Value(data['llmConfidence'] as int? ?? 0),
      userNotes: Value(data['userNotes'] as String?),
      userTags: Value(_encodeList(data['userTags'])),
      isFavorite: Value(data['isFavorite'] as bool? ?? false),
      userEditedFields: Value(_encodeList(data['userEditedFields'])),
      createdAt: Value(data['createdAt'] as String? ?? now),
      updatedAt: Value(data['updatedAt'] as String? ?? now),
      version: Value(data['version'] as int? ?? 1),
      deletedAt: Value(data['deletedAt'] as String?),
      syncStatus: const Value('synced'),
      lastSyncedAt: Value(now),
    );

    await into(receipts).insertOnConflictUpdate(companion);
  }

  /// Get all receipts as a lightweight list for building a sync manifest.
  Future<List<ReceiptEntry>> getAllForManifest() {
    return (select(receipts)
          ..orderBy([(r) => OrderingTerm.asc(r.receiptId)]))
        .get();
  }

  /// Encode a dynamic list (from JSON) into a JSON string for storage.
  static String? _encodeList(dynamic list) {
    if (list == null) return null;
    if (list is List) {
      if (list.isEmpty) return null;
      return jsonEncode(list.map((e) => e.toString()).toList());
    }
    if (list is String) return list;
    return null;
  }

  /// ISO 8601 date-only helper (YYYY-MM-DD).
  static String _dateOnly(DateTime dt) => dt.toIso8601String().substring(0, 10);
}
