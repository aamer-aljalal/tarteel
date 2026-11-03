import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/features/quran/khatma/services/khatma_service.dart';

class InAppNotification {
  final String id;
  final String title;
  final String body;
  final String
  type; // 'surah_kahf', 'morning_azkar', 'evening_azkar', 'sleep_azkar', 'duha', 'qiyam', 'fasting', 'dhikr', 'daily_content', 'khatma'
  final IconData icon;
  final Color color;
  final DateTime triggerTime;

  InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.icon,
    required this.color,
    required this.triggerTime,
  });
}

class InAppNotificationService {
  static Future<List<InAppNotification>> getActiveNotifications() async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month}-${now.day}';
    final prefs = await SharedPreferences.getInstance();
    final List<InAppNotification> list = [];

    // Helper to check if a specific notification has been completed today
    bool isCompleted(String keySuffix) {
      return prefs.getBool('completed_${keySuffix}_$dateStr') ?? false;
    }

    // ==================== 1. Morning Azkar ====================
    if (prefs.getBool('notifications_azkar') ?? true) {
      final morningTime = DateTime(now.year, now.month, now.day, 5, 0);
      if (now.isAfter(morningTime) && !isCompleted('azkar_أذكار الصباح')) {
        list.add(
          InAppNotification(
            id: 'morning_azkar',
            title: 'أذكار الصباح',
            body:
                '«أصبحنا وأصبح الملك لله».. حان وقت أذكار الصباح المأثورة لتنير يومك.',
            type: 'morning_azkar',
            icon: Icons.light_mode_outlined,
            color: Colors.amber.shade700,
            triggerTime: morningTime,
          ),
        );
      }
    }

    // ==================== 2. Evening Azkar ====================
    if (prefs.getBool('notifications_azkar') ?? true) {
      final eveningTime = DateTime(now.year, now.month, now.day, 15, 30);
      if (now.isAfter(eveningTime) && !isCompleted('azkar_أذكار المساء')) {
        list.add(
          InAppNotification(
            id: 'evening_azkar',
            title: 'أذكار المساء',
            body:
                '«أمسينا وأمسى الملك لله».. حان وقت أذكار المساء لتحفظك وتحرسك.',
            type: 'evening_azkar',
            icon: Icons.dark_mode_outlined,
            color: Colors.indigo.shade700,
            triggerTime: eveningTime,
          ),
        );
      }
    }

    // ==================== 3. Sleep Azkar ====================
    if (prefs.getBool('notifications_azkar') ?? true) {
      final sleepTime = DateTime(now.year, now.month, now.day, 21, 0);
      if ((now.hour >= 21 || now.hour < 4) &&
          !isCompleted('azkar_أذكار النوم')) {
        list.add(
          InAppNotification(
            id: 'sleep_azkar',
            title: 'أذكار النوم وآدابه',
            body:
                'تحصن بآية الكرسي والمعوذات واقرأ أذكار النوم لنوم هادئ وحفظ رباني.',
            type: 'sleep_azkar',
            icon: Icons.bedtime_outlined,
            color: Colors.purple.shade700,
            triggerTime: sleepTime,
          ),
        );
      }
    }

    // ==================== 4. Friday Surah Al-Kahf ====================
    if (prefs.getBool('notifications_friday') ?? true) {
      if (now.weekday == DateTime.friday) {
        final fridayTime = DateTime(now.year, now.month, now.day, 6, 0);
        if (now.isAfter(fridayTime) && !isCompleted('kahf')) {
          list.add(
            InAppNotification(
              id: 'surah_kahf',
              title: 'سورة الكهف نور الجمعة',
              body:
                  'تنبيه فائت: لا تنسَ سنن الجمعة وقراءة سورة الكهف لنور يضيء لك ما بين الجمعتين.',
              type: 'surah_kahf',
              icon: Icons.menu_book_outlined,
              color: Colors.green.shade700,
              triggerTime: fridayTime,
            ),
          );
        }
      }
    }

    // // ==================== 5. Fasting Monday & Thursday ====================
    // if (prefs.getBool('notifications_fasting') ?? true) {
    //   if (now.weekday == DateTime.monday && now.hour < 19 && !isCompleted('fasting_monday')) {
    //     list.add(InAppNotification(
    //       id: 'fasting_monday',
    //       title: 'صيام الاثنين اليوم',
    //       body: 'صيام يوم في سبيل الله يباعد وجهك عن النار سبعين خريفاً.. صياماً مقبولاً إن شاء الله.',
    //       type: 'fasting',
    //       icon: Icons.restaurant_menu_outlined,
    //       color: Colors.deepOrange.shade700,
    //       triggerTime: DateTime(now.year, now.month, now.day, 5, 0),
    //     ));
    //   } else if (now.weekday == DateTime.thursday && now.hour < 19 && !isCompleted('fasting_thursday')) {
    //     list.add(InAppNotification(
    //       id: 'fasting_thursday',
    //       title: 'صيام الخميس اليوم',
    //       body: 'تُرفع الأعمال اليوم الخميس.. فكن من الصائمين لتنال أجر صيام التطوع والسنن المأثورة.',
    //       type: 'fasting',
    //       icon: Icons.restaurant_menu_outlined,
    //       color: Colors.deepOrange.shade700,
    //       triggerTime: DateTime(now.year, now.month, now.day, 5, 0),
    //     ));
    //   }
    // }

    // // ==================== 6. Duha Prayer ====================
    // if (prefs.getBool('notifications_duha') ?? true) {
    //   final duhaStart = DateTime(now.year, now.month, now.day, 7, 30);
    //   final duhaEnd = DateTime(now.year, now.month, now.day, 12, 30);
    //   if (now.isAfter(duhaStart) && now.isBefore(duhaEnd) && !isCompleted('duha')) {
    //     list.add(InAppNotification(
    //       id: 'duha',
    //       title: 'صلاة الضحى صلاة الأوابين',
    //       body: 'حان وقت صلاة الضحى، تصدق عن مفاصل بدنك بركعتين لا تحرم نفسك أجرها الوفير.',
    //       type: 'duha',
    //       icon: Icons.wb_sunny_outlined,
    //       color: Colors.orange.shade700,
    //       triggerTime: duhaStart,
    //     ));
    //   }
    // }

    // // ==================== 7. Qiyam Al-Layl ====================
    // if (prefs.getBool('notifications_qiyam') ?? true) {
    //   if ((now.hour >= 21 || now.hour < 5) && !isCompleted('qiyam')) {
    //     list.add(InAppNotification(
    //       id: 'qiyam',
    //       title: 'قيام الليل والوتر',
    //       body: 'شرف المؤمن قيام الليل، ادعُ ربك واستغفر في الثلث الأخير من الليل.',
    //       type: 'qiyam',
    //       icon: Icons.star_border_rounded,
    //       color: Colors.blue.shade700,
    //       triggerTime: DateTime(now.year, now.month, now.day, 21, 30),
    //     ));
    //   }
    // }

    // ==================== 8. Daily Verse & Hadith ====================
    // if (prefs.getBool('notifications_daily_content') ?? true) {
    //   final dailyTime = DateTime(now.year, now.month, now.day, 10, 0);
    //   if (now.isAfter(dailyTime) && !isCompleted('daily_content')) {
    //     list.add(InAppNotification(
    //       id: 'daily_content',
    //       title: 'آية وحديث اليوم',
    //       body: 'تأمل في كلام الله وسنة رسوله المصطفى لتنير يومك وتسعد قلبك.',
    //       type: 'daily_content',
    //       icon: Icons.book_outlined,
    //       color: Colors.brown.shade700,
    //       triggerTime: dailyTime,
    //     ));
    //   }
    // }

    // ==================== 9. Khatma Plan Reminder ====================
    try {
      final plan = await KhatmaService.getActivePlan();
      if (plan != null) {
        final hasCompletedTarget =
            plan.pagesReadToday >= plan.targetPagesPerDay;
        final isKhatmaDone = isCompleted('khatma_daily');
        if (!hasCompletedTarget && !isKhatmaDone) {
          final remaining = plan.targetPagesPerDay - plan.pagesReadToday;
          list.add(
            InAppNotification(
              id: 'khatma_daily',
              title: 'ورد الختمة اليومي',
              body:
                  'متبقي لك $remaining ${remaining == 1 ? 'صفحة' : 'صفحات'} لإتمام وردك اليومي ومواصلة سلسلة التزامك المباركة.',
              type: 'khatma',
              icon: Icons.auto_stories_rounded,
              color: Colors.teal.shade700,
              triggerTime: DateTime(
                now.year,
                now.month,
                now.day,
                plan.reminderHour,
                plan.reminderMinute,
              ),
            ),
          );
        }
      }
    } catch (_) {}

    // Sort by trigger time descending so latest shows first
    list.sort((a, b) => b.triggerTime.compareTo(a.triggerTime));
    return list;
  }

  static Future<void> markCompleted(String type) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month}-${now.day}';
    final prefs = await SharedPreferences.getInstance();

    if (type == 'surah_kahf') {
      await prefs.setBool('completed_kahf_$dateStr', true);
    } else if (type == 'morning_azkar') {
      await prefs.setBool('completed_azkar_أذكار الصباح_$dateStr', true);
    } else if (type == 'evening_azkar') {
      await prefs.setBool('completed_azkar_أذكار المساء_$dateStr', true);
    } else if (type == 'sleep_azkar') {
      await prefs.setBool('completed_azkar_أذكار النوم_$dateStr', true);
    } else if (type == 'duha') {
      await prefs.setBool('completed_duha_$dateStr', true);
    } else if (type == 'qiyam') {
      await prefs.setBool('completed_qiyam_$dateStr', true);
    } else if (type == 'daily_content') {
      await prefs.setBool('completed_daily_content_$dateStr', true);
    } else if (type == 'khatma') {
      await prefs.setBool('completed_khatma_daily_$dateStr', true);
    } else if (type == 'fasting') {
      if (now.weekday == DateTime.monday) {
        await prefs.setBool('completed_fasting_monday_$dateStr', true);
      } else if (now.weekday == DateTime.thursday) {
        await prefs.setBool('completed_fasting_thursday_$dateStr', true);
      }
    }
  }
}
