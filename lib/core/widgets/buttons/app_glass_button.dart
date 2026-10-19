import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// زر أنيق متعدد الاستخدامات (دائري أو مستطيل مقصوص الحواف) بتأثير زجاجي متجاوب
class AppGlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final String? tooltip;
  final double width;
  final double height;
  final bool isCircle;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;

  const AppGlassButton({
    super.key,
    required this.onTap,
    required this.child,
    this.tooltip,
    required this.width,
    required this.height,
    this.isCircle = false,
    this.borderRadius = 6.0,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor =
        borderColor ?? Colors.white.withValues(alpha: 0.5);
    final effectiveBgColor =
        backgroundColor ?? Colors.white.withValues(alpha: 0.08);

    final Widget buttonBody = Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: isCircle ? const CircleBorder() : null,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: effectiveBgColor,
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
            border: Border.all(
              color: effectiveBorderColor,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: child,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: buttonBody,
      );
    }
    return buttonBody;
  }
}
