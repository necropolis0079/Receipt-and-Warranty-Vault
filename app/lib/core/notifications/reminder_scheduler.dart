import '../../features/receipt/domain/entities/receipt.dart';
import 'notification_service.dart';

/// Computes and schedules warranty reminders for receipts.
///
/// This is a stateless utility. Given one or more [Receipt] objects it
/// schedules local notifications at the [defaultIntervals] (7 days before,
/// 1 day before, and on the expiry day). Reminders that would fire in the
/// past are silently skipped.
class ReminderScheduler {
  /// Creates a [ReminderScheduler] backed by the given [notificationService].
  ReminderScheduler({required NotificationService notificationService})
      : _notificationService = notificationService;

  final NotificationService _notificationService;

  /// The default reminder intervals (days before expiry).
  ///
  /// * `7` — one week before warranty expires.
  /// * `1` — one day before warranty expires.
  /// * `0` — on the day the warranty expires.
  static const List<int> defaultIntervals = [7, 1, 0];

  /// Schedule reminders for a single [receipt].
  ///
  /// Cancels any existing reminders for this receipt first, then schedules
  /// new reminders at each of [defaultIntervals].
  ///
  /// Does nothing if:
  /// * [Receipt.warrantyMonths] is 0 or negative.
  /// * [Receipt.warrantyExpiryDate] is null or cannot be parsed.
  /// * The parsed expiry date is not in the future.
  Future<void> scheduleForReceipt(Receipt receipt) async {
    if (receipt.warrantyMonths <= 0 || receipt.warrantyExpiryDate == null) {
      return;
    }

    final expiryDate = DateTime.tryParse(receipt.warrantyExpiryDate!);
    if (expiryDate == null) return;

    final now = DateTime.now();
    if (!expiryDate.isAfter(now)) return;

    // Cancel previous reminders before scheduling fresh ones.
    await _notificationService.cancelReminder(receipt.receiptId);

    final storeName = receipt.displayName;

    for (final daysBefore in defaultIntervals) {
      final reminderDate = expiryDate.subtract(Duration(days: daysBefore));
      if (reminderDate.isBefore(now)) continue;

      await _notificationService.scheduleWarrantyReminder(
        receiptId: receipt.receiptId,
        storeName: storeName,
        expiryDate: expiryDate,
        daysBefore: daysBefore,
      );
    }
  }

  /// Schedule reminders for every receipt in [receipts] that has an active
  /// warranty.
  ///
  /// Receipts without a valid, future warranty are silently skipped.
  Future<void> scheduleForAll(List<Receipt> receipts) async {
    for (final receipt in receipts) {
      await scheduleForReceipt(receipt);
    }
  }

  /// Cancel all reminders for the receipt identified by [receiptId].
  Future<void> cancelForReceipt(String receiptId) async {
    await _notificationService.cancelReminder(receiptId);
  }
}
