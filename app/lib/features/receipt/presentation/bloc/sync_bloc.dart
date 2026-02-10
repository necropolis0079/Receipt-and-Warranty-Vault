import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:warrantyvault/core/database/daos/sync_queue_dao.dart';
import 'package:warrantyvault/core/services/connectivity_service.dart';
import 'package:warrantyvault/core/sync/sync_service.dart';
import 'sync_event.dart';
import 'sync_state.dart';

/// BLoC managing sync state between local Drift DB and cloud backend.
///
/// Responsibilities:
/// - Listens to [ConnectivityService] and auto-triggers sync when
///   connectivity is restored and there are pending queue items.
/// - Listens to [SyncQueueDao.watchPendingCount] to keep the UI
///   informed about how many operations are waiting.
/// - Handles manual [SyncRequested] and [SyncFullReconciliationRequested].
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc({
    required SyncService syncService,
    required ConnectivityService connectivityService,
    required SyncQueueDao syncQueueDao,
    required String userId,
  })  : _syncService = syncService,
        _connectivityService = connectivityService,
        _syncQueueDao = syncQueueDao,
        _userId = userId,
        super(const SyncIdle()) {
    // Register event handlers.
    on<SyncRequested>(_onSyncRequested);
    on<ConnectivityChanged>(_onConnectivityChanged);
    on<SyncFullReconciliationRequested>(_onFullReconciliationRequested);
    on<PendingCountUpdated>(_onPendingCountUpdated);

    // Listen to connectivity changes and dispatch [ConnectivityChanged].
    _connectivitySub = _connectivityService.stateStream.listen(
      (connectivityState) {
        add(ConnectivityChanged(state: connectivityState));
      },
    );

    // Listen to pending sync-queue count and dispatch internal event.
    _pendingCountSub = _syncQueueDao.watchPendingCount().listen(
      (count) {
        add(PendingCountUpdated(count: count));
      },
    );
  }

  final SyncService _syncService;
  final ConnectivityService _connectivityService;
  final SyncQueueDao _syncQueueDao;
  final String _userId;

  StreamSubscription<ConnectivityState>? _connectivitySub;
  StreamSubscription<int>? _pendingCountSub;

  /// Tracks the latest pending count so we can embed it in [SyncIdle].
  int _pendingCount = 0;

  /// Tracks the last successful sync timestamp.
  String? _lastSyncedAt;

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  /// Full sync cycle: pull + push.
  Future<void> _onSyncRequested(
    SyncRequested event,
    Emitter<SyncState> emit,
  ) async {
    // If we're offline, skip.
    final connectivity = _connectivityService.currentState;
    if (connectivity == ConnectivityState.offline) {
      emit(SyncIdle(
        lastSyncedAt: _lastSyncedAt,
        pendingCount: _pendingCount,
        isOnline: false,
      ));
      return;
    }

    emit(const SyncInProgress(phase: 'pulling'));

    try {
      final result = await _syncService.syncAll(_userId);

      _lastSyncedAt = DateTime.now().toUtc().toIso8601String();

      if (result.hasErrors) {
        dev.log(
          'Sync completed with ${result.errors} errors',
          name: 'SyncBloc',
        );
      }

      emit(SyncComplete(
        pulled: result.pulled,
        pushed: result.pushed,
        conflicts: result.conflicts,
      ));

      // Brief display of results, then transition to idle.
      await Future<void>.delayed(const Duration(seconds: 2));

      emit(SyncIdle(
        lastSyncedAt: _lastSyncedAt,
        pendingCount: _pendingCount,
        isOnline: true,
      ));
    } catch (e, stack) {
      dev.log('Sync failed: $e', name: 'SyncBloc', error: e, stackTrace: stack);
      emit(SyncError(message: e.toString()));
    }
  }

  /// Connectivity changed — auto-sync when back online if there are pending items.
  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<SyncState> emit,
  ) async {
    final isOnline = event.state == ConnectivityState.online;

    if (isOnline && _pendingCount > 0) {
      // Back online with pending items — trigger sync automatically.
      add(const SyncRequested());
    } else {
      // Update idle state so UI can show offline indicator.
      emit(SyncIdle(
        lastSyncedAt: _lastSyncedAt,
        pendingCount: _pendingCount,
        isOnline: isOnline,
      ));
    }
  }

  /// Full reconciliation (compare local manifest with server state).
  Future<void> _onFullReconciliationRequested(
    SyncFullReconciliationRequested event,
    Emitter<SyncState> emit,
  ) async {
    final connectivity = _connectivityService.currentState;
    if (connectivity == ConnectivityState.offline) {
      emit(SyncIdle(
        lastSyncedAt: _lastSyncedAt,
        pendingCount: _pendingCount,
        isOnline: false,
      ));
      return;
    }

    emit(const SyncInProgress(phase: 'reconciling'));

    try {
      final result = await _syncService.fullReconciliation(_userId);

      _lastSyncedAt = DateTime.now().toUtc().toIso8601String();

      emit(SyncComplete(
        pulled: result.pulled,
        pushed: result.pushed,
        conflicts: result.conflicts,
      ));

      await Future<void>.delayed(const Duration(seconds: 2));

      emit(SyncIdle(
        lastSyncedAt: _lastSyncedAt,
        pendingCount: _pendingCount,
        isOnline: true,
      ));
    } catch (e, stack) {
      dev.log(
        'Full reconciliation failed: $e',
        name: 'SyncBloc',
        error: e,
        stackTrace: stack,
      );
      emit(SyncError(message: e.toString()));
    }
  }

  /// Internal: pending queue count changed.
  void _onPendingCountUpdated(
    PendingCountUpdated event,
    Emitter<SyncState> emit,
  ) {
    _pendingCount = event.count;

    // If we're idle, re-emit with updated count so the UI can react.
    if (state is SyncIdle) {
      final idle = state as SyncIdle;
      emit(SyncIdle(
        lastSyncedAt: idle.lastSyncedAt,
        pendingCount: _pendingCount,
        isOnline: idle.isOnline,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    _pendingCountSub?.cancel();
    return super.close();
  }
}
