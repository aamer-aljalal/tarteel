import '../models/habit_stats_summary.dart';
import '../models/unified_habit_item.dart';

/// ==============================================================================
/// حالات سجل العبادات اليومي الموحد (المتبقية والمنجزة)
/// ==============================================================================
class HabitTrackerState {
  /// اليوم المعروض حالياً في الجدول
  final DateTime selectedDate;

  /// القائمة الكاملة الموحدة لجميع عبادات اليوم (مرتبة تسلسلياً)
  final List<UnifiedHabitItem> allItems;

  /// معرّفات جميع العبادات المكتملة في هذا اليوم
  final Set<String> completedIds;

  /// عدد أيام الالتزام المتتالية (Streak)
  final int streak;

  /// ملخص الإحصائيات الأسبوعية
  final HabitStatsSummary? statsSummary;

  /// هل التطبيق بصدد تحميل البيانات؟
  final bool isLoading;

  const HabitTrackerState({
    required this.selectedDate,
    this.allItems = const [],
    this.completedIds = const {},
    this.streak = 0,
    this.statsSummary,
    this.isLoading = false,
  });

  /// العبادات المتبقية (غير المنجزة)
  List<UnifiedHabitItem> get remainingItems {
    return allItems.where((item) => !completedIds.contains(item.id)).toList();
  }

  /// العبادات المنجزة
  List<UnifiedHabitItem> get completedItems {
    return allItems.where((item) => completedIds.contains(item.id)).toList();
  }

  /// هل التاريخ المختار يطابق اليوم الحالي؟
  bool get isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  /// إجمالي عدد المهام والعبادات في اليوم
  int get totalItemsCount => allItems.isNotEmpty ? allItems.length : 1;

  /// إجمالي العبادات المنجزة في اليوم
  int get totalCompletedCount => completedItems.length;

  /// نسبة إنجاز اليوم بالكامل (0.0 إلى 1.0)
  double get dailyCompletionPercentage {
    if (totalItemsCount <= 0) return 0.0;
    return (totalCompletedCount / totalItemsCount).clamp(0.0, 1.0);
  }

  HabitTrackerState copyWith({
    DateTime? selectedDate,
    List<UnifiedHabitItem>? allItems,
    Set<String>? completedIds,
    int? streak,
    HabitStatsSummary? statsSummary,
    bool? isLoading,
  }) {
    return HabitTrackerState(
      selectedDate: selectedDate ?? this.selectedDate,
      allItems: allItems ?? this.allItems,
      completedIds: completedIds ?? this.completedIds,
      streak: streak ?? this.streak,
      statsSummary: statsSummary ?? this.statsSummary,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
