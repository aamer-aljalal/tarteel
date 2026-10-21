import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/features/quran/views/surah_detail_page.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import '../services/habit_calendar_helper.dart';

/// ==============================================================================
/// لافتة المناسبات والسنن المؤكدة (الجمعة، صيام النوافل والأيام البيض)
/// ==============================================================================
class HabitSpecialBanner extends StatelessWidget {
  final DateTime selectedDate;

  const HabitSpecialBanner({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final isFriday = HabitCalendarHelper.isFriday(selectedDate);
    final fastingReason = HabitCalendarHelper.getFastingReason(selectedDate);

    // إذا لم تكن جمعة ولا يوجد سبب صيام لا نعرض شيئاً
    if (!isFriday && fastingReason == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.goldAccent.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // أيقونة المناسبة في دائرة أنيقة
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFriday ? Icons.auto_stories_rounded : Icons.today_rounded,
              size: 22.sp,
              color: isDark ? AppColors.goldAccent : const Color(0xFFB47D12),
            ),
          ),

          SizedBox(width: 12.w),

          // تفاصيل المناسبة والفضل
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFriday ? 'يوم الجمعة المبارك' : 'سنة الصيام اليوم',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkPrimaryText
                        : AppColors.lightPrimaryText,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isFriday
                      ? 'قراءة سورة الكهف نور ما بين الجمعتين، والإكثار من الصلاة على النبي ﷺ'
                      : fastingReason ?? '',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.lightSecondaryText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          if (isFriday) ...[
            SizedBox(width: 8.w),
            InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();
                try {
                  final surahs = await QuranService.loadSurahs();
                  final kahf = surahs.firstWhere((s) => s.number == 18);
                  final ayahs = await QuranService.loadAyahs(18);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SurahDetailPage(
                          surah: kahf,
                          ayahs: ayahs,
                        ),
                      ),
                    );
                  }
                } catch (_) {}
              },
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الكهف',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10.sp,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
