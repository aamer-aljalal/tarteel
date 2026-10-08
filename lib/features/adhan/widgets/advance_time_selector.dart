import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';

class AdvanceTimeSelector extends StatelessWidget {
  final int selectedMinutes;
  final Function(int) onChanged;

  const AdvanceTimeSelector({
    super.key,
    required this.selectedMinutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_outlined,
              color: Colors.blueAccent,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'موعد الأذان قبل وقت الصلاة',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'تنبيه مبكر قبل دخول الوقت',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            height: 38.h,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedMinutes,
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                dropdownColor: isDark ? const Color(0xFF222222) : Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                ),
                items: const [
                  DropdownMenuItem<int>(value: 15, child: Text('15 دقيقة')),
                  DropdownMenuItem<int>(value: 10, child: Text('10 دقائق')),
                  DropdownMenuItem<int>(value: 5, child: Text('5 دقائق')),
                  DropdownMenuItem<int>(value: 0, child: Text('0 دقيقة')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    onChanged(val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
