/// ==============================================================================
///  وصف الملف: section_progress_bar.dart
/// ==============================================================================
/// مكون شريط التقدم في القسم (قابل لإعادة الاستخدام بالكامل في أي شاشة).
///
/// المميزات:
/// 1. يحتوي على منطق الحساب البرمجي داخلياً بواسطة `SectionProgressCubit`.
/// 2. كل ما يحتاجه من الشاشة الخارجية هو تمرير الأرقام (الفهرس الحالي والإجمالي).
/// 3. يدعم التحديث التلقائي، والأنيميشن السلس عند تغيير القيم.
/// 4. قابل للتخصيص بالكامل (الألوان، النصوص، الارتفاع، الحشو، وإظهار النسبة المئوية أو الأرقام).
/// ==============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'cubit/section_progress_cubit.dart';
import 'cubit/section_progress_state.dart';

class SectionProgressBar extends StatelessWidget {
  /// الفهرس الحالي للعنصر المعروض (مثلاً 0 أو 1)
  final int currentIndex;

  /// إجمالي عدد العناصر في القسم
  final int totalCount;

  /// عنوان الشريط (افتراضياً: 'التقدم في القسم')
  final String title;

  /// هل الرقم الممرر `currentIndex` يبدأ من 0 (0-based) لكي يتم إضافة 1 له عند العرض
  /// إذا كان `true` (وهو الافتراضي في PageView): index 0 يعرض "1 / total"
  /// إذا كان `false`: يعرض الرقم كما هو
  final bool isZeroBasedIndex;

  /// هل يتم إظهار النسبة المئوية بجانب العداد (مثال: "50% (5 / 10)")
  final bool showPercentage;

  /// لون مؤشر التقدم (افتراضياً: AppColors.goldAccent)
  final Color? progressColor;

  /// لون خلفية الشريط (افتراضياً حسب الثيم)
  final Color? backgroundColor;

  /// ارتفاع شريط التقدم
  final double? height;

  /// الحشو الخارجي
  final EdgeInsetsGeometry? padding;

  /// كولباك مخصص لتنسيق نص العد في حال الرغبة بتخصيصه
  final String Function(int current, int total, int percentage)? customCounterBuilder;

  const SectionProgressBar({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    this.title = 'التقدم في القسم',
    this.isZeroBasedIndex = true,
    this.showPercentage = false,
    this.progressColor,
    this.backgroundColor,
    this.height,
    this.padding,
    this.customCounterBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // نحسب القيمة الرقمية الفعلية لتغذية الـ Cubit
    final int effectiveCurrent = isZeroBasedIndex ? currentIndex + 1 : currentIndex;

    return BlocProvider(
      create: (_) => SectionProgressCubit(
        currentIndex: effectiveCurrent,
        totalCount: totalCount,
      ),
      child: _SectionProgressBarView(
        currentIndex: effectiveCurrent,
        totalCount: totalCount,
        title: title,
        showPercentage: showPercentage,
        progressColor: progressColor,
        backgroundColor: backgroundColor,
        height: height,
        padding: padding,
        customCounterBuilder: customCounterBuilder,
      ),
    );
  }
}

class _SectionProgressBarView extends StatefulWidget {
  final int currentIndex;
  final int totalCount;
  final String title;
  final bool showPercentage;
  final Color? progressColor;
  final Color? backgroundColor;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final String Function(int current, int total, int percentage)? customCounterBuilder;

  const _SectionProgressBarView({
    required this.currentIndex,
    required this.totalCount,
    required this.title,
    required this.showPercentage,
    this.progressColor,
    this.backgroundColor,
    this.height,
    this.padding,
    this.customCounterBuilder,
  });

  @override
  State<_SectionProgressBarView> createState() => _SectionProgressBarViewState();
}

class _SectionProgressBarViewState extends State<_SectionProgressBarView> {
  @override
  void didUpdateWidget(covariant _SectionProgressBarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // عند تغير المدخلات من الشاشة الأم، نقوم بإشعار الكيوبت لتحديث الحسابات داخلياً
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.totalCount != widget.totalCount) {
      context.read<SectionProgressCubit>().updateProgress(
            currentIndex: widget.currentIndex,
            totalCount: widget.totalCount,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color activeColor = widget.progressColor ?? AppColors.goldAccent;
    final Color trackColor = widget.backgroundColor ??
        (isDark
            ? Colors.grey.shade900
            : AppColors.primary.withValues(alpha: 0.1));

    return BlocBuilder<SectionProgressCubit, SectionProgressState>(
      builder: (context, state) {
        // نص العداد المعروض
        final String countText = widget.customCounterBuilder != null
            ? widget.customCounterBuilder!(
                state.currentIndex,
                state.totalCount,
                state.percentage,
              )
            : widget.showPercentage
                ? '${state.currentIndex} / ${state.totalCount} (${state.percentage}%)'
                : '${state.currentIndex} / ${state.totalCount}';

        return Padding(
          padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  Text(
                    countText,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: state.progress),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, _) {
                    return LinearProgressIndicator(
                      value: animatedValue,
                      minHeight: widget.height ?? 6.h,
                      backgroundColor: trackColor,
                      valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
