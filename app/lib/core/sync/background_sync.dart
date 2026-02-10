import 'package:workmanager/workmanager.dart';

/// Unique task name for periodic delta sync (every 15 minutes).
const periodicSyncTaskName = 'com.cronos.warrantyvault.periodicSync';

/// Unique task name for periodic full reconciliation (daily).
const fullReconciliationTaskName =
    'com.cronos.warrantyvault.fullReconciliation';

/// Initialize WorkManager and register periodic background sync tasks.
///
/// Call this from `main.dart` after `WidgetsFlutterBinding.ensureInitialized()`.
Future<void> initializeBackgroundSync() async {
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Register periodic delta sync (every 15 minutes, minimum).
  await Workmanager().registerPeriodicTask(
    periodicSyncTaskName,
    periodicSyncTaskName,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

  // Register periodic full reconciliation (once per day).
  // The SyncService itself checks whether 7 days have elapsed before
  // actually performing a full reconciliation, so daily registration
  // just ensures the check runs frequently enough.
  await Workmanager().registerPeriodicTask(
    fullReconciliationTaskName,
    fullReconciliationTaskName,
    frequency: const Duration(hours: 24),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );
}

/// Top-level callback for WorkManager.
///
/// This function runs in a **separate isolate**, so it cannot access any
/// state or singletons from the main isolate. A full DI re-initialization
/// would be needed to obtain [SyncService] and its dependencies.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      switch (taskName) {
        case periodicSyncTaskName:
          // TODO(sync): Re-initialize DI container in this isolate,
          // then call syncService.syncAll(). For now the foreground
          // SyncBloc handles sync; this is a safety-net for when the
          // app is backgrounded.
          break;
        case fullReconciliationTaskName:
          // TODO(sync): Re-initialize DI container in this isolate,
          // then call syncService.fullReconciliation().
          break;
      }
      return true;
    } catch (e) {
      // Returning false tells WorkManager to retry with back-off.
      return false;
    }
  });
}

/// Cancel all registered background sync tasks.
///
/// Call this when the user logs out or switches to device-only storage mode.
Future<void> cancelBackgroundSync() async {
  await Workmanager().cancelAll();
}
