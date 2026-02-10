import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/receipt/data/datasources/sync_remote_source.dart';
import '../../features/receipt/data/models/receipt_mapper.dart';
import '../../features/receipt/domain/entities/receipt.dart';
import '../database/daos/receipts_dao.dart';
import '../database/daos/sync_queue_dao.dart';
import '../services/connectivity_service.dart';
import 'conflict_resolver.dart';
import 'sync_config.dart';

/// Statistics returned from any sync operation.
class SyncStats {
  const SyncStats({
    this.pulled = 0,
    this.pushed = 0,
    this.merged = 0,
    this.conflicts = 0,
    this.errors = 0,
  });

  final int pulled;
  final int pushed;
  final int merged;
  final int conflicts;
  final int errors;

  SyncStats operator +(SyncStats other) {
    return SyncStats(
      pulled: pulled + other.pulled,
      pushed: pushed + other.pushed,
      merged: merged + other.merged,
      conflicts: conflicts + other.conflicts,
      errors: errors + other.errors,
    );
  }

  bool get hasErrors => errors > 0;
  bool get hasConflicts => conflicts > 0;

  @override
  String toString() =>
      'SyncStats(pulled=$pulled, pushed=$pushed, merged=$merged, '
      'conflicts=$conflicts, errors=$errors)';
}

/// Sync orchestrator: delta pull, batch push, full reconciliation.
///
/// Coordinates between the local Drift DB and the remote API to keep data
/// consistent. All UI reads from the local DB; writes go to local DB + sync
/// queue. This service processes the queue asynchronously.
class SyncService {
  SyncService({
    required ReceiptsDao receiptsDao,
    required SyncQueueDao syncQueueDao,
    required SyncRemoteSource syncRemoteSource,
    required ConflictResolver conflictResolver,
    required ConnectivityService connectivityService,
  })  : _receiptsDao = receiptsDao,
        _syncQueueDao = syncQueueDao,
        _syncRemoteSource = syncRemoteSource,
        _conflictResolver = conflictResolver,
        _connectivityService = connectivityService;

  final ReceiptsDao _receiptsDao;
  final SyncQueueDao _syncQueueDao;
  final SyncRemoteSource _syncRemoteSource;
  final ConflictResolver _conflictResolver;
  final ConnectivityService _connectivityService;

  final _storage = const FlutterSecureStorage();
  bool _isSyncing = false;

  /// Whether a sync cycle is currently in progress.
  bool get isSyncing => _isSyncing;

  // =========================================================================
  // syncAll — top-level orchestrator
  // =========================================================================

  /// Run a complete sync cycle: pull -> push -> (optional) full reconciliation.
  ///
  /// Returns a combined [SyncStats]. If offline, returns immediately with all
  /// zeros and no errors.
  Future<SyncStats> syncAll(String userId) async {
    if (_isSyncing) {
      dev.log('Sync already in progress — skipping', name: 'Sync');
      return const SyncStats();
    }

    final connectivity = await _connectivityService.check();
    if (connectivity == ConnectivityState.offline) {
      dev.log('Offline — skipping sync', name: 'Sync');
      return const SyncStats();
    }

    _isSyncing = true;
    try {
      // 1. Delta pull
      final pullStats = await deltaPull(userId);

      // 2. Batch push
      final pushStats = await batchPush(userId);

      // 3. Full reconciliation (if due)
      var reconStats = const SyncStats();
      final lastFullRecon =
          await _storage.read(key: SyncConfig.lastFullReconciliationKey);
      final needsFullRecon = lastFullRecon == null ||
          DateTime.now().difference(DateTime.parse(lastFullRecon)) >
              SyncConfig.fullReconciliationInterval;

      if (needsFullRecon) {
        reconStats = await fullReconciliation(userId);
      }

      final combined = pullStats + pushStats + reconStats;
      dev.log('Sync cycle complete: $combined', name: 'Sync');
      return combined;
    } catch (e, st) {
      dev.log('Sync cycle failed: $e', name: 'Sync', error: e, stackTrace: st);
      return const SyncStats(errors: 1);
    } finally {
      _isSyncing = false;
    }
  }

  // =========================================================================
  // deltaPull
  // =========================================================================

