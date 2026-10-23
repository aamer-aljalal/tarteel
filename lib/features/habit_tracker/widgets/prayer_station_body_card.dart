import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import '../models/prayer_station_model.dart';
import '../services/habit_calendar_helper.dart';

/// ==============================================================================
/// بطاقة محطة الصلاة الرئيسية في منطقة المحراب السفلية (تقليب كامل بالأنميشن)
/// ==============================================================================
class PrayerStationBodyCard extends StatefulWidget {
  final List<PrayerStationModel> stations;
  final String selectedStationId;
  final Set<String> completedIds;
  final Function(String) onStationChanged;

  const PrayerStationBodyCard({
    super.key,
    required this.stations,
    required this.selectedStationId,
    required this.completedIds,
    required this.onStationChanged,
  });

  @override
  State<PrayerStationBodyCard> createState() => _PrayerStationBodyCardState();
}

class _PrayerStationBodyCardState extends State<PrayerStationBodyCard> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _findCurrentIndex();
    _pageController = PageController(initialPage: _currentIndex);
  }

  int _findCurrentIndex() {
    final idx = widget.stations.indexWhere(
      (s) => s.id == widget.selectedStationId,
    );
    return idx >= 0 ? idx : 0;
  }

  @override
  void didUpdateWidget(covariant PrayerStationBodyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStationId != widget.selectedStationId) {
      final newIdx = _findCurrentIndex();
      if (newIdx != _currentIndex && _pageController.hasClients) {
        _currentIndex = newIdx;
        _pageController.animateToPage(
          newIdx,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black45
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 106.h,
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.stations.length,
              onPageChanged: (index) {
                HapticFeedback.selectionClick();
                setState(() {
                  _currentIndex = index;
                });
                widget.onStationChanged(widget.stations[index].id);
              },
              itemBuilder: (context, index) {
                final station = widget.stations[index];
                final completedCount = station.getCompletedCount(
                  widget.completedIds,
                );
                final totalCount = station.items.length;
                final completedArabic = HabitCalendarHelper.toArabicNumbers(
                  completedCount,
                );
                final totalArabic = HabitCalendarHelper.toArabicNumbers(
                  totalCount,
                );

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // الصف الأول: الأيقونة، الاسم، التوقيت، وشارة الإنجاز
                      Row(
                        children: [
                          Container(
                            width: 38.w,
                            height: 38.w,
                            decoration: BoxDecoration(
                              color: AppColors.goldAccent.withValues(
                                alpha: 0.16,
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: AppColors.goldAccent.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Icon(
                              station.icon,
                              size: 20.sp,
                              color: isDark
                                  ? AppColors.goldAccent
                                  : const Color(0xFFB47D12),
                            ),
                          ),

                          SizedBox(width: 10.w),

                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  station.title,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.darkPrimaryText
                                        : AppColors.lightPrimaryText,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 7.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldAccent.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    station.approximateTime,
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.goldAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: completedCount == totalCount
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : (isDark
                                        ? Colors.white10
                                        : Colors.black.withValues(alpha: 0.05)),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              completedCount == totalCount
                                  ? 'مكتملة'
                                  : '$completedArabic من $totalArabic',
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

                      // الحديث الشريف وفضل الصلاة
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground.withValues(alpha: 0.7)
                              : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border(
                            right: BorderSide(
                              color: AppColors.goldAccent,
                              width: 2.5.w,
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
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // مؤشر النقاط التفاعلي أسفل البطاقة
          Padding(
            padding: EdgeInsets.only(bottom: 7.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.stations.length, (index) {
                final isSelected = index == _currentIndex;
                final isStationDone = widget.stations[index].isFullyCompleted(
                  widget.completedIds,
                );

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.symmetric(horizontal: 2.5.w),
                  width: isSelected ? 18.w : 6.w,
                  height: 4.5.h,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.goldAccent
                        : (isStationDone
                              ? AppColors.primaryLight
                              : (isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300)),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
