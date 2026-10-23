import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/Text/Responsive_text.dart';

class HomePrayerCard extends StatelessWidget {
  const HomePrayerCard({
    super.key,
    required this.countdown,
    required this.dynamicNextPrayer,
    required this.currentPrayerTimes,
    required this.cityName,
    required this.isLoadingLocation,
    required this.onUpdateLocation,
  });
  final String countdown;
  final String dynamicNextPrayer;
  final Map<String, String> currentPrayerTimes;
  final String cityName;
  final bool isLoadingLocation;
  final VoidCallback onUpdateLocation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return
    // بطاقة أوقات الصلاة الأفقية
    Container(
      padding: EdgeInsets.only(right: 8.w, left: 8.w, top: 4.h, bottom: 6.h),
      margin: EdgeInsets.only(top: 17.h, bottom: 4.h),
      decoration: BoxDecoration(
        // استخدام ألوان الثيم للبطاقة الشفافة
        // color: colorScheme.surface.withOpacity(0.15),
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
      ),

      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ResponsiveText(
                  content: 'مواقيت الصلاة',
                  fontSize: 12,
                  fontFamily: 'Cairo',
                  maxLines: 1,
                  color: AppColors.white,
                ),
                if (cityName.isNotEmpty) ...[
                  Text(
                    '   |   ',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Flexible(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onUpdateLocation();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 13.sp,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              'بتوقيت : $cityName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          if (isLoadingLocation)
                            SizedBox(
                              width: 10.w,
                              height: 10.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white,
                              ),
                            )
                          else
                            Icon(
                              Icons.refresh,
                              size: 12.sp,
                              color: Colors.white70,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // كم المتبقي للصلاة القادمة (تحت العنوان مباشرة بحجم صغير جداً ودون أي بادينج أو مارجين)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'متبقي لـ $dynamicNextPrayer : ',
                  style: TextStyle(
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.amberAccent,
                    fontFamily: 'Cairo',
                    height: 1.1,
                  ),
                ),
                Text(
                  countdown,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Amiri',
                    height: 1.1,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: currentPrayerTimes.entries.map((entry) {
                final isNext = entry.key == dynamicNextPrayer;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(vertical: isNext ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isNext
                        // ? colorScheme.surface.withOpacity(0.3)
                        ? Colors.black.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 0.3.h,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPrayerIcon(entry.key),
                          size: 16.sp,
                          color: isNext ? Colors.amberAccent : Colors.white70,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: isNext ? Colors.amberAccent : Colors.white70,
                            fontSize: 11.sp,
                            fontWeight: isNext
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          entry.value,
                          style: TextStyle(
                            color: isNext ? Colors.amberAccent : Colors.white,
                            fontSize: 10.sp,
                            fontFamily: 'Amiri',

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isNext) ...[
                          SizedBox(height: 6.h),
                          Icon(
                            Icons.arrow_upward,
                            color: Colors.amberAccent,
                            size: 14.sp,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
        return Icons.wb_twilight_rounded;
      case 'الظهر':
        return Icons.wb_sunny_rounded;
      case 'العصر':
        return Icons.wb_sunny_outlined;
      case 'المغرب':
        return Icons.brightness_medium_rounded;
      case 'العشاء':
        return Icons.nights_stay_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }
}
