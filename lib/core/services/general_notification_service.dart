import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';
import 'package:tarteel/features/quran/views/surah_detail_page.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/azkar/zkar_details.dart';
import 'package:tarteel/features/azkar/services/azkar_service.dart';
import 'package:tarteel/main.dart';

class GeneralNotificationService {
  GeneralNotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Notification IDs
  static const int idMorningAzkar = 8000;
  static const int idEveningAzkar = 8001;
  static const int idSleepAzkar = 8002;
  static const int idFridayKahf = 8003;
  static const int idFastingMonday = 8004;
  static const int idFastingThursday = 8005;
  static const int idDuha = 8006;
  static const int idQiyam = 8007;
  static const int idDailyContent = 8008;
  static const int idKhatmaReminder = 8020;
  static const List<int> idsKhatmaPrayers = [8021, 8022, 8023, 8024, 8025];

  // Legacy Periodic Dhikr IDs
  static const List<int> idsPeriodicDhikr = [8009, 8010, 8011, 8012, 8013, 8014];

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _notifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          final payload = response.payload;
          if (payload == null) return;

          if (payload == 'surah_kahf') {
            try {
              final surahs = await QuranService.loadSurahs();
              final kahfSurah = surahs.firstWhere((s) => s.number == 18);
              final ayahs = await QuranService.loadAyahs(18);

              tarteel.navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => SurahDetailPage(
                    surah: kahfSurah,
                    ayahs: ayahs,
                  ),
                ),
              );
            } catch (e) {
              debugPrint('Error navigating to Surah Al-Kahf: $e');
            }
          } else if (payload.startsWith('azkar_')) {
            try {
              final targetTitle = payload.substring(6);
              final categories = await AzkarService.loadAzkar();
              final match = categories.firstWhere(
                (c) => c.title == targetTitle,
              );

              tarteel.navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => AzkarDetailsScreen(category: match),
                ),
              );
            } catch (e) {
              debugPrint('Error navigating to Azkar: $e');
            }
          } else if (payload == 'khatma_planner') {
            try {
              final prefs = await SharedPreferences.getInstance();
              final khatmaSurah = prefs.getInt('khatma_last_read_surah');
              final khatmaAyah = prefs.getInt('khatma_last_read_ayah');
              
              if (khatmaSurah != null) {
                final surahs = await QuranService.loadSurahs();
                final surah = surahs.firstWhere((s) => s.number == khatmaSurah);
                final ayahs = await QuranService.loadAyahs(khatmaSurah);

                tarteel.navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => SurahDetailPage(
                      surah: surah,
                      ayahs: ayahs,
                      initialAyah: khatmaAyah,
                      isKhatmaSession: true,
                    ),
                  ),
                );
              } else {
                tarteel.navigatorKey.currentState?.pushNamed('/khatma-planner');
              }
            } catch (e) {
              debugPrint('Error navigating to Quran from Khatma notification: $e');
              tarteel.navigatorKey.currentState?.pushNamed('/khatma-planner');
            }
          }
        },
      );
    } catch (_) {}

    _initialized = true;
  }

  static Future<void> _configureLocalTimezone() async {
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    }
  }

  /// Master method to schedule all enabled notifications on startup
  static Future<void> scheduleAllEnabledNotifications() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();

    // 1. Cancel deleted legacy notifications
    await _notifications.cancel(id: idSleepAzkar);
    await _notifications.cancel(id: idFastingMonday);
    await _notifications.cancel(id: idFastingThursday);
    await _notifications.cancel(id: idDuha);
    await _notifications.cancel(id: idQiyam);
    await _notifications.cancel(id: idDailyContent);
    for (final id in idsPeriodicDhikr) {
      await _notifications.cancel(id: id);
    }

    // 2. Azkar (Morning, Evening)
    if (prefs.getBool('notifications_azkar') ?? true) {
      await scheduleAzkarNotifications();
    } else {
      await cancelAzkarNotifications();
    }

    // 3. Friday Reminder
    if (prefs.getBool('notifications_friday') ?? true) {
      await scheduleFridayReminder();
    } else {
      await _notifications.cancel(id: idFridayKahf);
    }
  }

  // ==================== 1. Azkar Reminders ====================

  static Future<void> scheduleAzkarNotifications() async {
    await cancelAzkarNotifications();

    const androidDetails = AndroidNotificationDetails(
      'azkar_reminders_channel',
      'تذكيرات الأذكار والسنن',
      channelDescription: 'تنبيهات يومية لقراءة أذكار الصباح والمساء',
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

    // Morning Azkar (7:00 AM)
    await _scheduleDailyTime(
      id: idMorningAzkar,
      title: 'أذكار الصباح',
      body: '«أصبحنا وأصبح الملك لله».. حان وقت أذكار الصباح المأثورة لتنير يومك وتصون عملك.',
      hour: 7,
      minute: 0,
      details: const NotificationDetails(android: androidDetails, iOS: darwinDetails),
      payload: 'azkar_أذكار الصباح',
    );

    // Evening Azkar (5:00 PM)
    await _scheduleDailyTime(
      id: idEveningAzkar,
      title: 'أذكار المساء',
      body: '«أمسينا وأمسى الملك لله».. حان وقت أذكار المساء لتحفظك وتحرسك حتى تصبح.',
      hour: 17,
      minute: 0,
      details: const NotificationDetails(android: androidDetails, iOS: darwinDetails),
      payload: 'azkar_أذكار المساء',
    );
  }

  static Future<void> cancelAzkarNotifications() async {
    await _notifications.cancel(id: idMorningAzkar);
    await _notifications.cancel(id: idEveningAzkar);
    await _notifications.cancel(id: idSleepAzkar);
  }

  // ==================== 2. Friday Kahf ====================

  static Future<void> scheduleFridayReminder() async {
    await _notifications.cancel(id: idFridayKahf);

    const androidDetails = AndroidNotificationDetails(
      'friday_channel',
      'تنبيهات يوم الجمعة',
      channelDescription: 'تذكير بقراءة سورة الكهف والسنن والصلاة على النبي',
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

    await _scheduleWeeklyDayAndTime(
      id: idFridayKahf,
      title: 'جمعة مباركة عامرة بالذكر',
      body: 'لا تنسَ سنن الجمعة: قراءة سورة الكهف لنور ما بين الجمعتين، الصلاة على النبي وكثرة الدعاء.',
      dayOfWeek: DateTime.friday,
      hour: 9,
      minute: 0,
      details: const NotificationDetails(android: androidDetails, iOS: darwinDetails),
      payload: 'surah_kahf',
    );
  }

  // ==================== Helper Core Methods ====================

  static Future<void> _scheduleDailyTime({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required NotificationDetails details,
    String? payload,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (_) {}
  }

  static Future<void> _scheduleWeeklyDayAndTime({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
    required NotificationDetails details,
    String? payload,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Roll forward to find the matching weekday
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If it's the target day but the time has already passed today, push it to next week
    if (scheduledDate.weekday == dayOfWeek && scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
    } catch (_) {}
  }

  static Future<void> scheduleKhatmaReminder(int hour, int minute) async {
    await initialize();
    await cancelKhatmaReminder();

    const androidDetails = AndroidNotificationDetails(
      'khatma_reminders_channel',
      'تذكير الورد اليومي',
      channelDescription: 'تنبيهات يومية لتذكيرك بقراءة وردك اليومي المخطط له',
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

    await _scheduleDailyTime(
      id: idKhatmaReminder,
      title: 'وردك اليومي من القرآن',
      body: 'حان وقت قراءة وردك اليومي المخطط له لختم كتاب الله. انقر للبدء بالقراءة والمتابعة.',
      hour: hour,
      minute: minute,
      details: const NotificationDetails(android: androidDetails, iOS: darwinDetails),
      payload: 'khatma_planner',
    );
  }

  static Future<void> scheduleKhatmaPrayerReminders() async {
    await initialize();
    await cancelKhatmaReminder();

    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('prayer_lat') ?? 21.4225;
      final lng = prefs.getDouble('prayer_lng') ?? 39.8262;
      final calcMethodIndex = prefs.getInt('prayer_calc_method_index');

      final calculationMethod = (calcMethodIndex != null &&
              calcMethodIndex >= 0 &&
              calcMethodIndex < CalculationMethod.values.length)
          ? CalculationMethod.values[calcMethodIndex]
          : CalculationMethod.umm_al_qura;

      final coordinates = Coordinates(lat, lng);
      final params = calculationMethod.getParameters();
      final prayerTimes = PrayerTimes.today(coordinates, params);

      const androidDetails = AndroidNotificationDetails(
        'khatma_reminders_channel',
        'تذكير ورد الصلوات',
        channelDescription: 'تنبيهات في رحاب الصلوات الخمس لتذكيرك بقراءة وردك القرآني',
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

      final prayers = [
        {'id': idsKhatmaPrayers[0], 'name': 'الفجر', 'time': prayerTimes.fajr},
        {'id': idsKhatmaPrayers[1], 'name': 'الظهر', 'time': prayerTimes.dhuhr},
        {'id': idsKhatmaPrayers[2], 'name': 'العصر', 'time': prayerTimes.asr},
        {'id': idsKhatmaPrayers[3], 'name': 'المغرب', 'time': prayerTimes.maghrib},
        {'id': idsKhatmaPrayers[4], 'name': 'العشاء', 'time': prayerTimes.isha},
      ];

      for (final p in prayers) {
        final prayerTime = p['time'] as DateTime;
        final reminderTime = prayerTime.add(const Duration(minutes: 15));

        await _scheduleDailyTime(
          id: p['id'] as int,
          title: 'ورد القرآن - بعد صلاة ${p['name']}',
          body: 'تقبل الله صلاتك. حان وقت قراءة وردك في رحاب صلاة ${p['name']}.',
          hour: reminderTime.hour,
          minute: reminderTime.minute,
          details: const NotificationDetails(android: androidDetails, iOS: darwinDetails),
          payload: 'khatma_planner',
        );
      }
    } catch (e) {
      debugPrint('Error scheduling Khatma prayer reminders: $e');
    }
  }

  static Future<void> cancelKhatmaReminder() async {
    await initialize();
    await _notifications.cancel(id: idKhatmaReminder);
    for (final id in idsKhatmaPrayers) {
      await _notifications.cancel(id: id);
    }
  }
}
