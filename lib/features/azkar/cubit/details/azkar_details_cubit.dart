/// ==============================================================================
///  وصف الملف: azkar_details_cubit.dart
/// ==============================================================================
/// العقل المدبر لشاشة تفاصيل وقراءة الأذكار بنمط Cubit.
/// يتولى إدارة العدادات، الحفظ اليومي في التخزين، التقليب، والتكبير/التصغير.
/// ==============================================================================
library;

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/in_app_notification_service.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/services/stats_service.dart';
import 'package:tarteel/features/azkar/model/zekr_category.dart';
import 'package:tarteel/features/azkar/services/azkar_service.dart';
import 'azkar_details_state.dart';

class AzkarDetailsCubit extends Cubit<AzkarDetailsState> {
  AzkarDetailsCubit({
    ZekrCategory? initialCategory,
    String? initialCategoryTitle,
  }) : super(AzkarDetailsState(
          category: initialCategory,
          categoryTitle: initialCategory?.title ?? initialCategoryTitle ?? '',
          isLoading: initialCategory == null,
        )) {
    _initialize(initialCategory, initialCategoryTitle);
  }

  Future<void> _initialize(
    ZekrCategory? initialCategory,
    String? initialCategoryTitle,
  ) async {
    ZekrCategory? cat = initialCategory;

    // إذا لم يتم تمرير الـ Category كاملة، نقوم بتحميلها فورياً عند الطلب
    if (cat == null && initialCategoryTitle != null) {
      emit(state.copyWith(isLoading: true));
      try {
        cat = await AzkarService.loadCategoryByTitle(initialCategoryTitle);
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'تعذر تحميل الأذكار',
        ));
        return;
      }
    }

    if (cat == null) return;

    emit(state.copyWith(
      category: cat,
      categoryTitle: cat.title,
      isLoading: false,
    ));

    // التحقق من إشعارات الأذكار الدورية وإكمالها
    if (cat.title == 'أذكار الصباح') {
      InAppNotificationService.markCompleted('morning_azkar');
    } else if (cat.title == 'أذكار المساء') {
      InAppNotificationService.markCompleted('evening_azkar');
    } else if (cat.title == 'أذكار النوم') {
      InAppNotificationService.markCompleted('sleep_azkar');
    }

    // استرجاع التقدم والعدادات اليومية من SharedPreferences
    await _loadSavedProgress(cat);
  }

  Future<void> _loadSavedProgress(ZekrCategory cat) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final haptic = prefs.getBool('haptic_feedback') ?? true;

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';
      final savedDate = prefs.getString('azkar_date_${cat.title}');

      if (savedDate == todayStr) {
        for (int i = 0; i < cat.azkar.length; i++) {
          final countVal = prefs.getInt('azkar_count_${cat.title}_$i') ?? 0;
          cat.azkar[i].currentCount = countVal;
        }
      } else {
        await prefs.setString('azkar_date_${cat.title}', todayStr);
        for (int i = 0; i < cat.azkar.length; i++) {
          cat.azkar[i].currentCount = 0;
          await prefs.remove('azkar_count_${cat.title}_$i');
        }
      }

      final savedIndex = prefs.getInt('zekr_index_${cat.title}') ?? 0;
      final validIndex =
          (savedIndex > 0 && savedIndex < cat.azkar.length) ? savedIndex : 0;

      final isCompleted = _checkAllCompleted(cat);

      emit(state.copyWith(
        currentIndex: validIndex,
        hapticEnabled: haptic,
        isCategoryCompleted: isCompleted,
      ));

      _saveRecentAction();
    } catch (_) {}
  }

  bool _checkAllCompleted(ZekrCategory cat) {
    return cat.azkar.every((zekr) {
      final repeat = int.tryParse(zekr.count) ?? 1;
      return zekr.currentCount >= repeat;
    });
  }

  /// النقر على العداد لتسجيل تكرار الذكر
  void incrementCounter({required void Function() onSingleCompleted, required void Function() onAllCompleted}) {
    final cat = state.category;
    if (cat == null || cat.azkar.isEmpty) return;

    final zekr = state.currentZekr;
    if (zekr == null) return;

    final targetTotal = state.totalRepeat;

    // تسجيل الإحصائيات
    StatsService.recordAction('azkar');

    if (zekr.currentCount < targetTotal) {
      zekr.currentCount++;

      // حفظ العداد الحالي محلياً
      final targetIndex = state.currentIndex;
      final categoryTitle = cat.title;
      final newCount = zekr.currentCount;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('azkar_count_${categoryTitle}_$targetIndex', newCount);
      }).catchError((_) {});

      if (state.hapticEnabled) {
        HapticFeedback.mediumImpact();
      }

      final isAllDone = _checkAllCompleted(cat);

      emit(state.copyWith(
        isCategoryCompleted: isAllDone,
      ));

      // في حال اكتمال تكرار هذا الذكر
      if (zekr.currentCount >= targetTotal) {
        StatsService.recordAction('completed_azkar_single');

        if (isAllDone) {
          StatsService.recordAction('completed_azkar_category');
          if (state.hapticEnabled) HapticFeedback.vibrate();
          onAllCompleted();
        } else {
          onSingleCompleted();
        }
      }
    }
  }

  /// تغيير الصفحة الحالية في الـ PageView
  void changePage(int newIndex) {
    if (state.category == null) return;
    if (newIndex >= 0 && newIndex < state.category!.azkar.length) {
      emit(state.copyWith(currentIndex: newIndex));
      _saveRecentAction();
    }
  }

  /// حفظ العمل الأخير للوصول السريع
  Future<void> _saveRecentAction() async {
    final cat = state.category;
    if (cat == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('zekr_index_${cat.title}', state.currentIndex);
      await RecentActionsManager.addAction(
        category: 'azkar',
        title: cat.title,
        subtitle: 'ذكر ${state.currentIndex + 1}/${cat.azkar.length}',
        extraData: {'category_title': cat.title},
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

  /// إعادة تعيين عدادات القسم بالكامل
  Future<void> resetCategory() async {
    final cat = state.category;
    if (cat == null) return;

    for (var zekr in cat.azkar) {
      zekr.currentCount = 0;
    }

    emit(state.copyWith(
      currentIndex: 0,
      isCategoryCompleted: false,
    ));

    try {
      final prefs = await SharedPreferences.getInstance();
      for (int i = 0; i < cat.azkar.length; i++) {
        await prefs.remove('azkar_count_${cat.title}_$i');
      }
    } catch (_) {}

    _saveRecentAction();
  }
}
