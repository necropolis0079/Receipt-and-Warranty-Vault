import 'package:flutter_test/flutter_test.dart';
import 'package:warrantyvault/core/notifications/mock_notification_service.dart';
import 'package:warrantyvault/core/notifications/notification_service.dart';

void main() {
  late MockNotificationService service;

  setUp(() {
    service = MockNotificationService();
  });

  group('MockNotificationService', () {
    test('implements NotificationService', () {
      expect(service, isA<NotificationService>());
    });

    test('initialize() sets initialized flag', () async {
      expect(service.initialized, isFalse);

      await service.initialize();

      expect(service.initialized, isTrue);
    });

    test('scheduleWarrantyReminder() adds to scheduledReminders list',
        () async {
      final expiryDate = DateTime(2027, 6, 15);

      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Test Store',
        expiryDate: expiryDate,
        daysBefore: 7,
      );

      expect(service.scheduledReminders, hasLength(1));
      expect(service.scheduledReminders.first.receiptId, 'r1');
      expect(service.scheduledReminders.first.storeName, 'Test Store');
      expect(service.scheduledReminders.first.expiryDate, expiryDate);
      expect(service.scheduledReminders.first.daysBefore, 7);
    });

    test('cancelReminder() adds to cancelledIds list', () async {
      // Schedule a reminder first so we can verify it gets removed.
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Test Store',
        expiryDate: DateTime(2027, 6, 15),
        daysBefore: 7,
      );

      await service.cancelReminder('r1');

      expect(service.cancelledIds, contains('r1'));
      expect(
        service.scheduledReminders.where((r) => r.receiptId == 'r1'),
        isEmpty,
      );
    });

    test(
        'cancelAllReminders() sets allCancelled flag and clears '
        'scheduledReminders', () async {
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

      expect(service.allCancelled, isFalse);

      await service.cancelAllReminders();

      expect(service.allCancelled, isTrue);
      expect(service.scheduledReminders, isEmpty);
    });

    test('multiple schedules accumulate correctly', () async {
      final expiryDate = DateTime(2027, 6, 15);

      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store A',
        expiryDate: expiryDate,
        daysBefore: 7,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store A',
        expiryDate: expiryDate,
        daysBefore: 1,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r2',
        storeName: 'Store B',
        expiryDate: DateTime(2027, 12, 1),
        daysBefore: 0,
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

    test('cancel then schedule creates fresh state', () async {
      final expiryDate = DateTime(2027, 6, 15);

      // Schedule initial reminders.
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store A',
        expiryDate: expiryDate,
        daysBefore: 7,
      );
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store A',
        expiryDate: expiryDate,
        daysBefore: 1,
      );
      expect(service.scheduledReminders, hasLength(2));

      // Cancel all reminders for r1.
      await service.cancelReminder('r1');
      expect(service.scheduledReminders, isEmpty);
      expect(service.cancelledIds, contains('r1'));

      // Schedule a new reminder for the same receipt.
      await service.scheduleWarrantyReminder(
        receiptId: 'r1',
        storeName: 'Store A',
        expiryDate: expiryDate,
        daysBefore: 0,
      );

      expect(service.scheduledReminders, hasLength(1));
      expect(service.scheduledReminders.first.daysBefore, 0);
    });
  });
}
