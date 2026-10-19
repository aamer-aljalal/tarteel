import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/general_notification_service.dart';
import 'package:tarteel/core/services/stats_service.dart';
import '../models/khatma_plan_model.dart';
import '../models/khatma_badge_model.dart';
import '../models/khatma_history_model.dart';

class KhatmaService {
  static const String _activePlanKey = 'khatma_active_plan_v2';
  static const String _badgesKey = 'khatma_badges_v2';
  static const String _historyKey = 'khatma_history_v2';
  static const String _streakKey = 'khatma_reading_streak';
  static const String _streakLastDateKey = 'khatma_streak_last_date';

  /// تحميل الخطة النشطة
  static Future<KhatmaPlanModel?> getActivePlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final jsonStr = prefs.getString(_activePlanKey);
    if (jsonStr == null) {
      // التحقق من وجود خطة قديمة للترقية التلقائية
      return _migrateLegacyPlanIfNeeded(prefs);
    }
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return KhatmaPlanModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// ترقية الخطة القديمة تلقائياً دون فقدان بيانات المستخدم
  static Future<KhatmaPlanModel?> _migrateLegacyPlanIfNeeded(SharedPreferences prefs) async {
    final active = prefs.getBool('khatma_active') ?? false;
    if (!active) return null;

    final days = prefs.getInt('khatma_days') ?? 30;
    final startStr = prefs.getString('khatma_start_date');
    final lastPage = prefs.getInt('khatma_last_read_page') ?? 1;
    final readToday = prefs.getInt('khatma_ayahs_read_today') ?? 0;
    final rHour = prefs.getInt('khatma_reminder_hour') ?? 20;
    final rMin = prefs.getInt('khatma_reminder_minute') ?? 0;

    final targetPages = (604 / days).ceil();
    final migrated = KhatmaPlanModel(
      id: 'khatma_${DateTime.now().millisecondsSinceEpoch}',
      title: 'ختمة المصحف الشريف',
      type: KhatmaPlanType.durationDays,
      targetPagesPerDay: targetPages,
      targetDays: days,
      startDate: startStr != null ? DateTime.parse(startStr) : DateTime.now(),
      currentPage: lastPage.clamp(1, 604),
      pagesReadToday: (readToday / 15).round().clamp(0, 604),
      reminderHour: rHour,
      reminderMinute: rMin,
    );

    await saveActivePlan(migrated);
    return migrated;
  }

  /// حفظ أو تحديث الخطة النشطة
  static Future<void> saveActivePlan(KhatmaPlanModel plan) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(plan.toJson());
    await prefs.setString(_activePlanKey, jsonStr);

