import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import '../services/habit_calendar_helper.dart';

/// ==============================================================================
/// بطاقة التقدم الرئيسية والتقويم لسجل العبادات (تصميم إسلامي راقٍ بدون أي إيموجي)
/// ==============================================================================
class HabitHeaderCard extends StatelessWidget {
  final DateTime selectedDate;
  final double percentage;
  final int completedCount;
  final int totalCount;
  final int streak;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onToday;
  final VoidCallback onOpenStats;

  const HabitHeaderCard({
    super.key,
    required this.selectedDate,
    required this.percentage,
    required this.completedCount,
    required this.totalCount,
    required this.streak,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onToday,
    required this.onOpenStats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isToday = _isCurrentDay(selectedDate);

    final dayName = HabitCalendarHelper.getDayName(selectedDate);
    final hijriStr = HabitCalendarHelper.formatHijri(selectedDate);
    final gregorianStr = HabitCalendarHelper.formatGregorian(selectedDate);

    final pctInteger = (percentage * 100).round();
    final pctArabic = HabitCalendarHelper.toArabicNumbers(pctInteger);
    final completedArabic = HabitCalendarHelper.toArabicNumbers(completedCount);
    final totalArabic = HabitCalendarHelper.toArabicNumbers(totalCount);
    final streakArabic = HabitCalendarHelper.toArabicNumbers(streak);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(18.w),
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
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- صف التاريخ وأزرار التنقل ---
          Row(
            children: [
              // زر اليوم السابق
              _buildNavArrow(
                icon: Icons.chevron_right_rounded,
                tooltip: 'اليوم السابق',
                onTap: onPreviousDay,
                isDark: isDark,
              ),

              SizedBox(width: 8.w),

              // التاريخ الهجري والميلادي في المنتصف
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        if (isToday) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'اليوم',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      hijriStr,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    Text(
                      gregorianStr,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8.w),

              // زر اليوم التالي
              _buildNavArrow(
                icon: Icons.chevron_left_rounded,
                tooltip: 'اليوم التالي',
                onTap: onNextDay,
                isDark: isDark,
              ),
            ],
          ),

          SizedBox(height: 18.h),

          // --- فاصل زخرفي هادئ ---
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),

          SizedBox(height: 18.h),

          // --- شريط التقدم الدائري وسلسلة الالتزام ---
          Row(
            children: [
              // مؤشر التقدم الدائري الحديث
              SizedBox(
                width: 76.w,
                height: 76.w,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76.w,
                      height: 76.w,
                      child: CircularProgressIndicator(
                        value: percentage,
                        strokeWidth: 7.w,
                        strokeCap: StrokeCap.round,
                        backgroundColor: isDark
                            ? Colors.white10
                            : AppColors.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage >= 1.0
                              ? AppColors.goldAccent
                              : AppColors.primaryLight,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '%$pctArabic',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        Text(
                          'إنجاز',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: 18.w),

              // تفاصيل الإنجاز والـ Streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عدد العبادات المنجزة
                    Row(
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 16.sp,
                          color: AppColors.primaryLight,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'أنجزت $completedArabic من $totalArabic عبادات',
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

                    SizedBox(height: 8.h),

                    // بطاقة سلسلة الأيام (Streak)
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onOpenStats();
                      },
                      borderRadius: BorderRadius.circular(10.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.goldAccent.withValues(alpha: 0.3),
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
                            SizedBox(width: 6.w),
                            Text(
                              'سلسلة الالتزام: $streakArabic أيام متتالية',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.goldAccent
                                    : const Color(0xFFB47D12),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10.sp,
                              color: isDark
                                  ? AppColors.goldAccent
                                  : const Color(0xFFB47D12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavArrow({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 20.sp,
          color: isDark
              ? AppColors.darkPrimaryText
              : AppColors.lightPrimaryText,
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
