// ============================================================================
// اسم الملف: adhan_notification_service.dart
// وصف الملف: خدمة جدولة وعرض إشعارات الأذان المحلية عند دخول أوقات الصلوات الخمس.
//            يعتمد الملف على حزمة 'flutter_local_notifications' للتعامل مع نظام
//            التشغيل لجدولة منبهات دقيقة، وتشغيل صوت الأذان المخصص لكل مؤذن
//            حتى لو كان التطبيق مغلقاً أو الهاتف في وضع السبات.
// ============================================================================

import 'package:adhan/adhan.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import 'native_alarm_service.dart';

/// كلاس يمثل بيانات المؤذن (الاسم، المعرف، ومسار ملف الصوت)
class AdhanMuezzin {
  const AdhanMuezzin({
    required this.id,
    required this.name,
    required this.rawResourceName,
    required this.assetPath,
  });

  final String id; // المعرف الفريد للمؤذن (يستخدم في الإعدادات)
  final String name; // الاسم المعروض للمستخدم باللغة العربية
  final String
  rawResourceName; // اسم ملف الصوت بدون صيغة (للاستخدام في نظام أندرويد res/raw)
  final String assetPath; // مسار ملف الصوت في الأصول (للاستخدام داخل التطبيق)
}

/// الخدمة المسؤولة عن إعداد، طلب صلاحيات، وجدولة إشعارات الأذان المحددة بالثانية
class AdhanNotificationService {
  AdhanNotificationService._(); // لمنع إنشاء كائن من هذا الكلاس (Utility Class)

  static const String _selectedMuezzinKey = 'selected_adhan_muezzin';
  static const String _notificationsEnabledKey = 'prayer_notifications_enabled';

  // رقم أساسي تبدأ منه معرفات الإشعارات (ID) لتجنب التداخل مع إشعارات أخرى في التطبيق
  static const int _notificationBaseId = 9000;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _notificationsAvailable = true;

  /// قائمة المؤذنين المتاحين في التطبيق وأسماء ملفاتهم الصوتية
  static const List<AdhanMuezzin> muezzins = [
    AdhanMuezzin(
      id: 'adhan_mevlan_kurtishi',
      name: 'مولانا كورتشي',
      rawResourceName: 'adhan_mevlan_kurtishi',
      assetPath: 'assets/audio/adhan/adhan_mevlan_kurtishi.m4a',
    ),
    AdhanMuezzin(
      id: 'adhan_islam_sobhi',
      name: 'إسلام صبحي',
      rawResourceName: 'adhan_islam_sobhi',
      assetPath: 'assets/audio/adhan/adhan_islam_sobhi.m4a',
    ),
    AdhanMuezzin(
      id: 'adhan_abdul_rahman',
      name: 'عبد الرحمن',
      rawResourceName: 'adhan_abdul_rahman',
      assetPath: 'assets/audio/adhan/adhan_abdul_rahman.m4a',
    ),
    AdhanMuezzin(
      id: 'adhan_mohammad_marwan',
      name: 'محمد مروان',
      rawResourceName: 'adhan_mohammad_marwan',
      assetPath: 'assets/audio/adhan/adhan_mohammad_marwan.m4a',
    ),
    AdhanMuezzin(
      id: 'adhan_nasser_alqatami',
      name: 'ناصر القطامي',
      rawResourceName: 'adhan_nasser_alqatami',
      assetPath: 'assets/audio/adhan/adhan_nasser_alqatami.m4a',
    ),
  ];

  static AdhanMuezzin get defaultMuezzin => muezzins.first;

  /// تهيئة إعدادات الإشعارات وتحديد المنطقة الزمنية عند تشغيل التطبيق
  static Future<void> initialize() async {
    if (_initialized) return;

    // تهيئة مكتبة المناطق الزمنية (Timezone) لضمان دقة مواعيد الجدولة
    tz.initializeTimeZones();
    await _configureLocalTimezone();

    // إعدادات التهيئة الخاصة بنظام الأندرويد
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    try {
      await _notifications.initialize(settings: initializationSettings);
      await _requestPermissions();
    } on MissingPluginException {
      _notificationsAvailable = false;
    } on PlatformException {
      _notificationsAvailable = false;
    }

    _initialized = true;
  }

