/// ==============================================================================
///  وصف الملف: hisn_cubit.dart
/// ==============================================================================
/// العقل المدبر لشاشة أقسام حصن المسلم بنمط Cubit.
/// يتولى جلب الأبواب من الخدمة والبحث والتصفية الذكية.
/// ==============================================================================
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tarteel/core/helpers/arabic_search_helper.dart';
import 'package:tarteel/features/hisn_almuslim/services/hisn_service.dart';
import 'hisn_state.dart';

class HisnCubit extends Cubit<HisnState> {
  HisnCubit() : super(const HisnState(isLoading: true)) {
    loadCategories();
  }

  /// تحميل أقسام وأبواب حصن المسلم
  Future<void> loadCategories() async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      final actions = await HisnService.loadHisnAsActions();
      emit(state.copyWith(
        allActions: actions,
        filteredActions: actions,
        isLoading: false,
        searchQuery: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تحميل كتاب حصن المسلم',
      ));
    }
  }

  /// البحث وتصفية أبواب حصن المسلم باللغة العربية
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
