import 'package:warrantyvault/core/services/connectivity_service.dart';

/// Events consumed by [SyncBloc].
///
/// Not `sealed` because the bloc defines private internal events
/// (e.g. `_PendingCountUpdated`) in a separate library file.
abstract class SyncEvent {
  const SyncEvent();
}

/// User or system requests a full sync cycle (pull + push).
class SyncRequested extends SyncEvent {
  const SyncRequested();
}

/// Server pull phase finished — carries pull statistics.
class SyncPullCompleted extends SyncEvent {
  const SyncPullCompleted({required this.pulled, required this.merged});

  final int pulled;
  final int merged;
}

/// Client push phase finished — carries push statistics.
class SyncPushCompleted extends SyncEvent {
  const SyncPushCompleted({required this.pushed});

  final int pushed;
}

/// An error occurred during sync.
class SyncFailed extends SyncEvent {
  const SyncFailed({required this.message});

  final String message;
}

/// Network connectivity changed (online / offline / limited).
class ConnectivityChanged extends SyncEvent {
  const ConnectivityChanged({required this.state});

  final ConnectivityState state;
}

/// Request a full reconciliation (compare local manifest with server).
class SyncFullReconciliationRequested extends SyncEvent {
  const SyncFullReconciliationRequested();
}

/// Internal event: pending sync-queue count changed.
///
/// Dispatched by the bloc's subscription to [SyncQueueDao.watchPendingCount].
class PendingCountUpdated extends SyncEvent {
  const PendingCountUpdated({required this.count});
  final int count;
}