  /// تحديد المنطقة الزمنية الحالية للهاتف، مع وضع الرياض كافتراضي في حال الفشل
  static Future<void> _configureLocalTimezone() async {
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } on MissingPluginException {
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    } on PlatformException {
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    }
  }

  /// طلب الأذونات الخاصة بالإشعارات والمنبه الدقيق من نظام تشغيل أندرويد
  static Future<void> _requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // طلب إذن عرض الإشعارات (أندرويد 13+)
    await androidPlugin?.requestNotificationsPermission();

    // طلب إذن جدولة منبهات دقيقة بالثانية (ضروري جداً لتشغيل الأذان في وقته تماماً)
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static const String _advanceTimeKey = 'adhan_advance_minutes';

  /// الحصول على وقت الأذان المسبق بالدقائق (الافتراضي 15 دقيقة)
  static Future<int> getAdhanAdvanceMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_advanceTimeKey) ?? 15;
  }

  /// حفظ وقت الأذان المسبق بالدقائق
  static Future<void> setAdhanAdvanceMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_advanceTimeKey, minutes);
  }

  /// التحقق من حالة تفعيل إشعارات الأذان من إعدادات التطبيق
  static Future<bool> arePrayerNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }

  /// حفظ حالة تفعيل أو إلغاء تفعيل إشعارات الأذان
  static Future<void> setPrayerNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  /// الحصول على المؤذن المختار حالياً من قبل المستخدم
  static Future<AdhanMuezzin> selectedMuezzin() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_selectedMuezzinKey);

    return muezzins.firstWhere(
      (muezzin) => muezzin.id == id,
      orElse: () => defaultMuezzin,
    );
  }

  /// حفظ المؤذن المختار الجديد
  static Future<void> setSelectedMuezzin(AdhanMuezzin muezzin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedMuezzinKey, muezzin.id);
  }

  /// الحصول على مفتاح الذاكرة الخاص بكل صلاة
  static String _prayerEnabledKey(Prayer prayer) {
    return 'adhan_enabled_${prayer.name}';
  }

  /// التحقق مما إذا كان الأذان مفعلاً لصلاة معينة
  static Future<bool> isSinglePrayerAdhanEnabled(Prayer prayer) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prayerEnabledKey(prayer)) ?? true;
  }

  /// حفظ حالة تفعيل أو إلغاء الأذان لصلاة معينة
  static Future<void> setSinglePrayerAdhanEnabled(
    Prayer prayer,
    bool enabled,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prayerEnabledKey(prayer), enabled);
  }

  /// جدولة الإشعارات والمنبهات للصلوات الخمس بناءً على موقع المستخدم
  static Future<void> schedulePrayerAdhan({
    required Coordinates coordinates,
    required CalculationParameters calculationParameters,
  }) async {
    await initialize();
    if (!_notificationsAvailable) return;

    final enabled = await arePrayerNotificationsEnabled();
    final prefs = await SharedPreferences.getInstance();

    final selected = await selectedMuezzin();
    final advanceMinutes = await getAdhanAdvanceMinutes();
    final now = DateTime.now();

    // --- نظام الجدولة الذكي (Smart Scheduling) ---
    // لمنع التطبيق من تكرار جدولة 225 صلاة عند كل فتح للتطبيق، نقوم بصنع "بصمة" للإعدادات
    final enabledPrayersList = <String>[];
    for (final p in [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha]) {
      final isPrayerEnabled = await isSinglePrayerAdhanEnabled(p);
      if (isPrayerEnabled) enabledPrayersList.add(p.name);
    }
    
    final currentSettingsHash = '${coordinates.latitude}_${coordinates.longitude}_${calculationParameters.method}_${selected.id}_${advanceMinutes}_${enabledPrayersList.join('-')}_$enabled';
    final lastSettingsHash = prefs.getString('last_adhan_schedule_hash');
    final lastScheduleTimeMillis = prefs.getInt('last_adhan_schedule_time') ?? 0;
    
    final daysSinceLastSchedule = now.difference(DateTime.fromMillisecondsSinceEpoch(lastScheduleTimeMillis)).inDays;
    
    // إذا كانت الإعدادات متطابقة (الموقع والمؤذن والصلوات)، ولم يمر 10 أيام منذ آخر جدولة، فلا داعي لحذف وجدولة 225 منبه مجدداً
    if (currentSettingsHash == lastSettingsHash && daysSinceLastSchedule < 10) {
      debugPrint('Adhan Schedule is perfectly up to date, skipping heavy scheduling.');
      return; 
    }
    // ----------------------------------------------

    // مسح كافة التنبيهات المجدولة سابقاً لتجنب التكرار والتضارب
    await cancelPrayerAdhan();
    
    if (!enabled) {
      await prefs.setString('last_adhan_schedule_hash', currentSettingsHash);
      return;
    }

    // جدولة الصلوات لمدة 45 يوماً متلفة ومتتابعة للمستقبل (حوالي 225 صلاة) ليعمل الأذان دون توقف حتى لو اغلق التطبيق
    const int totalDaysToSchedule = 45;
    int notificationOffset = 0;

    final prayers = <Prayer>[
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    for (int day = 0; day < totalDaysToSchedule; day++) {
      final targetDate = now.add(Duration(days: day));
      final dayPrayerTimes = PrayerTimes(
        coordinates,
        DateComponents.from(targetDate),
        calculationParameters,
      );

      for (final prayer in prayers) {
        final prayerTime = dayPrayerTimes.timeForPrayer(prayer);
        if (prayerTime == null) continue;

        // حساب وقت الأذان بناءً على التقديم المحدد (15، 10، 5، أو 0 دقيقة)
        final scheduledTime = advanceMinutes > 0
            ? prayerTime.subtract(Duration(minutes: advanceMinutes))
            : prayerTime;

        // نتخطى الصلوات التي مضى موعد تنبيهها بالفعل
        if (scheduledTime.isBefore(now)) continue;

        // نتخطى الصلاة إذا كان الأذان معطلاً لهذه الفريضة المحددة
        final isPrayerEnabled = await isSinglePrayerAdhanEnabled(prayer);
        if (!isPrayerEnabled) continue;

        await _scheduleSingleAdhan(
          id: _notificationBaseId + notificationOffset,
          prayerName: _prayerName(prayer),
          scheduledTime: scheduledTime,
          muezzin: selected,
          advanceMinutes: advanceMinutes,
        );
        notificationOffset++;
      }
    }
    
    // حفظ البصمة ووقت الجدولة بعد نجاح العملية بالكامل
    await prefs.setString('last_adhan_schedule_hash', currentSettingsHash);
    await prefs.setInt('last_adhan_schedule_time', DateTime.now().millisecondsSinceEpoch);
  }

  /// إلغاء كافة إشعارات الأذان المجدولة في النظام
  static Future<void> cancelPrayerAdhan() async {
    if (!_notificationsAvailable) return;

    // مسح نطاق كامل يغطي كافة الـ 300 إشعار المحتمله المجدولة للأذان
    for (var index = 0; index < 300; index++) {
      await _notifications.cancel(id: _notificationBaseId + index);
    }

    // إلغاء كافة المنبهات المجدولة في الأندرويد الأصلي أيضاً
    if (Platform.isAndroid) {
      await NativeAlarmService.cancelAllAlarms();
    }
  }

  /// دالة مخصصة لاختبار المنبه بعد מספר من الثواني بأمان دون تداخل الصلوات
  static Future<void> testScheduleAdhanInSeconds(
    int seconds, {
    String prayerName = 'المغرب',
  }) async {
    final selected = await selectedMuezzin();
    final targetTime = DateTime.now().add(Duration(seconds: seconds));

    final prefs = await SharedPreferences.getInstance();
    final vibrateEnabled = prefs.getBool('adhan_vibration_enabled') ?? true;
    final volumeLevel = prefs.getDouble('adhan_volume') ?? 1.0;

    debugPrint('بدء الجدولة الاختبارية لصلاة $prayerName بعد $seconds ثانية');

    await NativeAlarmService.scheduleAlarm(
      id: 'adhan_test_timer',
      type: 'ADHAN',
      title: 'حان الآن موعد صلاة $prayerName',
      subtitle: 'أذان بصوت المؤذن ${selected.name} (تجريب)',
      audioFile: selected.rawResourceName,
      audioSource: 'RAW_RESOURCE',
      scheduledTime: targetTime,
      vibrate: vibrateEnabled,
      fullScreen: true,
      volume: volumeLevel,
      loopAudio: false,
    );
  }

  /// جدولة إشعار/منبه فردي لصلاة معينة بصوت المؤذن المحدد
  static Future<void> _scheduleSingleAdhan({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required AdhanMuezzin muezzin,
    int advanceMinutes = 0,
  }) async {
    final alarmTitle = advanceMinutes > 0
        ? 'اقترب موعد صلاة $prayerName'
        : 'حان الآن موعد صلاة $prayerName';
    final alarmSubtitle = advanceMinutes > 0
        ? 'أذان بصوت المؤذن ${muezzin.name} (قبل الصلاة بـ $advanceMinutes دقيقة)'
        : 'أذان بصوت المؤذن ${muezzin.name}';

    // 1. جدولة المنبه الأصلي لنظام الأندرويد فوراً (الخدمة الأساسية الحصرية للتطبيق)
    if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      final vibrateEnabled = prefs.getBool('adhan_vibration_enabled') ?? true;
      final volumeLevel = prefs.getDouble('adhan_volume') ?? 1.0;

      final success = await NativeAlarmService.scheduleAlarm(
        id: 'adhan_prayer_$id',
        type: 'ADHAN',
        title: alarmTitle,
        subtitle: alarmSubtitle,
        audioFile: muezzin.rawResourceName,
        audioSource: 'RAW_RESOURCE',
        scheduledTime: scheduledTime,
        vibrate: vibrateEnabled,
        fullScreen: true,
        volume: volumeLevel,
        loopAudio: false,
      );

      if (success) {
        debugPrint(
          'Native Adhan scheduled successfully for $prayerName at $scheduledTime (Advance: $advanceMinutes m)',
        );

        return; // ننهي الدالة لكي لا تتم جدولة إشعار مكرر عبر flutter_local_notifications
      } else {
        debugPrint(
          'Native Adhan scheduling failed for $prayerName, falling back to local notifications',
        );
      }
    }

    // 2. الدعم البديل في حال تعذر تشغيل المنبه الأصلي
    final channelId = 'adhan_${muezzin.rawResourceName}_channel_v4';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'أذان ${muezzin.name}',
      channelDescription: 'تشغيل أذان ${muezzin.name} عند دخول وقت الصلاة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(muezzin.rawResourceName),
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: alarmTitle,
        body: advanceMinutes > 0
            ? 'أذان بصوت ${muezzin.name} قبل الصلاة بـ $advanceMinutes دقيقة'
            : 'الله أكبر',
        scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails: NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Exact alarm scheduling failed, falling back to inexact: $e');
      try {
        await _notifications.zonedSchedule(
          id: id,
          title: 'حان الآن موعد صلاة $prayerName',
          body: 'الله أكبر',
          scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
          notificationDetails: NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (innerError) {
        debugPrint('Fallback notification scheduling failed: $innerError');
      }
    }
  }

  /// ترجمة اسم الصلاة من الكلاس الداخلي إلى اللغة العربية لعرضه للمستخدم
  static String _prayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.none:
        return '';
    }
  }
}
