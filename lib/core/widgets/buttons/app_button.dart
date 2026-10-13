/// ==============================================================================
/// 📌 وصف الملف: app_button.dart
/// ==============================================================================
/// المكون العام والموحد للأزرار في تطبيق ترتيل (Universal App Button Component).
///
/// 🌟 الخصائص والميزات الأساسية:
/// 1. أنماط متعددة (Variants):
///    - primary: أخضر إسلامي فاخر للعمليات الرئيسية.
///    - secondary: لون ثانوي أنيق.
///    - gold: ذهبي فاخر للأوسمة والجوائز والمكافآت.
///    - outline: إطار أنيق مع خلفية شفافة.
///    - glass: زجاجي شفاف يعكس خلفية الصحراء مع حواف مضيئة وتأثير بلور.
///    - danger / error: أحمر للعمليات التحذيرية أو الإجابات الخاطئة.
///    - success: أخضر زمردي للإجابات الصحيحة والتفوق.
///
/// 2. أحجام وأشكال مرنة:
///    - small, medium, large
///    - زر دائري عمودي (AppButton.circular): يعرض أيقونة في دائرة زجاجية وتحتها نص بخط Amiri
///    - زر زجاجي كبسولي (AppButton.glass)
/// ==============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';

enum AppButtonVariant {
  primary,
  secondary,
  gold,
  outline,
  glass,
  danger,
  success,
}

