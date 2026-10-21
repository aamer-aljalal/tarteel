import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import '../models/habit_stats_summary.dart';
import '../services/habit_calendar_helper.dart';

/// ==============================================================================
/// لوحة الإحصائيات الأسبوعية وسلسلة الالتزام (رسم بياني ومؤشرات رقمية نقية)
/// ==============================================================================
class HabitWeeklyChartSheet extends StatelessWidget {
  final HabitStatsSummary summary;

  const HabitWeeklyChartSheet({
    super.key,
    required this.summary,
  });

  static Future<void> show(
    BuildContext context, {
    required HabitStatsSummary summary,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitWeeklyChartSheet(summary: summary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentStreakStr = HabitCalendarHelper.toArabicNumbers(summary.currentStreak);
    final longestStreakStr = HabitCalendarHelper.toArabicNumbers(summary.longestStreak);
    final totalCompletedStr = HabitCalendarHelper.toArabicNumbers(summary.totalCompletedThisWeek);
    final avgPct = (summary.weeklyAverage * 100).round();
    final avgPctStr = HabitCalendarHelper.toArabicNumbers(avgPct);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            // مقبض السحب
            SizedBox(height: 12.h),
            Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 14.h),

            // العنوان
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إحصائيات وثبات العبادات',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkPrimaryText
                              : AppColors.lightPrimaryText,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'متابعة مستوى التزامك خلال الأيام السبعة الأخيرة',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Divider(
              height: 20.h,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                children: [
                  // بطاقات المؤشرات الرئيسية (4 كروت في شبكة)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'السلسلة الحالية',
                          value: '$currentStreakStr أيام',
                          icon: Icons.local_fire_department_rounded,
                          color: AppColors.goldAccent,
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'أطول سلسلة',
                          value: '$longestStreakStr أيام',
                          icon: Icons.workspace_premium_rounded,
                          color: AppColors.primaryLight,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10.h),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'معدل الالتزام',
                          value: '%$avgPctStr',
                          icon: Icons.trending_up_rounded,
                          color: AppColors.primaryLight,
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'عبادات الأسبوع',
                          value: '$totalCompletedStr عبادة',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.goldAccent,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // عنوان الرسم البياني
                  Text(
                    'رسم بياني لإنجاز الأيام السبعة الأخيرة',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.lightPrimaryText,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // الرسم البياني (7 أعمدة أنيقة تفاعلية)
                  Container(
                    height: 190.h,
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: summary.last7DaysProgress.entries.map((entry) {
                        return _buildChartBar(
                          date: entry.key,
                          percentage: entry.value,
                          isDark: isDark,
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // رسالة توجيهية إيمانية
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          size: 20.sp,
                          color: AppColors.primaryLight,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'قال رسول الله ﷺ: «أَحَبُّ الأَعْمَالِ إِلَى اللهِ أَدْوَمُهَا وَإِنْ قَلَّ». المجاهدة والثبات اليومي هما مفتاح كل خير.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.sp, color: color),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
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
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar({
    required DateTime date,
    required double percentage,
    required bool isDark,
  }) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final dayNameShort = HabitCalendarHelper.getDayName(date).replaceAll('ال', '');
    final pctInt = (percentage * 100).round();
    final pctStr = HabitCalendarHelper.toArabicNumbers(pctInt);
    final clampedPct = percentage.clamp(0.04, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // النسبة أعلى العمود
        Text(
          '$pctStr%',
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            color: isToday
                ? AppColors.goldAccent
                : (isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.lightSecondaryText),
          ),
        ),

        SizedBox(height: 6.h),

        // العمود الملون
        Container(
          width: 24.w,
          height: 100.h * clampedPct,
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.goldAccent
                : (percentage >= 0.70
                    ? AppColors.primaryLight
                    : (isDark ? Colors.white24 : Colors.grey.shade300)),
            borderRadius: BorderRadius.circular(6.r),
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: AppColors.goldAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),

        SizedBox(height: 8.h),

        // اسم اليوم أسفل العمود
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: isToday
              ? BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.r),
                )
              : null,
          child: Text(
            dayNameShort,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
              color: isToday
                  ? AppColors.goldAccent
                  : (isDark
                      ? AppColors.darkPrimaryText
                      : AppColors.lightPrimaryText),
            ),
          ),
        ),
      ],
    );
  }
}
