import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tarteel/core/services/stats_service.dart';
import '../models/daily_habits_record.dart';
import '../models/habit_item.dart';
import '../services/habit_calendar_helper.dart';
import '../services/habit_storage_service.dart';
import 'habit_tracker_state.dart';

/// ==============================================================================
/// كيونت إدارة سجل العبادات اليومي
/// ==============================================================================
class HabitTrackerCubit extends Cubit<HabitTrackerState> {
  HabitTrackerCubit()
      : super(
          HabitTrackerState(
            selectedDate: DateTime.now(),
            activeHabits: const [],
            completedIds: const {},
            allHabits: HabitItem.getDefaultHabits(),
            enabledHabitIds: const {},
            streak: 0,
            isLoading: true,
          ),
        );

  /// تهيئة وتحميل بيانات اليوم
  Future<void> init() async {
    emit(state.copyWith(isLoading: true));
    try {
      final enabledIds = await HabitStorageService.getEnabledHabitIds();
      final now = DateTime.now();
      final activeList = _buildActiveHabitsForDate(now, enabledIds);
      final record = await HabitStorageService.getRecord(now);
      final streak = await HabitStorageService.calculateCurrentStreak(activeList.length);
      final summary = await HabitStorageService.getStatsSummary(activeList.length);

      emit(
        state.copyWith(
          selectedDate: now,
          allHabits: HabitItem.getDefaultHabits(),
          enabledHabitIds: enabledIds,
          activeHabits: activeList,
          completedIds: record.completedHabitIds,
          streak: streak,
          statsSummary: summary,
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// التبديل بين الأيام السابقة أو التالية
  Future<void> changeDate(DateTime date) async {
    emit(state.copyWith(isLoading: true));
    try {
      final activeList = _buildActiveHabitsForDate(date, state.enabledHabitIds);
      final record = await HabitStorageService.getRecord(date);

      emit(
        state.copyWith(
          selectedDate: date,
          activeHabits: activeList,
          completedIds: record.completedHabitIds,
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// تبديل حالة عبادة (إكمال / إلغاء إكمال)
  Future<void> toggleHabit(String habitId) async {
    final currentSet = Set<String>.from(state.completedIds);
    final wasCompleted = currentSet.contains(habitId);

    if (wasCompleted) {
      currentSet.remove(habitId);
    } else {
      currentSet.add(habitId);
      // التكامل مع StatsService لتسجيل النشاط الإيماني
      _recordStatsForHabit(habitId);
    }

    // حفظ السجل في التخزين المحلي
    final dateKey = HabitCalendarHelper.formatDateKey(state.selectedDate);
    final newRecord = DailyHabitsRecord(
      date: dateKey,
      completedHabitIds: currentSet,
    );
    await HabitStorageService.saveRecord(newRecord);

    // تحديث السلسلة والإحصائيات
    final streak = await HabitStorageService.calculateCurrentStreak(state.activeHabits.length);
    final summary = await HabitStorageService.getStatsSummary(state.activeHabits.length);

    emit(
      state.copyWith(
        completedIds: currentSet,
        streak: streak,
        statsSummary: summary,
      ),
    );
  }

  /// حفظ تخصيص قائمة العبادات التي يريد المستخدم متابعتها
  Future<void> updateCustomization(Set<String> newEnabledIds) async {
    await HabitStorageService.saveEnabledHabitIds(newEnabledIds);
    final activeList = _buildActiveHabitsForDate(state.selectedDate, newEnabledIds);
    final streak = await HabitStorageService.calculateCurrentStreak(activeList.length);
    final summary = await HabitStorageService.getStatsSummary(activeList.length);

    emit(
      state.copyWith(
        enabledHabitIds: newEnabledIds,
        activeHabits: activeList,
        streak: streak,
        statsSummary: summary,
      ),
    );
  }

  /// بناء قائمة العبادات المعروضة بناءً على التاريخ واختيارات المستخدم
  List<HabitItem> _buildActiveHabitsForDate(DateTime date, Set<String> enabledIds) {
    final all = HabitItem.getDefaultHabits();
    final List<HabitItem> result = [];

    for (final item in all) {
      // 1. الصلوات المفروضة الخمس تُعرض دائماً
      if (item.isMandatory) {
        result.add(item);
        continue;
      }

      // 2. إذا لم يكن مفعلاً من قبل المستخدم يتم تجاوزه
      if (!enabledIds.contains(item.id)) {
        continue;
      }

      // 3. سورة الكهف: تظهر فقط يوم الجمعة
      if (item.id == 'surah_kahf') {
        if (HabitCalendarHelper.isFriday(date)) {
          result.add(item);
        }
        continue;
      }

      // 4. صيام التطوع: يظهر فقط إذا كان اليوم إثنين، خميس، أو من الأيام البيض
      if (item.id == 'fasting_sunnah') {
        final fastingReason = HabitCalendarHelper.getFastingReason(date);
        if (fastingReason != null) {
          result.add(item.copyWith(subtitle: fastingReason));
        }
        continue;
      }

      // 5. باقي السنن والأوراد العادية المفعّلة
      result.add(item);
    }

    return result;
  }

  /// إرسال النشاط لنظام إحصائيات التطبيق العام
  void _recordStatsForHabit(String habitId) {
    if (habitId.contains('azkar')) {
      StatsService.recordAction('azkar', amount: 1);
    } else if (habitId == 'daily_istighfar') {
      StatsService.recordAction('tasbeeh', amount: 33);
    } else if (habitId == 'quran_wird') {
      StatsService.recordAction('quran', amount: 1);
    }
  }
}
