import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ActionGridCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color activeColor;
  final bool isActive;
  final bool isErrorState; // تُستخدم لحالة تشغيل الصوت (اللون الأحمر)
  final VoidCallback onTap;
  final Widget actionWidget;

  const ActionGridCard({
    super.key,
    required this.title,
    required this.icon,
    required this.activeColor,
    required this.isActive,
    required this.onTap,
    required this.actionWidget,
    this.isErrorState = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // تحديد الألوان بناءً على حالة العنصر
    final borderColor = isActive
        ? activeColor.withValues(alpha: 0.5)
        : (isDark ? Colors.white10 : Colors.grey.shade200);
    final borderWidth = isActive ? 1.5 : 1.0;

    final shadowColor = isActive
        ? activeColor.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.03);

    final iconBgColor = isActive
        ? activeColor.withValues(alpha: 0.15)
        : (isErrorState
              ? Colors.red.withValues(alpha: 0.1)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100));

    final iconFillColor = isErrorState
        ? Colors.red
        : (isActive
              ? activeColor
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade500));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconFillColor, size: 18.sp),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              Expanded(flex: 4, child: Center(child: actionWidget)),
            ],
          ),
        ),
      ),
    );
  }
}
