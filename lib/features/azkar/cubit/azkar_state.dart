/// ==============================================================================
///  وصف الملف: azkar_state.dart
/// ==============================================================================
/// يمثل حالة (State) شاشة أقسام الأذكار بنمط Cubit.
/// ==============================================================================
library;

import 'package:tarteel/Model/AccessListModel.dart';

class AzkarState {
  /// جميع أقسام الأذكار الأصلية
  final List<AccessListModel> allActions;

  /// أقسام الأذكار بعد التصفية والبحث
  final List<AccessListModel> filteredActions;

  /// حالة التحميل
  final bool isLoading;

  /// رسالة الخطأ (إن وجدت)
  final String? errorMessage;

  /// نص البحث الحالي
  final String searchQuery;

  const AzkarState({
    this.allActions = const [],
    this.filteredActions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  AzkarState copyWith({
    List<AccessListModel>? allActions,
    List<AccessListModel>? filteredActions,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return AzkarState(
      allActions: allActions ?? this.allActions,
      filteredActions: filteredActions ?? this.filteredActions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
