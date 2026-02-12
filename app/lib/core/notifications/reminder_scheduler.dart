import 'dart:convert';

import '../../features/receipt/domain/entities/receipt.dart';
import '../database/daos/settings_dao.dart';
import 'notification_service.dart';

/// Computes and schedules warranty reminders for receipts.
///
/// Intervals are configurable via [SettingsDao]. When no custom intervals
/// have been saved the [defaultIntervals] are used.
class ReminderScheduler {
  /// Creates a [ReminderScheduler] backed by the given [notificationService].
  ReminderScheduler({
    required NotificationService notificationService,
    required SettingsDao settingsDao,
  })  : _notificationService = notificationService,
        _settingsDao = settingsDao;

  final NotificationService _notificationService;
  final SettingsDao _settingsDao;

  /// Key used to persist the user-chosen intervals in [SettingsDao].
  static const String _intervalsKey = 'reminder_intervals';

  /// The default reminder intervals (days before expiry).
  ///
  /// * `7` — one week before warranty expires.
  /// * `1` — one day before warranty expires.
  /// * `0` — on the day the warranty expires.
  static const List<int> defaultIntervals = [7, 1, 0];

  /// Returns the currently configured intervals (user-selected or defaults).
  Future<List<int>> getIntervals() async {
    final json = await _settingsDao.getValue(_intervalsKey);
    if (json == null) return defaultIntervals;
    try {
      final decoded = jsonDecode(json) as List;
      return decoded.cast<int>()..sort((a, b) => b.compareTo(a));
    } catch (_) {
      return defaultIntervals;
    }
  }

  /// Persist user-chosen [intervals] for future scheduling.
  Future<void> saveIntervals(List<int> intervals) async {
    final sorted = List<int>.from(intervals)..sort((a, b) => b.compareTo(a));
    await _settingsDao.setValue(_intervalsKey, jsonEncode(sorted));
  }

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
    final intervals = await getIntervals();

    for (final daysBefore in intervals) {
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
