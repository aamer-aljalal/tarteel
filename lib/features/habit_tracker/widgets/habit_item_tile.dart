import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/views/surah_detail_page.dart';
import '../models/habit_item.dart';

/// ==============================================================================
/// بطاقة العبادة الفردية مع زر الإنجاز والانتقال السريع (تصميم نظيف بدون إيموجي)
/// ==============================================================================
class HabitItemTile extends StatelessWidget {
  final HabitItem item;
  final bool isCompleted;
  final VoidCallback onToggle;

  const HabitItemTile({
    super.key,
    required this.item,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.05)
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isCompleted
              ? AppColors.primaryLight.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isCompleted ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : AppColors.subtleShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onToggle();
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                // مربع الاختيار التفاعلي المخصص
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primaryLight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.primaryLight
                          : (isDark
                              ? AppColors.darkSecondaryText.withValues(alpha: 0.5)
                              : AppColors.lightSecondaryText.withValues(alpha: 0.5)),
                      width: 2.0,
                    ),
                  ),
                  child: isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          size: 18.sp,
                          color: Colors.white,
                        )
                      : null,
                ),

                SizedBox(width: 14.w),

                // أيقونة العبادة في حاوية أنيقة
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20.sp,
                    color: isCompleted
                        ? AppColors.primaryLight
                        : (isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.lightPrimaryText),
                  ),
                ),

                SizedBox(width: 12.w),

                // العنوان والوصف
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: isCompleted
                              ? (isDark
                                  ? AppColors.darkSecondaryText
                                  : AppColors.lightSecondaryText)
                              : (isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.lightPrimaryText),
                        ),
                      ),
                      if (item.subtitle.isNotEmpty) ...[
                        SizedBox(height: 3.h),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.lightSecondaryText,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // زر انتقال سريع إذا كانت العبادة مرتبطة بشاشة (مثل الأذكار أو المصحف)
                if (item.route != null) ...[
                  SizedBox(width: 6.w),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14.sp,
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.lightSecondaryText,
                    ),
                    tooltip: 'الانتقال للعبادة',
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      if (item.id == 'surah_kahf') {
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
                        return;
                      }

                      Navigator.pushNamed(
                        context,
                        item.route!,
                        arguments: item.routeArguments,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
