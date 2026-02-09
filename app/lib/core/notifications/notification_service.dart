/// Abstract notification service for warranty reminders.
///
/// Wraps platform notification APIs so they can be swapped or mocked
/// in tests. All implementations must support scheduling, cancelling,
/// and bulk-cancelling warranty expiry reminders.
abstract class NotificationService {
  /// Initialize the notification subsystem (channels, permissions, timezone).
  Future<void> initialize();

  /// Schedule a single warranty reminder notification.
  ///
  /// [receiptId] — the receipt this reminder belongs to.
  /// [storeName] — displayed in the notification title/body.
  /// [expiryDate] — the warranty expiry date.
  /// [daysBefore] — how many days before [expiryDate] to fire (0 = on the day).
  Future<void> scheduleWarrantyReminder({
    required String receiptId,
    required String storeName,
    required DateTime expiryDate,
    required int daysBefore,
  });

  /// Cancel all scheduled reminders for the given [receiptId].
  Future<void> cancelReminder(String receiptId);

  /// Cancel every scheduled reminder across all receipts.
  Future<void> cancelAllReminders();
}
