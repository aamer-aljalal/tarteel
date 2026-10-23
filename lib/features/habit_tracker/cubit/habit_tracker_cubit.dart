import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:tarteel/core/services/stats_service.dart';
import '../models/daily_habits_record.dart';
import '../models/prayer_station_model.dart';
import '../services/habit_calendar_helper.dart';
import '../services/habit_storage_service.dart';
import 'habit_tracker_state.dart';

/// ==============================================================================
/// كيونت إدارة محطات العبادات والمسار الزمني الذكي
/// ==============================================================================
class HabitTrackerCubit extends Cubit<HabitTrackerState> {
  HabitTrackerCubit()
    : super(
        HabitTrackerState(
          selectedDate: DateTime.now(),
          stations: PrayerStationModel.getDefaultStations(),
          selectedStationId: 'dhuhr',
          completedIds: const {},
          streak: 0,
          isLoading: true,
        ),
      );

  /// تهيئة المحطات بناءً على مواقيت الصلاة والوقت الحالي
  Future<void> init({PrayerTimes? prayerTimes}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final now = DateTime.now();
      final stations = _buildStationsWithTimes(prayerTimes);
      final activeStationId = _resolveActiveStationId(now, prayerTimes);

      final record = await HabitStorageService.getRecord(now);
      final totalCount = _calculateTotalItems(stations);
      final streak = await HabitStorageService.calculateCurrentStreak(
        totalCount,
      );
      final summary = await HabitStorageService.getStatsSummary(totalCount);

      emit(
        state.copyWith(
          selectedDate: now,
          stations: stations,
          selectedStationId: activeStationId,
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

  /// التبديل بين محطات الصلاة (الفجر، الظهر، العصر...)
  void selectStation(String stationId) {
    if (state.selectedStationId != stationId) {
      emit(state.copyWith(selectedStationId: stationId));
    }
  }

  /// الانتقال للمحطة السابقة في المسار
  void previousStation() {
    final list = state.stations;
    if (list.isEmpty) return;
    final currentIndex = list.indexWhere(
      (s) => s.id == state.selectedStationId,
    );
    final prevIndex = (currentIndex - 1 + list.length) % list.length;
    emit(state.copyWith(selectedStationId: list[prevIndex].id));
  }

  /// الانتقال للمحطة التالية في المسار
  void nextStation() {
    final list = state.stations;
    if (list.isEmpty) return;
    final currentIndex = list.indexWhere(
      (s) => s.id == state.selectedStationId,
    );
    final nextIndex = (currentIndex + 1) % list.length;
    emit(state.copyWith(selectedStationId: list[nextIndex].id));
  }

  /// التبديل بين الأيام السابقة أو التالية
  Future<void> changeDate(DateTime date) async {
    emit(state.copyWith(isLoading: true));
    try {
      final record = await HabitStorageService.getRecord(date);
      emit(
        state.copyWith(
          selectedDate: date,
          completedIds: record.completedHabitIds,
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  /// تبديل إنجاز عبادة محددة (سنة قبلية، فريضة، سنة بعدية، أذكار)
  Future<void> toggleItem(String itemId) async {
    final currentSet = Set<String>.from(state.completedIds);
    final wasCompleted = currentSet.contains(itemId);

    if (wasCompleted) {
      currentSet.remove(itemId);
    } else {
      currentSet.add(itemId);
      // إرسال نشاط للإحصائيات العامة
      if (itemId.contains('azkar')) {
        StatsService.recordAction('azkar', amount: 1);
      }
    }

    final dateKey = HabitCalendarHelper.formatDateKey(state.selectedDate);
    final newRecord = DailyHabitsRecord(
      date: dateKey,
      completedHabitIds: currentSet,
    );
    await HabitStorageService.saveRecord(newRecord);

    final totalCount = _calculateTotalItems(state.stations);
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

  /// حساب الوقت الفعلي لكل محطة بناءً على مواقيت الصلاة المحسوبة
  List<PrayerStationModel> _buildStationsWithTimes(PrayerTimes? pt) {
    final defaults = PrayerStationModel.getDefaultStations();
    if (pt == null) return defaults;

    String formatTime(DateTime dt) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'م' : 'ص';
      return HabitCalendarHelper.toArabicNumbers('$hour:$minute $period');
    }

    return defaults.map((station) {
      String resolvedTime = station.approximateTime;
      switch (station.id) {
        case 'fajr':
          resolvedTime = formatTime(pt.fajr);
          break;
        case 'duha':
          resolvedTime = formatTime(
            pt.sunrise.add(const Duration(minutes: 20)),
          );
          break;
        case 'dhuhr':
          resolvedTime = formatTime(pt.dhuhr);
          break;
        case 'asr':
          resolvedTime = formatTime(pt.asr);
          break;
        case 'maghrib':
          resolvedTime = formatTime(pt.maghrib);
          break;
        case 'isha':
          resolvedTime = formatTime(pt.isha);
          break;
        case 'qiyam':
          resolvedTime = '١١:٠٠ م';
          break;
      }

      return PrayerStationModel(
        id: station.id,
        title: station.title,
        shortName: station.shortName,
        icon: station.icon,
        approximateTime: resolvedTime,
        virtueHadith: station.virtueHadith,
        items: station.items,
      );
    }).toList();
  }

  /// تحديد المحطة النشطة بناءً على اللحظة الحالية في اليوم
  String _resolveActiveStationId(DateTime now, PrayerTimes? pt) {
    if (pt != null) {
      if (now.isBefore(pt.sunrise)) return 'fajr';
      if (now.isBefore(pt.dhuhr)) return 'duha';
      if (now.isBefore(pt.asr)) return 'dhuhr';
      if (now.isBefore(pt.maghrib)) return 'asr';
      if (now.isBefore(pt.isha)) return 'maghrib';
      if (now.hour < 22) return 'isha';
      return 'qiyam';
    }

    final hour = now.hour;
    if (hour >= 4 && hour < 7) return 'fajr';
    if (hour >= 7 && hour < 12) return 'duha';
    if (hour >= 12 && hour < 15) return 'dhuhr';
    if (hour >= 15 && hour < 18) return 'asr';
    if (hour >= 18 && hour < 20) return 'maghrib';
    if (hour >= 20 && hour < 23) return 'isha';
    return 'qiyam';
  }

  int _calculateTotalItems(List<PrayerStationModel> list) {
    int total = 0;
    for (final s in list) {
      total += s.items.length;
    }
    return total > 0 ? total : 1;
  }
}
