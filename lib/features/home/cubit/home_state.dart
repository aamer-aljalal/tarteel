/// ==============================================================================
///  وصف الملف: home_state.dart
/// ==============================================================================
/// يمثل حالة (State) الصفحة الرئيسية في تطبيق ترتيل بنمط Cubit.
///
///  البيانات التي تحتوي عليها الحالة:
/// 1. actions: قائمة الأزرار الحالية المحملة من الخدمة.
/// 2. isLoading: هل البيانات قيد التحميل من الذاكرة أو الملف.
/// 3. إحصائيات الأذكار وقراءة القرآن الحقيقية (أرقام التقدم والأهداف).
/// ==============================================================================
library;

import 'package:tarteel/Model/AccessListModel.dart';

class HomeState {
  /// قائمة أزرار الصفحة الرئيسية
  final List<AccessListModel> actions;

  /// حالة التحميل
  final bool isLoading;

  /// رسالة خطأ (إن وجدت)
  final String? errorMessage;

  /// إحصائيات الأذكار
  final int adhkarCount;
  final int adhkarTarget;

  /// إحصائيات قراءة القرآن
  final int pagesRead;
  final int pagesTarget;

  const HomeState({
    this.actions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.adhkarCount = 0,
    this.adhkarTarget = 300,
    this.pagesRead = 0,
    this.pagesTarget = 20,
  });

  /// نسبة تقدم الأذكار من 0.0 إلى 1.0
  double get adhkarProgress =>
      adhkarTarget > 0 ? (adhkarCount / adhkarTarget).clamp(0.0, 1.0) : 0.0;

  /// نسبة تقدم قراءة القرآن من 0.0 إلى 1.0
  double get readingProgress =>
      pagesTarget > 0 ? (pagesRead / pagesTarget).clamp(0.0, 1.0) : 0.0;

  /// دالة نسخ الحالة وتحديث بعض الحقول (copyWith)
  HomeState copyWith({
    List<AccessListModel>? actions,
    bool? isLoading,
    String? errorMessage,
    int? adhkarCount,
    int? adhkarTarget,
    int? pagesRead,
    int? pagesTarget,
  }) {
    return HomeState(
      actions: actions ?? this.actions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      adhkarCount: adhkarCount ?? this.adhkarCount,
      adhkarTarget: adhkarTarget ?? this.adhkarTarget,
      pagesRead: pagesRead ?? this.pagesRead,
      pagesTarget: pagesTarget ?? this.pagesTarget,
    );
  }
}