    // الحفاظ على مفاتيح التوافق القديمة للشاشات والإشعارات
    await prefs.setBool('khatma_active', !plan.isCompleted);
    await prefs.setInt('khatma_days', plan.targetDays);
    await prefs.setInt('khatma_last_read_page', plan.currentPage);
    await prefs.setInt('khatma_reminder_hour', plan.reminderHour);
    await prefs.setInt('khatma_reminder_minute', plan.reminderMinute);
  }

  /// إنشاء خطة جديدة
  static Future<KhatmaPlanModel> createPlan({
    required String title,
    required KhatmaPlanType type,
    required int targetPagesPerDay,
    required int targetDays,
    required TimeOfDay reminderTime,
  }) async {
    final newPlan = KhatmaPlanModel(
      id: 'khatma_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      type: type,
      targetPagesPerDay: targetPagesPerDay,
      targetDays: targetDays,
      startDate: DateTime.now(),
      currentPage: 1,
      pagesReadToday: 0,
      reminderHour: reminderTime.hour,
      reminderMinute: reminderTime.minute,
      isCompleted: false,
    );

    await saveActivePlan(newPlan);

    // جدولة التنبيه اليومي
    await GeneralNotificationService.scheduleKhatmaReminder(
      reminderTime.hour,
      reminderTime.minute,
    );

    return newPlan;
  }

  /// تسجيل تقدم القراءة لصفحة محددة مع فحص الأوسمة والإتمام
  /// يعيد وسام المحطة الجديد إن تم تحقيقه في هذه اللحظة
  static Future<KhatmaBadgeModel?> updateReadingProgress({
    required int newPage,
  }) async {
    final plan = await getActivePlan();
    if (plan == null) return null;

    final oldPage = plan.currentPage;
    final clampedPage = newPage.clamp(1, 604);
    final pagesDelta = (clampedPage - oldPage).clamp(0, 604);

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    int newPagesToday = plan.pagesReadToday;
    if (plan.lastReadDate != null) {
      final lastDate = plan.lastReadDate!;
      final lastDayStr = '${lastDate.year}-${lastDate.month}-${lastDate.day}';
      if (todayStr != lastDayStr) {
        newPagesToday = 0;
      }
    }
    newPagesToday += pagesDelta;

    // تحديث سلسلة الالتزام اليومي (Streak)
    await _updateStreakOnReading();

    // فحص اكتمال الختمة (عند بلوغ صفحة 604)
    final bool isJustCompleted = clampedPage >= 604 && !plan.isCompleted;

    final updatedPlan = plan.copyWith(
      currentPage: clampedPage,
      pagesReadToday: newPagesToday,
      lastReadDate: now,
      isCompleted: isJustCompleted,
      completedDate: isJustCompleted ? now : plan.completedDate,
    );

    await saveActivePlan(updatedPlan);

    // إذا اكتملت الختمة، أرشفة الخطة وزيادة عدد الختمات في الإحصائيات العامة
    if (isJustCompleted) {
      await _archiveCompletedPlan(updatedPlan);
      await StatsService.incrementCompletedKhatmas();
    }

    // فحص فتح الأوسمة والمحطات
    return await _checkAndUnlockBadges(clampedPage);
  }

  /// تحديث سلسلة القراءة اليومية المستمرة (Reading Streak)
  static Future<int> _updateStreakOnReading() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    final lastDateStr = prefs.getString(_streakLastDateKey);
    var streak = prefs.getInt(_streakKey) ?? 0;

    if (lastDateStr == null) {
      streak = 1;
      await prefs.setInt(_streakKey, streak);
      await prefs.setString(_streakLastDateKey, todayStr);
    } else if (lastDateStr != todayStr) {
      final lastDate = DateTime.parse(lastDateStr);
      final differenceInDays = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;

      if (differenceInDays == 1) {
        streak += 1;
      } else if (differenceInDays > 1) {
        streak = 1; // انقطعت السلسلة وبدأت من جديد
      }
      await prefs.setInt(_streakKey, streak);
      await prefs.setString(_streakLastDateKey, todayStr);
    }
    return streak;
  }

  /// استرجاع عدد أيام سلسلة الالتزام الحالية
  static Future<int> getStreakDays() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastDateStr = prefs.getString(_streakLastDateKey);

    if (lastDateStr == null) return 0;

    final lastDate = DateTime.parse(lastDateStr);
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
        .inDays;

    if (diff > 1) {
      return 0; // انقطعت السلسلة
    }
    return prefs.getInt(_streakKey) ?? 0;
  }

  /// فحص الأوسمة والمحطات
  static Future<KhatmaBadgeModel?> _checkAndUnlockBadges(int currentPage) async {
    final allBadges = await getAllBadges();
    KhatmaBadgeModel? newlyUnlocked;

    final updatedBadges = <KhatmaBadgeModel>[];
    for (final badge in allBadges) {
      if (!badge.isUnlocked && currentPage >= badge.targetPage) {
        final unlocked = badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        updatedBadges.add(unlocked);
        newlyUnlocked = unlocked;
      } else {
        updatedBadges.add(badge);
      }
    }

    if (newlyUnlocked != null) {
      await _saveBadges(updatedBadges);
    }
    return newlyUnlocked;
  }

  /// استرجاع جميع الأوسمة مع حالتها
  static Future<List<KhatmaBadgeModel>> getAllBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_badgesKey);
    final defaultList = KhatmaBadgeModel.defaultBadges();

    if (jsonStr == null) return defaultList;

    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      final mapList = list.cast<Map<String, dynamic>>();

      return defaultList.map((defaultBadge) {
        final match = mapList.firstWhere(
          (m) => m['id'] == defaultBadge.id,
          orElse: () => {},
        );
        if (match.isNotEmpty) {
          return defaultBadge.copyWith(
            isUnlocked: match['isUnlocked'] as bool? ?? false,
            unlockedAt: match['unlockedAt'] != null
                ? DateTime.parse(match['unlockedAt'] as String)
                : null,
          );
        }
        return defaultBadge;
      }).toList();
    } catch (_) {
      return defaultList;
    }
  }

  static Future<void> _saveBadges(List<KhatmaBadgeModel> badges) async {
    final prefs = await SharedPreferences.getInstance();
    final list = badges.map((b) => b.toJson()).toList();
    await prefs.setString(_badgesKey, jsonEncode(list));
  }

  /// أرشفة الخطة المكتملة في سجل الختمات السابقة
  static Future<void> _archiveCompletedPlan(KhatmaPlanModel plan) async {
    final history = await getHistory();
    final daysTaken = (plan.completedDate ?? DateTime.now())
        .difference(plan.startDate)
        .inDays
        .clamp(1, 365);

    final historyItem = KhatmaHistoryModel(
      id: plan.id,
      title: plan.title,
      type: plan.type,
      startDate: plan.startDate,
      completedDate: plan.completedDate ?? DateTime.now(),
      daysTaken: daysTaken,
      totalPages: 604,
    );

    history.insert(0, historyItem);

    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((h) => h.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  /// استرجاع سجل الختمات السابقة
  static Future<List<KhatmaHistoryModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_historyKey);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => KhatmaHistoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// إلغاء أو إنهاء الخطة الحالية مع الحفاظ الكامل على الأرشيف والأوسمة
  static Future<void> cancelCurrentPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activePlanKey);
    await prefs.setBool('khatma_active', false);
    await GeneralNotificationService.cancelKhatmaReminder();
  }
}
