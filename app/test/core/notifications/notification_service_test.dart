import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/notifications/mock_notification_service.dart';
import 'package:warrantyvault/core/notifications/notification_service.dart';

void main() {
  late MockNotificationService service;

  setUp(() {
    service = MockNotificationService();
  });

  group('MockNotificationService', () {
    test('implements NotificationService interface', () {
      expect(service, isA<NotificationService>());
    });

    // ---------------------------------------------------------------
    // 1. initialize sets initialized flag
    // ---------------------------------------------------------------
    test('initialize() sets initialized flag to true', () async {
      expect(service.initialized, isFalse);

      await service.initialize();

      expect(service.initialized, isTrue);
    });

    test('initialize() can be called multiple times without error', () async {
      await service.initialize();
      await service.initialize();

      expect(service.initialized, isTrue);
    });

    // ---------------------------------------------------------------
    // 2. scheduleWarrantyReminder adds to scheduledReminders list
    // ---------------------------------------------------------------
    test('scheduleWarrantyReminder() adds reminder to scheduledReminders',
        () async {
      final expiryDate = DateTime(2027, 6, 15);

      await service.scheduleWarrantyReminder(
        receiptId: 'receipt-001',
        storeName: 'Best Buy',
        expiryDate: expiryDate,
        daysBefore: 7,
      );

      expect(service.scheduledReminders, hasLength(1));

      final reminder = service.scheduledReminders.first;
      expect(reminder.receiptId, 'receipt-001');
      expect(reminder.storeName, 'Best Buy');
      expect(reminder.expiryDate, expiryDate);
      expect(reminder.daysBefore, 7);
    });

    test('scheduleWarrantyReminder() accumulates multiple reminders', () async {
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store A',
        expiryDate: DateTime(2027, 3, 1),
        daysBefore: 30,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r2',
        storeName: 'Store B',
        expiryDate: DateTime(2027, 6, 15),
        daysBefore: 7,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store A',
        expiryDate: DateTime(2027, 3, 1),
        daysBefore: 1,
      );

      expect(service.scheduledReminders, hasLength(3));
      expect(
        service.scheduledReminders.where((r) => r.receiptId == 'r1'),
        hasLength(2),
      );
      expect(
        service.scheduledReminders.where((r) => r.receiptId == 'r2'),
        hasLength(1),
      );
    });

    // ---------------------------------------------------------------
    // 3. scheduleWarrantyReminder with optional title/body params
    // ---------------------------------------------------------------
    test('scheduleWarrantyReminder() accepts optional title and body params',
        () async {
      // The mock service accepts title/body per the interface but does not
      // store them in MockScheduledReminder. We verify the call succeeds
      // and the reminder is recorded.
      final expiryDate = DateTime(2027, 12, 25);

      await service.scheduleWarrantyReminder(
        receiptId: 'r-custom',
        storeName: 'Custom Store',
        expiryDate: expiryDate,
        daysBefore: 14,
        title: 'Warranty expiring soon!',
        body: 'Your warranty for Custom Store expires in 14 days.',
      );

      expect(service.scheduledReminders, hasLength(1));
      expect(service.scheduledReminders.first.receiptId, 'r-custom');
      expect(service.scheduledReminders.first.storeName, 'Custom Store');
      expect(service.scheduledReminders.first.daysBefore, 14);
    });

    test('scheduleWarrantyReminder() works without optional title and body',
        () async {
      await service.scheduleWarrantyReminder(
        receiptId: 'r-no-title',
        storeName: 'Store',
        expiryDate: DateTime(2027, 1, 1),
        daysBefore: 0,
      );

      expect(service.scheduledReminders, hasLength(1));
      expect(service.scheduledReminders.first.receiptId, 'r-no-title');
    });

    // ---------------------------------------------------------------
    // 4. cancelReminder removes by receiptId
    // ---------------------------------------------------------------
    test('cancelReminder() removes all reminders matching the receiptId',
        () async {
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store A',
        expiryDate: DateTime(2027, 6, 15),
        daysBefore: 7,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store A',
        expiryDate: DateTime(2027, 6, 15),
        daysBefore: 1,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r2',
        storeName: 'Store B',
        expiryDate: DateTime(2027, 8, 20),
        daysBefore: 3,
      );

      await service.cancelReminder('r1');

      expect(service.cancelledIds, contains('r1'));
      expect(
        service.scheduledReminders.where((r) => r.receiptId == 'r1'),
        isEmpty,
      );
      // r2 should still be present
      expect(
        service.scheduledReminders.where((r) => r.receiptId == 'r2'),
        hasLength(1),
      );
    });

    test('cancelReminder() records receiptId in cancelledIds', () async {
      await service.cancelReminder('nonexistent-id');

      expect(service.cancelledIds, contains('nonexistent-id'));
      expect(service.scheduledReminders, isEmpty);
    });

    // ---------------------------------------------------------------
    // 5. cancelAllReminders clears all
    // ---------------------------------------------------------------
    test('cancelAllReminders() clears all reminders and sets flag', () async {
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store A',
        expiryDate: DateTime(2027, 6, 15),
        daysBefore: 7,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r2',
        storeName: 'Store B',
        expiryDate: DateTime(2027, 8, 20),
        daysBefore: 1,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r3',
        storeName: 'Store C',
        expiryDate: DateTime(2027, 12, 1),
        daysBefore: 14,
      );

      expect(service.allCancelled, isFalse);

      await service.cancelAllReminders();

      expect(service.allCancelled, isTrue);
      expect(service.scheduledReminders, isEmpty);
    });

    test('cancelAllReminders() works when no reminders are scheduled',
        () async {
      expect(service.scheduledReminders, isEmpty);

      await service.cancelAllReminders();

      expect(service.allCancelled, isTrue);
      expect(service.scheduledReminders, isEmpty);
    });

    // ---------------------------------------------------------------
    // 6. Multiple schedules + selective cancel
    // ---------------------------------------------------------------
    test('selective cancel leaves other receipts intact', () async {
      final dates = [
        DateTime(2027, 3, 1),
        DateTime(2027, 6, 15),
        DateTime(2027, 9, 30),
      ];

      // Schedule reminders for three different receipts
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Alpha Store',
        expiryDate: dates[0],
        daysBefore: 30,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r2',
        storeName: 'Beta Store',
        expiryDate: dates[1],
        daysBefore: 7,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r3',
        storeName: 'Gamma Store',
        expiryDate: dates[2],
        daysBefore: 1,
      );

      expect(service.scheduledReminders, hasLength(3));

      // Cancel only r2
      await service.cancelReminder('r2');

      expect(service.scheduledReminders, hasLength(2));
      expect(
        service.scheduledReminders.map((r) => r.receiptId),
        containsAll(['r1', 'r3']),
      );
      expect(
        service.scheduledReminders.map((r) => r.receiptId),
        isNot(contains('r2')),
      );
    });

    test('scheduling multiple reminders for same receiptId then cancelling '
        'removes all of them', () async {
      final expiryDate = DateTime(2027, 6, 15);

      // Schedule 3 reminders for the same receipt (different daysBefore)
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store',
        expiryDate: expiryDate,
        daysBefore: 30,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store',
        expiryDate: expiryDate,
        daysBefore: 7,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store',
        expiryDate: expiryDate,
        daysBefore: 1,
      );

      expect(service.scheduledReminders, hasLength(3));

      await service.cancelReminder('r1');

      expect(service.scheduledReminders, isEmpty);
    });

    // ---------------------------------------------------------------
    // 7. Cancel then schedule again
    // ---------------------------------------------------------------
    test('can schedule new reminders after cancelling', () async {
      final expiryDate = DateTime(2027, 6, 15);

      // Schedule and then cancel
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store A',
        expiryDate: expiryDate,
        daysBefore: 7,
      );
      await service.cancelReminder('r1');

      expect(service.scheduledReminders, isEmpty);
      expect(service.cancelledIds, contains('r1'));

      // Schedule again for the same receipt
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store A',
        expiryDate: expiryDate,
        daysBefore: 3,
      );

      expect(service.scheduledReminders, hasLength(1));
      expect(service.scheduledReminders.first.receiptId, 'r1');
      expect(service.scheduledReminders.first.daysBefore, 3);
    });

    test('can schedule after cancelAllReminders', () async {
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store A',
        expiryDate: DateTime(2027, 6, 15),
        daysBefore: 7,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r2',
        storeName: 'Store B',
        expiryDate: DateTime(2027, 8, 20),
        daysBefore: 1,
      );

      await service.cancelAllReminders();
      expect(service.scheduledReminders, isEmpty);
      expect(service.allCancelled, isTrue);

      // Schedule fresh reminders
      await service.scheduleWarrantyReminder(
        receiptId: 'r3',
        storeName: 'Store C',
        expiryDate: DateTime(2028, 1, 1),
        daysBefore: 14,
      );

      expect(service.scheduledReminders, hasLength(1));
      expect(service.scheduledReminders.first.receiptId, 'r3');
    });
  });

  group('MockScheduledReminder', () {
    test('toString() returns a readable representation', () {
      final reminder = MockScheduledReminder(
        receiptId: 'r1',
        storeName: 'Test Store',
        expiryDate: DateTime(2027, 6, 15),
        daysBefore: 7,
      );

      final str = reminder.toString();

      expect(str, contains('r1'));
      expect(str, contains('Test Store'));
      expect(str, contains('7'));
    });
  });
}
