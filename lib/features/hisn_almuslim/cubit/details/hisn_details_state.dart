/// ==============================================================================
///  وصف الملف: hisn_details_state.dart
/// ==============================================================================
/// يمثل حالة (State) شاشة تفاصيل وقراءة أدعية حصن المسلم بنمط Cubit.
/// ==============================================================================
library;

import 'package:tarteel/features/hisn_almuslim/model/hisn_category.dart';

class HisnDetailsState {
  /// القسم المحمّل حالياً
  final HisnCategory? category;

  /// عنوان القسم
  final String categoryTitle;

  /// الفهرس الحالي للدعاء المعروض
  final int currentIndex;

  /// قائمة العدادات لكل دعاء في الباب
  final List<int> counters;

  /// حجم خط القراءة
  final double fontSize;

  /// هل الاهتزاز مفعل
  final bool hapticEnabled;

  /// حالة التحميل عند الطلب
  final bool isLoading;

  /// رسالة خطأ إن وجدت
  final String? errorMessage;

  const HisnDetailsState({
    this.category,
    this.categoryTitle = '',
    this.currentIndex = 0,
    this.counters = const [],
    this.fontSize = 18.0,
    this.hapticEnabled = true,
    this.isLoading = false,
    this.errorMessage,
  });

  /// إجمالي الأدعية
  int get totalTexts => category?.texts.length ?? 0;

  /// النص المعروض حالياً
  String get currentText =>
      (category != null && currentIndex >= 0 && currentIndex < category!.texts.length)
          ? category!.texts[currentIndex]
          : '';

  /// الحاشية الحالية إن وجدت
  String? get currentFootnote =>
      (category != null && currentIndex >= 0 && currentIndex < category!.footnotes.length)
          ? category!.footnotes[currentIndex]
          : null;

  /// تكرار الدعاء المطلوب (حصن المسلم 1 افتراضياً)
  int get totalRepeat => 1;

  /// العداد الحالي للدعاء
  int get currentCount =>
      (counters.isNotEmpty && currentIndex >= 0 && currentIndex < counters.length)
          ? counters[currentIndex]
          : 0;

  /// نسبة تقدم الدعاء
  double get currentProgress =>
      (currentCount / totalRepeat).clamp(0.0, 1.0);

  /// هل تم إكمال جميع أدعية هذا الباب
  bool get isAllCompleted =>
      counters.isNotEmpty && counters.every((count) => count >= totalRepeat);

  HisnDetailsState copyWith({
    HisnCategory? category,
    String? categoryTitle,
    int? currentIndex,
    List<int>? counters,
    double? fontSize,
    bool? hapticEnabled,
    bool? isLoading,
    String? errorMessage,
  }) {
    return HisnDetailsState(
      category: category ?? this.category,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      currentIndex: currentIndex ?? this.currentIndex,
      counters: counters ?? this.counters,
      fontSize: fontSize ?? this.fontSize,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
