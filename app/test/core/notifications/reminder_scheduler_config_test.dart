import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/database/app_database.dart';
import 'package:warrantyvault/core/notifications/mock_notification_service.dart';
import 'package:warrantyvault/core/notifications/reminder_scheduler.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';

void main() {
  late MockNotificationService mockService;
  late ReminderScheduler scheduler;
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockService = MockNotificationService();
    scheduler = ReminderScheduler(
      notificationService: mockService,
      settingsDao: db.settingsDao,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Receipt createReceipt({
    String receiptId = 'test-id',
    int warrantyMonths = 12,
  }) {
    return Receipt(
      receiptId: receiptId,
      userId: 'user-1',
      storeName: 'Test Store',
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      warrantyMonths: warrantyMonths,
      warrantyExpiryDate: DateTime.now()
          .add(const Duration(days: 180))
          .toIso8601String(),
    );
  }

  group('ReminderScheduler — configurable intervals', () {
    group('getIntervals', () {
      test('returns default intervals when no custom value saved', () async {
        final intervals = await scheduler.getIntervals();
        expect(intervals, equals([7, 1, 0]));
      });

      test('returns saved intervals when set', () async {
        await scheduler.saveIntervals([30, 7, 0]);
        final intervals = await scheduler.getIntervals();
        expect(intervals, equals([30, 7, 0]));
      });

      test('returns defaults for malformed JSON', () async {
        await db.settingsDao.setValue('reminder_intervals', 'not-json');
        final intervals = await scheduler.getIntervals();
        expect(intervals, equals([7, 1, 0]));
      });
    });

    group('saveIntervals', () {
      test('saves and retrieves custom intervals', () async {
        await scheduler.saveIntervals([14, 3, 1]);
        final intervals = await scheduler.getIntervals();
        expect(intervals, equals([14, 3, 1]));
      });

      test('sorts intervals in descending order', () async {
        await scheduler.saveIntervals([0, 3, 14]);
        final intervals = await scheduler.getIntervals();
        expect(intervals, equals([14, 3, 0]));
      });

      test('handles single interval', () async {
        await scheduler.saveIntervals([7]);
        final intervals = await scheduler.getIntervals();
        expect(intervals, equals([7]));
      });

      test('handles empty list', () async {
        await scheduler.saveIntervals([]);
        final intervals = await scheduler.getIntervals();
        expect(intervals, isEmpty);
      });
    });

    group('scheduleForReceipt with custom intervals', () {
      test('uses custom intervals when configured', () async {
        await scheduler.saveIntervals([30, 14]);
        final receipt = createReceipt();
        await scheduler.scheduleForReceipt(receipt);

        expect(mockService.scheduledReminders, hasLength(2));
        final daysBefore = mockService.scheduledReminders
            .map((r) => r.daysBefore)
            .toList();
        expect(daysBefore, containsAll([30, 14]));
      });

      test('uses default intervals when none saved', () async {
        final receipt = createReceipt();
        await scheduler.scheduleForReceipt(receipt);

        expect(mockService.scheduledReminders, hasLength(3));
        final daysBefore = mockService.scheduledReminders
            .map((r) => r.daysBefore)
            .toList();
        expect(daysBefore, containsAll([7, 1, 0]));
      });

      test('changing intervals affects subsequent scheduling', () async {
        final receipt = createReceipt();

        // Schedule with defaults
        await scheduler.scheduleForReceipt(receipt);
        expect(mockService.scheduledReminders, hasLength(3));

        // Change to custom intervals
        await scheduler.saveIntervals([30, 14, 7, 3, 1, 0]);
        await scheduler.scheduleForReceipt(receipt);

        // Should have 6 reminders (cancel + reschedule)
        expect(mockService.scheduledReminders, hasLength(6));
      });
    });
  });
}
