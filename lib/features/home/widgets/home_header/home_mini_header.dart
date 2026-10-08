import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class HomeMiniHeader extends StatelessWidget {
  const HomeMiniHeader({
    super.key,
    required this.hijriDate,
    required this.gregorianDate,
    required this.onDateTap,
  });

  final String hijriDate;
  final String gregorianDate;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final now = DateTime.now();
    final timeDigits = DateFormat('h:mm', 'en').format(now);
    final amPmEn = DateFormat('a', 'en').format(now); // "AM" or "PM"
    final amPmAr = amPmEn == 'AM' ? 'ص' : 'م';
    final currentTime = '$timeDigits $amPmAr';

    String dayName = '';
    switch (now.weekday) {
      case DateTime.monday:
        dayName = 'الإثنين';
        break;
      case DateTime.tuesday:
        dayName = 'الثلاثاء';
        break;
      case DateTime.wednesday:
        dayName = 'الأربعاء';
        break;
      case DateTime.thursday:
        dayName = 'الخميس';
        break;
      case DateTime.friday:
        dayName = 'الجمعة';
        break;
      case DateTime.saturday:
        dayName = 'السبت';
        break;
      case DateTime.sunday:
        dayName = 'الأحد';
        break;
    }
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.onSurface.withOpacity(0.1),
              width: 1.5.w,
            ),
            // color: colorScheme.surface.withOpacity(0.15),
    color: Colors.black.withOpacity(0.15), 
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              Text(
                '$currentTime  •  $dayName',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.sp,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        GestureDetector(
          onTap: onDateTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.1),
                width: 1.5.w,
              ),
              // color: colorScheme.surface.withOpacity(0.15),
    color: Colors.black.withOpacity(0.15), 

              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 11.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 6.w),
                Text(
                  '$hijriDate  |  $gregorianDate',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
