import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_habits_record.dart';
import '../models/habit_stats_summary.dart';
import 'habit_calendar_helper.dart';

/// ==============================================================================
/// خدمة التخزين المحلي لسجل العبادات وحساب الإحصائيات وسلسلة الأيام
/// ==============================================================================
class HabitStorageService {
  HabitStorageService._();

  static const String _prefixRecord = 'habit_record_';
  static const String _keyLongestStreak = 'habit_longest_streak';

  /// جلب سجل يوم محدد
  static Future<DailyHabitsRecord> getRecord(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = HabitCalendarHelper.formatDateKey(date);
    final raw = prefs.getString('$_prefixRecord$dateKey');
    if (raw == null) {
      return DailyHabitsRecord(date: dateKey, completedHabitIds: const {});
    }
    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      return DailyHabitsRecord.fromJson(jsonMap);
    } catch (_) {
      return DailyHabitsRecord(date: dateKey, completedHabitIds: const {});
    }
  }

  /// حفظ سجل يوم محدد
  static Future<void> saveRecord(DailyHabitsRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(record.toJson());
    await prefs.setString('$_prefixRecord${record.date}', raw);
  }

  /// حساب سلسلة أيام الالتزام المتتالية (Streak)
  static Future<int> calculateCurrentStreak(int activeHabitsCount) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // التحقق من اليوم الحالي أولاً
    final todayRecord = await getRecord(now);
    final todayPct = todayRecord.getPercentage(activeHabitsCount);

    int streak = 0;
    DateTime checkDate = now;

    // إذا كان إنجاز اليوم >= 40%، يُحسب اليوم ضمن السلسلة
    if (todayPct >= 0.40) {
      streak++;
      checkDate = now.subtract(const Duration(days: 1));
    } else {
      // إذا لم ينجز اليوم بعد (ما زال في بدايته)، نبدأ الفحص من الأمس حتى لا تنكسر السلسلة نهاراً
      checkDate = now.subtract(const Duration(days: 1));
    }

    // فحص الأيام السابقة متتالية
    while (true) {
      final rec = await getRecord(checkDate);
      final pct = rec.getPercentage(activeHabitsCount);
      if (pct >= 0.40) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }

      // أقصى حد أمان 365 يوماً لمنع الدوران اللانهائي
      if (streak > 365) break;
    }

    // تحديث أطول سلسلة مسجلة
    final longest = prefs.getInt(_keyLongestStreak) ?? 0;
    if (streak > longest) {
      await prefs.setInt(_keyLongestStreak, streak);
    }

    return streak;
  }

  /// جلب أطول سلسلة مسجلة
  static Future<int> getLongestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLongestStreak) ?? 0;
  }

  /// جلب ملخص الإحصائيات الكامل للأسبوع الأخير
  static Future<HabitStatsSummary> getStatsSummary(int activeHabitsCount) async {
    final now = DateTime.now();
    final Map<DateTime, double> last7Days = {};
    int totalCompleted = 0;
    double sumPercentages = 0.0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final rec = await getRecord(date);
      final pct = rec.getPercentage(activeHabitsCount);
      last7Days[DateTime(date.year, date.month, date.day)] = pct;
      totalCompleted += rec.completedCount;
      sumPercentages += pct;
    }

    final todayRec = await getRecord(now);
    final currentStreak = await calculateCurrentStreak(activeHabitsCount);
    final longestStreak = await getLongestStreak();

    return HabitStatsSummary(
      currentStreak: currentStreak,
      longestStreak: longestStreak > currentStreak ? longestStreak : currentStreak,
      todayPercentage: todayRec.getPercentage(activeHabitsCount),
      weeklyAverage: sumPercentages / 7.0,
      totalCompletedThisWeek: totalCompleted,
      last7DaysProgress: last7Days,
    );
  }
}
