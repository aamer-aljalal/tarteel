import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import '../models/prayer_station_model.dart';
import '../services/habit_calendar_helper.dart';

/// ==============================================================================
/// بطاقة محطة الصلاة المركزة والأزرار اللمسية الفاخرة (تصميم تفاعلي بدون أي إيموجي)
/// ==============================================================================
class PrayerStationHeroCard extends StatelessWidget {
  final PrayerStationModel station;
  final Set<String> completedIds;
  final Function(String) onToggleItem;

  const PrayerStationHeroCard({
    super.key,
    required this.station,
    required this.completedIds,
    required this.onToggleItem,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final completedCount = station.getCompletedCount(completedIds);
    final totalCount = station.items.length;
    final completedArabic = HabitCalendarHelper.toArabicNumbers(completedCount);
    final totalArabic = HabitCalendarHelper.toArabicNumbers(totalCount);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : AppColors.subtleShadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس المحطة: الأيقونة والعنوان والتوقيت ونسبة الإنجاز
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  station.icon,
                  size: 22.sp,
                  color: isDark ? AppColors.goldAccent : const Color(0xFFB47D12),
                ),
              ),

              SizedBox(width: 12.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          station.title,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          station.approximateTime,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'أنجزت $completedArabic من $totalArabic خطوات',
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

              // شارة الإنجاز الدائرية
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: completedCount == totalCount
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  completedCount == totalCount ? 'مكتملة' : '$completedArabic/$totalArabic',
                  style: TextStyle(
                    fontSize: 11.sp,
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

          // الحديث النبوي وفضل المحطة
          if (station.virtueHadith.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(10.r),
                border: Border(
                  right: BorderSide(
                    color: AppColors.goldAccent,
                    width: 3.w,
                  ),
                ),
              ),
              child: Text(
                station.virtueHadith,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.lightSecondaryText,
                  height: 1.35,
                ),
              ),
            ),
          ],

          SizedBox(height: 16.h),

          // قائمة الأزرار اللمسية التفاعلية للعبادات داخل المحطة
          ...station.items.map((item) {
            final isDone = completedIds.contains(item.id);

            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onToggleItem(item.id);
                },
                borderRadius: BorderRadius.circular(16.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.07)
                        : (isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isDone
                          ? AppColors.primaryLight.withValues(alpha: 0.5)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: isDone ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      // زر دائرة الإنجاز المتوهج
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.primaryLight
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone
                                ? AppColors.primaryLight
                                : (isDark
                                    ? AppColors.darkSecondaryText.withValues(alpha: 0.5)
                                    : AppColors.lightSecondaryText.withValues(alpha: 0.5)),
                            width: 1.8,
                          ),
                        ),
                        child: isDone
                            ? Icon(
                                Icons.check_rounded,
                                size: 18.sp,
                                color: Colors.white,
                              )
                            : null,
                      ),

                      SizedBox(width: 12.w),

                      // اسم العبادة والوصف الفقهي
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: isDone
                                        ? (isDark
                                            ? AppColors.darkSecondaryText
                                            : AppColors.lightSecondaryText)
                                        : (isDark
                                            ? AppColors.darkPrimaryText
                                            : AppColors.lightPrimaryText),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                // شارة عدد الركعات
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? AppColors.primaryLight.withValues(alpha: 0.15)
                                        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    item.rakahs,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isDone
                                          ? AppColors.primaryLight
                                          : (isDark
                                              ? AppColors.darkSecondaryText
                                              : AppColors.lightSecondaryText),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              item.detail,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark
                                    ? AppColors.darkSecondaryText
                                    : AppColors.lightSecondaryText,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // زر الانتقال المباشر إذا كان البند مرتبطاً بالأذكار
                      if (item.route != null) ...[
                        SizedBox(width: 8.w),
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pushNamed(
                              context,
                              item.route!,
                              arguments: item.routeArguments,
                            );
                          },
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'قراءة',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10.sp,
                                  color: AppColors.primaryLight,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
