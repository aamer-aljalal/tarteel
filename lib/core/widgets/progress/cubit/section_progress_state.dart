/// ==============================================================================
///  وصف الملف: section_progress_state.dart
/// ==============================================================================
/// يمثل حالة (State) شريط تقدم القسم.
/// ==============================================================================
library;

class SectionProgressState {
  /// الفهرس أو الترتيب الحالي (1-based أو 0-based يتم تحويله للعرض)
  final int currentIndex;

  /// إجمالي العناصر في القسم
  final int totalCount;

  /// نسبة الإنجاز المحسوبة رياضياً بين 0.0 و 1.0
  final double progress;

  /// النسبة المئوية المنسقة (مثال: "50%")
  final int percentage;

  const SectionProgressState({
    required this.currentIndex,
    required this.totalCount,
    required this.progress,
    required this.percentage,
  });

  /// إنشاء حالة أولية
  factory SectionProgressState.initial({int currentIndex = 0, int totalCount = 1}) {
    final validTotal = totalCount > 0 ? totalCount : 1;
    final validCurrent = currentIndex.clamp(0, validTotal);
    final prog = (validCurrent / validTotal).clamp(0.0, 1.0);
    return SectionProgressState(
      currentIndex: validCurrent,
      totalCount: validTotal,
      progress: prog,
      percentage: (prog * 100).round(),
    );
  }

  SectionProgressState copyWith({
    int? currentIndex,
    int? totalCount,
    double? progress,
    int? percentage,
  }) {
    return SectionProgressState(
      currentIndex: currentIndex ?? this.currentIndex,
      totalCount: totalCount ?? this.totalCount,
      progress: progress ?? this.progress,
      percentage: percentage ?? this.percentage,
    );
  }
}
