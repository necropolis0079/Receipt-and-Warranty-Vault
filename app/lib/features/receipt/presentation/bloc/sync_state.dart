import 'package:equatable/equatable.dart';

/// States emitted by [SyncBloc].
sealed class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

/// No sync operation in progress.
class SyncIdle extends SyncState {
  const SyncIdle({
    this.lastSyncedAt,
    this.pendingCount = 0,
    this.isOnline = true,
  });

  /// ISO-8601 timestamp of the last successful sync, or null if never synced.
  final String? lastSyncedAt;

  /// Number of operations waiting in the sync queue.
  final int pendingCount;

  /// Whether the device currently has internet access.
  final bool isOnline;

  @override
  List<Object?> get props => [lastSyncedAt, pendingCount, isOnline];
}

/// A sync operation is currently running.
class SyncInProgress extends SyncState {
  const SyncInProgress({required this.phase, this.progress = 0.0});

  /// Current phase: 'pulling', 'pushing', or 'reconciling'.
  final String phase;

  /// Progress within the current phase (0.0 – 1.0).
  final double progress;

  @override
  List<Object?> get props => [phase, progress];
}

/// Sync completed successfully.
class SyncComplete extends SyncState {
  const SyncComplete({
    required this.pulled,
    required this.pushed,
    required this.conflicts,
  });

  final int pulled;
  final int pushed;
  final int conflicts;

  @override
  List<Object?> get props => [pulled, pushed, conflicts];
}

/// Sync failed with an error.
class SyncError extends SyncState {
  const SyncError({required this.message, this.canRetry = true});

  /// Human-readable description of what went wrong.
  final String message;

  /// Whether the user can retry the sync (false for auth errors, etc.).
  final bool canRetry;

  @override
  List<Object?> get props => [message, canRetry];
}
