/// ==============================================================================
///  وصف الملف: azkar_details_state.dart
/// ==============================================================================
/// يمثل حالة (State) شاشة تفاصيل وقراءة الأذكار بنمط Cubit.
/// ==============================================================================
library;

import 'package:tarteel/features/azkar/model/zekr_category.dart';
import 'package:tarteel/features/azkar/model/zekr_model%20.dart';

class AzkarDetailsState {
  /// القسم المحمّل حالياً
  final ZekrCategory? category;

  /// عنوان القسم (في حال جاري التحميل عند الطلب)
  final String categoryTitle;

  /// الفهرس الحالي للذكر المعروض في الـ PageView
  final int currentIndex;

  /// حجم خط القراءة
  final double fontSize;

  /// هل الاهتزاز مفعل
  final bool hapticEnabled;

  /// حالة التحميل الأولي عند الطلب
  final bool isLoading;

  /// هل تم إكمال جميع أذكار هذا القسم بالكامل
  final bool isCategoryCompleted;

  /// رسالة الخطأ إن وجدت
  final String? errorMessage;

  const AzkarDetailsState({
    this.category,
    this.categoryTitle = '',
    this.currentIndex = 0,
    this.fontSize = 16.0,
    this.hapticEnabled = true,
    this.isLoading = false,
    this.isCategoryCompleted = false,
    this.errorMessage,
  });

  /// الذكر المعروض حالياً
  ZekrModel? get currentZekr {
    if (category == null || category!.azkar.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= category!.azkar.length) return null;
    return category!.azkar[currentIndex];
  }

  /// إجمالي عدد مرات التكرار للذكر الحالي
  int get totalRepeat {
    final zekr = currentZekr;
    if (zekr == null) return 1;
    return int.tryParse(zekr.count) ?? 1;
  }

  /// نسبة تقدم الذكر الحالي (من 0.0 إلى 1.0)
  double get currentProgress {
    final zekr = currentZekr;
    if (zekr == null) return 0.0;
    final total = totalRepeat;
    return (zekr.currentCount / (total > 0 ? total : 1)).clamp(0.0, 1.0);
  }

  /// إجمالي عدد الأذكار في القسم
  int get azkarCount => category?.azkar.length ?? 0;

  AzkarDetailsState copyWith({
    ZekrCategory? category,
    String? categoryTitle,
    int? currentIndex,
    double? fontSize,
    bool? hapticEnabled,
    bool? isLoading,
    bool? isCategoryCompleted,
    String? errorMessage,
  }) {
    return AzkarDetailsState(
      category: category ?? this.category,
      categoryTitle: categoryTitle ?? this.categoryTitle,
      currentIndex: currentIndex ?? this.currentIndex,
      fontSize: fontSize ?? this.fontSize,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      isLoading: isLoading ?? this.isLoading,
      isCategoryCompleted: isCategoryCompleted ?? this.isCategoryCompleted,
      errorMessage: errorMessage,
    );
  }
}