enum AppButtonSize {
  small,
  medium,
  large,
}

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? customColor;
  final Color? customTextColor;
  final String? subtitle;
  final String? badge;
  final bool isLoading;
  final bool isFullWidth;
  final bool isCircular; // نمط دائري رأسي (أيقونة داخل دائرة + نص تحته)
  final String fontFamily; // يدعم Amiri أو Cairo
  final double? width;
  final double? height;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.customColor,
    this.customTextColor,
    this.subtitle,
    this.badge,
    this.isLoading = false,
    this.isFullWidth = false,
    this.isCircular = false,
    this.fontFamily = 'Amiri',
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
  });

  /// 🌟 مصنع سريع لزر دائري زجاجي معبر (Circular Glass Button)
  /// يعرض أيقونة دائرية زجاجية شفافة بنسبة 0.45 وتحتها اسم الوسام أو الزر بخط Amiri
  factory AppButton.circular({
    Key? key,
    required String text,
    required IconData icon,
    required VoidCallback? onPressed,
    Color? iconColor,
    double? diameter,
    String? fontFamily = 'Amiri',
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.glass,
      leadingIcon: icon,
      isCircular: true,
      customTextColor: iconColor,
      fontFamily: fontFamily ?? 'Amiri',
      width: diameter ?? 40.w,
      height: diameter ?? 40.h,
    );
  }

  /// 🌟 مصنع سريع لزر زجاجي عائم (Floating Glass Button)
  factory AppButton.glass({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    IconData? leadingIcon,
    String? subtitle,
    String? badge,
    Color? iconColor,
    double? width,
    String fontFamily = 'Amiri',
    EdgeInsetsGeometry? padding,
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.glass,
      size: AppButtonSize.small,
      leadingIcon: leadingIcon,
      subtitle: subtitle,
      badge: badge,
      customTextColor: iconColor,
      width: width,
      fontFamily: fontFamily,
      padding: padding,
    );
  }

  /// 🌟 مصنع سريع لزر ذهبي فاخر
  factory AppButton.gold({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    IconData? leadingIcon,
    IconData? trailingIcon,
    bool isFullWidth = false,
    String fontFamily = 'Amiri',
  }) {
    return AppButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: AppButtonVariant.gold,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      isFullWidth: isFullWidth,
      fontFamily: fontFamily,
    );
  }

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    final config = _getButtonConfig(isDark, isEnabled);

    // 1️⃣ النمط الدائري الرأسي (أيقونة في دائرة زجاجية شفافة + النص تحتها بخط Amiri)
    if (widget.isCircular) {
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          if (isEnabled) {
            HapticFeedback.lightImpact();
            widget.onPressed!();
          }
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // الدائرة الزجاجية الشفافة بنسبة ~0.45
              Container(
                width: widget.width ?? 40.w,
                height: widget.height ?? 40.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.45),
                  border: Border.all(
                    color: config.borderColor,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 14.r,
                          height: 14.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(config.textColor),
                          ),
                        )
                      : Icon(
                          widget.leadingIcon,
                          size: 19.sp,
                          color: widget.customTextColor ?? config.iconColor,
                        ),
                ),
              ),

              SizedBox(height: 3.h),

              // النص تحت الدائرة بخط Amiri الأصيل
              Text(
                widget.text,
                style: TextStyle(
                  fontFamily: widget.fontFamily,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.goldAccent : AppColors.primary,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 2️⃣ النمط الأفقي العادي (كبسولة / مستطيل)
    Widget buttonContent = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16.r,
            height: 16.r,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(config.textColor),
            ),
          ),
          SizedBox(width: 8.w),
        ] else if (widget.leadingIcon != null) ...[
          Icon(
            widget.leadingIcon,
            size: config.iconSize,
            color: widget.customTextColor ?? config.iconColor,
          ),
          SizedBox(width: 6.w),
        ],

        // النصوص (العنوان الرئيسي + العنوان الفرعي إن وجد)
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.text,
                style: TextStyle(
                  fontFamily: widget.fontFamily,
                  fontSize: config.fontSize,
                  fontWeight: FontWeight.bold,
                  color: config.textColor,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontFamily: widget.fontFamily,
                    fontSize: (config.fontSize - 3).clamp(9.0, 14.0).sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        if (widget.badge != null && widget.badge!.isNotEmpty) ...[
          SizedBox(width: 6.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColors.goldAccent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              widget.badge!,
              style: TextStyle(
                fontFamily: widget.fontFamily,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],

        if (widget.trailingIcon != null && !widget.isLoading) ...[
          SizedBox(width: 6.w),
          Icon(
            widget.trailingIcon,
            size: config.iconSize,
            color: widget.customTextColor ?? config.iconColor,
          ),
        ],
      ],
    );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        if (isEnabled) {
          HapticFeedback.lightImpact();
          widget.onPressed!();
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.isFullWidth ? double.infinity : widget.width,
          height: widget.height,
          padding: widget.padding ?? config.padding,
          decoration: BoxDecoration(
            color: config.backgroundColor,
            gradient: config.gradient,
            borderRadius: BorderRadius.circular(
              widget.borderRadius ?? config.borderRadius,
            ),
            border: Border.all(
              color: config.borderColor,
              width: config.borderWidth,
            ),
            boxShadow: config.boxShadow,
          ),
          child: buttonContent,
        ),
      ),
    );
  }

  _ButtonStylingConfig _getButtonConfig(bool isDark, bool isEnabled) {
    EdgeInsets padding;
    double fontSize;
    double iconSize;
    double borderRadius;

    switch (widget.size) {
      case AppButtonSize.small:
        padding = EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h);
        fontSize = 13.sp;
        iconSize = 16.sp;
        borderRadius = 12.r;
        break;
      case AppButtonSize.large:
        padding = EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h);
        fontSize = 17.sp;
        iconSize = 22.sp;
        borderRadius = 18.r;
        break;
      case AppButtonSize.medium:
        padding = EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h);
        fontSize = 15.sp;
        iconSize = 18.sp;
        borderRadius = 14.r;
        break;
    }

    if (!isEnabled) {
      return _ButtonStylingConfig(
        backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
        borderColor: Colors.transparent,
        borderWidth: 0,
        textColor: isDark ? Colors.white30 : Colors.grey.shade500,
        iconColor: isDark ? Colors.white30 : Colors.grey.shade500,
        padding: padding,
        fontSize: fontSize,
        iconSize: iconSize,
        borderRadius: borderRadius,
        boxShadow: [],
      );
    }

    Color bgColor = Colors.transparent;
    Color borderColor = Colors.transparent;
    double borderWidth = 1.0;
    Color textColor = Colors.white;
    Color iconColor = Colors.white;
    Gradient? gradient;
    List<BoxShadow> boxShadow = [];

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bgColor = widget.customColor ?? AppColors.primary;
        textColor = Colors.white;
        iconColor = Colors.white;
        boxShadow = [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ];
        break;

      case AppButtonVariant.gold:
        gradient = const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFD4AF37), Color(0xFFB58E24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderColor = const Color(0xFFFFF176).withValues(alpha: 0.7);
        borderWidth = 1.2;
        textColor = const Color(0xFF2E2300);
        iconColor = const Color(0xFF2E2300);
        boxShadow = [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];
        break;

      case AppButtonVariant.glass:
        // زجاجي شفاف بنسبة 0.45 يعكس خلفية الصحراء
        bgColor = isDark
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.45);
        borderColor = isDark
            ? AppColors.goldAccent.withValues(alpha: 0.45)
            : AppColors.primary.withValues(alpha: 0.40);
        borderWidth = 1.2;
        textColor = isDark ? Colors.white : AppColors.primary;
        iconColor = widget.customTextColor ?? AppColors.goldAccent;
        boxShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ];
        break;

      case AppButtonVariant.outline:
        bgColor = Colors.transparent;
        borderColor = widget.customColor ?? AppColors.primary;
        borderWidth = 1.5;
        textColor = widget.customColor ?? (isDark ? Colors.white : AppColors.primary);
        iconColor = textColor;
        break;

      case AppButtonVariant.danger:
        bgColor = const Color(0xFFD32F2F);
        textColor = Colors.white;
        iconColor = Colors.white;
        boxShadow = [
          BoxShadow(
            color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ];
        break;

      case AppButtonVariant.success:
        bgColor = const Color(0xFF2E7D32);
        textColor = Colors.white;
        iconColor = Colors.white;
        boxShadow = [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ];
        break;

      case AppButtonVariant.secondary:
        bgColor = widget.customColor ?? AppColors.secondary;
        textColor = Colors.white;
        iconColor = Colors.white;
        break;
    }

    if (widget.customTextColor != null) {
      textColor = widget.customTextColor!;
    }

    return _ButtonStylingConfig(
      backgroundColor: bgColor,
      gradient: gradient,
      borderColor: borderColor,
      borderWidth: borderWidth,
      textColor: textColor,
      iconColor: iconColor,
      padding: padding,
      fontSize: fontSize,
      iconSize: iconSize,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
    );
  }
}

class _ButtonStylingConfig {
  final Color backgroundColor;
  final Gradient? gradient;
  final Color borderColor;
  final double borderWidth;
  final Color textColor;
  final Color iconColor;
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
  final double borderRadius;
  final List<BoxShadow> boxShadow;

  _ButtonStylingConfig({
    required this.backgroundColor,
    this.gradient,
    required this.borderColor,
    required this.borderWidth,
    required this.textColor,
    required this.iconColor,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.borderRadius,
    required this.boxShadow,
  });
}
