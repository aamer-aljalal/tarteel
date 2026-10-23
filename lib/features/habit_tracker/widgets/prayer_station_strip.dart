import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import '../models/prayer_station_model.dart';

/// ==============================================================================
/// شريط المسار الزمني الأفقي لمحطات الصلاة واليوم (تصميم فخم خالٍ تماماً من الإيموجي)
/// ==============================================================================
class PrayerStationStrip extends StatelessWidget {
  final List<PrayerStationModel> stations;
  final String selectedStationId;
  final Set<String> completedIds;
  final Function(String) onSelectStation;

  const PrayerStationStrip({
    super.key,
    required this.stations,
    required this.selectedStationId,
    required this.completedIds,
    required this.onSelectStation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 82.h,
      margin: EdgeInsets.symmetric(vertical: 6.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        itemCount: stations.length,
        itemBuilder: (context, index) {
          final station = stations[index];
          final isSelected = station.id == selectedStationId;
          final isCompleted = station.isFullyCompleted(completedIds);
          final completedCount = station.getCompletedCount(completedIds);

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelectStation(station.id);
              },
              borderRadius: BorderRadius.circular(16.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 90.w,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                      : (isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.goldAccent
                        : (isCompleted
                            ? AppColors.primaryLight.withValues(alpha: 0.5)
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.goldAccent.withValues(alpha: 0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // الصف العلوي: الأيقونة وشارة الإنجاز
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          station.icon,
                          size: 16.sp,
                          color: isSelected
                              ? AppColors.goldAccent
                              : (isCompleted
                                  ? AppColors.primaryLight
                                  : (isDark
                                      ? AppColors.darkSecondaryText
                                      : AppColors.lightSecondaryText)),
                        ),
                        if (isCompleted)
                          Container(
                            width: 7.w,
                            height: 7.w,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                          )
                        else if (completedCount > 0)
                          Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: BoxDecoration(
                              color: AppColors.goldAccent.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          SizedBox(width: 7.w),
                      ],
                    ),

                    // اسم المحطة
                    Text(
                      station.shortName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? (isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.lightPrimaryText)
                            : (isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // وقت المحطة
                    Text(
                      station.approximateTime,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppColors.goldAccent
                            : (isDark
                                ? AppColors.darkSecondaryText.withValues(alpha: 0.7)
                                : AppColors.lightSecondaryText.withValues(alpha: 0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
