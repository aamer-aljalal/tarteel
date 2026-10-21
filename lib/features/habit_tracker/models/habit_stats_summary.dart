/// ==============================================================================
/// ملخص إحصائيات الالتزام الأسبوعي وسلسلة الأيام
/// ==============================================================================
class HabitStatsSummary {
  /// عدد أيام التتابع الحالية دون انقطاع
  final int currentStreak;

  /// أطول سلسلة التزام متواصلة حققها المستخدم
  final int longestStreak;

  /// نسبة إنجاز اليوم الحالي (0.0 إلى 1.0)
  final double todayPercentage;

  /// متوسط الالتزام الأسبوعي (0.0 إلى 1.0)
  final double weeklyAverage;

  /// إجمالي العبادات المكتملة خلال الأسبوع الأخير
  final int totalCompletedThisWeek;

  /// نسب الإنجاز لآخر 7 أيام مرتبة من الأقدم إلى اليوم
  /// المفتاح: التاريخ كـ DateTime أو نص، القيمة: النسبة من 0.0 إلى 1.0
  final Map<DateTime, double> last7DaysProgress;

  const HabitStatsSummary({
    required this.currentStreak,
    required this.longestStreak,
    required this.todayPercentage,
    required this.weeklyAverage,
    required this.totalCompletedThisWeek,
    required this.last7DaysProgress,
  });
}
