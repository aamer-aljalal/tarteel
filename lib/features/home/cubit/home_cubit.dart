/// ==============================================================================
///  وصف الملف: home_cubit.dart
/// ==============================================================================
/// العقل المدبر لبيانات الصفحة الرئيسية بنمط Cubit.
///
///  وظائفه:
/// 1. جلب الأزرار من الخدمة (HomeActionsService) بدون أي كتابة يدوية في الكود.
/// 2. إدارة وتحديث الأزرار في الوقت الفعلي عند وصول زر جديد من جيت هب.
/// 3. إشعار الواجهة فوراً عبر emit() دون الحاجة لأي إعادة تشغيل للتطبيق.
/// ==============================================================================
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/features/home/cubit/home_state.dart';
import 'package:tarteel/features/home/services/home_actions_service.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState(isLoading: true)) {
    loadHomeData();
  }

  // ============================================================================
  //  جلب بيانات الصفحة الرئيسية (الأزرار من الخدمة والتخزين المحلي)
  // ============================================================================
  Future<void> loadHomeData() async {
    try {
      emit(state.copyWith(isLoading: true));

      // جلب الأزرار مباشرة من الخدمة الذكية (SharedPreferences أو JSON)
      final actions = await HomeActionsService.loadActions();

      emit(
        state.copyWith(
          actions: actions,
          isLoading: false,
          // يمكن ربطها لاحقاً بقيم حقيقية من StatsService
          adhkarCount: 120,
          adhkarTarget: 300,
          pagesRead: 5,
          pagesTarget: 20,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'فشل تحميل الأزرار: $e',
        ),
      );
    }
  }

  // ============================================================================
  //  إضافة أو تحديث زر ديناميكي جديد (من جيت هب أو أي مصدر)
  // ============================================================================
  Future<void> addDynamicAction(AccessListModel newAction) async {
    try {
      // حفظ الزر في التخزين الدائم للخدمة أولاً
      final updatedActions =
          await HomeActionsService.addOrUpdateAction(newAction);

      //  إشعار الواجهة فوراً بالحالة الجديدة ليظهر الزر على الشاشة مباشرة!
      emit(state.copyWith(actions: updatedActions));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'فشل إضافة الزر: $e'));
    }
  }

  // ============================================================================
  //  مزامنة الأزرار من رابط GitHub وتحديث الصفحة فوراً
  // ============================================================================
  Future<void> syncFromGithub(String rawUrl) async {
    try {
      final updatedActions = await HomeActionsService.syncFromGithub(rawUrl);
      emit(state.copyWith(actions: updatedActions));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'فشل مزامنة الأزرار: $e'));
    }
  }

  // ============================================================================
  //  إزالة أو إخفاء زر
  // ============================================================================
  Future<void> removeDynamicAction(String id) async {
    try {
      final updatedActions = await HomeActionsService.removeDynamicAction(id);
      emit(state.copyWith(actions: updatedActions));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'فشل حذف الزر: $e'));
    }
  }

  // ============================================================================
  //  إعادة تعيين الأزرار إلى الحالة الافتراضية
  // ============================================================================
  Future<void> resetToDefaults() async {
    final defaultActions = await HomeActionsService.resetToDefaults();
    emit(state.copyWith(actions: defaultActions));
  }
}
