import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import '../models/unified_habit_item.dart';

/// ==============================================================================
/// بطاقة العبادة الموحدة (نقر مخصص على الدائرة + أنميشن متأنٍ + بدون أيقونات جانبية)
/// ==============================================================================
class UnifiedHabitTile extends StatefulWidget {
  final UnifiedHabitItem item;
  final bool isCompleted;
  final VoidCallback onToggle;

  const UnifiedHabitTile({
    super.key,
    required this.item,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  State<UnifiedHabitTile> createState() => _UnifiedHabitTileState();
}

class _UnifiedHabitTileState extends State<UnifiedHabitTile> {
  // حالة محلية تسبق الانتقال لإظهار علامة الصح بوضوح وتأني للمستخدم
  bool? _localCompletedOverride;
  bool _isTransitioning = false;

  bool get _effectiveCompleted => _localCompletedOverride ?? widget.isCompleted;

  @override
  void didUpdateWidget(covariant UnifiedHabitTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCompleted != widget.isCompleted) {
      _localCompletedOverride = null;
      _isTransitioning = false;
    }
  }

  void _handleCircleTap() {
    if (_isTransitioning) return;

    HapticFeedback.mediumImpact();

    // 1. إظهار علامة الصح أو إزالتها لحظياً داخل الدائرة
    final targetState = !_effectiveCompleted;
    setState(() {
      _localCompletedOverride = targetState;
      _isTransitioning = true;
    });

    // 2. إعطاء مهلة بصرية مريحة ومتأنية (450 مللي ثانية) ليرى المستخدم الصح، ثم يتم النقل للتبويب الآخر
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) {
        widget.onToggle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDone = _effectiveCompleted;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _isTransitioning ? 0.65 : 1.0,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isDone
              ? (isDark
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : AppColors.primary.withValues(alpha: 0.06))
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDone
                ? AppColors.primaryLight.withValues(alpha: 0.5)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08)),
            width: isDone ? 1.2 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : AppColors.subtleShadow.withValues(alpha: 0.45),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
          child: Row(
            children: [
              // 1. زر الاختيار الدائري (حصري للنقر ومستقل عن باقي البطاقة)
              GestureDetector(
                onTap: _handleCircleTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(4.w), // منطقة لمس واسعة ومريحة
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOut,
                    width: 29.w,
                    height: 29.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isDone
                            ? AppColors.primary
                            : (isDark
                                ? Colors.white54
                                : AppColors.lightSecondaryText.withValues(alpha: 0.6)),
                        width: 1.8,
                      ),
                    ),
                    child: isDone
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 200),
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 18.r,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                        : null,
                  ),
                ),
              ),

              SizedBox(width: 10.w),

              // 2. تفاصيل العبادة (تم حذف أيقونات الشمس والنجمة وغيرها كما طلبت)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // الصف الأول: اسم العبادة وبادج الركعات / التفصيل
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.bold,
                              color: isDone
                                  ? (isDark
                                      ? Colors.white60
                                      : AppColors.lightSecondaryText)
                                  : (isDark ? Colors.white : AppColors.darkBackground),
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                          child: Text(
                            widget.item.badgeText,
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppColors.lightSecondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 5.h),

                    // الصف الثاني: الوقت والوصف المختصر
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13.r,
                          color: AppColors.goldAccent,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          widget.item.timeLabel,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldAccent,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            widget.item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.lightSecondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. زر الإجراء السريع (قراءة الأذكار / فتح المسبحة / قراءة السورة)
              if (widget.item.actionText != null && widget.item.route != null) ...[
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (widget.item.routeArguments != null) {
                      Navigator.pushNamed(
                        context,
                        widget.item.route!,
                        arguments: widget.item.routeArguments,
                      );
                    } else {
                      Navigator.pushNamed(context, widget.item.route!);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.item.actionText!,
                          style: TextStyle(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 10.r,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