  /// Fetch items changed on the server since the last sync timestamp.
  ///
  /// For each returned item:
  /// - If not found locally: insert as new.
  /// - If found locally: run [ConflictResolver.resolve] and apply the merged
  ///   result.
  ///
  /// Updates the stored last-sync timestamp on success.
  Future<SyncStats> deltaPull(String userId) async {
    final lastSync =
        await _storage.read(key: SyncConfig.lastSyncTimestampKey) ??
            '1970-01-01T00:00:00Z';

    dev.log('Delta pull from $lastSync', name: 'Sync');

    int pulled = 0;
    int inserted = 0;
    int merged = 0;
    int conflicts = 0;
    int errors = 0;

    try {
      final response = await _syncRemoteSource.pull(lastSync);

      for (final serverItem in response.items) {
        final receiptId = serverItem['receiptId'] as String?;
        if (receiptId == null) continue;

        try {
          final localEntry = await _receiptsDao.getById(receiptId);

          if (localEntry == null) {
            // ---------------------------------------------------------------
            // New item from server — insert locally
            // ---------------------------------------------------------------
            final receipt = _serverItemToReceipt(serverItem, userId);
            await _receiptsDao.insertReceipt(ReceiptMapper.toCompanion(receipt));
            inserted++;
            pulled++;
          } else {
            // ---------------------------------------------------------------
            // Existing item — merge via conflict resolver
            // ---------------------------------------------------------------
            final localReceipt = ReceiptMapper.toReceipt(localEntry);
            final result = _conflictResolver.resolve(
              localReceipt: localReceipt,
              serverItem: serverItem,
            );

            await _receiptsDao.updateReceipt(
              ReceiptMapper.toCompanion(result.mergedReceipt),
            );

            if (result.hadConflict) {
              conflicts++;
            }
            merged++;
            pulled++;
          }
        } catch (e) {
          dev.log('Error processing server item $receiptId: $e', name: 'Sync');
          errors++;
        }
      }

      // Persist the server timestamp for next delta pull
      if (response.serverTimestamp.isNotEmpty) {
        await _storage.write(
          key: SyncConfig.lastSyncTimestampKey,
          value: response.serverTimestamp,
        );
      }
    } catch (e, st) {
      dev.log('Delta pull failed: $e', name: 'Sync', error: e, stackTrace: st);
      errors++;
    }

    dev.log(
      'Delta pull complete: pulled=$pulled (inserted=$inserted, merged=$merged), '
      'conflicts=$conflicts, errors=$errors',
      name: 'Sync',
    );

    return SyncStats(
      pulled: pulled,
      merged: merged,
      conflicts: conflicts,
      errors: errors,
    );
  }

  // =========================================================================
  // batchPush
  // =========================================================================

  /// Push pending local changes to the server in batches.
  ///
  /// Reads entries from [SyncQueueDao], converts them to maps via
  /// [ReceiptMapper], and sends them in batches of [SyncConfig.batchSize].
  ///
  /// For each push result:
  /// - "accepted": mark queue entry completed + receipt synced.
  /// - "merged": apply server's merged item locally + mark completed.
  /// - "conflict": mark receipt as conflict + mark queue entry failed.
  Future<SyncStats> batchPush([String? userId]) async {
    int pushed = 0;
    int merged = 0;
    int conflicts = 0;
    int errors = 0;

    try {
      while (true) {
        final batch = await _syncQueueDao.getPendingBatch(
          limit: SyncConfig.batchSize,
        );
        if (batch.isEmpty) break;

        // Build items to push
        final items = <Map<String, dynamic>>[];
        final queueIdByReceiptId = <String, int>{};

        for (final entry in batch) {
          final receiptEntry = await _receiptsDao.getById(entry.receiptId);
          if (receiptEntry == null) {
            // Receipt was deleted locally — clear queue entry
            await _syncQueueDao.markCompleted(entry.id);
            continue;
          }

          final receipt = ReceiptMapper.toReceipt(receiptEntry);
          final item = _receiptToMap(receipt);
          item['_operation'] = entry.operation;
          items.add(item);
          queueIdByReceiptId[entry.receiptId] = entry.id;
        }

        if (items.isEmpty) break;

        try {
          final response = await _syncRemoteSource.push(items);

          for (final result in response.results) {
            final queueId = queueIdByReceiptId[result.receiptId];
            if (queueId == null) continue;

            switch (result.outcome) {
              case 'accepted':
                await _syncQueueDao.markCompleted(queueId);
                await _receiptsDao.markSynced(result.receiptId);
                pushed++;

              case 'merged':
                await _syncQueueDao.markCompleted(queueId);
                if (result.mergedItem != null) {
                  // Apply the server's merged version locally.
                  // userId comes from the merged item or fallback to param.
                  final mergedUserId =
                      result.mergedItem!['userId'] as String? ??
                          userId ??
                          '';
                  final mergedReceipt =
                      _serverItemToReceipt(result.mergedItem!, mergedUserId);
                  await _receiptsDao.updateReceipt(
                    ReceiptMapper.toCompanion(mergedReceipt),
                  );
                }
                pushed++;
                merged++;

              case 'conflict':
                await _syncQueueDao.markFailed(
                    queueId, 'Unresolvable conflict');
                await _receiptsDao.markConflict(result.receiptId);
                conflicts++;

              default:
                dev.log(
                  'Unknown push outcome "${result.outcome}" for ${result.receiptId}',
                  name: 'Sync',
                );
                errors++;
            }
          }
        } catch (e) {
          // Network error during push — mark all batch entries as failed
          dev.log('Push batch failed: $e', name: 'Sync');
          for (final entry in batch) {
            await _syncQueueDao.markFailed(entry.id, e.toString());
          }
          errors += batch.length;
          break; // Stop pushing on network error
        }
      }
    } catch (e, st) {
      dev.log('Batch push failed: $e', name: 'Sync', error: e, stackTrace: st);
      errors++;
    }

    dev.log(
      'Batch push complete: pushed=$pushed, merged=$merged, '
      'conflicts=$conflicts, errors=$errors',
      name: 'Sync',
    );

    return SyncStats(
      pushed: pushed,
      merged: merged,
      conflicts: conflicts,
      errors: errors,
    );
  }

