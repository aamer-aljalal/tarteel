import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:tarteel/core/providers/prayer_provider.dart';
import 'package:tarteel/core/widgets/backgrounds/islamic_pattern_background.dart';
import '../cubit/habit_tracker_cubit.dart';
import '../cubit/habit_tracker_state.dart';
import '../widgets/habit_tracker_fixed_header.dart';
import '../widgets/habit_weekly_chart_sheet.dart';
import '../widgets/prayer_station_action_list.dart';

/// ==============================================================================
/// الشاشة الرئيسية ليوميات المسلم (تصميم فخم، رأس ثابت يحوي بطاقة الإنجاز والمسار بالسحب)
/// ==============================================================================
class HabitTrackerScreen extends StatelessWidget {
  const HabitTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prayerProvider = context.read<PrayerProvider>();

    return BlocProvider(
      create: (_) => HabitTrackerCubit()..init(prayerTimes: prayerProvider.prayerTimes),
      child: const _HabitTrackerView(),
    );
  }
}

class _HabitTrackerView extends StatelessWidget {
  const _HabitTrackerView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: BlocBuilder<HabitTrackerCubit, HabitTrackerState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final cubit = context.read<HabitTrackerCubit>();
            final currentStation = state.currentStation;

            return Column(
              children: [
                // 1. رأس الصفحة الثابت في الأعلى (يحوي بطاقة الإنجاز الموحدة + بطاقة المسار البارزة بالسحب)
                HabitTrackerFixedHeader(
                  selectedDate: state.selectedDate,
                  percentage: state.dailyCompletionPercentage,
                  completedCount: state.totalCompletedCount,
                  totalCount: state.totalItemsCount,
                  streak: state.streak,
                  stations: state.stations,
                  selectedStationId: state.selectedStationId,
                  completedIds: state.completedIds,
                  onPreviousDay: () {
                    cubit.changeDate(
                      state.selectedDate.subtract(const Duration(days: 1)),
                    );
                  },
                  onNextDay: () {
                    cubit.changeDate(
                      state.selectedDate.add(const Duration(days: 1)),
                    );
                  },
                  onOpenStats: () {
                    if (state.statsSummary != null) {
                      HabitWeeklyChartSheet.show(
                        context,
                        summary: state.statsSummary!,
                      );
                    }
                  },
                  onStationChanged: (id) => cubit.selectStation(id),
                ),

                // 2. الجزء التفاعلي تحت الرأس مباشرة: قائمة كبسولات العبادات التفاعلية
                Expanded(
                  child: IslamicPatternBackground(
                    child: PrayerStationActionList(
                      station: currentStation,
                      completedIds: state.completedIds,
                      selectedDate: state.selectedDate,
                      onToggleItem: (id) => cubit.toggleItem(id),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
