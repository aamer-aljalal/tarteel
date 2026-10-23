import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import '../models/prayer_station_model.dart';
import '../services/habit_calendar_helper.dart';

/// ==============================================================================
/// بطاقة محطة الصلاة الشفافة بالكامل مع تقليب البطاقة كلياً بالسحب والأنميشن
/// ==============================================================================
class PrayerStationSwiperCard extends StatefulWidget {
  final List<PrayerStationModel> stations;
  final String selectedStationId;
  final Set<String> completedIds;
  final Function(String) onStationChanged;

  const PrayerStationSwiperCard({
    super.key,
    required this.stations,
    required this.selectedStationId,
    required this.completedIds,
    required this.onStationChanged,
  });

  @override
  State<PrayerStationSwiperCard> createState() => _PrayerStationSwiperCardState();
}

class _PrayerStationSwiperCardState extends State<PrayerStationSwiperCard> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _findCurrentIndex();
    _pageController = PageController(initialPage: _currentIndex);
  }

  int _findCurrentIndex() {
    final idx = widget.stations.indexWhere((s) => s.id == widget.selectedStationId);
    return idx >= 0 ? idx : 0;
  }

  @override
  void didUpdateWidget(covariant PrayerStationSwiperCard oldWidget) {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // منطقة تقليب البطاقة بالكامل (PageView)
        SizedBox(
          height: 104.h,
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
              final completedCount = station.getCompletedCount(widget.completedIds);
              final totalCount = station.items.length;
              final completedArabic = HabitCalendarHelper.toArabicNumbers(completedCount);
              final totalArabic = HabitCalendarHelper.toArabicNumbers(totalCount);

              // البطاقة الشفافة الكاملة التي يتم تقليبها كلياً
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // الصف الأول: الأيقونة، الاسم، التوقيت، وشارة الإنجاز
                    Row(
                      children: [
                        // أيقونة المحطة
                        Container(
                          width: 34.w,
                          height: 34.w,
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.goldAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(
                            station.icon,
                            size: 18.sp,
                            color: AppColors.goldAccent,
                          ),
                        ),

                        SizedBox(width: 10.w),

                        // اسم المحطة وتوقيتها
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                station.title,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: AppColors.goldAccent.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  station.approximateTime,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.goldAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // شارة الإنجاز داخل المحطة
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: completedCount == totalCount
                                ? AppColors.primary.withValues(alpha: 0.35)
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: completedCount == totalCount
                                  ? AppColors.primaryLight
                                  : Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '$completedArabic من $totalArabic',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // فضل المحطة والحديث النبوي الشريف
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
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
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
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

        SizedBox(height: 6.h),

        // مؤشر النقاط التفاعلي أسفل البطاقة الشفافة
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.stations.length, (index) {
            final isSelected = index == _currentIndex;
            final isStationDone = widget.stations[index].isFullyCompleted(widget.completedIds);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              width: isSelected ? 16.w : 5.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.goldAccent
                    : (isStationDone
                        ? AppColors.primaryLight.withValues(alpha: 0.8)
                        : Colors.white30),
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          }),
        ),
      ],
    );
  }
}
