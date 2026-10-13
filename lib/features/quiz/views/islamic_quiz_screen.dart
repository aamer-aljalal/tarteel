/// ==============================================================================
/// 📌 وصف الملف: islamic_quiz_screen.dart
/// ==============================================================================
/// شاشة المسابقات والتحديات الإسلامية لتطبيق ترتيل.
/// هذه الشاشة تفتح عند الضغط على الزر الديناميكي المجلوب من جيت هب (/islamic-quiz).
/// ==============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/widgets/backgrounds/islamic_pattern_background.dart';

class IslamicQuizScreen extends StatelessWidget {
  const IslamicQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: tarteelAppBar(
        titleText: 'تحدي المسابقات الإسلامية',
        elevation: 0,
        toolbarHeight: 90,
      ),
      body: IslamicPatternBackground(
        child: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90.w,
                      height: 90.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.goldAccent.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.quiz_rounded,
                        size: 46.sp,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'أهلاً بك في تحدي المسابقات! ',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'تم فتح هذه الصفحة بنجاح عبر الزر الديناميكي الجديد المجلوب من GitHub!\nفي المرحلة القادمة سنقوم بدمج بنك الأسئلة والتحديات التفاعلية.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontFamily: 'Cairo',
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
