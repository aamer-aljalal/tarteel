import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'habit_achievement_card.dart';

/// ==============================================================================
/// رأس الصفحة الثابت ليوميات المسلم (ارتفاع مدروس لراحة اليد وسهولة الوصول بيد واحدة)
/// ==============================================================================
class HabitTrackerFixedHeader extends StatelessWidget {
  final DateTime selectedDate;
  final double percentage;
  final int completedCount;
  final int totalCount;
  final int streak;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onOpenStats;

  const HabitTrackerFixedHeader({
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/TopBar/2.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 14.w,
              top: 8.h,
              right: 14.w,
              bottom: 18.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. شريط العنوان وأزرار التنقل مع مساحة تنفس واسعة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // زر الرجوع
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'رجوع',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),

                    // عنوان الصفحة
                    Text(
                      'يوميات المسلم',
                      style: TextStyle(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),

                    // زر الإحصائيات
                    IconButton(
                      icon: const Icon(
                        Icons.insights_rounded,
                        color: AppColors.goldAccent,
                      ),
                      tooltip: 'الإحصائيات وسلسلة الالتزام',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onOpenStats();
                      },
                    ),
                  ],
                ),

                SizedBox(height: 10.h),

                // 2. بطاقة نسبة الإنجاز والتقويم الموحدة الشفافة الأعرض والأطول
                HabitAchievementCard(
                  selectedDate: selectedDate,
                  percentage: percentage,
                  completedCount: completedCount,
                  totalCount: totalCount,
                  streak: streak,
                  onPreviousDay: onPreviousDay,
                  onNextDay: onNextDay,
                  onOpenStats: onOpenStats,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
