import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/core/database/daos/sync_queue_dao.dart';
import 'package:warrantyvault/core/services/connectivity_service.dart';
import 'package:warrantyvault/core/sync/sync_service.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/sync_bloc.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/sync_event.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/sync_state.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSyncService extends Mock implements SyncService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSyncQueueDao extends Mock implements SyncQueueDao {}

void main() {
  late MockSyncService mockSyncService;
  late MockConnectivityService mockConnectivityService;
  late MockSyncQueueDao mockSyncQueueDao;

  // StreamControllers used to drive the subscriptions that SyncBloc
  // creates in its constructor.
  late StreamController<ConnectivityState> connectivityController;
  late StreamController<int> pendingCountController;

  const testUserId = 'user-test-123';

  /// A successful sync result with some data.
  const successResult = SyncStats(
    pulled: 2,
    pushed: 1,
    merged: 0,
    conflicts: 0,
    errors: 0,
  );

  /// A successful full reconciliation result.
  const reconResult = SyncStats(
    pulled: 3,
    pushed: 0,
    merged: 1,
    conflicts: 0,
    errors: 0,
  );

  setUp(() {
    mockSyncService = MockSyncService();
    mockConnectivityService = MockConnectivityService();
    mockSyncQueueDao = MockSyncQueueDao();

    connectivityController = StreamController<ConnectivityState>.broadcast();
    pendingCountController = StreamController<int>.broadcast();

    // Default stubs: online, no pending items.
    when(() => mockConnectivityService.stateStream)
        .thenAnswer((_) => connectivityController.stream);
    when(() => mockConnectivityService.currentState)
        .thenReturn(ConnectivityState.online);
    when(() => mockSyncQueueDao.watchPendingCount())
        .thenAnswer((_) => pendingCountController.stream);
  });

  tearDown(() {
    connectivityController.close();
    pendingCountController.close();
  });

  /// Helper to build a SyncBloc with the current mocks.
  SyncBloc buildBloc() => SyncBloc(
        syncService: mockSyncService,
        connectivityService: mockConnectivityService,
        syncQueueDao: mockSyncQueueDao,
        userId: testUserId,
      );

  group('SyncBloc', () {
    // -----------------------------------------------------------------------
    // 1. Initial state
    // -----------------------------------------------------------------------
    test('initial state is SyncIdle', () {
      final bloc = buildBloc();
      expect(bloc.state, const SyncIdle());
      bloc.close();
    });

    // -----------------------------------------------------------------------
    // 2. SyncRequested when online
    // -----------------------------------------------------------------------
    blocTest<SyncBloc, SyncState>(
      'SyncRequested when online emits '
      '[SyncInProgress, SyncComplete, SyncIdle]',
      build: () {
        when(() => mockConnectivityService.currentState)
            .thenReturn(ConnectivityState.online);
        when(() => mockSyncService.syncAll(testUserId))
            .thenAnswer((_) async => successResult);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SyncRequested()),
      wait: const Duration(seconds: 3),
      expect: () => [
        const SyncInProgress(phase: 'pulling'),
        const SyncComplete(pulled: 2, pushed: 1, conflicts: 0),
        isA<SyncIdle>()
            .having((s) => s.isOnline, 'isOnline', true)
            .having((s) => s.lastSyncedAt, 'lastSyncedAt', isNotNull),
      ],
      verify: (_) {
        verify(() => mockSyncService.syncAll(testUserId)).called(1);
      },
    );

    // -----------------------------------------------------------------------
    // 3. SyncRequested when offline
    // -----------------------------------------------------------------------
    blocTest<SyncBloc, SyncState>(
      'SyncRequested when offline emits SyncIdle(isOnline: false)',
      build: () {
        when(() => mockConnectivityService.currentState)
            .thenReturn(ConnectivityState.offline);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SyncRequested()),
      expect: () => [
        const SyncIdle(isOnline: false),
      ],
      verify: (_) {
        verifyNever(() => mockSyncService.syncAll(any()));
      },
    );

    // -----------------------------------------------------------------------
    // 4. SyncRequested with error
    // -----------------------------------------------------------------------
    blocTest<SyncBloc, SyncState>(
      'SyncRequested with error emits [SyncInProgress, SyncError]',
      build: () {
        when(() => mockConnectivityService.currentState)
            .thenReturn(ConnectivityState.online);
        when(() => mockSyncService.syncAll(testUserId))
            .thenThrow(Exception('Network timeout'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SyncRequested()),
      expect: () => [
        const SyncInProgress(phase: 'pulling'),
        isA<SyncError>().having(
          (s) => s.message,
          'message',
          contains('Network timeout'),
        ),
      ],
    );

    // -----------------------------------------------------------------------
    // 5. ConnectivityChanged to online with pending items -> auto-sync
    // -----------------------------------------------------------------------
    blocTest<SyncBloc, SyncState>(
      'ConnectivityChanged to online with pending items triggers auto-sync',
      build: () {
        when(() => mockConnectivityService.currentState)
            .thenReturn(ConnectivityState.online);
        when(() => mockSyncService.syncAll(testUserId))
            .thenAnswer((_) async => successResult);
        return buildBloc();
      },
      seed: () => const SyncIdle(pendingCount: 0, isOnline: false),
      act: (bloc) {
        // First inject a pending count so _pendingCount > 0 inside the bloc.
        pendingCountController.add(3);
        // Then signal connectivity restored.
        connectivityController.add(ConnectivityState.online);
      },
      wait: const Duration(seconds: 4),
      expect: () => [
        // PendingCountUpdated re-emits SyncIdle with updated count
        const SyncIdle(pendingCount: 3, isOnline: false),
        // ConnectivityChanged with pendingCount > 0 triggers SyncRequested
        const SyncInProgress(phase: 'pulling'),
        const SyncComplete(pulled: 2, pushed: 1, conflicts: 0),
        isA<SyncIdle>()
            .having((s) => s.isOnline, 'isOnline', true)
            .having((s) => s.pendingCount, 'pendingCount', 3),
      ],
    );

    // -----------------------------------------------------------------------
    // 6. ConnectivityChanged to online with no pending items
    // -----------------------------------------------------------------------
    blocTest<SyncBloc, SyncState>(
      'ConnectivityChanged to online with no pending items '
      'emits SyncIdle(isOnline: true)',
      build: () {
        // _pendingCount defaults to 0 so no auto-sync should trigger.
        return buildBloc();
      },
      act: (bloc) {
        connectivityController.add(ConnectivityState.online);
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        const SyncIdle(isOnline: true),
      ],
      verify: (_) {
        verifyNever(() => mockSyncService.syncAll(any()));
      },
    );

    // -----------------------------------------------------------------------
    // 7. ConnectivityChanged to offline
    // -----------------------------------------------------------------------
    blocTest<SyncBloc, SyncState>(
      'ConnectivityChanged to offline emits SyncIdle(isOnline: false)',
      build: () {
        return buildBloc();
      },
      act: (bloc) {
        connectivityController.add(ConnectivityState.offline);
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        const SyncIdle(isOnline: false),
      ],
    );

    // -----------------------------------------------------------------------
    // 8. PendingCountUpdated while idle
    // -----------------------------------------------------------------------
    blocTest<SyncBloc, SyncState>(
      'PendingCountUpdated while idle re-emits SyncIdle with updated count',
      build: () {
        return buildBloc();
      },
      act: (bloc) {
        pendingCountController.add(5);
      },
      wait: const Duration(milliseconds: 300),
      expect: () => [
        const SyncIdle(pendingCount: 5, isOnline: true),
      ],
    );

    // -----------------------------------------------------------------------
    // 9. SyncFullReconciliationRequested when online
    // -----------------------------------------------------------------------
    blocTest<SyncBloc, SyncState>(
      'SyncFullReconciliationRequested when online emits '
      '[SyncInProgress(reconciling), SyncComplete, SyncIdle]',
      build: () {
        when(() => mockConnectivityService.currentState)
            .thenReturn(ConnectivityState.online);
        when(() => mockSyncService.fullReconciliation(testUserId))
            .thenAnswer((_) async => reconResult);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const SyncFullReconciliationRequested()),
      wait: const Duration(seconds: 3),
      expect: () => [
        const SyncInProgress(phase: 'reconciling'),
        const SyncComplete(pulled: 3, pushed: 0, conflicts: 0),
        isA<SyncIdle>()
            .having((s) => s.isOnline, 'isOnline', true)
            .having((s) => s.lastSyncedAt, 'lastSyncedAt', isNotNull),
      ],
      verify: (_) {
        verify(() => mockSyncService.fullReconciliation(testUserId))
            .called(1);
      },
    );

    // -----------------------------------------------------------------------
    // 10. SyncFullReconciliationRequested when offline
    // -----------------------------------------------------------------------
    blocTest<SyncBloc, SyncState>(
      'SyncFullReconciliationRequested when offline '
      'emits SyncIdle(isOnline: false)',
      build: () {
        when(() => mockConnectivityService.currentState)
            .thenReturn(ConnectivityState.offline);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const SyncFullReconciliationRequested()),
      expect: () => [
        const SyncIdle(isOnline: false),
      ],
      verify: (_) {
        verifyNever(() => mockSyncService.fullReconciliation(any()));
      },
    );
  });
}