  // =========================================================================
  // fullReconciliation
  // =========================================================================

  /// Compare a local manifest with the server to find and resolve differences.
  ///
  /// 1. Load all local receipts and build a manifest ({receiptId, version,
  ///    updatedAt}).
  /// 2. Send to server via [SyncRemoteSource.fullReconciliation].
  /// 3. Apply `toUpdate` items (insert or merge).
  /// 4. Handle `toDelete` items (soft-delete locally).
  /// 5. Save reconciliation timestamp.
  Future<SyncStats> fullReconciliation(String userId) async {
    dev.log('Starting full reconciliation', name: 'Sync');

    int pulled = 0;
    int merged = 0;
    int conflicts = 0;
    int errors = 0;

    try {
      // Build local manifest from all receipts regardless of status.
      // ReceiptsDao does not expose a single getAllForUser Future, so we
      // query each status individually and combine the results.
      final activeReceipts =
          await _getReceiptsByStatus(userId, 'active');
      final returnedReceipts =
          await _getReceiptsByStatus(userId, 'returned');
      final deletedReceipts =
          await _getReceiptsByStatus(userId, 'deleted');

      final allReceipts = [
        ...activeReceipts,
        ...returnedReceipts,
        ...deletedReceipts,
      ];

      final manifest = allReceipts.map((r) {
        return <String, dynamic>{
          'receiptId': r.receiptId,
          'version': r.version,
          'updatedAt': r.updatedAt,
        };
      }).toList();

      final response =
          await _syncRemoteSource.fullReconciliation(manifest);

      // Process toUpdate — items the server says we need to update locally
      for (final serverItem in response.toUpdate) {
        final receiptId = serverItem['receiptId'] as String?;
        if (receiptId == null) continue;

        try {
          final localEntry = await _receiptsDao.getById(receiptId);

          if (localEntry == null) {
            // Server-only item — insert locally
            final receipt = _serverItemToReceipt(serverItem, userId);
            await _receiptsDao.insertReceipt(
              ReceiptMapper.toCompanion(receipt),
            );
            pulled++;
          } else {
            // Both exist — merge
            final localReceipt = ReceiptMapper.toReceipt(localEntry);
            final result = _conflictResolver.resolve(
              localReceipt: localReceipt,
              serverItem: serverItem,
            );

            await _receiptsDao.updateReceipt(
              ReceiptMapper.toCompanion(result.mergedReceipt),
            );

            if (result.hadConflict) conflicts++;
            merged++;
            pulled++;
          }
        } catch (e) {
          dev.log('Error in full recon for $receiptId: $e', name: 'Sync');
          errors++;
        }
      }

      // Process toDelete — items the server says should be deleted locally
      for (final receiptId in response.toDelete) {
        try {
          await _receiptsDao.softDelete(receiptId);
          pulled++;
        } catch (e) {
          dev.log('Error soft-deleting $receiptId: $e', name: 'Sync');
          errors++;
        }
      }

      // Save reconciliation timestamps
      final now = DateTime.now().toUtc().toIso8601String();
      await _storage.write(
        key: SyncConfig.lastFullReconciliationKey,
        value: now,
      );
      if (response.serverTimestamp.isNotEmpty) {
        await _storage.write(
          key: SyncConfig.lastSyncTimestampKey,
          value: response.serverTimestamp,
        );
      }
    } catch (e, st) {
      dev.log('Full reconciliation failed: $e',
          name: 'Sync', error: e, stackTrace: st);
      errors++;
    }

    dev.log(
      'Full reconciliation complete: pulled=$pulled, merged=$merged, '
      'conflicts=$conflicts, errors=$errors',
      name: 'Sync',
    );

    return SyncStats(
      pulled: pulled,
      merged: merged,
      conflicts: conflicts,
      errors: errors,
    );
  }

