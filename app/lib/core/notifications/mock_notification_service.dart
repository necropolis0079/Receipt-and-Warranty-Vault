import 'notification_service.dart';

/// A scheduled reminder entry stored by [MockNotificationService].
class MockScheduledReminder {
  const MockScheduledReminder({
    required this.receiptId,
    required this.storeName,
    required this.expiryDate,
    required this.daysBefore,
  });

  final String receiptId;
  final String storeName;
  final DateTime expiryDate;
  final int daysBefore;

  @override
  String toString() =>
      'MockScheduledReminder(receiptId: $receiptId, storeName: $storeName, '
      'expiryDate: $expiryDate, daysBefore: $daysBefore)';
}

/// In-memory [NotificationService] for testing.
///
/// Records every scheduled reminder and cancellation so tests can
/// inspect what the app requested without touching platform APIs.
class MockNotificationService implements NotificationService {
  /// All reminders that have been scheduled (and not yet cancelled).
  final List<MockScheduledReminder> scheduledReminders = [];

  /// Receipt IDs for which [cancelReminder] was called.
  final List<String> cancelledIds = [];

  /// Whether [initialize] has been called.
  bool initialized = false;

  /// Whether [cancelAllReminders] has been called.
  bool allCancelled = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> scheduleWarrantyReminder({
    required String receiptId,
    required String storeName,
    required DateTime expiryDate,
    required int daysBefore,
  }) async {
    scheduledReminders.add(
      MockScheduledReminder(
        receiptId: receiptId,
        storeName: storeName,
        expiryDate: expiryDate,
        daysBefore: daysBefore,
      ),
    );
  }

  @override
  Future<void> cancelReminder(String receiptId) async {
    cancelledIds.add(receiptId);
    scheduledReminders.removeWhere((r) => r.receiptId == receiptId);
  }

  @override
  Future<void> cancelAllReminders() async {
    allCancelled = true;
    scheduledReminders.clear();
  }
}
