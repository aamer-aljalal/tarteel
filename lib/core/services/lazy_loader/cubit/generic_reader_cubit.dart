/// ==============================================================================
///  وصف الملف: generic_reader_cubit.dart
/// ==============================================================================
/// كيوبت عام وموحد بنسبة 100% لإدارة شاشات التفاصيل والقراءة في التطبيق بالكامل:
/// (الأذكار، حصن المسلم، الأحاديث، السور، قصص الأنبياء، أسماء الله الحسنى...).
///
/// يدير بدون تكرار الكود:
/// 1. التحميل عند الطلب والتخزين الذكي.
/// 2. العدادات وتكرار القراءة والتنبيهات الاهتزازية.
/// 3. التكبير والتصغير وتغيير حجم الخط.
/// 4. الحفظ التلقائي لموقع المستخدم اليومي في SharedPreferences.
/// ==============================================================================
library;

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/services/stats_service.dart';
import 'generic_reader_state.dart';

class GenericReaderCubit<TDetail, TItem>
    extends Cubit<GenericReaderState<TDetail, TItem>> {
  /// دالة جلب التفاصيل عند الطلب
  final Future<TDetail> Function(String title) detailFetcher;

  /// دالة استخراج العناصر الفرعية من الكائن (مثل استخراج الآيات أو الأدعية)
  final List<TItem> Function(TDetail detail) itemsExtractor;

  /// دالة استخراج الهدف الرقمي لكل عنصر (كم مرة يُكرر، الافتراضي 1)
  final int Function(TItem item)? targetRepeatExtractor;

  /// تصنيف العمل للوصول السريع والإحصائيات (مثل: 'azkar', 'hisn', 'quran', 'hadith')
  final String categoryKey;

  GenericReaderCubit({
    TDetail? initialDetail,
    required String initialTitle,
    required this.detailFetcher,
    required this.itemsExtractor,
    required this.categoryKey,
    this.targetRepeatExtractor,
  }) : super(GenericReaderState(
          detail: initialDetail,
          title: initialTitle,
          isLoading: initialDetail == null,
        )) {
    _initialize(initialDetail, initialTitle);
  }

  Future<void> _initialize(TDetail? initialDetail, String title) async {
    TDetail? detail = initialDetail;

    if (detail == null) {
      emit(state.copyWith(isLoading: true));
      try {
        detail = await detailFetcher(title);
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'تعذر تحميل البيانات: $e',
        ));
      }
    }

    if (detail == null) return;

    final subItems = itemsExtractor(detail);
    final initialCounters = List<int>.filled(subItems.length, 0);

    emit(state.copyWith(
      detail: detail,
      title: title,
      items: subItems,
      counters: initialCounters,
      isLoading: false,
    ));

    await _loadSavedProgress(title, subItems);
  }

  Future<void> _loadSavedProgress(String title, List<TItem> subItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final haptic = prefs.getBool('haptic_feedback') ?? true;
      final savedFontSize =
          prefs.getDouble('${categoryKey}_font_size') ?? 18.0;

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month}-${now.day}';
      final savedDate = prefs.getString('${categoryKey}_date_$title');

      final loadedCounters = List<int>.filled(subItems.length, 0);

      if (savedDate == todayStr) {
        for (int i = 0; i < subItems.length; i++) {
          loadedCounters[i] =
              prefs.getInt('${categoryKey}_count_${title}_$i') ?? 0;
        }
      } else {
        await prefs.setString('${categoryKey}_date_$title', todayStr);
        for (int i = 0; i < subItems.length; i++) {
          await prefs.remove('${categoryKey}_count_${title}_$i');
        }
      }

      final savedIndex = prefs.getInt('${categoryKey}_index_$title') ?? 0;
      final validIndex =
          (savedIndex > 0 && savedIndex < subItems.length) ? savedIndex : 0;

      emit(state.copyWith(
        currentIndex: validIndex,
        counters: loadedCounters,
        fontSize: savedFontSize,
        hapticEnabled: haptic,
      ));

      _saveRecentAction();
    } catch (_) {}
  }

  /// زيادة العداد للعنصر الحالي
  void incrementCounter({
    VoidCallback? onSingleCompleted,
    VoidCallback? onAllCompleted,
  }) {
    if (state.items.isEmpty || state.counters.isEmpty) return;

    final idx = state.currentIndex;
    final item = state.currentItem;
    if (item == null) return;

    final target = targetRepeatExtractor != null
        ? targetRepeatExtractor!(item)
        : 1;

    final updated = List<int>.from(state.counters);
    updated[idx]++;

    if (state.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }

    emit(state.copyWith(counters: updated));

    // حفظ في التخزين
    final count = updated[idx];
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt('${categoryKey}_count_${state.title}_$idx', count);
    }).catchError((_) {});

    StatsService.recordAction(categoryKey, amount: 1);

    // التحقق من اكتمال هذا العنصر
    if (count >= target) {
      final isAllDone = _checkAllCompleted(updated);
      if (isAllDone) {
        StatsService.recordAction('completed_${categoryKey}_category');
        if (state.hapticEnabled) HapticFeedback.vibrate();
        onAllCompleted?.call();
      } else {
        onSingleCompleted?.call();
      }
    }
  }

  bool _checkAllCompleted(List<int> currentCounters) {
    for (int i = 0; i < state.items.length; i++) {
      final target = targetRepeatExtractor != null
          ? targetRepeatExtractor!(state.items[i])
          : 1;
      if (currentCounters[i] < target) return false;
    }
    return true;
  }

  /// تغيير الصفحة الحالية
  void changePage(int newIndex) {
    if (newIndex >= 0 && newIndex < state.items.length) {
      emit(state.copyWith(currentIndex: newIndex));
      _saveRecentAction();
    }
  }

  Future<void> _saveRecentAction() async {
    if (state.title.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${categoryKey}_index_${state.title}', state.currentIndex);
      await RecentActionsManager.addAction(
        category: categoryKey,
        title: state.title,
        subtitle: 'العنصر ${state.currentIndex + 1}/${state.items.length}',
        extraData: {
          'category_title': state.title,
          'current_index': state.currentIndex,
        },
      );
    } catch (_) {}
  }

  /// تكبير الخط
  void zoomIn() {
    if (state.fontSize < 34.0) {
      final newSize = state.fontSize + 2.0;
      emit(state.copyWith(fontSize: newSize));
      _persistFontSize(newSize);
      if (state.hapticEnabled) HapticFeedback.mediumImpact();
    }
  }

  /// تصغير الخط
  void zoomOut() {
    if (state.fontSize > 14.0) {
      final newSize = state.fontSize - 2.0;
      emit(state.copyWith(fontSize: newSize));
      _persistFontSize(newSize);
      if (state.hapticEnabled) HapticFeedback.mediumImpact();
    }
  }

  Future<void> _persistFontSize(double size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${categoryKey}_font_size', size);
    } catch (_) {}
  }

  /// تصفية وإعادة تعيين العدادات
  Future<void> resetCategory() async {
    final reset = List<int>.filled(state.items.length, 0);
    emit(state.copyWith(currentIndex: 0, counters: reset));

    try {
      final prefs = await SharedPreferences.getInstance();
      for (int i = 0; i < state.items.length; i++) {
        await prefs.remove('${categoryKey}_count_${state.title}_$i');
      }
    } catch (_) {}

    _saveRecentAction();
  }
}
