/// ==============================================================================
///  وصف الملف: app_status_view.dart
/// ==============================================================================
/// مكون واجهة مستخدم موحد وقابل لإعادة الاستخدام في كافة شاشات التطبيق:
/// 1. حالات الخطأ وتعذر التحميل (Error State) مع زر إعادة المحاولة.
/// 2. الحالات الفارغة (Empty State) مثل: نتائج بحث فارغة، عدم وجود أذكار أو تسابيح.
/// 3. الحالات المخصصة (Custom / Info State) مع إمكانية عرض زر مخصص بتصميم موحد.
///
///  يعتمد داخلياً على الزر الموحد الفاخر `AppButton` دون الحاجة لإعادة كتابة الأزرار.
/// ==============================================================================
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/buttons/app_button.dart';

class AppStatusView extends StatelessWidget {
  /// عنوان أو نص الرسالة الأساسي
  final String title;

  /// وصف أو تفاصيل إضافية تحت العنوان (اختياري)
  final String? subtitle;

  /// الأيقونة المعروضة
  final IconData icon;

  /// لون الأيقونة
  final Color? iconColor;

  /// حجم الأيقونة
  final double? iconSize;

  /// نص الزر (إذا لم يُحدد لن يظهر الزر)
  final String? buttonText;

  /// الدالة المنفذة عند الضغط على الزر
  final VoidCallback? onButtonPressed;

  /// أيقونة تظهر داخل الزر (اختياري)
  final IconData? buttonIcon;

  /// نمط الزر من منظومة أزرار التطبيق (primary, gold, outline, etc.)
  final AppButtonVariant buttonVariant;

  /// هل يوضع إطار دائري ناعم خلف الأيقونة (شكل جمالي راقٍ)
  final bool hasIconBackground;

  /// هل يأخذ مساحة الصفحة كاملة بالتوسيط (الافتراضي true)
  final bool isCentered;

  /// مسافات الحشو حول المكون
  final EdgeInsetsGeometry? padding;

  const AppStatusView({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.iconSize,
    this.buttonText,
    this.onButtonPressed,
    this.buttonIcon,
    this.buttonVariant = AppButtonVariant.primary,
    this.hasIconBackground = false,
    this.isCentered = true,
    this.padding,
  });

  // ============================================================================
  //  Constructor مخصص لحالات الخطأ والفشل (Error)
  // ============================================================================
  factory AppStatusView.error({
    Key? key,
    required String message,
    String? subtitle,
    IconData icon = Icons.error_outline_rounded,
    Color? iconColor,
    String buttonText = 'إعادة المحاولة',
    VoidCallback? onRetry,
  }) {
    return AppStatusView(
      key: key,
      title: message,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor ?? Colors.red.shade400,
      buttonText: onRetry != null ? buttonText : null,
      onButtonPressed: onRetry,
      buttonIcon: Icons.refresh_rounded,
      buttonVariant: AppButtonVariant.outline,
    );
  }

  // ============================================================================
  //  Constructor مخصص للحالات الفارغة (Empty State / No Results)
  // ============================================================================
  factory AppStatusView.empty({
    Key? key,
    required String title,
    String? subtitle,
    IconData icon = Icons.inbox_outlined,
    Color? iconColor,
    String? buttonText,
    VoidCallback? onButtonPressed,
    IconData? buttonIcon,
    AppButtonVariant buttonVariant = AppButtonVariant.primary,
  }) {
    return AppStatusView(
      key: key,
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor ?? Colors.grey.shade400,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
      buttonIcon: buttonIcon,
      buttonVariant: buttonVariant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // أيقونة الحالة
          if (hasIconBackground)
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize ?? 56.sp,
                color: iconColor ?? AppColors.primary,
              ),
            )
          else
            Icon(
              icon,
              size: iconSize ?? 68.sp,
              color: iconColor ?? AppColors.primary,
            ),
          SizedBox(height: 16.h),

          // العنوان الرئيسي
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // النص التوضيحي إن وجد
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
                fontFamily: 'Cairo',
              ),
            ),
          ],

          // الزر الموحد إن وُجد
          if (buttonText != null && onButtonPressed != null) ...[
            SizedBox(height: 20.h),
            AppButton(
              text: buttonText!,
              onPressed: onButtonPressed,
              variant: buttonVariant,
              leadingIcon: buttonIcon,
              size: AppButtonSize.medium,
              fontFamily: 'Cairo',
            ),
          ],
        ],
      ),
    );

    if (isCentered) {
      return Center(child: content);
    }
    return content;
  }
}
