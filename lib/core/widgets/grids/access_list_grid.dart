/// وصف الملف:
/// هذا الملف يحتوي على عنصر `AccessListGrid` وهو عبارة عن شبكة عرض (Grid) مخصصة ومتجاوبة
/// لعرض خيارات الوصول السريع للأقسام المختلفة في التطبيق (مثل القرآن، حصن المسلم، الأذكار، إلخ).
///
/// عمل الملف:
/// - استقبال قائمة من موديلات `AccessListModel` التي تحتوي على الأيقونة والعنوان ومسار الصفحة المحددة.
/// - بناء وتنسيق العناصر بشكل شبكي يتناسب مع أحجام الشاشات المختلفة ودعم المظهرين (النهاري والليلي).
/// - تشغيل حركة دخول متحركة ومتدرجة لكل عنصر بشكل تصاعدي (Staggered Entrance Animation)
///   مع حماية التطبيق من الانهيار عند وجود عدد كبير من العناصر عن طريق تحديد حد أقصى لتأخير الأنيميشن.
library;

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/theme/app_radius.dart';

class AccessListGrid extends StatelessWidget {
  final List<AccessListModel> actions;
  final AnimationController controller;

  const AccessListGrid({
    super.key,
    required this.actions,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),

      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];

        // حل مشكلة توقف التطبيق (Crash):
        // نقوم بضرب مؤشر العنصر (index) في قيمة تأخير صغيرة، ونحد من قيمتها القصوى باستخدام clamp لتكون أقل من 1.0 دائماً (الحد الأقصى المسموح به في Interval هو 1.0).
        // هذا يضمن تشغيل التدرج الحركي بشكل رائع للعناصر الأولى، ويمنع التطبيق من الانهيار مع القوائم الطويلة مثل فصول حصن المسلم.
        final animationDelay = (index * 0.04).clamp(0.0, 0.95);

        final animation = CurvedAnimation(
          parent: controller,
          curve: Interval(animationDelay, 1.0, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: animation,

          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.6),
              end: Offset.zero,
            ).animate(animation),

            child: GestureDetector(
              onTap: () {
                // Navigator.pushNamed(context, item.route);
                Navigator.pushNamed(
                  context,
                  item.route,
                  arguments: item.arguments,
                );
              },

              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: brightness == Brightness.dark
                        ? AppColors.greenBorder.withOpacity(0.50)
                        : AppColors.disabled,
                    width: 2.w,
                  ),

                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightSecondaryText.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    SizedBox(height: 12.h),

                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.goldAccent),
                        color: brightness == Brightness.dark
                            ? AppColors.primary.withOpacity(0.25)
                            : AppColors.primary.withOpacity(0.22),
                        shape: BoxShape.circle,
                      ),

                      child: Icon(
                        item.icon,
                        size: 20.sp,
                        color: AppColors.greenBorder,
                        // color: AppColors.goldAccent,
                      ),
                    ),

                    SizedBox(height: 10.h),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 7.w),
                        child: AutoSizeText(
                          item.title,
                          maxLines: 2,
                          minFontSize: 9,
                          maxFontSize: 13,
                          stepGranularity: 0.5,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: 13.sp,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Cairo',
                              ),
                        ),
                      ),
                    ),
                    SizedBox(height: 5.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
