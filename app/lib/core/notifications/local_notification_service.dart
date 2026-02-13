import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';

/// Concrete [NotificationService] backed by [FlutterLocalNotificationsPlugin].
///
/// Creates a high-importance Android channel for warranty reminders and
/// requests alert/badge/sound permissions on iOS. Notifications are
/// scheduled with [zonedSchedule] using [TZDateTime].
class LocalNotificationService implements NotificationService {
  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Android notification channel identifier.
  static const String channelId = 'warranty_reminders';

  /// Android notification channel display name.
  static const String channelName = 'Warranty Reminders';

  /// Android notification channel description.
  static const String channelDescription =
      'Reminders for upcoming warranty expirations';

  /// The standard reminder intervals used by [cancelReminder] to derive
  /// notification IDs for a given receipt.
  static const List<int> _cancelIntervals = [7, 1, 0];

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Create the Android notification channel explicitly so it exists before
    // the first notification is scheduled.
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.high,
          ),
        );
      }
    }
  }

  @override
  Future<void> scheduleWarrantyReminder({
    required String receiptId,
    required String storeName,
    required DateTime expiryDate,
    required int daysBefore,
    String? title,
    String? body,
  }) async {
    final scheduledDate = expiryDate.subtract(Duration(days: daysBefore));
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) return;

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final notificationId = _notificationId(receiptId, daysBefore);

    // Use pre-localized strings if provided, otherwise fall back to English.
    final String resolvedTitle;
    final String resolvedBody;

    if (title != null && body != null) {
      resolvedTitle = title;
      resolvedBody = body;
    } else if (daysBefore == 0) {
      resolvedTitle = 'Warranty expires today';
      resolvedBody = 'The warranty for $storeName expires today.';
    } else if (daysBefore == 1) {
      resolvedTitle = 'Warranty expires tomorrow';
      resolvedBody = 'The warranty for $storeName expires tomorrow.';
    } else {
      resolvedTitle = 'Warranty expiring soon';
      resolvedBody = 'The warranty for $storeName expires in $daysBefore days.';
    }

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      notificationId,
      resolvedTitle,
      resolvedBody,
      tzScheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
      payload: receiptId,
    );
  }

  @override
  Future<void> cancelReminder(String receiptId) async {
    for (final interval in _cancelIntervals) {
      await _plugin.cancel(_notificationId(receiptId, interval));
    }
  }

  @override
  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }

  /// Derive a stable, deterministic notification ID from a receipt ID and a
  /// days-before interval. The ID must be a 32-bit signed integer.
  int _notificationId(String receiptId, int daysBefore) {
    return (receiptId.hashCode ^ daysBefore.hashCode) & 0x7FFFFFFF;
  }
}
