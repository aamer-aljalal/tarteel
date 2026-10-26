import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import '../services/habit_calendar_helper.dart';

/// ==============================================================================
/// بطاقة نسبة الإنجاز والتقويم الموحدة الطويلة والشفافة (One-Handed UX Friendly)
/// ==============================================================================
class HabitAchievementCard extends StatelessWidget {
  final DateTime selectedDate;
  final double percentage;
  final int completedCount;
  final int totalCount;
  final int streak;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onOpenStats;

  const HabitAchievementCard({
    super.key,
    required this.selectedDate,
    required this.percentage,
    required this.completedCount,
    required this.totalCount,
    required this.streak,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onOpenStats,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isCurrentDay(selectedDate);
    final dayName = HabitCalendarHelper.getDayName(selectedDate);
    final hijriStr = HabitCalendarHelper.formatHijri(selectedDate);
    final gregorianStr = HabitCalendarHelper.formatGregorian(selectedDate);

    final pctInteger = (percentage * 100).round();
    final pctArabic = HabitCalendarHelper.toArabicNumbers(pctInteger);
    final completedArabic = HabitCalendarHelper.toArabicNumbers(completedCount);
    final totalArabic = HabitCalendarHelper.toArabicNumbers(totalCount);
    final streakArabic = HabitCalendarHelper.toArabicNumbers(streak);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 200) {
            // سحب يميناً في RTL يعني اليوم السابق
            HapticFeedback.selectionClick();
            onPreviousDay();
          } else if (details.primaryVelocity! < -200) {
            // سحب يساراً يعني اليوم التالي
            HapticFeedback.selectionClick();
            onNextDay();
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. صف التاريخ واليوم (تقليب يدوي بالسحب يميناً ويساراً)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (isToday) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: AppColors.goldAccent.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          'اليوم',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // التاريخ الهجري والميلادي
                Text(
                  '$hijriStr  •  $gregorianStr',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),

            // فاصل خفيف وواسع
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),

            // 2. نسبة الإنجاز والخطوات وسلسلة الأيام
            Row(
              children: [
                // مؤشر التقدم الدائري الأكبر والأوضح
                SizedBox(
                  width: 52.w,
                  height: 52.w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 52.w,
                        height: 52.w,
                        child: CircularProgressIndicator(
                          value: percentage,
                          strokeWidth: 5.w,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.goldAccent,
                          ),
                        ),
                      ),
                      Text(
                        '%$pctArabic',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 14.w),

                // نص الخطوات والتحفيز
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أنجزت $completedArabic من $totalArabic خطوة اليوم',
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        percentage >= 1.0
                            ? 'ما شاء الله، أتممت جميع أوراد اليوم'
                            : 'اسحب أفقياً للانتقال بين الأيام',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // شارة سلسلة الالتزام (Streak)
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onOpenStats();
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 16.sp,
                          color: AppColors.goldAccent,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '$streakArabic أيام',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isCurrentDay(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
