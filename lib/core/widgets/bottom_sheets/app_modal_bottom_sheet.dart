import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';

/// [AppModalBottomSheet]
/// مكون سفلي احترافي عام وموحد وعالي المرونة (UI & UX متميز)
/// يدعم نمط القوائم (ListView)، ونمط النماذج والمحتوى المخصص (Custom Child)،
/// والأزرار المثبتة في الأسفل (Sticky Bottom Widget)، مع معالجة ذكية للوحة المفاتيح وتوافق كامل مع الثيم.
class AppModalBottomSheet extends StatelessWidget {
  /// عنوان النافذة السفلية
  final String title;

  /// وصف أو تنبيه توضيحي اختياري أسفل العنوان
  final String? subtitle;

  /// أيقونة أو ويدجت إضافي في يسار شريط العنوان (مثل زر إضافة، زر إغلاق، إلخ)
  final Widget? trailing;

  /// ويدجت مخصص في يمين العنوان (بديل عن الشريط اللوني الافتراضي)
  final Widget? leading;

  /// نسبة ارتفاع النافذة من الشاشة (مثلاً 0.65 = 65% من الشاشة). إذا كان null يتكيف مع المحتوى
  final double? heightFraction;

  /// محتوى مخصص بالكامل (للنماذج، الإدخال، الحقول، إلخ)
  final Widget? child;

  /// عدد عناصر القائمة (عند استخدام نمط القائمة)
  final int? itemCount;

  /// باني عناصر القائمة
  final IndexedWidgetBuilder? itemBuilder;

  /// فاصل بين عناصر القائمة
  final IndexedWidgetBuilder? separatorBuilder;

  /// ويدجت يظهر عند خلو القائمة
  final Widget? emptyWidget;

  /// رسالة نصية تظهر عند خلو القائمة
  final String? emptyMessage;

  /// مكون مثبت أسفل النافذة (مثل زر الحفظ أو أزرار التأكيد)
  final Widget? bottomWidget;

  /// هل يظهر مؤشر السحب الرمادي في الأعلى
  final bool showDragHandle;

  /// هل يظهر الشريط اللوني الرأسي بجانب العنوان
  final bool showPrimaryBar;

  /// حشوة داخلية للمحتوى
  final EdgeInsetsGeometry? contentPadding;

  const AppModalBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.heightFraction = 0.65,
    this.child,
    this.itemCount,
    this.itemBuilder,
    this.separatorBuilder,
    this.emptyWidget,
    this.emptyMessage = 'لا توجد بيانات حالياً',
    this.bottomWidget,
    this.showDragHandle = true,
    this.showPrimaryBar = true,
    this.contentPadding,
  });

  /// دالة مساعدة سريعة لفتح الشيت السفلية من أي مكان في التطبيق بسطر واحد وبأفضل إعدادات
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? trailing,
    Widget? leading,
    double? heightFraction = 0.65,
    Widget? child,
    int? itemCount,
    IndexedWidgetBuilder? itemBuilder,
    IndexedWidgetBuilder? separatorBuilder,
    Widget? emptyWidget,
    String? emptyMessage,
    Widget? bottomWidget,
    bool showDragHandle = true,
    bool showPrimaryBar = true,
    bool isDismissible = true,
    bool enableDrag = true,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => AppModalBottomSheet(
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        leading: leading,
        heightFraction: heightFraction,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: separatorBuilder,
        emptyWidget: emptyWidget,
        emptyMessage: emptyMessage,
        bottomWidget: bottomWidget,
        showDragHandle: showDragHandle,
        showPrimaryBar: showPrimaryBar,
        contentPadding: contentPadding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    // حساب الارتفاع الثابت أو المتجاوب
    final double? fixedHeight = heightFraction != null
        ? (mediaQuery.size.height * heightFraction!) + (keyboardHeight > 0 ? keyboardHeight * 0.5 : 0)
        : null;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Container(
        height: fixedHeight,
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: heightFraction != null ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. مؤشر السحب الرمادي العلوي
              if (showDragHandle)
                Center(
                  child: Container(
                    width: 44.w,
                    height: 4.5.h,
                    margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),

              // 2. شريط العنوان التفاعلي
              Padding(
                padding: EdgeInsets.only(
                  top: showDragHandle ? 4.h : 16.h,
                  left: 16.w,
                  right: 16.w,
                  bottom: 8.h,
                ),
                child: Row(
                  children: [
                    // الشريط اللوني المميز للعنوان
                    if (leading != null)
                      leading!
                    else if (showPrimaryBar) ...[
                      Container(
                        width: 4.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],

                    // نص العنوان
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.primary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),

                    // الإجراء الجانبي (زر الإضافة، زر الإغلاق...)
                    if (trailing != null) trailing!,
                  ],
                ),
              ),

              // 3. التنبيه أو الوصف الفرعي (اختياري)
              if (subtitle != null && subtitle!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: isDark ? AppColors.goldAccent : AppColors.primary,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey.shade300 : AppColors.primary,
                              height: 1.4,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // فاصل خفيف
              Divider(
                height: 12.h,
                thickness: 0.8,
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
              ),

              // 4. المحتوى الرئيسي (سواءً قائمة أو محتوى مخصص)
              Expanded(
                flex: heightFraction != null ? 1 : 0,
                child: Padding(
                  padding: contentPadding ?? EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildBody(context, isDark),
                ),
              ),

              // 5. الويدجت المثبت في الأسفل (أزرار الحفظ أو الإجراءات)
              if (bottomWidget != null) ...[
                Container(
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    top: 10.h,
                    bottom: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: bottomWidget!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    // إذا تم تمرير child مباشر (مثل النماذج)
    if (child != null) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 16.h),
        child: child!,
      );
    }

    // إذا كانت القائمة فارغة
    if (itemCount == null || itemCount == 0) {
      if (emptyWidget != null) return emptyWidget!;
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                size: 40.sp,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 12.h),
              Text(
                emptyMessage ?? 'لا توجد بيانات حالياً',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey.shade500,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // بناء القائمة (ListView)
    if (separatorBuilder != null) {
      return ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(top: 4.h, bottom: 16.h),
        itemCount: itemCount!,
        separatorBuilder: separatorBuilder!,
        itemBuilder: itemBuilder!,
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(top: 4.h, bottom: 16.h),
      itemCount: itemCount!,
      itemBuilder: itemBuilder!,
    );
  }
}
