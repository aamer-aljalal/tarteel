import '../models/habit_item.dart';
import '../models/habit_stats_summary.dart';

/// ==============================================================================
/// حالات سجل العبادات اليومي
/// ==============================================================================
class HabitTrackerState {
  /// اليوم المعروض حالياً في الجدول
  final DateTime selectedDate;

  /// قائمة العبادات النشطة والمعروضة في جدول هذا اليوم
  final List<HabitItem> activeHabits;

  /// معرّفات العبادات المكتملة في هذا اليوم
  final Set<String> completedIds;

  /// القائمة الكاملة الشاملة للعبادات (لأغراض شاشة التخصيص)
  final List<HabitItem> allHabits;

  /// معرّفات العبادات التي اختار المستخدم تفعيلها
  final Set<String> enabledHabitIds;

  /// عدد أيام الالتزام المتتالية
  final int streak;

  /// ملخص الإحصائيات الأسبوعية
  final HabitStatsSummary? statsSummary;

  /// هل التطبيق بصدد تحميل البيانات؟
  final bool isLoading;

  const HabitTrackerState({
    required this.selectedDate,
    required this.activeHabits,
    required this.completedIds,
    required this.allHabits,
    required this.enabledHabitIds,
    required this.streak,
    this.statsSummary,
    this.isLoading = false,
  });

  /// هل التاريخ المختار يطابق اليوم الحالي؟
  bool get isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  /// نسبة إنجاز جدول اليوم
  double get completionPercentage {
    if (activeHabits.isEmpty) return 0.0;
    final completedInActive = activeHabits.where((h) => completedIds.contains(h.id)).length;
    return (completedInActive / activeHabits.length).clamp(0.0, 1.0);
  }

  /// عدد العبادات المكتملة لليوم
  int get completedCount {
    return activeHabits.where((h) => completedIds.contains(h.id)).length;
  }

  /// عدد العبادات الإجمالي المعروضة لليوم
  int get totalCount => activeHabits.length;

  HabitTrackerState copyWith({
    DateTime? selectedDate,
    List<HabitItem>? activeHabits,
    Set<String>? completedIds,
    List<HabitItem>? allHabits,
    Set<String>? enabledHabitIds,
    int? streak,
    HabitStatsSummary? statsSummary,
    bool? isLoading,
  }) {
    return HabitTrackerState(
      selectedDate: selectedDate ?? this.selectedDate,
      activeHabits: activeHabits ?? this.activeHabits,
      completedIds: completedIds ?? this.completedIds,
      allHabits: allHabits ?? this.allHabits,
      enabledHabitIds: enabledHabitIds ?? this.enabledHabitIds,
      streak: streak ?? this.streak,
      statsSummary: statsSummary ?? this.statsSummary,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
