/// ==============================================================================
///  وصف الملف: hisn_details_cubit.dart
/// ==============================================================================
/// العقل المدبر لشاشة تفاصيل وقراءة حصن المسلم بنمط Cubit.
/// يتولى إدارة العدادات، الحفظ اليومي، التكبير/التصغير، والتنقل.
/// ==============================================================================
library;

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/services/stats_service.dart';
import 'package:tarteel/features/hisn_almuslim/model/hisn_category.dart';
import 'package:tarteel/features/hisn_almuslim/services/hisn_service.dart';
import 'hisn_details_state.dart';

class HisnDetailsCubit extends Cubit<HisnDetailsState> {
  HisnDetailsCubit({
    HisnCategory? initialCategory,
    String? initialCategoryTitle,
  }) : super(HisnDetailsState(
          category: initialCategory,
          categoryTitle: initialCategory?.title ?? initialCategoryTitle ?? '',
          isLoading: initialCategory == null,
        )) {
    _initialize(initialCategory, initialCategoryTitle);
  }

  Future<void> _initialize(
    HisnCategory? initialCategory,
    String? initialCategoryTitle,
  ) async {
    HisnCategory? cat = initialCategory;

    if (cat == null && initialCategoryTitle != null) {
      emit(state.copyWith(isLoading: true));
      try {
        cat = await HisnService.loadCategoryByTitle(initialCategoryTitle);
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'تعذر تحميل أدعية الباب',
        ));
        return;
      }
    }

    if (cat == null) return;

    final counters = List<int>.filled(cat.texts.length, 0);

    emit(state.copyWith(
      category: cat,
      categoryTitle: cat.title,
      counters: counters,
      isLoading: false,
    ));

    await _loadSavedProgress(cat);
  }

  Future<void> _loadSavedProgress(HisnCategory cat) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final haptic = prefs.getBool('haptic_feedback') ?? true;

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';
      final savedDate = prefs.getString('hisn_date_${cat.title}');

      final newCounters = List<int>.filled(cat.texts.length, 0);

      if (savedDate == todayStr) {
        for (int i = 0; i < cat.texts.length; i++) {
          final countVal = prefs.getInt('hisn_count_${cat.title}_$i') ?? 0;
          newCounters[i] = countVal;
        }
      } else {
        await prefs.setString('hisn_date_${cat.title}', todayStr);
        for (int i = 0; i < cat.texts.length; i++) {
          await prefs.remove('hisn_count_${cat.title}_$i');
        }
      }

      final savedIndex = prefs.getInt('hisn_index_${cat.title}') ?? 0;
      final validIndex =
          (savedIndex > 0 && savedIndex < cat.texts.length) ? savedIndex : 0;

      emit(state.copyWith(
        currentIndex: validIndex,
        counters: newCounters,
        hapticEnabled: haptic,
      ));

      _saveRecentAction();
    } catch (_) {}
  }

  /// النقر على عداد الدعاء
  void incrementCounter({required void Function() onNextRequested}) {
    if (state.category == null || state.counters.isEmpty) return;

    final updated = List<int>.from(state.counters);
    final idx = state.currentIndex;
    updated[idx]++;

    if (state.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }

    emit(state.copyWith(counters: updated));

    // حفظ في الذاكرة
    final catTitle = state.categoryTitle;
    final count = updated[idx];
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('hisn_count_${catTitle}_$idx', count);
    }).catchError((_) {});

    StatsService.recordAction('hisn', amount: 1);

    // الانتقال للدعاء التالي إذا اكتمل
    if (updated[idx] >= state.totalRepeat) {
      if (state.hapticEnabled) {
        Future.delayed(const Duration(milliseconds: 150), () {
          HapticFeedback.heavyImpact();
        });
      }

      if (idx < state.category!.texts.length - 1) {
        onNextRequested();
      }
    }
  }

  /// تغيير الصفحة
  void changePage(int newIndex) {
    if (state.category == null) return;
    if (newIndex >= 0 && newIndex < state.category!.texts.length) {
      emit(state.copyWith(currentIndex: newIndex));
      _saveRecentAction();
    }
  }

  /// حفظ العمل الأخير
  Future<void> _saveRecentAction() async {
    final catTitle = state.categoryTitle;
    if (catTitle.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('hisn_index_$catTitle', state.currentIndex);
      await RecentActionsManager.addAction(
        category: 'hisn',
        title: catTitle,
        subtitle: 'الدعاء ${state.currentIndex + 1}',
        extraData: {
          'category_title': catTitle,
          'current_index': state.currentIndex,
        },
      );
    } catch (_) {}
  }

  /// تكبير الخط
  void zoomIn() {
    if (state.fontSize < 34.0) {
      emit(state.copyWith(fontSize: state.fontSize + 2.0));
      if (state.hapticEnabled) HapticFeedback.mediumImpact();
    }
  }

  /// تصغير الخط
  void zoomOut() {
    if (state.fontSize > 14.0) {
      emit(state.copyWith(fontSize: state.fontSize - 2.0));
      if (state.hapticEnabled) HapticFeedback.mediumImpact();
    }
  }

  /// إعادة تعيين العدادات بالكامل
  Future<void> resetCategory() async {
    if (state.category == null) return;

    final resetCounters = List<int>.filled(state.category!.texts.length, 0);

    emit(state.copyWith(
      currentIndex: 0,
      counters: resetCounters,
    ));

    try {
      final prefs = await SharedPreferences.getInstance();
      for (int i = 0; i < state.category!.texts.length; i++) {
        await prefs.remove('hisn_count_${state.categoryTitle}_$i');
      }
    } catch (_) {}

    _saveRecentAction();
  }
}
