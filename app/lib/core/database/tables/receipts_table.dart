import 'package:drift/drift.dart';

/// Drift table definition for local receipts storage.
///
/// Mirrors the DynamoDB receipt entity with additional local-only fields
/// for sync tracking and local image management. Encrypted at rest via
/// SQLCipher (AES-256).
@DataClassName('ReceiptEntry')
class Receipts extends Table {
  // ── Primary key ──────────────────────────────────────────────────────
  TextColumn get receiptId => text()();

  // ── Ownership ────────────────────────────────────────────────────────
  TextColumn get userId => text()();

  // ── Merchant / store ─────────────────────────────────────────────────
  TextColumn get storeName => text().nullable()();
  TextColumn get extractedMerchantName => text().nullable()();

  // ── Date ─────────────────────────────────────────────────────────────
  /// ISO 8601 date (YYYY-MM-DD).
  TextColumn get purchaseDate => text().nullable()();

  /// Raw LLM extraction of date.
  TextColumn get extractedDate => text().nullable()();

  // ── Amounts ──────────────────────────────────────────────────────────
  RealColumn get totalAmount => real().nullable()();
  RealColumn get extractedTotal => real().nullable()();

  /// ISO 4217 currency code. Defaults to EUR.
  TextColumn get currency => text().withDefault(const Constant('EUR'))();

  // ── Classification ───────────────────────────────────────────────────
  TextColumn get category => text().nullable()();

  // ── Warranty ─────────────────────────────────────────────────────────
  /// Duration in months. 0 means no warranty.
  IntColumn get warrantyMonths =>
      integer().withDefault(const Constant(0))();

  /// Calculated: purchaseDate + warrantyMonths. ISO 8601 date.
  TextColumn get warrantyExpiryDate => text().nullable()();

  // ── Status ───────────────────────────────────────────────────────────
  /// One of: active, returned, deleted.
  TextColumn get status =>
      text().withDefault(const Constant('active'))();

  // ── Images (JSON-encoded lists) ──────────────────────────────────────
  /// JSON list of S3 object keys for originals.
  TextColumn get imageKeys => text().nullable()();

  /// JSON list of S3 object keys for thumbnails.
  TextColumn get thumbnailKeys => text().nullable()();

  // ── OCR / LLM ────────────────────────────────────────────────────────
  /// Raw OCR output from ML Kit + Tesseract.
  TextColumn get ocrRawText => text().nullable()();

  /// LLM confidence score (0-100).
  IntColumn get llmConfidence =>
      integer().withDefault(const Constant(0))();

  // ── User content ─────────────────────────────────────────────────────
  TextColumn get userNotes => text().nullable()();

  /// JSON list of tag strings.
  TextColumn get userTags => text().nullable()();

  /// Boolean stored as 0/1.
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))();

  /// JSON list of field names the user has manually edited.
  TextColumn get userEditedFields => text().nullable()();

  // ── Timestamps ───────────────────────────────────────────────────────
  /// ISO 8601 datetime. Set once at creation, never modified.
  TextColumn get createdAt => text()();

  /// ISO 8601 datetime. Updated on every write.
  TextColumn get updatedAt => text()();

  // ── Versioning ───────────────────────────────────────────────────────
  /// Optimistic concurrency version, starts at 1.
  IntColumn get version =>
      integer().withDefault(const Constant(1))();

  /// ISO 8601 datetime. Set on soft delete.
  TextColumn get deletedAt => text().nullable()();

  // ── Legacy columns (kept for schema compatibility, unused) ──────────
  /// Unused — retained to avoid DB migration.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  /// Unused — retained to avoid DB migration.
  TextColumn get lastSyncedAt => text().nullable()();

  /// JSON list of local file paths for cached/captured images.
  TextColumn get localImagePaths => text().nullable()();

  // ── Table configuration ──────────────────────────────────────────────
  @override
  Set<Column> get primaryKey => {receiptId};

  @override
  List<Set<Column>> get uniqueKeys => [];

  @override
  String get tableName => 'receipts';
}

/// Index definitions for the receipts table.
///
/// These are applied in the database migration via [customStatement].
/// Drift does not support declarative index creation on tables, so we
/// create them manually in the migration callback.
///
/// Indexes:
/// - idx_receipts_user_id          ON receipts(user_id)
/// - idx_receipts_purchase_date    ON receipts(purchase_date)
/// - idx_receipts_category         ON receipts(category)
/// - idx_receipts_status           ON receipts(status)
/// - idx_receipts_warranty_expiry  ON receipts(warranty_expiry_date)
/// - idx_receipts_updated_at       ON receipts(updated_at)
const List<String> receiptsIndexStatements = [
  'CREATE INDEX IF NOT EXISTS idx_receipts_user_id ON receipts(user_id)',
  'CREATE INDEX IF NOT EXISTS idx_receipts_purchase_date ON receipts(purchase_date)',
  'CREATE INDEX IF NOT EXISTS idx_receipts_category ON receipts(category)',
  'CREATE INDEX IF NOT EXISTS idx_receipts_status ON receipts(status)',
  'CREATE INDEX IF NOT EXISTS idx_receipts_warranty_expiry ON receipts(warranty_expiry_date)',
  'CREATE INDEX IF NOT EXISTS idx_receipts_updated_at ON receipts(updated_at)',
];

/// SQL to create the FTS5 virtual table for full-text search.
///
/// Indexes: store_name, ocr_raw_text, user_notes, user_tags.
/// Uses the unicode61 tokenizer for accented character and Greek support.
/// The `content` and `content_rowid` options make this an external-content
/// FTS table, so it shares storage with the receipts table.
const String createReceiptsFtsStatement = '''
  CREATE VIRTUAL TABLE IF NOT EXISTS receipts_fts USING fts5(
    store_name,
    ocr_raw_text,
    user_notes,
    user_tags,
    content='receipts',
    content_rowid='rowid',
    tokenize='unicode61'
  )
''';

/// Triggers to keep the FTS5 index in sync with the receipts table.
const List<String> receiptsFtsTriggerStatements = [
  // After insert: add the new row to the FTS index.
  '''
  CREATE TRIGGER IF NOT EXISTS receipts_fts_insert AFTER INSERT ON receipts BEGIN
    INSERT INTO receipts_fts(rowid, store_name, ocr_raw_text, user_notes, user_tags)
    VALUES (new.rowid, new.store_name, new.ocr_raw_text, new.user_notes, new.user_tags);
  END
  ''',
  // After delete: remove the old row from the FTS index.
  '''
  CREATE TRIGGER IF NOT EXISTS receipts_fts_delete AFTER DELETE ON receipts BEGIN
    INSERT INTO receipts_fts(receipts_fts, rowid, store_name, ocr_raw_text, user_notes, user_tags)
    VALUES ('delete', old.rowid, old.store_name, old.ocr_raw_text, old.user_notes, old.user_tags);
  END
  ''',
  // After update: remove old, add new.
  '''
  CREATE TRIGGER IF NOT EXISTS receipts_fts_update AFTER UPDATE ON receipts BEGIN
    INSERT INTO receipts_fts(receipts_fts, rowid, store_name, ocr_raw_text, user_notes, user_tags)
    VALUES ('delete', old.rowid, old.store_name, old.ocr_raw_text, old.user_notes, old.user_tags);
    INSERT INTO receipts_fts(rowid, store_name, ocr_raw_text, user_notes, user_tags)
    VALUES (new.rowid, new.store_name, new.ocr_raw_text, new.user_notes, new.user_tags);
  END
  ''',
];
