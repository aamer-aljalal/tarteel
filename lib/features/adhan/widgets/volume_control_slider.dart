import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';

class VolumeControlSlider extends StatelessWidget {
  final double volume;
  final bool isTestingAdhan;
  final Function(double) onVolumeChanged;
  final Function(double) onVolumeChangeEnd;
  final VoidCallback onToggleTest;

  const VolumeControlSlider({
    super.key,
    required this.volume,
    required this.isTestingAdhan,
    required this.onVolumeChanged,
    required this.onVolumeChangeEnd,
    required this.onToggleTest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'مستوى صوت الأذان',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(5.w),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: Colors.amber,
                  size: 15.sp,
                ),
              ),
              Expanded(
                child: Slider(
                  value: volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.primary.withValues(alpha: 0.2),
                  onChanged: onVolumeChanged,
                  onChangeEnd: onVolumeChangeEnd,
                ),
              ),
              Text(
                '${(volume * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 10.w),
              FilledButton(
                onPressed: onToggleTest,
                style: FilledButton.styleFrom(
                  backgroundColor: isTestingAdhan ? Colors.red.shade600 : AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(44.w, 36.h),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: 2,
                  shadowColor: (isTestingAdhan ? Colors.red.shade600 : AppColors.primary)
                      .withValues(alpha: 0.25),
                ),
                child: Icon(
                  isTestingAdhan ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
