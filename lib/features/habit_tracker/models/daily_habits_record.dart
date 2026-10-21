/// ==============================================================================
/// سجل العبادات المكتملة ليوم محدد
/// ==============================================================================
class DailyHabitsRecord {
  /// تاريخ اليوم بصيغة (YYYY-MM-DD)
  final String date;

  /// معرّفات العبادات التي تم إنجازها في هذا اليوم
  final Set<String> completedHabitIds;

  const DailyHabitsRecord({
    required this.date,
    required this.completedHabitIds,
  });

  bool isCompleted(String habitId) => completedHabitIds.contains(habitId);

  int get completedCount => completedHabitIds.length;

  double getPercentage(int totalTracked) {
    if (totalTracked <= 0) return 0.0;
    return (completedHabitIds.length / totalTracked).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'completedHabitIds': completedHabitIds.toList(),
    };
  }

  factory DailyHabitsRecord.fromJson(Map<String, dynamic> json) {
    return DailyHabitsRecord(
      date: json['date'] as String? ?? '',
      completedHabitIds: (json['completedHabitIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toSet(),
    );
  }

  DailyHabitsRecord copyWith({
    String? date,
    Set<String>? completedHabitIds,
  }) {
    return DailyHabitsRecord(
      date: date ?? this.date,
      completedHabitIds: completedHabitIds ?? this.completedHabitIds,
    );
  }
}