  // =========================================================================
  // Private helpers
  // =========================================================================

  /// Get receipts by status using the DAO's watchByStatus stream (take first
  /// emission). This is a workaround until a dedicated Future-based method is
  /// added to ReceiptsDao.
  Future<List<Receipt>> _getReceiptsByStatus(
      String userId, String status) async {
    final entries = await _receiptsDao.watchByStatus(userId, status).first;
    return entries.map(ReceiptMapper.toReceipt).toList();
  }

  /// Convert a server JSON map into a domain [Receipt].
  ///
  /// Handles type coercion for numeric fields that may arrive as int or double,
  /// and JSON-encoded list fields.
  Receipt _serverItemToReceipt(Map<String, dynamic> item, String userId) {
    return Receipt(
      receiptId: item['receiptId'] as String,
      userId: item['userId'] as String? ?? userId,
      storeName: item['storeName'] as String?,
      extractedMerchantName: item['extractedMerchantName'] as String?,
      purchaseDate: item['purchaseDate'] as String?,
      extractedDate: item['extractedDate'] as String?,
      totalAmount: (item['totalAmount'] as num?)?.toDouble(),
      extractedTotal: (item['extractedTotal'] as num?)?.toDouble(),
      currency: item['currency'] as String? ?? 'EUR',
      category: item['category'] as String?,
      warrantyMonths: item['warrantyMonths'] as int? ?? 0,
      warrantyExpiryDate: item['warrantyExpiryDate'] as String?,
      status: _parseStatus(item['status'] as String? ?? 'active'),
      imageKeys: _decodeList(item['imageKeys']),
      thumbnailKeys: _decodeList(item['thumbnailKeys']),
      ocrRawText: item['ocrRawText'] as String?,
      llmConfidence: item['llmConfidence'] as int? ?? 0,
      userNotes: item['userNotes'] as String?,
      userTags: _decodeList(item['userTags']),
      isFavorite: item['isFavorite'] as bool? ?? false,
      userEditedFields: _decodeList(item['userEditedFields']),
      createdAt: item['createdAt'] as String? ??
          DateTime.now().toUtc().toIso8601String(),
      updatedAt: item['updatedAt'] as String? ??
          DateTime.now().toUtc().toIso8601String(),
      version: item['version'] as int? ?? 1,
      deletedAt: item['deletedAt'] as String?,
      syncStatus: SyncStatus.synced,
      lastSyncedAt: DateTime.now().toUtc().toIso8601String(),
      localImagePaths: const [], // no local paths for server-sourced items
    );
  }

  /// Convert a domain [Receipt] to a JSON map for pushing to the server.
  Map<String, dynamic> _receiptToMap(Receipt receipt) {
    return {
      'receiptId': receipt.receiptId,
      'userId': receipt.userId,
      'storeName': receipt.storeName,
      'extractedMerchantName': receipt.extractedMerchantName,
      'purchaseDate': receipt.purchaseDate,
      'extractedDate': receipt.extractedDate,
      'totalAmount': receipt.totalAmount,
      'extractedTotal': receipt.extractedTotal,
      'currency': receipt.currency,
      'category': receipt.category,
      'warrantyMonths': receipt.warrantyMonths,
      'warrantyExpiryDate': receipt.warrantyExpiryDate,
      'status': receipt.status.name,
      'imageKeys': receipt.imageKeys,
      'thumbnailKeys': receipt.thumbnailKeys,
      'ocrRawText': receipt.ocrRawText,
      'llmConfidence': receipt.llmConfidence,
      'userNotes': receipt.userNotes,
      'userTags': receipt.userTags,
      'isFavorite': receipt.isFavorite,
      'userEditedFields': receipt.userEditedFields,
      'createdAt': receipt.createdAt,
      'updatedAt': receipt.updatedAt,
      'version': receipt.version,
      'deletedAt': receipt.deletedAt,
    };
  }

  /// Parse a [ReceiptStatus] from its string name.
  static ReceiptStatus _parseStatus(String value) {
    return ReceiptStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReceiptStatus.active,
    );
  }

  /// Decode a dynamic value that may be a List, a JSON string, or null.
  static List<String> _decodeList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = _tryJsonDecode(value);
        if (decoded is List) return decoded.cast<String>();
      } catch (_) {
        // Not valid JSON
      }
    }
    return [];
  }

  static dynamic _tryJsonDecode(String value) {
    // Inline import-free JSON decode
    return _jsonCodec.decode(value);
  }

  static const _jsonCodec = JsonCodec();
}
