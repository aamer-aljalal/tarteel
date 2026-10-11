import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:tarteel/features/Tasbeeh/models/dhikr_model.dart';

class TasbeehNotificationService {
  TasbeehNotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Schedules or reschedules a daily reminder for the given [dhikr]
  static Future<void> scheduleReminder(DhikrModel dhikr) async {
    if (dhikr.key == null) return;

    // Always cancel any existing reminder first to prevent duplicates
    await cancelReminder(dhikr);

    if (!dhikr.isReminderEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'tasbeeh_reminders_channel',
      'تذكيرات التسبيح والأدعية',
      channelDescription: 'تذكير يومي لقول التسبيح والأدعية المخصصة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      dhikr.reminderHour,
      dhikr.reminderMinute,
    );

    // If the scheduled time has already passed today, schedule it for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final id = dhikr.key.hashCode;

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: 'حان موعد ذكرك اليومي',
        body: dhikr.text,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: darwinDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time, // Daily recurring
      );
    } catch (_) {}
  }

  /// Cancels the reminder for the given [dhikr]
  static Future<void> cancelReminder(DhikrModel dhikr) async {
    if (dhikr.key == null) return;
    final id = dhikr.key.hashCode;
    try {
      await _notifications.cancel(id: id);
    } catch (_) {}
  }
}
