/// ==============================================================================
///  وصف الملف: hisn_state.dart
/// ==============================================================================
/// يمثل حالة (State) شاشة أقسام حصن المسلم بنمط Cubit.
/// ==============================================================================
library;

import 'package:tarteel/Model/AccessListModel.dart';

class HisnState {
  /// جميع أبواب وأقسام حصن المسلم الأصلية
  final List<AccessListModel> allActions;

  /// الأبواب بعد التصفية والبحث
  final List<AccessListModel> filteredActions;

  /// حالة التحميل
  final bool isLoading;

  /// رسالة الخطأ (إن وجدت)
  final String? errorMessage;

  /// نص البحث الحالي
  final String searchQuery;

  const HisnState({
    this.allActions = const [],
    this.filteredActions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  HisnState copyWith({
    List<AccessListModel>? allActions,
    List<AccessListModel>? filteredActions,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return HisnState(
      allActions: allActions ?? this.allActions,
      filteredActions: filteredActions ?? this.filteredActions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
