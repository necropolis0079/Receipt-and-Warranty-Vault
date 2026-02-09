import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/notifications/mock_notification_service.dart';
import 'package:warrantyvault/core/notifications/reminder_scheduler.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';

void main() {
  late MockNotificationService mockService;
  late ReminderScheduler scheduler;

  setUp(() {
    mockService = MockNotificationService();
    scheduler = ReminderScheduler(notificationService: mockService);
  });

  Receipt createReceipt({
    String receiptId = 'test-id',
    String userId = 'user-1',
    String storeName = 'Test Store',
    int warrantyMonths = 12,
    String? warrantyExpiryDate,
  }) {
    return Receipt(
      receiptId: receiptId,
      userId: userId,
      storeName: storeName,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      warrantyMonths: warrantyMonths,
      warrantyExpiryDate: warrantyExpiryDate ??
          DateTime.now()
              .add(const Duration(days: 180))
              .toIso8601String(),
    );
  }

  group('ReminderScheduler', () {
    group('scheduleForReceipt', () {
      test(
          'with valid future warranty schedules 3 reminders (7d, 1d, 0d)',
          () async {
        final receipt = createReceipt();

        await scheduler.scheduleForReceipt(receipt);

        // Should cancel existing first (1 cancel) then schedule 3 reminders.
        expect(mockService.cancelledIds, contains('test-id'));
        expect(mockService.scheduledReminders, hasLength(3));

        final daysBefore = mockService.scheduledReminders
            .map((r) => r.daysBefore)
            .toList();
        expect(daysBefore, containsAll([7, 1, 0]));

        // All reminders should reference the same receipt.
        for (final reminder in mockService.scheduledReminders) {
          expect(reminder.receiptId, 'test-id');
          expect(reminder.storeName, 'Test Store');
        }
      });

      test('with 0 warrantyMonths does nothing', () async {
        final receipt = createReceipt(warrantyMonths: 0);

        await scheduler.scheduleForReceipt(receipt);

        expect(mockService.scheduledReminders, isEmpty);
        expect(mockService.cancelledIds, isEmpty);
      });

      test('with null warrantyExpiryDate does nothing', () async {
        final receipt = Receipt(
          receiptId: 'test-id',
          userId: 'user-1',
          storeName: 'Test Store',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          warrantyMonths: 12,
          warrantyExpiryDate: null,
        );

        await scheduler.scheduleForReceipt(receipt);

        expect(mockService.scheduledReminders, isEmpty);
        expect(mockService.cancelledIds, isEmpty);
      });

      test('with expired warranty does nothing', () async {
        final receipt = createReceipt(
          warrantyExpiryDate: DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String(),
        );

        await scheduler.scheduleForReceipt(receipt);

        expect(mockService.scheduledReminders, isEmpty);
        // No cancel should be called either since we bail out early.
        expect(mockService.cancelledIds, isEmpty);
      });

      test('cancels existing reminders before scheduling new ones', () async {
        final receipt = createReceipt();

        // Schedule once.
        await scheduler.scheduleForReceipt(receipt);
        expect(mockService.cancelledIds, hasLength(1));
        expect(mockService.scheduledReminders, hasLength(3));

        // Schedule the same receipt again.
        await scheduler.scheduleForReceipt(receipt);

        // Cancel should have been called twice total (once per call).
        expect(mockService.cancelledIds, hasLength(2));
        expect(mockService.cancelledIds, everyElement('test-id'));

        // The second call cancels the first batch then adds 3 new ones.
        // cancelReminder removes matching entries, so we end up with 3.
        expect(mockService.scheduledReminders, hasLength(3));
      });
    });

    group('scheduleForAll', () {
      test('schedules for multiple receipts', () async {
        final receipts = [
          createReceipt(
            receiptId: 'r1',
            storeName: 'Store A',
          ),
          createReceipt(
            receiptId: 'r2',
            storeName: 'Store B',
          ),
          createReceipt(
            receiptId: 'r3',
            storeName: 'Store C',
          ),
        ];

        await scheduler.scheduleForAll(receipts);

        // Each receipt should have had cancelReminder called, then 3 scheduled.
        expect(mockService.cancelledIds, hasLength(3));
        expect(mockService.scheduledReminders, hasLength(9));

        // Verify each receipt has exactly 3 reminders.
        for (final id in ['r1', 'r2', 'r3']) {
          final reminders = mockService.scheduledReminders
              .where((r) => r.receiptId == id)
              .toList();
          expect(reminders, hasLength(3),
              reason: 'Receipt $id should have 3 reminders');
        }
      });
    });
  });
}
