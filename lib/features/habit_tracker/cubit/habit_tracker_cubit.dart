import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:adhan/adhan.dart';
import 'package:tarteel/core/services/stats_service.dart';
import '../models/daily_habits_record.dart';
import '../services/habit_calendar_helper.dart';
import '../services/habit_storage_service.dart';
import '../services/unified_habit_factory.dart';
import 'habit_tracker_state.dart';

/// ==============================================================================
/// كيوبيت إدارة العبادات اليومية الموحدة (المتبقية والمنجزة)
/// ==============================================================================
class HabitTrackerCubit extends Cubit<HabitTrackerState> {
  PrayerTimes? _cachedPrayerTimes;

  HabitTrackerCubit()
      : super(
          HabitTrackerState(
            selectedDate: DateTime.now(),
            allItems: const [],
            completedIds: const {},
            streak: 0,
            isLoading: true,
          ),
        );

  /// تهيئة القائمة بناءً على مواقيت الصلاة واليوم الحالي
  Future<void> init({PrayerTimes? prayerTimes}) async {
    _cachedPrayerTimes = prayerTimes;
    emit(state.copyWith(isLoading: true));
    try {
      final now = DateTime.now();
      final items = UnifiedHabitFactory.buildDailyList(
        date: now,
        prayerTimes: _cachedPrayerTimes,
      );

      final record = await HabitStorageService.getRecord(now);
      final totalCount = items.length;
      final streak = await HabitStorageService.calculateCurrentStreak(totalCount);
      final summary = await HabitStorageService.getStatsSummary(totalCount);

      emit(
        state.copyWith(
          selectedDate: now,
          allItems: items,
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
      final items = UnifiedHabitFactory.buildDailyList(
        date: date,
        prayerTimes: _cachedPrayerTimes,
      );
      final record = await HabitStorageService.getRecord(date);
      emit(
        state.copyWith(
          selectedDate: date,
          allItems: items,
          completedIds: record.completedHabitIds,
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// تبديل حالة إنجاز عبادة محددة (نقل فوري بين المتبقية والمنجزة)
  Future<void> toggleItem(String itemId) async {
    final currentSet = Set<String>.from(state.completedIds);
    final wasCompleted = currentSet.contains(itemId);

    if (wasCompleted) {
      currentSet.remove(itemId);
    } else {
      currentSet.add(itemId);
      // تسجيل نشاط في إحصائيات التطبيق العامة
      if (itemId.contains('azkar') || itemId.contains('tasbeeh')) {
        StatsService.recordAction('azkar', amount: 1);
      } else if (itemId.contains('quran')) {
        StatsService.recordAction('quran', amount: 1);
      }
    }

    final dateKey = HabitCalendarHelper.formatDateKey(state.selectedDate);
    final newRecord = DailyHabitsRecord(
      date: dateKey,
      completedHabitIds: currentSet,
    );
    await HabitStorageService.saveRecord(newRecord);

    final totalCount = state.allItems.length;
    final streak = await HabitStorageService.calculateCurrentStreak(totalCount);
    final summary = await HabitStorageService.getStatsSummary(totalCount);

    emit(
      state.copyWith(
        completedIds: currentSet,
        streak: streak,
        statsSummary: summary,
      ),
      
    );
  }
}
