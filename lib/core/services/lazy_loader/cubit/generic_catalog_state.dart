/// ==============================================================================
///  وصف الملف: generic_catalog_state.dart
/// ==============================================================================
/// يمثل حالة الكتالوج العام لأي قائمة (عناوين، بحث، تحميل، كاش).
/// ==============================================================================
library;

class GenericCatalogState<THeader> {
  /// جميع عناصر الكتالوج الأصلية
  final List<THeader> allItems;

  /// العناصر بعد البحث والتصفية
  final List<THeader> filteredItems;

  /// حالة التحميل الأولي
  final bool isLoading;

  /// رسالة الخطأ إن وجدت
  final String? errorMessage;

  /// نص البحث الحالي
  final String searchQuery;

  const GenericCatalogState({
    this.allItems = const [],
    this.filteredItems = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  GenericCatalogState<THeader> copyWith({
    List<THeader>? allItems,
    List<THeader>? filteredItems,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return GenericCatalogState<THeader>(
      allItems: allItems ?? this.allItems,
      filteredItems: filteredItems ?? this.filteredItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
