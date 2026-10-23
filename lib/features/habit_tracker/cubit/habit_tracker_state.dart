import '../models/habit_item.dart';
import '../models/habit_stats_summary.dart';
import '../models/prayer_station_model.dart';

/// ==============================================================================
/// حالات سجل العبادات ومحطات الصلوات اليومية
/// ==============================================================================
class HabitTrackerState {
  /// اليوم المعروض حالياً في الجدول
  final DateTime selectedDate;

  /// قائمة محطات اليوم (الفجر، الضحى، الظهر، العصر، المغرب، العشاء، قيام الليل)
  final List<PrayerStationModel> stations;

  /// معرّف المحطة المختارة حالياً للتركيز والعرض في البطاقة
  final String selectedStationId;

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
    required this.stations,
    required this.selectedStationId,
    required this.completedIds,
    required this.streak,
    this.statsSummary,
    this.isLoading = false,
  });

  /// المحطة المعروضة حالياً
  PrayerStationModel get currentStation {
    return stations.firstWhere(
      (s) => s.id == selectedStationId,
      orElse: () => stations.isNotEmpty ? stations.first : PrayerStationModel.getDefaultStations().first,
    );
  }

  /// هل التاريخ المختار يطابق اليوم الحالي؟
  bool get isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  /// إجمالي عدد المهام والعبادات في كل المحطات
  int get totalItemsCount {
    int count = 0;
    for (final st in stations) {
      count += st.items.length;
    }
    return count > 0 ? count : 1;
  }

  /// إجمالي العبادات المنجزة في اليوم
  int get totalCompletedCount {
    int count = 0;
    for (final st in stations) {
      count += st.getCompletedCount(completedIds);
    }
    return count;
  }

  /// نسبة إنجاز اليوم بالكامل
  double get dailyCompletionPercentage {
    if (totalItemsCount <= 0) return 0.0;
    return (totalCompletedCount / totalItemsCount).clamp(0.0, 1.0);
  }

  HabitTrackerState copyWith({
    DateTime? selectedDate,
    List<PrayerStationModel>? stations,
    String? selectedStationId,
    Set<String>? completedIds,
    int? streak,
    HabitStatsSummary? statsSummary,
    bool? isLoading,
  }) {
    return HabitTrackerState(
      selectedDate: selectedDate ?? this.selectedDate,
      stations: stations ?? this.stations,
      selectedStationId: selectedStationId ?? this.selectedStationId,
      completedIds: completedIds ?? this.completedIds,
      streak: streak ?? this.streak,
      statsSummary: statsSummary ?? this.statsSummary,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
