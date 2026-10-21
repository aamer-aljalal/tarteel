import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/widgets/backgrounds/islamic_pattern_background.dart';
import '../cubit/habit_tracker_cubit.dart';
import '../cubit/habit_tracker_state.dart';
import '../models/habit_category.dart';
import '../models/habit_item.dart';
import '../widgets/habit_customization_sheet.dart';
import '../widgets/habit_header_card.dart';
import '../widgets/habit_item_tile.dart';
import '../widgets/habit_special_banner.dart';
import '../widgets/habit_weekly_chart_sheet.dart';
import '../widgets/prayer_tracker_section.dart';

/// ==============================================================================
/// الشاشة الرئيسية لسجل العبادات اليومي وبناء العادات (يوميات المسلم)
/// ==============================================================================
class HabitTrackerScreen extends StatelessWidget {
  const HabitTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HabitTrackerCubit()..init(),
      child: const _HabitTrackerView(),
    );
  }
}

class _HabitTrackerView extends StatelessWidget {
  const _HabitTrackerView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: tarteelAppBar(
          titleText: 'يوميات المسلم',
          elevation: 0,
          toolbarHeight: 80,
          actions: [
            // زر عرض الإحصائيات الأسبوعية
            IconButton(
              icon: Icon(
                Icons.insights_rounded,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
              tooltip: 'الإحصائيات وسلسلة الالتزام',
              onPressed: () {
                HapticFeedback.selectionClick();
                final summary = context.read<HabitTrackerCubit>().state.statsSummary;
                if (summary != null) {
                  HabitWeeklyChartSheet.show(context, summary: summary);
                }
              },
            ),

            // زر تخصيص العبادات
            IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: isDark
                    ? AppColors.darkPrimaryText
                    : AppColors.lightPrimaryText,
              ),
              tooltip: 'تخصيص العبادات',
              onPressed: () {
                HapticFeedback.selectionClick();
                final cubit = context.read<HabitTrackerCubit>();
                HabitCustomizationSheet.show(
                  context,
                  allHabits: cubit.state.allHabits,
                  initiallyEnabledIds: cubit.state.enabledHabitIds,
                  onSave: (newIds) => cubit.updateCustomization(newIds),
                );
              },
            ),
            SizedBox(width: 8.w),
          ],
        ),
        body: IslamicPatternBackground(
          child: BlocBuilder<HabitTrackerCubit, HabitTrackerState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final cubit = context.read<HabitTrackerCubit>();

              // فصل العبادات حسب الأقسام
              final prayerHabits = state.activeHabits
                  .where((h) => h.category == HabitCategory.prayers)
                  .toList();
              final sunanHabits = state.activeHabits
                  .where((h) => h.category == HabitCategory.sunan)
                  .toList();
              final azkarAndQuranHabits = state.activeHabits
                  .where((h) => h.category == HabitCategory.azkarAndQuran)
                  .toList();
              final specialHabits = state.activeHabits
                  .where((h) => h.category == HabitCategory.special)
                  .toList();

              return RefreshIndicator(
                onRefresh: () => cubit.init(),
                color: AppColors.primaryLight,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.only(bottom: 40.h),
                  children: [
                    SizedBox(height: 8.h),

                    // بطاقة التاريخ ونسبة الإنجاز والـ Streak
                    HabitHeaderCard(
                      selectedDate: state.selectedDate,
                      percentage: state.completionPercentage,
                      completedCount: state.completedCount,
                      totalCount: state.totalCount,
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
                      onToday: () {
                        cubit.changeDate(DateTime.now());
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

                    // لافتة المناسبات الخاصة (سورة الكهف / الصيام) إن وجدت
                    HabitSpecialBanner(selectedDate: state.selectedDate),

                    SizedBox(height: 4.h),

                    // قسم الصلوات الخمس المفروضة
                    if (prayerHabits.isNotEmpty)
                      PrayerTrackerSection(
                        prayerHabits: prayerHabits,
                        completedIds: state.completedIds,
                        onToggle: (id) => cubit.toggleHabit(id),
                      ),

                    // قسم السنن والنوافل
                    if (sunanHabits.isNotEmpty) ...[
                      _buildCategoryHeader('السنن والنوافل', isDark),
                      ...sunanHabits.map((item) {
                        return HabitItemTile(
                          item: item,
                          isCompleted: state.completedIds.contains(item.id),
                          onToggle: () => cubit.toggleHabit(item.id),
                        );
                      }),
                    ],

                    // قسم الأذكار والأوراد القرآنية
                    if (azkarAndQuranHabits.isNotEmpty) ...[
                      _buildCategoryHeader('الأذكار والأوراد القرآنية', isDark),
                      ...azkarAndQuranHabits.map((item) {
                        return HabitItemTile(
                          item: item,
                          isCompleted: state.completedIds.contains(item.id),
                          onToggle: () => cubit.toggleHabit(item.id),
                        );
                      }),
                    ],

                    // قسم المناسبات والسنن الخاصة (سورة الكهف، صيام التطوع)
                    if (specialHabits.isNotEmpty) ...[
                      _buildCategoryHeader('المناسبات والسنن المؤكدة', isDark),
                      ...specialHabits.map((item) {
                        return HabitItemTile(
                          item: item,
                          isCompleted: state.completedIds.contains(item.id),
                          onToggle: () => cubit.toggleHabit(item.id),
                        );
                      }),
                    ],

                    SizedBox(height: 16.h),

                    // زر سفلي لتعديل العبادات
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: TextButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          HabitCustomizationSheet.show(
                            context,
                            allHabits: cubit.state.allHabits,
                            initiallyEnabledIds: cubit.state.enabledHabitIds,
                            onSave: (newIds) => cubit.updateCustomization(newIds),
                          );
                        },
                        icon: Icon(
                          Icons.tune_rounded,
                          size: 16.sp,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                        label: Text(
                          'تعديل وتخصيص قائمة عباداتي اليومية',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        right: 20.w,
        left: 20.w,
        top: 14.h,
        bottom: 6.h,
      ),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 14.h,
            decoration: BoxDecoration(
              color: AppColors.goldAccent,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkPrimaryText
                  : AppColors.lightPrimaryText,
            ),
          ),
        ],
      ),
    );
  }
}
