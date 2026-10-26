import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/providers/prayer_provider.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/backgrounds/islamic_pattern_background.dart';
import '../cubit/habit_tracker_cubit.dart';
import '../cubit/habit_tracker_state.dart';
import '../models/unified_habit_item.dart';
import '../services/habit_calendar_helper.dart';
import '../widgets/habit_tracker_fixed_header.dart';
import '../widgets/habit_weekly_chart_sheet.dart';
import '../widgets/unified_habit_tile.dart';

/// ==============================================================================
/// الشاشة الرئيسية ليوميات المسلم (قائمة موحدة بتبويبين: المتبقية والمنجزة)
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

            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // 1. رأس الصفحة الثابت في الأعلى (بطاقة الإنجاز والتقويم الطويلة الشفافة)
                  HabitTrackerFixedHeader(
                    selectedDate: state.selectedDate,
                    percentage: state.dailyCompletionPercentage,
                    completedCount: state.totalCompletedCount,
                    totalCount: state.totalItemsCount,
                    streak: state.streak,
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
                  ),

                  // 2. شريط التبويب الأنيق والمدمج (المتبقية والمنجزة)
                  _buildCompactTabBar(context, state),

                  // 3. القائمة المتسلسلة الموحدة (بدون فواصل أو تصنيفات مصطنعة)
                  Expanded(
                    child: IslamicPatternBackground(
                      child: TabBarView(
                        children: [
                          // التبويب الأول: العبادات المتبقية
                          _buildHabitsList(
                            items: state.remainingItems,
                            emptyMessage: 'ما شاء الله! أنجزت جميع عبادات هذا اليوم بالكامل.',
                            emptyIcon: Icons.verified_rounded,
                            isCompletedList: false,
                            onToggle: (id) => cubit.toggleItem(id),
                          ),

                          // التبويب الثاني: العبادات المنجزة
                          _buildHabitsList(
                            items: state.completedItems,
                            emptyMessage: 'لم تقم بإنجاز أي عبادة بعد، ابدأ يومك بذكر الله وتأدية السنن والفرائض.',
                            emptyIcon: Icons.task_alt_rounded,
                            isCompletedList: true,
                            onToggle: (id) => cubit.toggleItem(id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// شريط التبويب المدمج والمصمم بعناية فائقة لاستغلال المساحة
  Widget _buildCompactTabBar(BuildContext context, HabitTrackerState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final remainingArabic = HabitCalendarHelper.toArabicNumbers(
      state.remainingItems.length,
    );
    final completedArabic = HabitCalendarHelper.toArabicNumbers(
      state.completedItems.length,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
      ),
      child: Container(
        height: 34.h,
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: TabBar(
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6.r),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? Colors.white60 : AppColors.lightSecondaryText,
          labelStyle: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.normal,
            fontFamily: 'Cairo',
          ),
          dividerColor: Colors.transparent,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radio_button_unchecked_rounded, size: 14.r),
                  SizedBox(width: 5.w),
                  Text('المتبقية ($remainingArabic)'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 14.r),
                  SizedBox(width: 5.w),
                  Text('المنجزة ($completedArabic)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// القائمة المتصلة للعبادات بدون عناوين أقسام، مع تفادي الفراغات الكبيرة
  Widget _buildHabitsList({
    required List<UnifiedHabitItem> items,
    required String emptyMessage,
    required IconData emptyIcon,
    required bool isCompletedList,
    required Function(String) onToggle,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                emptyIcon,
                size: 42.r,
                color: AppColors.goldAccent.withValues(alpha: 0.8),
              ),
              SizedBox(height: 10.h),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightSecondaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: 6.h, bottom: 24.h),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return UnifiedHabitTile(
          item: item,
          isCompleted: isCompletedList,
          onToggle: () => onToggle(item.id),
        );
      },
    );
  }
}
