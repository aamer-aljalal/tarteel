/// ==============================================================================
///  وصف الملف: generic_reader_state.dart
/// ==============================================================================
/// يمثل حالة (State) شاشة القراءة والتفاصيل العامة لأي عنصر بنمط Cubit:
/// (أذكار، حصن المسلم، سور القرآن، أحاديث، قصص الأنبياء، إلخ).
/// ==============================================================================
library;

class GenericReaderState<TDetail, TItem> {
  /// الكائن الرئيسي للتفاصيل (مثل: سورة كاملة، أو قسم أذكار كامل، أو حديث)
  final TDetail? detail;

  /// عنوان العنصر الرئيسي
  final String title;

  /// قائمة العناصر الفرعية للقراءة (مثل: قائمة الآيات، أو قائمة الأذكار والأدعية)
  final List<TItem> items;

  /// الفهرس الحالي المعروض (PageView index)
  final int currentIndex;

  /// العدادات الحالية لكل عنصر (إن وجدت)
  final List<int> counters;

  /// حجم خط القراءة
  final double fontSize;

  /// هل الاهتزاز مفعل
  final bool hapticEnabled;

  /// حالة التحميل الأولي عند الطلب
  final bool isLoading;

  /// رسالة الخطأ إن وجدت
  final String? errorMessage;

  /// هل تم إكمال كافة عناصر هذا القسم
  final bool isCompleted;

  const GenericReaderState({
    this.detail,
    this.title = '',
    this.items = const [],
    this.currentIndex = 0,
    this.counters = const [],
    this.fontSize = 18.0,
    this.hapticEnabled = true,
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
  });

  /// إجمالي عدد العناصر للقراءة
  int get totalCount => items.length;

  /// العنصر الفرعي الحالي المعروض
  TItem? get currentItem =>
      (items.isNotEmpty && currentIndex >= 0 && currentIndex < items.length)
          ? items[currentIndex]
          : null;

  /// العداد الحالي للعنصر المعروض
  int get currentCount =>
      (counters.isNotEmpty && currentIndex >= 0 && currentIndex < counters.length)
          ? counters[currentIndex]
          : 0;

  GenericReaderState<TDetail, TItem> copyWith({
    TDetail? detail,
    String? title,
    List<TItem>? items,
    int? currentIndex,
    List<int>? counters,
    double? fontSize,
    bool? hapticEnabled,
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
  }) {
    return GenericReaderState<TDetail, TItem>(
      detail: detail ?? this.detail,
      title: title ?? this.title,
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      counters: counters ?? this.counters,
      fontSize: fontSize ?? this.fontSize,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
