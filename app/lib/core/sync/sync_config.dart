/// Sync engine configuration constants.
///
/// Centralizes all tuneable parameters for the sync engine:
/// intervals, batch sizes, retry limits, and storage keys.
class SyncConfig {
  const SyncConfig._();

  /// Delta sync interval for periodic background sync.
  static const Duration deltaSyncInterval = Duration(minutes: 15);

  /// Full reconciliation interval (safety net).
  static const Duration fullReconciliationInterval = Duration(days: 7);

  /// Maximum retries for a single sync operation before it is abandoned.
  static const int maxRetries = 5;

  /// Maximum items per push batch.
  static const int batchSize = 20;

  /// Backoff multiplier for retries (seconds). Retry N waits N * this value.
  static const int backoffMultiplierSeconds = 2;

  /// Maximum image upload size in bytes (10 MB).
  static const int imageUploadMaxSize = 10 * 1024 * 1024;

  /// Pre-signed URL expiry duration.
  static const Duration presignedUrlExpiry = Duration(minutes: 10);

  /// Secure-storage key for last delta-sync timestamp.
  static const String lastSyncTimestampKey = 'last_sync_timestamp';

  /// Secure-storage key for last full-reconciliation timestamp.
  static const String lastFullReconciliationKey = 'last_full_reconciliation';
}
