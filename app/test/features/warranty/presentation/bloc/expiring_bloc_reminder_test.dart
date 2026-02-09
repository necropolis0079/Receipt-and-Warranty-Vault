import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:warrantyvault/core/notifications/reminder_scheduler.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:warrantyvault/features/warranty/presentation/bloc/expiring_bloc.dart';
import 'package:warrantyvault/features/warranty/presentation/bloc/expiring_event.dart';
import 'package:warrantyvault/features/warranty/presentation/bloc/expiring_state.dart';

class MockReceiptRepository extends Mock implements ReceiptRepository {}

class MockReminderScheduler extends Mock implements ReminderScheduler {}

void main() {
  late MockReceiptRepository mockReceiptRepository;
  late MockReminderScheduler mockReminderScheduler;

  final now = DateTime.now();

  final expiringReceipt = Receipt(
    receiptId: 'test-id',
    userId: 'user-1',
    storeName: 'Test Store',
    warrantyMonths: 12,
    warrantyExpiryDate:
        now.add(const Duration(days: 15)).toIso8601String(),
    createdAt: now.toIso8601String(),
    updatedAt: now.toIso8601String(),
  );

  final expiredReceipt = Receipt(
    receiptId: 'expired-id',
    userId: 'user-1',
    storeName: 'Old Store',
    warrantyMonths: 6,
    warrantyExpiryDate:
        now.subtract(const Duration(days: 10)).toIso8601String(),
    createdAt: now.subtract(const Duration(days: 200)).toIso8601String(),
    updatedAt: now.subtract(const Duration(days: 10)).toIso8601String(),
  );

  setUp(() {
    mockReceiptRepository = MockReceiptRepository();
    mockReminderScheduler = MockReminderScheduler();
  });

  group('ExpiringBloc reminder scheduling', () {
    blocTest<ExpiringBloc, ExpiringState>(
      'triggers scheduleForAll on reminderScheduler '
      'when expiring receipts exist',
      setUp: () {
        when(() => mockReceiptRepository.getExpiringWarranties('user-1', 30))
            .thenAnswer((_) async => [expiringReceipt]);
        when(() => mockReceiptRepository.getExpiredWarranties('user-1'))
            .thenAnswer((_) async => [expiredReceipt]);
        when(() => mockReminderScheduler.scheduleForAll(any()))
            .thenAnswer((_) async {});
      },
      build: () => ExpiringBloc(
        receiptRepository: mockReceiptRepository,
        reminderScheduler: mockReminderScheduler,
      ),
      act: (bloc) =>
          bloc.add(const ExpiringLoadRequested('user-1', daysAhead: 30)),
      expect: () => [
        const ExpiringLoading(),
        ExpiringLoaded(
          expiringSoon: [expiringReceipt],
          expired: [expiredReceipt],
        ),
      ],
      verify: (_) {
        verify(() =>
            mockReminderScheduler.scheduleForAll([expiringReceipt])).called(1);
      },
    );

    blocTest<ExpiringBloc, ExpiringState>(
      'does NOT call scheduleForAll when expiringSoon is empty',
      setUp: () {
        when(() => mockReceiptRepository.getExpiringWarranties('user-1', 30))
            .thenAnswer((_) async => []);
        when(() => mockReceiptRepository.getExpiredWarranties('user-1'))
            .thenAnswer((_) async => [expiredReceipt]);
      },
      build: () => ExpiringBloc(
        receiptRepository: mockReceiptRepository,
        reminderScheduler: mockReminderScheduler,
      ),
      act: (bloc) =>
          bloc.add(const ExpiringLoadRequested('user-1', daysAhead: 30)),
      expect: () => [
        const ExpiringLoading(),
        ExpiringLoaded(
          expiringSoon: const [],
          expired: [expiredReceipt],
        ),
      ],
      verify: (_) {
        verifyNever(() => mockReminderScheduler.scheduleForAll(any()));
      },
    );

    blocTest<ExpiringBloc, ExpiringState>(
      'works without reminderScheduler (null) — loads successfully',
      setUp: () {
        when(() => mockReceiptRepository.getExpiringWarranties('user-1', 30))
            .thenAnswer((_) async => [expiringReceipt]);
        when(() => mockReceiptRepository.getExpiredWarranties('user-1'))
            .thenAnswer((_) async => []);
      },
      build: () => ExpiringBloc(
        receiptRepository: mockReceiptRepository,
        reminderScheduler: null,
      ),
      act: (bloc) =>
          bloc.add(const ExpiringLoadRequested('user-1', daysAhead: 30)),
      expect: () => [
        const ExpiringLoading(),
        ExpiringLoaded(
          expiringSoon: [expiringReceipt],
          expired: const [],
        ),
      ],
    );

    blocTest<ExpiringBloc, ExpiringState>(
      'ExpiringRefreshRequested re-triggers load and schedules reminders again',
      setUp: () {
        when(() => mockReceiptRepository.getExpiringWarranties('user-1', 30))
            .thenAnswer((_) async => [expiringReceipt]);
        when(() => mockReceiptRepository.getExpiredWarranties('user-1'))
            .thenAnswer((_) async => []);
        when(() => mockReminderScheduler.scheduleForAll(any()))
            .thenAnswer((_) async {});
      },
      build: () => ExpiringBloc(
        receiptRepository: mockReceiptRepository,
        reminderScheduler: mockReminderScheduler,
      ),
      act: (bloc) async {
        bloc.add(const ExpiringLoadRequested('user-1', daysAhead: 30));
        // Wait for the first load to complete before refreshing.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const ExpiringRefreshRequested());
      },
      // Initial load emits Loading + Loaded, refresh re-emits Loading + Loaded.
      expect: () => [
        const ExpiringLoading(),
        ExpiringLoaded(
          expiringSoon: [expiringReceipt],
          expired: const [],
        ),
        const ExpiringLoading(),
        ExpiringLoaded(
          expiringSoon: [expiringReceipt],
          expired: const [],
        ),
      ],
      verify: (_) {
        // scheduleForAll should be called twice — once per load.
        verify(() =>
            mockReminderScheduler.scheduleForAll([expiringReceipt])).called(2);
      },
    );
  });
}
