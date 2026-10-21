import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import '../models/habit_item.dart';
import '../services/habit_calendar_helper.dart';

/// ==============================================================================
/// قسم متابعة الصلوات الخمس المفروضة بتصميم تفاعلي متقن (خالٍ تماماً من الإيموجي)
/// ==============================================================================
class PrayerTrackerSection extends StatelessWidget {
  final List<HabitItem> prayerHabits;
  final Set<String> completedIds;
  final Function(String) onToggle;

  const PrayerTrackerSection({
    super.key,
    required this.prayerHabits,
    required this.completedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final completedCount = prayerHabits
        .where((h) => completedIds.contains(h.id))
        .length;
    final totalCount = prayerHabits.length;
    final completedArabic = HabitCalendarHelper.toArabicNumbers(completedCount);
    final totalArabic = HabitCalendarHelper.toArabicNumbers(totalCount);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : AppColors.subtleShadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس القسم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.mosque_outlined,
                      size: 18.sp,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'الصلوات المفروضة الخمس',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: completedCount == totalCount
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$completedArabic من $totalArabic',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: completedCount == totalCount
                        ? AppColors.primaryLight
                        : (isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // شبكة كبسولات الصلوات الخمس
          Row(
            children: prayerHabits.map((habit) {
              final isDone = completedIds.contains(habit.id);
              final shortName = habit.title.replaceAll('صلاة ', '');

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onToggle(habit.id);
                    },
                    borderRadius: BorderRadius.circular(14.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : (isDark
                                ? AppColors.darkBackground
                                : AppColors.lightBackground),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isDone
                              ? AppColors.primaryLight
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                          width: isDone ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: isDone ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isDone ? Icons.check_circle_rounded : habit.icon,
                              size: 22.sp,
                              color: isDone
                                  ? AppColors.primaryLight
                                  : (isDark
                                      ? AppColors.darkSecondaryText
                                      : AppColors.lightSecondaryText),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            shortName,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: isDone ? FontWeight.bold : FontWeight.w600,
                              color: isDone
                                  ? AppColors.primaryLight
                                  : (isDark
                                      ? AppColors.darkPrimaryText
                                      : AppColors.lightPrimaryText),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
