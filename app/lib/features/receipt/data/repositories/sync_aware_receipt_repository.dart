import 'dart:developer' as dev;

import 'package:warrantyvault/core/services/connectivity_service.dart';
import 'package:warrantyvault/core/sync/sync_service.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'local_receipt_repository.dart';

/// Receipt repository that composes local storage with background sync.
///
/// All reads come from the local Drift DB (via [LocalReceiptRepository]).
/// All writes go to local DB first (which auto-enqueues to the sync queue),
/// then trigger an immediate push attempt if the device is online.
///
/// This is the repository provided to the rest of the app via DI.
class SyncAwareReceiptRepository implements ReceiptRepository {
  SyncAwareReceiptRepository({
    required LocalReceiptRepository localRepository,
    required SyncService syncService,
    required ConnectivityService connectivityService,
  })  : _localRepository = localRepository,
        _syncService = syncService,
        _connectivityService = connectivityService;

  final LocalReceiptRepository _localRepository;
  final SyncService _syncService;
  final ConnectivityService _connectivityService;

  // ---------------------------------------------------------------------------
  // Background sync helper
  // ---------------------------------------------------------------------------

  /// Attempt an immediate sync push if the device is online.
  ///
  /// Fire-and-forget: the caller is never blocked and errors are logged
  /// rather than propagated. The sync queue guarantees eventual delivery.
  void _trySyncInBackground() {
    if (_connectivityService.currentState == ConnectivityState.online) {
      _syncService.batchPush().then(
        (_) {},
        onError: (Object e) {
          dev.log(
            'Background sync push failed (will retry later): $e',
            name: 'SyncAwareReceiptRepository',
          );
        },
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Reads — all delegate to local repository (offline-first)
  // ---------------------------------------------------------------------------

  @override
  Stream<List<Receipt>> watchUserReceipts(String userId) =>
      _localRepository.watchUserReceipts(userId);

  @override
  Future<Receipt?> getById(String receiptId) =>
      _localRepository.getById(receiptId);

  @override
  Stream<List<Receipt>> watchByStatus(String userId, ReceiptStatus status) =>
      _localRepository.watchByStatus(userId, status);

  @override
  Future<List<Receipt>> getExpiringWarranties(String userId, int daysAhead) =>
      _localRepository.getExpiringWarranties(userId, daysAhead);

  @override
  Future<List<Receipt>> getExpiredWarranties(String userId) =>
      _localRepository.getExpiredWarranties(userId);

  @override
  Future<List<Receipt>> search(String userId, String query) =>
      _localRepository.search(userId, query);

  @override
  Future<int> countActive(String userId) =>
      _localRepository.countActive(userId);

  // ---------------------------------------------------------------------------
  // Writes — delegate to local, then trigger background sync
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveReceipt(Receipt receipt) async {
    await _localRepository.saveReceipt(receipt);
    _trySyncInBackground();
  }

  @override
  Future<void> updateReceipt(Receipt receipt) async {
    await _localRepository.updateReceipt(receipt);
    _trySyncInBackground();
  }

  @override
  Future<void> softDelete(String receiptId) async {
    await _localRepository.softDelete(receiptId);
    _trySyncInBackground();
  }

  @override
  Future<void> hardDelete(String receiptId) async {
    // Hard deletes remove the sync-queue entries, so no push needed.
    await _localRepository.hardDelete(receiptId);
  }

  @override
  Future<void> restoreReceipt(String receiptId) async {
    await _localRepository.restoreReceipt(receiptId);
    _trySyncInBackground();
  }

  @override
  Future<int> purgeOldDeleted(int days) =>
      _localRepository.purgeOldDeleted(days);
}
