/// ==============================================================================
///  وصف الملف: azkar_cubit.dart
/// ==============================================================================
/// العقل المدبر لشاشة أقسام الأذكار بنمط Cubit.
/// يتولى جلب الأقسام من الخدمة والبحث والتصفية الذكية.
/// ==============================================================================
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tarteel/core/helpers/arabic_search_helper.dart';
import 'package:tarteel/features/azkar/services/azkar_service.dart';
import 'azkar_state.dart';

class AzkarCubit extends Cubit<AzkarState> {
  AzkarCubit() : super(const AzkarState(isLoading: true)) {
    loadCategories();
  }

  /// تحميل أقسام الأذكار
  Future<void> loadCategories() async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      final actions = await AzkarService.loadAzkarAsActions();
      emit(state.copyWith(
        allActions: actions,
        filteredActions: actions,
        isLoading: false,
        searchQuery: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تحميل أقسام الأذكار',
      ));
    }
  }

  /// البحث وتصفية أقسام الأذكار باللغة العربية بذكاء
  void filterCategories(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(
        filteredActions: state.allActions,
        searchQuery: '',
      ));
      return;
    }

    final normalizedQuery = ArabicSearchHelper.normalize(trimmed).toLowerCase();

    final filtered = state.allActions.where((action) {
      final normalizedTitle =
          ArabicSearchHelper.normalize(action.title).toLowerCase();
      return normalizedTitle.contains(normalizedQuery);
    }).toList();

    emit(state.copyWith(
      filteredActions: filtered,
      searchQuery: query,
    ));
  }

  /// مسح نص البحث
  void clearSearch() {
    emit(state.copyWith(
      filteredActions: state.allActions,
      searchQuery: '',
    ));
  }
}
