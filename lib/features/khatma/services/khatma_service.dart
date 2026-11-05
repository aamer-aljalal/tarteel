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
  static const String _historyKey = 'khatma_history_v2';
  static const String _streakKey = 'khatma_reading_streak';
  static const String _streakLastDateKey = 'khatma_streak_last_date';
  static const String _pendingBadgesKey = 'khatma_pending_celebration_badge_ids';
  static const String _migratedKey = 'khatma_legacy_migrated_v2';

  /// تحميل الخطة النشطة
  static Future<KhatmaPlanModel?> getActivePlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final jsonStr = prefs.getString(_activePlanKey);
    if (jsonStr == null) {
      final alreadyMigrated = prefs.getBool(_migratedKey) ?? false;
      if (alreadyMigrated) return null;
      // التحقق من وجود خطة قديمة للترقية التلقائية (مرة واحدة فقط)
      return _migrateLegacyPlanIfNeeded(prefs);
    }
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return KhatmaPlanModel.fromJson(map);
    } catch (e, stack) {
      debugPrint('Error parsing KhatmaPlanModel: $e\n$stack');
      return null;
    }
  }

  /// ترقية الخطة القديمة تلقائياً دون فقدان بيانات المستخدم
  static Future<KhatmaPlanModel?> _migrateLegacyPlanIfNeeded(SharedPreferences prefs) async {
    await prefs.setBool(_migratedKey, true);

    final active = prefs.getBool('khatma_active') ?? false;
    if (!active) {
      await _cleanLegacyKeys(prefs);
      return null;
    }

    final days = prefs.getInt('khatma_days') ?? 30;
    final startStr = prefs.getString('khatma_start_date');
    final lastPage = prefs.getInt('khatma_last_read_page') ?? 1;
    final readToday = prefs.getInt('khatma_ayahs_read_today') ?? 0;
    final rHour = prefs.getInt('khatma_reminder_hour') ?? 20;
    final rMin = prefs.getInt('khatma_reminder_minute') ?? 0;

    final targetPages = (604 / days).ceil();
    final currentP = lastPage.clamp(1, 604);
    final startDate = _parseDateSafe(startStr) ?? DateTime.now();

    final migrated = KhatmaPlanModel(
      id: 'khatma_${DateTime.now().millisecondsSinceEpoch}',
      title: 'ختمة المصحف الشريف',
      type: KhatmaPlanType.durationDays,
      targetPagesPerDay: targetPages,
      targetDays: days,
      startDate: startDate,
      currentPage: currentP,
      pagesReadToday: (readToday / 15).round().clamp(0, 604),
      reminderHour: rHour,
      reminderMinute: rMin,
      badges: KhatmaBadgeModel.defaultBadges().map((b) {
        if (currentP >= b.targetPage) {
          return b.copyWith(isUnlocked: true, unlockedAt: DateTime.now());
        }
        return b;
      }).toList(),
    );

    await saveActivePlan(migrated);
    await _cleanLegacyKeys(prefs);
    return migrated;
  }

  static Future<void> _cleanLegacyKeys(SharedPreferences prefs) async {
    await prefs.remove('khatma_active');
    await prefs.remove('khatma_days');
    await prefs.remove('khatma_start_date');
    await prefs.remove('khatma_last_read_page');
    await prefs.remove('khatma_ayahs_read_today');
    await prefs.remove('khatma_reminder_hour');
    await prefs.remove('khatma_reminder_minute');
  }

  /// حفظ أو تحديث الخطة النشطة
  static Future<void> saveActivePlan(KhatmaPlanModel plan) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(plan.toJson());
    await prefs.setString(_activePlanKey, jsonStr);
    await prefs.setBool(_migratedKey, true);

    // الحفاظ على مفتاح آخر صفحة مقروءة للإشعارات
    await prefs.setInt('khatma_last_read_page', plan.currentPage);
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
      badges: KhatmaBadgeModel.defaultBadges(),
    );

    await saveActivePlan(newPlan);

    // جدولة التنبيه المناسب لمسار الختمة
    try {
      if (type == KhatmaPlanType.prayers) {
        await GeneralNotificationService.scheduleKhatmaPrayerReminders();
      } else {
        await GeneralNotificationService.scheduleKhatmaReminder(
          reminderTime.hour,
          reminderTime.minute,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling Khatma notification: $e');
    }

    return newPlan;
  }

  /// تنسيق التاريخ بصيغة ISO القياسية المضمونة YYYY-MM-DD
  static String _formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// تحليل التاريخ بأمان تام مع دعم التواريخ القديمة غير المسبوقة بأصفار مثل (2026-11-3)
  static DateTime? _parseDateSafe(String? str) {
    if (str == null || str.trim().isEmpty) return null;
    final direct = DateTime.tryParse(str.trim());
    if (direct != null) return direct;
    try {
      final parts = str.trim().split('-');
      if (parts.length >= 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      }
    } catch (_) {}
    return null;
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
    // احتساب الزيادة في الصفحات المقروءة اليوم (فقط عند التقدم للأمام)
    final pagesDelta = clampedPage > oldPage ? (clampedPage - oldPage) : 0;

    final now = DateTime.now();
    final todayStr = _formatDateKey(now);

    int newPagesToday = plan.pagesReadToday;
    if (plan.lastReadDate != null) {
      final lastDayStr = _formatDateKey(plan.lastReadDate!);
      if (todayStr != lastDayStr) {
        newPagesToday = 0;
      }
    }
    newPagesToday += pagesDelta;

    // تحديث سلسلة الالتزام اليومي (Streak)
    await _updateStreakOnReading();

    // فحص وتحديث الأوسمة التابعة لهذه الختمة المحددة
    final currentBadges = plan.badges.isEmpty
        ? KhatmaBadgeModel.defaultBadges()
        : plan.badges;
    KhatmaBadgeModel? newlyUnlocked;
    final newlyUnlockedList = <KhatmaBadgeModel>[];
    final updatedBadges = <KhatmaBadgeModel>[];

    for (final badge in currentBadges) {
      if (!badge.isUnlocked && clampedPage >= badge.targetPage) {
        final unlocked = badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        updatedBadges.add(unlocked);
        newlyUnlocked = unlocked;
        newlyUnlockedList.add(unlocked);
      } else {
        updatedBadges.add(badge);
      }
    }

    // حفظ أي أوسمة جديدة معلقة ليتم الاحتفال بها وعرضها فور رجوع المستخدم
    if (newlyUnlockedList.isNotEmpty) {
      for (final b in newlyUnlockedList) {
        await addPendingCelebrationBadge(b.id);
      }
    }

    // فحص اكتمال الختمة (عند بلوغ صفحة 604)
    final bool isJustCompleted = clampedPage >= 604 && !plan.isCompleted;

    final updatedPlan = plan.copyWith(
      currentPage: clampedPage,
      pagesReadToday: newPagesToday,
      lastReadDate: now,
      isCompleted: isJustCompleted || plan.isCompleted,
      completedDate: isJustCompleted ? now : plan.completedDate,
      badges: updatedBadges,
    );

    await saveActivePlan(updatedPlan);

    // إذا اكتملت الختمة، أرشفة الخطة وزيادة عدد الختمات في الإحصائيات العامة
    if (isJustCompleted) {
      await _archiveCompletedPlan(updatedPlan);
      await StatsService.incrementCompletedKhatmas();
    }

    return newlyUnlocked;
  }

  /// حفظ وسام جديد في قائمة الانتظار لعرضه وتهنئة المستخدم به عند العودة
  static Future<void> addPendingCelebrationBadge(String badgeId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_pendingBadgesKey) ?? [];
    if (!list.contains(badgeId)) {
      list.add(badgeId);
      await prefs.setStringList(_pendingBadgesKey, list);
    }
  }

  /// استرجاع ومسح الأوسمة المعلقة للاحتفال بها
  static Future<List<KhatmaBadgeModel>> consumePendingCelebrationBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_pendingBadgesKey) ?? [];
    if (list.isEmpty) return [];
    await prefs.remove(_pendingBadgesKey);

    final allBadges = await getAllBadges();
    final defaultBadges = KhatmaBadgeModel.defaultBadges();
    final result = <KhatmaBadgeModel>[];
    for (final id in list) {
      final found = allBadges.firstWhere(
        (b) => b.id == id,
        orElse: () => defaultBadges.firstWhere(
          (b) => b.id == id,
          orElse: () => defaultBadges.first,
        ),
      );
      result.add(found);
    }
    return result;
  }

  /// تحديث سلسلة القراءة اليومية المستمرة (Reading Streak)
  static Future<int> _updateStreakOnReading() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final todayStr = _formatDateKey(todayDate);

    final lastDateStr = prefs.getString(_streakLastDateKey);
    var streak = prefs.getInt(_streakKey) ?? 0;

    if (lastDateStr == null) {
      streak = 1;
      await prefs.setInt(_streakKey, streak);
      await prefs.setString(_streakLastDateKey, todayStr);
    } else {
      final lastDate = _parseDateSafe(lastDateStr);
      if (lastDate != null) {
        final cleanLastDate =
            DateTime(lastDate.year, lastDate.month, lastDate.day);
        final differenceInDays = todayDate.difference(cleanLastDate).inDays;

        if (differenceInDays == 1) {
          streak += 1;
          await prefs.setInt(_streakKey, streak);
          await prefs.setString(_streakLastDateKey, todayStr);
        } else if (differenceInDays > 1) {
          streak = 1; // انقطعت السلسلة وبدأت من جديد
          await prefs.setInt(_streakKey, streak);
          await prefs.setString(_streakLastDateKey, todayStr);
        } else if (differenceInDays == 0) {
          // قرأ في نفس اليوم - نضمن تحديث المفتاح لصيغة ISO القياسية
          if (lastDateStr != todayStr) {
            await prefs.setString(_streakLastDateKey, todayStr);
          }
        }
      } else {
        streak = 1;
        await prefs.setInt(_streakKey, streak);
        await prefs.setString(_streakLastDateKey, todayStr);
      }
    }
    return streak;
  }

  /// استرجاع عدد أيام سلسلة الالتزام الحالية
  static Future<int> getStreakDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final lastDateStr = prefs.getString(_streakLastDateKey);

      if (lastDateStr == null) return 0;

      final lastDate = _parseDateSafe(lastDateStr);
      if (lastDate == null) return 0;

      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;

      if (diff > 1) {
        return 0; // انقطعت السلسلة
      }
      return prefs.getInt(_streakKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// استرجاع أوسمة الخطة النشطة الحالية
  static Future<List<KhatmaBadgeModel>> getAllBadges() async {
    final plan = await getActivePlan();
    if (plan != null && plan.badges.isNotEmpty) {
      return plan.badges;
    }
    return KhatmaBadgeModel.defaultBadges();
  }

  /// أرشفة الخطة المكتملة في سجل الختمات السابقة مع أوسمتها الخاصة
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
      badges: plan.badges,
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
    await prefs.setBool(_migratedKey, true);
    await prefs.remove(_pendingBadgesKey);
    await _cleanLegacyKeys(prefs);

    try {
      await GeneralNotificationService.cancelKhatmaReminder();
    } catch (e) {
      debugPrint('Error cancelling Khatma reminders: $e');
    }
  }
}
