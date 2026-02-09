import 'package:drift/drift.dart';

/// Drift table definition for the offline sync queue.
///
/// Holds operations that need to be sent to the server. Items are added when
/// the user creates, updates, or deletes a receipt while offline (or when the
/// immediate sync attempt fails). The background sync service (WorkManager)
/// processes this queue when connectivity is available.
///
/// Operations are processed in order of [priority] (descending), then
/// [createdAt] (ascending). After 10 failed retries, operations are marked as
/// failed and the corresponding receipt's sync_status is set to 'conflict'.
@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  /// Auto-incrementing local primary key.
  IntColumn get id => integer().autoIncrement()();

  /// The receipt this operation applies to.
  TextColumn get receiptId => text()();

  /// Operation type: create, update, delete, upload_image, or refine_ocr.
  TextColumn get operation => text()();

  /// JSON-encoded operation payload.
  /// - For create/update: full receipt data.
  /// - For upload_image: local file path.
  /// - For delete: null (receipt_id is sufficient).
  TextColumn get payload => text().nullable()();

  /// ISO 8601 datetime when the operation was queued.
  TextColumn get createdAt => text()();

  /// Number of failed sync attempts. Abandoned after 10 retries.
  IntColumn get retryCount =>
      integer().withDefault(const Constant(0))();

  /// Error message from the most recent failed attempt.
  TextColumn get lastError => text().nullable()();

  /// Processing priority. Higher values are processed first.
  /// Image uploads have lower priority than data sync.
  IntColumn get priority =>
      integer().withDefault(const Constant(0))();

  @override
  String get tableName => 'sync_queue';
}

/// Index definitions for the sync_queue table.
///
/// Applied via [customStatement] in the database migration.
const List<String> syncQueueIndexStatements = [
  'CREATE INDEX IF NOT EXISTS idx_sync_queue_receipt_id ON sync_queue(receipt_id)',
  'CREATE INDEX IF NOT EXISTS idx_sync_queue_created_at ON sync_queue(created_at)',
  'CREATE INDEX IF NOT EXISTS idx_sync_queue_retry_count ON sync_queue(retry_count)',
];
